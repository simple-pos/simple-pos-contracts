pragma solidity >=0.6.0 <0.7.0;

import "../interfaces/IUniswapExchange.sol";

contract MockUniswapExchange is IUniswapExchange {
    address _tokenAddress;
    uint _ethToTokenSwapRate;
    uint _tokenToTokenSwapRate;

    constructor () 
        public 
    {
        _tokenAddress = 0x2448eE2641d78CC42D7AD76498917359D961A783;
        _ethToTokenSwapRate = 1;
        _tokenToTokenSwapRate = 1;
    }

    // Address of ERC20 token sold on this exchange
    function tokenAddress() 
        external 
        view 
        override 
        returns (address token) 
    {
        return _tokenAddress;
    }

    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) 
        external 
        payable 
        override
        returns (uint256  tokens_bought) 
    {
        return msg.value * _ethToTokenSwapRate;
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
