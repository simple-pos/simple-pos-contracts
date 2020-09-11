pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SimplePOSToken is ERC20, AccessControl {
    bytes32 public constant TOKEN_MANAGER_ROLE = keccak256("TOKEN_MANAGER_ROLE");

    constructor (string memory name, string memory symbol) ERC20(name, symbol) public {
        _setupRole(TOKEN_MANAGER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(TOKEN_MANAGER_ROLE, msg.sender), "Caller is not a token manager");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        require(hasRole(TOKEN_MANAGER_ROLE, msg.sender), "Caller is not a token manager");
        _burn(from, amount);
    }
}
