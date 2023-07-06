// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/swap/IBKSwap.sol';
import '../interfaces/swap/IBKSwapRouter.sol';
import './TransferHelper.sol';
import './BKBridgeKey.sol';
import '../interfaces/IBKBridgeErrors.sol';
import {OrderInfo, SignInfo, SwapV1Info, SwapV2Info, HandlerCallBack} from '../interfaces/IBKBridgeParams.sol';

library BKBridgeHandler {
    using SafeERC20 for IERC20;

    uint256 private constant _INEXIST = 0;
    uint256 private constant _SEND = 1;
    uint256 private constant _RELAY = 2;
    uint256 private constant _CANCEL = 3;
    uint256 private constant _REFUND = 4;

    function send(
        OrderInfo calldata _orderInfo,
        mapping(bytes32 => uint256) storage orderStatus,
        mapping(bytes32 => uint256) storage orderAmount
    ) external returns (HandlerCallBack memory callback) {
        bytes32 key = BKBridgeKey.keyOf(_orderInfo);
        if (orderStatus[key] != _INEXIST) {
            revert IBKBridgeErrors.OrderAlreadyExist();
        }

        IERC20 iVaultToken = IERC20(_orderInfo.srcToken);
        uint256 vaultBeforeBalance = iVaultToken.balanceOf(_orderInfo.vaultReceiver);

        orderAmount[key] = _orderInfo.amount;
        orderStatus[key] = _SEND;
        TransferHelper.safeTransferFrom(_orderInfo.srcToken, msg.sender, _orderInfo.vaultReceiver, _orderInfo.amount);

        if (iVaultToken.balanceOf(_orderInfo.vaultReceiver) - vaultBeforeBalance != _orderInfo.amount) {
            revert IBKBridgeErrors.WrongVaultReceiveToken();
        }

        callback.amount = _orderInfo.amount;
        callback.status = _SEND;
    }

    function sendV1(
        OrderInfo calldata _orderInfo,
        SwapV1Info calldata _swapV1Info,
        mapping(bytes32 => uint256) storage orderStatus,
        mapping(bytes32 => uint256) storage orderAmount
    ) external returns (HandlerCallBack memory callback) {
        address swapTokenOut = _swapV1Info.path[_swapV1Info.path.length - 1];
        bytes32 key = BKBridgeKey.keyOf(_orderInfo);
        if (orderStatus[key] != _INEXIST) {
            revert IBKBridgeErrors.OrderAlreadyExist();
        }

        IERC20 iSwapTokenOut = IERC20(swapTokenOut);
        uint256 vaultBeforeBalance = iSwapTokenOut.balanceOf(_orderInfo.vaultReceiver);

        orderStatus[key] = _SEND;
        _bridgeForSwapV1(_swapV1Info);

        uint256 valutTokenAmount = iSwapTokenOut.balanceOf(_orderInfo.vaultReceiver) - vaultBeforeBalance;
        if (valutTokenAmount < _swapV1Info.minAmountOut) {
            revert IBKBridgeErrors.WrongVaultReceiveToken();
        }

        orderAmount[key] = valutTokenAmount;

        callback.amount = valutTokenAmount;
        callback.status = _SEND;
    }

    function sendV2(
        OrderInfo calldata _orderInfo,
        SwapV2Info calldata _swapV2Info,
        mapping(bytes32 => uint256) storage orderStatus,
        mapping(bytes32 => uint256) storage orderAmount
    ) external returns (HandlerCallBack memory callback) {
        bytes32 key = BKBridgeKey.keyOf(_orderInfo);
        if (orderStatus[key] != _INEXIST) {
            revert IBKBridgeErrors.OrderAlreadyExist();
        }

        IERC20 iSwapTokenOut = IERC20(_swapV2Info.toTokenAddress);
        uint256 vaultBeforeBalance = iSwapTokenOut.balanceOf(_orderInfo.vaultReceiver);

        orderStatus[key] = _SEND;
        _bridgeForSwapV2(_swapV2Info);

        uint256 valutTokenAmount = iSwapTokenOut.balanceOf(_orderInfo.vaultReceiver) - vaultBeforeBalance;
        if (valutTokenAmount < _swapV2Info.minAmountOut) {
            revert IBKBridgeErrors.WrongVaultReceiveToken();
        }

        orderAmount[key] = valutTokenAmount;
        
        callback.amount = valutTokenAmount;
        callback.status = _SEND;
    }

    function relay(OrderInfo calldata _orderInfo, uint256 _relayAmount, mapping(bytes32 => uint256) storage orderStatus)
        external
        returns (HandlerCallBack memory callback)
    {
        bytes32 key = BKBridgeKey.keyOf(_orderInfo);
        if (orderStatus[key] != _INEXIST) {
            revert IBKBridgeErrors.OrderAlreadyExist();
        }
        IERC20 iVaultToken = IERC20(_orderInfo.dstToken);
        uint256 vaultBeforeBalance = iVaultToken.balanceOf(msg.sender);

        orderStatus[key] = _RELAY;
        TransferHelper.safeTransferFrom(_orderInfo.dstToken, msg.sender, _orderInfo.receiver, _relayAmount);
        if (vaultBeforeBalance - iVaultToken.balanceOf(msg.sender) != _relayAmount) {
            revert IBKBridgeErrors.WrongRelayAmount();
        }

        callback.amount = _relayAmount;
        callback.status = _RELAY;
    }

    function relayV1(
        OrderInfo calldata _orderInfo,
        SwapV1Info calldata _swapV1Info,
        uint256 _relayAmount,
        mapping(bytes32 => uint256) storage orderStatus
    ) external returns (HandlerCallBack memory callback) {
        address swapTokenIn = _swapV1Info.path[0];
        bytes32 key = BKBridgeKey.keyOf(_orderInfo);
        if (orderStatus[key] != _INEXIST) {
            revert IBKBridgeErrors.OrderAlreadyExist();
        }

        IERC20 iSwapTokenIn = IERC20(swapTokenIn);
        uint256 vaultBeforeBalance = iSwapTokenIn.balanceOf(msg.sender);

        address SwapTokenOutAddress = _swapV1Info.path[_swapV1Info.path.length - 1];
        uint256 receiverBeforeBalance; 
        if(TransferHelper.isETH(SwapTokenOutAddress)) {
            receiverBeforeBalance = _orderInfo.receiver.balance;
        } else {
            receiverBeforeBalance = IERC20(SwapTokenOutAddress).balanceOf(_orderInfo.receiver);
        }

        orderStatus[key] = _RELAY;
        _bridgeForSwapV1(_swapV1Info);

        uint256 valutTokenAmount = vaultBeforeBalance - iSwapTokenIn.balanceOf(msg.sender);
        if (_relayAmount != valutTokenAmount) {
            revert IBKBridgeErrors.WrongRelayAmount();
        }

        if(TransferHelper.isETH(SwapTokenOutAddress)) {
            if ((_orderInfo.receiver.balance - receiverBeforeBalance) < _swapV1Info.minAmountOut) {
                revert IBKBridgeErrors.SwapInsuffenceOutPut();
            } 
        } else {
            if ((IERC20(SwapTokenOutAddress).balanceOf(_orderInfo.receiver) - receiverBeforeBalance) < _swapV1Info.minAmountOut) {
                revert IBKBridgeErrors.SwapInsuffenceOutPut();
            } 
        }

        callback.amount = _relayAmount;
        callback.status = _RELAY;
    }

    function relayV2(
        OrderInfo calldata _orderInfo,
        SwapV2Info calldata _swapV2Info,
        uint256 _relayAmount,
        mapping(bytes32 => uint256) storage orderStatus
    ) external returns (HandlerCallBack memory callback) {
        bytes32 key = BKBridgeKey.keyOf(_orderInfo);
        if (orderStatus[key] != _INEXIST) {
            revert IBKBridgeErrors.OrderAlreadyExist();
        }

        IERC20 iSwapTokenIn = IERC20(_swapV2Info.fromTokenAddress);
        uint256 vaultBeforeBalance = iSwapTokenIn.balanceOf(msg.sender);

        address SwapTokenOutAddress = _swapV2Info.toTokenAddress;
        uint256 receiverBeforeBalance; 
        if(TransferHelper.isETH(SwapTokenOutAddress)) {
            receiverBeforeBalance = _orderInfo.receiver.balance;
        } else {
            receiverBeforeBalance = IERC20(SwapTokenOutAddress).balanceOf(_orderInfo.receiver);
        }
        
        orderStatus[key] = _RELAY;
        _bridgeForSwapV2(_swapV2Info);

        uint256 valutTokenAmount = vaultBeforeBalance - iSwapTokenIn.balanceOf(msg.sender);
        if (_relayAmount != valutTokenAmount) {
            revert IBKBridgeErrors.WrongRelayAmount();
        }

        if(TransferHelper.isETH(SwapTokenOutAddress)) {
            if ((_orderInfo.receiver.balance - receiverBeforeBalance) < _swapV2Info.minAmountOut) {
                revert IBKBridgeErrors.SwapInsuffenceOutPut();
            } 
        } else {
            if ((IERC20(SwapTokenOutAddress).balanceOf(_orderInfo.receiver) - receiverBeforeBalance) < _swapV2Info.minAmountOut) {
                revert IBKBridgeErrors.SwapInsuffenceOutPut();
            } 
        }

        callback.amount = _relayAmount;
        callback.status = _RELAY;
    }

    function cancel(OrderInfo calldata _orderInfo, mapping(bytes32 => uint256) storage orderStatus)
        external
        returns (HandlerCallBack memory callback)
    {
        bytes32 key = BKBridgeKey.keyOf(_orderInfo);
        if (orderStatus[key] != _INEXIST) {
            revert IBKBridgeErrors.OrderAlreadyExist();
        }

        orderStatus[key] = _CANCEL;
        callback.amount = 0;
        callback.status = _CANCEL;
    }

    function refund(
        OrderInfo calldata _orderInfo,
        uint256 _refundAmount,
        address _vaultToken,
        mapping(bytes32 => uint256) storage orderStatus,
        mapping(bytes32 => uint256) storage orderAmount
    ) external returns (HandlerCallBack memory callback) {
        bytes32 key = BKBridgeKey.keyOf(_orderInfo);
        if (orderStatus[key] != _SEND) {
            revert IBKBridgeErrors.OrderNotSend();
        }
        if (_refundAmount > orderAmount[key]) {
            revert IBKBridgeErrors.WrongRefundAmount();
        }
        orderAmount[key] = 0;
        orderStatus[key] = _REFUND;
        TransferHelper.safeTransferFrom(_vaultToken, msg.sender, _orderInfo.sender, _refundAmount);
        callback.amount = _refundAmount;
        callback.status = _REFUND;
    }

    function _bridgeForSwapV1(SwapV1Info calldata _swapV1Info) internal {
        address swapTokenIn = _swapV1Info.path[0];

        if (TransferHelper.isETH(swapTokenIn)) {
            if (msg.value < _swapV1Info.amountIn) {
                revert IBKBridgeErrors.EthBalanceNotEnough();
            }
        } else {
            TransferHelper.safeTransferFrom(swapTokenIn, msg.sender, address(this), _swapV1Info.amountIn);
            TransferHelper.approveMax(IERC20(swapTokenIn), _swapV1Info.bkSwapV1Router, _swapV1Info.amountIn);
        }

        IBKSwap(_swapV1Info.bkSwapV1Router).swap{value: msg.value}(
            payable(_swapV1Info.handlerAddress),
            _swapV1Info.router,
            _swapV1Info.path,
            _swapV1Info.poolFee,
            _swapV1Info.amountIn,
            _swapV1Info.minAmountOut,
            _swapV1Info.to
        );
    }

    function _bridgeForSwapV2(SwapV2Info calldata _swapV2Info) internal {
        address swapTokenIn = _swapV2Info.fromTokenAddress;
        if (TransferHelper.isETH(swapTokenIn)) {
            if (msg.value < _swapV2Info.amountInTotal) {
                revert IBKBridgeErrors.EthBalanceNotEnough();
            }
        } else {
            TransferHelper.safeTransferFrom(swapTokenIn, msg.sender, address(this), _swapV2Info.amountInTotal);
            TransferHelper.approveMax(IERC20(swapTokenIn), _swapV2Info.bkSwapV2Router, _swapV2Info.amountInTotal);
        }

        IBKSwapRouter(_swapV2Info.bkSwapV2Router).swap{value: msg.value}(
            IBKSwapRouter.SwapParams(_swapV2Info.fromTokenAddress, _swapV2Info.amountInTotal, _swapV2Info.data)
        );
    }
}
