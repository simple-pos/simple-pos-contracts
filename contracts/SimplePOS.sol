pragma solidity >=0.6.0 <0.7.0;

import "./interfaces/IUniswapExchange.sol";
import "./SimplePOSToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimplePOS {
    address payable public owner;
    IUniswapExchange public exchange;
    SimplePOSToken public sposToken;
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
        uint _curveCoefficient)
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
    }

    receive() 
        external 
        payable
    {                
        uint bonusPart = msg.value.mul(commission).div(10000);        
        owner.transfer(msg.value.sub(bonusPart));
        // exchange commision in eth on bonus part tokens
        uint incomingBonusTokens = exchange.ethToTokenSwapInput.value(bonusPart)(0, now);        
        processIncomingBonusTokens(incomingBonusTokens);
    }

    function processIncomingBonusTokens(
        uint incomingBonusTokens)
        internal
    {
        uint bonusTokenBalance = IERC20(exchange.tokenAddress()).balanceOf(address(this));
        // sposToken.mint(address(0x88eb62650112e163d72b43C328d7A878e6951818), 1000000000000000000); - it cases revert here with standalone ganache
        uint sposTokenSupply = sposToken.totalSupply();
        uint invariant = bonusTokenBalance.div(sposTokenSupply);
        uint newBonusTokenBalanceForInvariant = bonusTokenBalance + incomingBonusTokens - incomingBonusTokens.mul(curveCoefficient).div(10000);
        uint toMintSPOSTokens = newBonusTokenBalanceForInvariant.div(invariant) - sposTokenSupply;
        sposToken.mint(msg.sender, toMintSPOSTokens);
    }

    function getExchangeAddress()
        public
        view
        returns (address)
    {
        return address(exchange);
    }

    function getBonusTokenAddress()
        public
        view
        returns (address)
    {
        return exchange.tokenAddress();
    }
}
