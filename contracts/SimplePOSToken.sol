pragma solidity >=0.4.21 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Mintable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

contract SimplePOSToken is ERC20Mintable, ERC20Detailed {
    constructor (string memory name, string memory symbol) ERC20Detailed(name, symbol, 18) public {}
}
