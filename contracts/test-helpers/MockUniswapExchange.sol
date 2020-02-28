pragma solidity >=0.4.21 <0.7.0;

import "../interfaces/IUniswapExchange.sol";

contract MockUniswapExchange is IUniswapExchange {

    address _tokenAddress;

    constructor () public {
        _tokenAddress = 0x2448eE2641d78CC42D7AD76498917359D961A783;
    }

    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token) {
        return _tokenAddress;
    }

}
