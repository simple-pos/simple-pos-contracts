// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.5;

import "./SimplePOS.sol";
import "./interfaces/IUniswapExchange.sol";

contract SimplePOSFactory {
    event POSCreated(SimplePOS spos);

    /**
     * @dev Deploys Point of Sale
     * @param _exchange Exchange for bonus token owners
     * @param _sposTokenName SimplePOSToken name; SimplePOSToken controls bonus tokens pool
     * @param _sposTokenSymbol SimplePOSToken symbol; SimplePOSToken controls bonus tokens pool
     * @param _initialRatio SimplePOS creator sets up the initial ratio of bonus tokens pool to the SimplePOSToken supply
     * @param _commission Commission on incoming payments that should form bonus tokens pool; [0..10000); 1 unit == 0.01%
     * @param _curveCoefficient The bonding curve coefficient; [0..10000); 1 unit == 0.01%
     */
    function createPOS(
        IUniswapExchange _exchange,
        string calldata _sposTokenName,
        string calldata _sposTokenSymbol,
        uint256 _initialRatio,
        uint256 _commission,
        uint256 _curveCoefficient
    ) external payable {
        SimplePOS spos =
            new SimplePOS{value: msg.value}(
                _exchange,
                _sposTokenName,
                _sposTokenSymbol,
                _initialRatio,
                _commission,
                _curveCoefficient
            );

        emit POSCreated(spos);
    }
}
