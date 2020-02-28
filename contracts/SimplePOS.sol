pragma solidity >=0.4.21 <0.7.0;

import "./interfaces/IUniswapExchange.sol";
import "./SimplePOSToken.sol";

contract SimplePOS {
    address public owner;
    IUniswapExchange public exchange;
    SimplePOSToken public posToken;
    uint public commission;

    constructor(
        IUniswapExchange _exchange,
        string memory _posTokenName,
        string memory _posTokenSymbol,
        uint _initialRatio,
        uint _commission)
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
