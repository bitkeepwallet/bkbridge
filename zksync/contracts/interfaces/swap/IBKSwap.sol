//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

interface IBKSwap {
    function swap(
        address payable _handlerAddress,
        address _router,
        address[] memory _path,
        uint24[] memory _poolFee,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _to,
        bool[] calldata _stable
    ) external payable returns (uint256);
}
