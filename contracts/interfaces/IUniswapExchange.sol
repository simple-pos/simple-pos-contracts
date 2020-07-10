pragma solidity >=0.6.0 <0.7.0;

abstract contract IUniswapExchange {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view virtual returns (address token);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline) external payable virtual returns (uint256  tokens_bought);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(uint256 tokens_sold, uint256 min_tokens_bought, uint256 min_eth_bought, uint256 deadline, address token_addr) external virtual returns (uint256  tokens_bought);
}
