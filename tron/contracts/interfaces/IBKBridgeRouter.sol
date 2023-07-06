// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {SignInfo, OrderInfo, SwapV1Info, SwapV2Info, HandlerCallBack} from './IBKBridgeParams.sol';

interface IBKBridgeRouter {
    function orderStatus(bytes32 _key) external view returns (uint256);
    function orderAmount(bytes32 _key) external view returns (uint256);

    function send(SignInfo calldata _signInfo, OrderInfo calldata _orderInfo) external payable;

    function sendV1(SignInfo calldata _signInfo, OrderInfo calldata _orderInfo, SwapV1Info calldata _swapV1Info)
        external
        payable;

    function sendV2(SignInfo calldata _signInfo, OrderInfo calldata _orderInfo, SwapV2Info calldata _swapV2Info)
        external
        payable;

    function relay(SignInfo calldata _signInfo, OrderInfo calldata _orderInfo, uint256 _relayAmount) external payable;

    function relayV1(
        SignInfo calldata _signInfo,
        OrderInfo calldata _orderInfo,
        SwapV1Info calldata _swapV1Info,
        uint256 _relayAmount
    ) external payable;

    function relayV2(
        SignInfo calldata _signInfo,
        OrderInfo calldata _orderInfo,
        SwapV2Info calldata _swapV2Info,
        uint256 _relayAmount
    ) external payable;

    function cancel(SignInfo calldata _signInfo, OrderInfo calldata _orderInfo) external payable;

    function refund(SignInfo calldata _signInfo, OrderInfo calldata _orderInfo, uint256 _refundAmount)
        external
        payable;
}
