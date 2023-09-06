// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import './libs/BKBridgeHandler.sol';
import './interfaces/IBKBridgeRouter.sol';
import './BKBridgeAccess.sol';

contract BKBridgeRouter is IBKBridgeRouter, BKBridgeAccess {
    mapping(bytes32 => uint256) public orderStatus;
    mapping(bytes32 => uint256) public orderAmount;

    event BKBridge(
        uint256 indexed orderStatus,
        bytes32 indexed transferId,
        address vaultReceiver,
        address sender,
        address receiver,
        address srcToken,
        address dstToken,
        uint256 srcChainId,
        uint256 dstChainId,
        uint256 amount,
        uint256 timestamp
    );

    constructor(address _owner) BKBridgeAccess() {
        _checkZero(_owner);
        _transferOwnership(_owner);
    }

    receive() external payable {}

    function send(SignInfo calldata _signInfo, OrderInfo calldata _orderInfo)
        external
        payable
        whenNotPaused
        nonReentrant
        onlySender(_orderInfo.sender)
    {
        _checkSigner(_signInfo.nonce, _signInfo.signature, _orderInfo.transferId, _orderInfo.dstChainId);
        _checkVaultReceiver(_orderInfo.vaultReceiver);
        _checkVaultToken(_orderInfo.srcToken);
        HandlerCallBack memory _callback = BKBridgeHandler.send(_orderInfo, orderStatus, orderAmount);
        _emitEvent(_orderInfo, _callback);
    }

    function sendV1(SignInfo calldata _signInfo, OrderInfo calldata _orderInfo, SwapV1Info calldata _swapV1Info)
        external
        payable
        whenNotPaused
        nonReentrant
        onlySender(_orderInfo.sender)
    {
        _checkSigner(_signInfo.nonce, _signInfo.signature, _orderInfo.transferId, _orderInfo.dstChainId);
        _checkVaultReceiver(_orderInfo.vaultReceiver);
        _checkVaultToken(_swapV1Info.path[_swapV1Info.path.length - 1]);
        _checkRouter(_swapV1Info.bkSwapV1Router);
        _checkSwapReceiver(vault, _swapV1Info.to);
        HandlerCallBack memory _callback = BKBridgeHandler.sendV1(_orderInfo, _swapV1Info, orderStatus, orderAmount);
        _emitEvent(_orderInfo, _callback);
    }

    function sendV2(SignInfo calldata _signInfo, OrderInfo calldata _orderInfo, SwapV2Info calldata _swapV2Info)
        external
        payable
        whenNotPaused
        nonReentrant
        onlySender(_orderInfo.sender)
    {
        _checkSigner(_signInfo.nonce, _signInfo.signature, _orderInfo.transferId, _orderInfo.dstChainId);
        _checkVaultReceiver(_orderInfo.vaultReceiver);
        _checkVaultToken(_swapV2Info.toTokenAddress);
        _checkRouter(_swapV2Info.bkSwapV2Router);
        _checkSwapReceiver(vault, _swapV2Info.to);
        HandlerCallBack memory _callback = BKBridgeHandler.sendV2(_orderInfo, _swapV2Info, orderStatus, orderAmount);
        _emitEvent(_orderInfo, _callback);
    }

    function relay(SignInfo calldata _signInfo, OrderInfo calldata _orderInfo, uint256 _relayAmount)
        external
        payable
        whenNotPaused
        nonReentrant
        onlyRelayer
    {
        _checkSigner(_signInfo.nonce, _signInfo.signature, _orderInfo.transferId, _orderInfo.dstChainId);
        _checkVaultReceiver(_orderInfo.vaultReceiver);
        _checkVaultToken(_orderInfo.dstToken);
        HandlerCallBack memory _callback = BKBridgeHandler.relay(_orderInfo, _relayAmount, orderStatus);
        _emitEvent(_orderInfo, _callback);
    }

    function relayV1(
        SignInfo calldata _signInfo,
        OrderInfo calldata _orderInfo,
        SwapV1Info calldata _swapV1Info,
        uint256 _relayAmount
    ) external payable whenNotPaused nonReentrant onlyRelayer {
        _checkSigner(_signInfo.nonce, _signInfo.signature, _orderInfo.transferId, _orderInfo.dstChainId);
        _checkVaultReceiver(_orderInfo.vaultReceiver);
        _checkVaultToken(_swapV1Info.path[0]);
        _checkRouter(_swapV1Info.bkSwapV1Router);
        _checkSwapReceiver(_orderInfo.receiver, _swapV1Info.to);
        HandlerCallBack memory _callback = BKBridgeHandler.relayV1(_orderInfo, _swapV1Info, _relayAmount, orderStatus);
        _emitEvent(_orderInfo, _callback);
    }

    function relayV2(
        SignInfo calldata _signInfo,
        OrderInfo calldata _orderInfo,
        SwapV2Info calldata _swapV2Info,
        uint256 _relayAmount
    ) external payable whenNotPaused nonReentrant onlyRelayer {
        _checkSigner(_signInfo.nonce, _signInfo.signature, _orderInfo.transferId, _orderInfo.dstChainId);
        _checkVaultReceiver(_orderInfo.vaultReceiver);
        _checkVaultToken(_swapV2Info.fromTokenAddress);
        _checkRouter(_swapV2Info.bkSwapV2Router);
        _checkSwapReceiver(_orderInfo.receiver, _swapV2Info.to);
        HandlerCallBack memory _callback = BKBridgeHandler.relayV2(_orderInfo, _swapV2Info, _relayAmount, orderStatus);
        _emitEvent(_orderInfo, _callback);
    }

    function cancel(SignInfo calldata _signInfo, OrderInfo calldata _orderInfo)
        external
        payable
        whenNotPaused
        nonReentrant
        onlyRelayer
    {
        _checkSigner(_signInfo.nonce, _signInfo.signature, _orderInfo.transferId, _orderInfo.dstChainId);
        HandlerCallBack memory _callback = BKBridgeHandler.cancel(_orderInfo, orderStatus);
        _emitEvent(_orderInfo, _callback);
    }

    function refund(SignInfo calldata _signInfo, OrderInfo calldata _orderInfo, uint256 _refundAmount)
        external
        payable
        whenNotPaused
        nonReentrant
        onlyRelayer
    {
        _checkSigner(_signInfo.nonce, _signInfo.signature, _orderInfo.transferId, _orderInfo.dstChainId);
        HandlerCallBack memory _callback =
            BKBridgeHandler.refund(_orderInfo, _refundAmount, vaultToken, orderStatus, orderAmount);
        _emitEvent(_orderInfo, _callback);
    }

    function _emitEvent(OrderInfo calldata _orderInfo, HandlerCallBack memory _callback) internal {
        emit BKBridge(
            _callback.status,
            _orderInfo.transferId,
            _orderInfo.vaultReceiver,
            _orderInfo.sender,
            _orderInfo.receiver,
            _orderInfo.srcToken,
            _orderInfo.dstToken,
            block.chainid,
            _orderInfo.dstChainId,
            _callback.amount,
            _orderInfo.timestamp
        );
    }
}
