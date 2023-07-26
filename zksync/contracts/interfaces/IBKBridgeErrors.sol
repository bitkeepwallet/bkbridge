// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

interface IBKBridgeErrors {
    error AccessTypeNotAvailable();
    error TransferFailed();
    error InvalidAddress();
    error InvalidNonce();
    error NotSafe();
    error NotOperator();
    error NotSigner();
    error NotVault();
    error NotVaultToken();
    error NotSender();
    error NotRelayer();
    error NotRouter();
    error OrderAlreadyExist();
    error OrderNotSend();
    error OrderAlreadySend();
    error EthBalanceNotEnough();
    error WrongVaultReceiveToken();
    error WrongRefundAmount();
    error WrongRelayAmount();
    error SwapInsuffenceOutPut();
    error SwapReceiverMisMatch();
}
