pragma solidity >=0.4.21 <0.7.0;

import "./interfaces/IUniswapExchange.sol";
import "./SimplePOSToken.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract SimplePOS {
    address public owner;
    IUniswapExchange public exchange;
    SimplePOSToken public posToken;
    uint public commission;

    using SafeMath for uint;

    constructor(
        IUniswapExchange _exchange,
        string memory _posTokenName,
        string memory _posTokenSymbol,
        uint _initialRatio, // initialMintedPOSTokens = initialExchangeTokenValue * _initialRatio
        uint _commission) // <= 50%; comission = incommingValue / _comission
        public
        payable
    {
        require(_commission > 1, "Commission should not be 100%");
        require(msg.value > 0, "ETH is required to provide initial liquidity in _exchange token for SimplePOS.");
        require(_initialRatio > 0, "Initial ratio should be positive.");
        owner = msg.sender;
        exchange = _exchange;
        posToken = new SimplePOSToken(_posTokenName, _posTokenSymbol);
        commission = _commission;
        uint initialExchangeTokenValue = exchange.ethToTokenSwapInput.value(msg.value)(0, now);
        uint initialMintedPOSTokens = initialExchangeTokenValue.mul(_initialRatio);
        posToken.mint(msg.sender, initialMintedPOSTokens);
    }

    function getExchangeAddress()
        public
        view
        returns (address)
    {
        return address(exchange);
    }

    function getLiquidityTokenAddress()
        public
        view
        returns (address)
    {
        return exchange.tokenAddress();
    }
}
