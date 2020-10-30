pragma solidity >=0.6.0 <0.7.0;

import "./interfaces/IUniswapExchange.sol";
import "./SimplePOSToken.sol";
import "./subscription/Subscription.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimplePOS {
    address payable public owner;
    IUniswapExchange public exchange;
    SimplePOSToken public sposToken;
    Subscription public subscription;
    uint public commission;
    uint public curveCoefficient;

    using SafeMath for uint;

    /**
     * @dev Constructor
     * @param _exchange Exchange for bonus token owners
     * @param _sposTokenName SimplePOSToken name; SimplePOSToken controls bonus tokens pool
     * @param _sposTokenSymbol SimplePOSToken symbol; SimplePOSToken controls bonus tokens pool
     * @param _initialRatio SimplePOS creator sets up the initial ratio of bonus tokens pool to the SimplePOSToken supply
     * @param _commission Commission on incoming payments that should form bonus tokens pool; [0..10000); 1 unit == 0.01%
     * @param _curveCoefficient The bonding curve coefficient; [0..10000); 1 unit == 0.01%
     */
    constructor(
        IUniswapExchange _exchange,
        string memory _sposTokenName,
        string memory _sposTokenSymbol,
        uint _initialRatio,
        uint _commission,
        uint _curveCoefficient
    )
        public
        payable
    {
        require(msg.value > 0, "ETH is required to form bonus tokens pool");
        require(_initialRatio > 0, "Initial ratio should be positive");
        require(_commission < 10000, "Commission should be less than 100%");
        require(_curveCoefficient < 10000, "Curve coefficient should be less than 100%");
        owner = msg.sender;
        exchange = _exchange;
        sposToken = new SimplePOSToken(_sposTokenName, _sposTokenSymbol);
        commission = _commission;
        curveCoefficient = _curveCoefficient;
        uint initialExchangeTokenValue = exchange.ethToTokenSwapInput.value(msg.value)(0, now);
        uint initialMintedPOSTokens = initialExchangeTokenValue.mul(_initialRatio);
        sposToken.mint(msg.sender, initialMintedPOSTokens);
        // Deploy subscription contract (_toAddress, _tokenAddress, _tokenAmount, _periodSeconds, _gasPrice).
        // No limitation on required subscription fee and period. 
        // _gasPrice = 0 meaning we do not expect transactions relaying
        subscription = new Subscription(address(this), exchange.tokenAddress(), 0, 0, 0);
    }

    receive() 
        external 
        payable
    {                
        uint bonusPart = msg.value.mul(commission).div(10000);
        owner.transfer(msg.value.sub(bonusPart));
        (uint bonusTokenBalance, uint sposTokenSupply, uint invariant) = getBalanceSupplyInvariant();
        uint incomingBonusTokens = exchange.ethToTokenSwapInput.value(bonusPart)(0, now);
        mintSPOSTokens(incomingBonusTokens, bonusTokenBalance, sposTokenSupply, invariant, msg.sender);
    }

    function getBalanceSupplyInvariant()
        internal
        returns (uint bonusTokenBalance, uint sposTokenSupply, uint invariant)
    {
        bonusTokenBalance = IERC20(exchange.tokenAddress()).balanceOf(address(this));
        sposTokenSupply = sposToken.totalSupply();
        // We calculate with a precesion of 4 numbers
        invariant = bonusTokenBalance.mul(10000).div(sposTokenSupply);
    }

    function mintSPOSTokens(
        uint incomingBonusTokens,
        uint bonusTokenBalance,
        uint sposTokenSupply,
        uint invariant,
        address receiver
    )
        internal
    {
        uint newBonusTokenBalanceForInvariant = bonusTokenBalance + incomingBonusTokens - incomingBonusTokens.mul(curveCoefficient).div(10000);
        uint toMintSPOSTokens = newBonusTokenBalanceForInvariant.mul(10000).div(invariant) - sposTokenSupply;
        sposToken.mint(receiver, toMintSPOSTokens);
    }

    /**
     * @dev Exchange SPOS tokens on bonus tokens. This action burns 'amount' of SPOS and transfers bonus tokens to a caller.
     * @param _amount Amount of SPOS tokens to exchange     
     */
    function exchangeSposTokensOnBonusTokens(
        uint _amount
    )
        external        
    {
        // There should be always spos tokens minted to properly calculate invariant
        require(_amount < sposToken.totalSupply(), "SPOS token amount should be less than total supply.");
        // We do not check tokens availability here as 'burn' will check it
        IERC20 bonusToken = IERC20(exchange.tokenAddress());
        // toTransferBonusTokens < bonusToken.balanceOf(address(this) will always be true
        uint toTransferBonusTokens = _amount.mul(bonusToken.balanceOf(address(this))).div(sposToken.totalSupply());
        sposToken.burn(msg.sender, _amount);
        bonusToken.transfer(msg.sender, toTransferBonusTokens);        
    }

    /**
     * @dev Execute subscription for a user. This will accept payment in bonus tokens (signed by a user). SPOS tokens will be minted accordingly.
     * @param _from the SimplePOS subscriber
     * @param _tokenAmount amount of SimplePOS exchange tokens payed for the subscription
     * @param _periodSeconds the period in seconds between payments
     */
    function executeSubscription(
        address _from,
        uint256 _tokenAmount,
        uint256 _periodSeconds,
        bytes calldata _signature
    ) 
        external
        returns (bool success)
    {
        // calculate current parameters necessary for proper SPOS token minting
        (uint bonusTokenBalance, uint sposTokenSupply, uint invariant) = getBalanceSupplyInvariant();
        // execute subscription -- it will transfer bonus tokens to this contract
        // (from, to, tokenAddress, tokenAmount, periodSeconds, gasPrice, nonce, signature)
        require(subscription.executeSubscription(_from, address(this), exchange.tokenAddress(), _tokenAmount, _periodSeconds, 0, 1, _signature),
                "Could not execute subscription.");
        // transfer the owner part
        uint ownerPart = _tokenAmount.mul(10000 - commission).div(10000);
        IERC20 bonusToken = IERC20(exchange.tokenAddress());
        bonusToken.transfer(owner, ownerPart);
        // mint SPOS tokens to the subscriber
        mintSPOSTokens(_tokenAmount - ownerPart, bonusTokenBalance, sposTokenSupply, invariant, _from);
    }

    function getBonusTokenAddress()
        public
        view
        returns (address)
    {
        return exchange.tokenAddress();
    }
}
