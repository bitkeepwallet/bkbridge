// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {AccessType} from './IBKBridgeParams.sol';

interface IBKBridgeAccess {
    function setAccess(AccessType _accessType, bytes calldata _inputs) external;

    function checkBridgeReady() external view returns (bool);

    function pause() external;

    function unpause() external;

    function rescueETH() external;

    function rescueERC20(address asset) external;
}
