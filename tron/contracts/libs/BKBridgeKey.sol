// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {OrderInfo} from '../interfaces/IBKBridgeParams.sol';

library BKBridgeKey {
    bytes16 internal constant BRIDGE_SALT0 = 'BKBridge';
    bytes16 internal constant BRIDGE_SALT1 = 'v1.0.0';

    function keyOf(OrderInfo calldata _orderInfo) internal pure returns (bytes32 key) {
        key = keccak256(
            abi.encodePacked(
                _orderInfo.transferId,
                _orderInfo.vaultReceiver,
                BRIDGE_SALT0,
                _orderInfo.sender,
                _orderInfo.receiver,
                _orderInfo.srcToken,
                _orderInfo.dstToken,
                _orderInfo.srcChainId,
                BRIDGE_SALT1,
                _orderInfo.dstChainId,
                _orderInfo.amount,
                _orderInfo.timestamp
            )
        );
    }
}
