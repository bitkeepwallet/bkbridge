// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

enum AccessType {
    SET_SAFE,
    SET_OPERATOR,
    SET_SINGER,
    SET_VAULT,
    SET_VAULT_TOKEN,
    SET_RELAYERS,
    SET_ROUTERS
}

struct SignInfo {
    uint256 nonce;
    bytes signature;
}

struct OrderInfo {
    address vaultReceiver;
    bytes32 transferId;
    address sender;
    address receiver;
    address srcToken;
    address dstToken;
    uint256 srcChainId;
    uint256 dstChainId;
    uint256 amount;
    uint256 timestamp;
}

struct SwapV1Info {
    address bkSwapV1Router;
    address handlerAddress;
    address router;
    address[] path;
    uint24[] poolFee;
    uint256 amountIn;
    uint256 minAmountOut;
    address to;
}

struct SwapV2Info {
    address bkSwapV2Router;
    address fromTokenAddress;
    address toTokenAddress;
    address to;
    uint256 amountInTotal;
    uint256 minAmountOut;
    bytes data;
}

struct HandlerCallBack {
    uint256 amount;
    uint256 status;
}
