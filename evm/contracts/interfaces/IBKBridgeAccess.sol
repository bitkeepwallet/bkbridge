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

    // function paused() external view returns(bool);

    // function transferOwnership(address newOwner) external;

    // function owner() external view returns(address);

    // function safe() external view returns(address);

    // function operator() external view returns(address);

    // function signer() external view returns(address);

    // function vault() external view returns(address);

    // function vaultToken() external view returns(address);

    // function isRelayer(address _addr) external view returns(bool);

    // function isRouter(address _addr) external view returns(bool);
}
