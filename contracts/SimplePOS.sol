pragma solidity >=0.4.21 <0.7.0;

import "./interfaces/IUniswapExchange.sol";
import "./SimplePOSToken.sol";

contract SimplePOS {

    address public owner;
    SimplePOSToken public posToken;
    uint public commission;

    constructor(
        string memory _posTokenName,
        string memory _posTokenSymbol,
        uint _commission) public
    {
        require(_commission > 1, "Commission should not be 100%");
        owner = msg.sender;
        posToken = new SimplePOSToken(_posTokenName, _posTokenSymbol);
        commission = _commission;
    }

}
