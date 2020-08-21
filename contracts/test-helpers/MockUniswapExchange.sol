pragma solidity >=0.6.0 <0.7.0;

import "../interfaces/IUniswapExchange.sol";
import "./MockStableCoin.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUniswapExchange is IUniswapExchange {
    MockStableCoin _exchangeToken;
    uint _ethToTokenSwapRate;
    uint _tokenToTokenSwapRate;

    event MockExchangeCreated(address indexed stableCoin);

    constructor () 
        public 
    {
        _exchangeToken = new MockStableCoin("Stable Coin", "STBL");
        _ethToTokenSwapRate = 1;
        _tokenToTokenSwapRate = 1;
        emit MockExchangeCreated(address(_exchangeToken));
    }

    // Address of ERC20 token sold on this exchange
    function tokenAddress() 
        external 
        view 
        override 
        returns (address token) 
    {
        return address(_exchangeToken);
    }

    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) 
        external 
        payable 
        override
        returns (uint256 tokens_bought) 
    {
        tokens_bought = msg.value * _ethToTokenSwapRate;
        _exchangeToken.mint(msg.sender, tokens_bought);
    }

    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) 
        external 
        override
        returns (uint256  tokens_bought) 
    {
        return tokens_sold * _tokenToTokenSwapRate;
    }

    function setEthToTokenSwapRate(uint newRate) 
        external
    {
        _ethToTokenSwapRate = newRate;
    }
}
