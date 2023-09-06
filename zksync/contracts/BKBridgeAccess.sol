// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import './libs/TransferHelper.sol';
import './interfaces/IBKBridgeAccess.sol';
import './interfaces/IBKBridgeErrors.sol';

contract BKBridgeAccess is IBKBridgeAccess, IBKBridgeErrors, Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    address public safe;
    address public operator;
    address public signer;
    address public vault;
    address public vaultToken;
    mapping(address => bool) public isRelayer;
    mapping(address => bool) public isRouter;
    mapping(uint256 => uint256) private nonceBitmap;

    event RescueETH(address recipient, uint256 amount);
    event RescueERC20(address asset, address recipient, uint256 amount);
    event SetSafe(address newSafe);
    event SetOperator(address newOperator);
    event SetSigner(address newSigner);
    event SetVault(address newVault);
    event SetVaultToken(address newValutToken);
    event SetRelayers(address[] relayers, bool isTrue);
    event SetRouters(address[] routers, bool isTrue);

    modifier onlyOperator() {
        _checkOperator();
        _;
    }

    modifier onlySender(address _orderSender) {
        _checkSender(_orderSender);
        _;
    }

    modifier onlyRelayer() {
        _checkRelayer();
        _;
    }

    function setAccess(AccessType _accessType, bytes calldata _inputs) external onlyOwner {
        if (_accessType > AccessType.SET_ROUTERS) {
            revert AccessTypeNotAvailable();
        }
        if (_accessType <= AccessType.SET_VAULT_TOKEN) {
            address addr = abi.decode(_inputs, (address));
            _checkZero(addr);

            if (_accessType == AccessType.SET_SAFE) {
                safe = addr;
                emit SetSafe(addr);
            } else if (_accessType == AccessType.SET_OPERATOR) {
                operator = addr;
                emit SetOperator(addr);
            } else if (_accessType == AccessType.SET_SINGER) {
                signer = addr;
                emit SetSigner(addr);
            } else if (_accessType == AccessType.SET_VAULT) {
                vault = addr;
                emit SetVault(addr);
            } else if (_accessType == AccessType.SET_VAULT_TOKEN) {
                vaultToken = addr;
                emit SetVaultToken(addr);
            }
        } else {
            (address[] memory addrs, bool isTrue) = abi.decode(_inputs, (address[], bool));

            bool isSetRelayer = _accessType == AccessType.SET_RELAYERS;
            uint256 length = addrs.length;
            for (uint256 i = 0; i < length;) {
                address addr = addrs[i];
                _checkZero(addr);

                if (isSetRelayer) {
                    isRelayer[addr] = isTrue;
                } else {
                    isRouter[addr] = isTrue;
                }
                unchecked {
                    ++i;
                }
            }
            if (isSetRelayer) {
                emit SetRelayers(addrs, isTrue);
            } else {
                emit SetRouters(addrs, isTrue);
            }
        }
    }

    function checkBridgeReady() external view returns (bool) {
        if (safe == address(0)) {
            revert NotSafe();
        } else if (operator == address(0)) {
            revert NotOperator();
        } else if (signer == address(0)) {
            revert NotSigner();
        } else if (vault == address(0)) {
            revert NotVault();
        } else if (vaultToken == address(0)) {
            revert NotVaultToken();
        }
        return true;
    }

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }

    function rescueERC20(address asset) external onlyOperator {
        _checkZero(safe);
        uint256 amount = IERC20(asset).balanceOf(address(this));
        TransferHelper.safeTransfer(asset, safe, amount);
        emit RescueERC20(asset, safe, amount);
    }

    function rescueETH() external onlyOperator {
        _checkZero(safe);
        uint256 amount = address(this).balance;
        TransferHelper.safeTransferETH(safe, amount);
        emit RescueETH(safe, amount);
    }

    function _checkOperator() internal view {
        if (msg.sender != operator) {
            revert NotOperator();
        }
    }

    function _checkSender(address orderSender) internal view {
        if (msg.sender != orderSender) {
            revert NotSender();
        }
    }

    function _checkRelayer() internal view {
        if (!isRelayer[msg.sender]) {
            revert NotRelayer();
        }
    }

    function _checkZero(address _address) internal pure {
        if (_address == address(0)) {
            revert InvalidAddress();
        }
    }

    function _checkVaultToken(address _vaultToken) internal view {
        if (_vaultToken != vaultToken) {
            revert NotVaultToken();
        }
    }

    function _checkVaultReceiver(address _vaultReceiver) internal view {
        if (_vaultReceiver != vault) {
            revert NotVault();
        }
    }

    function _checkSwapReceiver(address _targetReceiver, address _swapReceiver) internal pure {
        if (_targetReceiver != _swapReceiver) {
            revert SwapReceiverMisMatch();
        }
    }

    function _checkRouter(address _router) internal view {
        if (!isRouter[_router]) {
            revert NotRouter();
        }
    }

    function _checkSigner(uint256 _nonce, bytes calldata _signature, bytes32 _transferId, uint256 _dstChainId) internal {
        _useUnorderedNonce(_nonce);

        bytes32 msgHash = keccak256(abi.encodePacked(_nonce, block.chainid, address(this), msg.sender, _transferId, _dstChainId));

        bytes32 finalMsgHash = msgHash.toEthSignedMessageHash();

        address signer_ = finalMsgHash.recover(_signature);

        if (signer_ != signer) {
            revert NotSigner();
        }
    }

    /// @notice Checks whether a nonce is taken and sets the bit at the bit position in the bitmap at the word position
    /// @param nonce The nonce to spend
    function _useUnorderedNonce(uint256 nonce) internal {
        (uint256 wordPos, uint256 bitPos) = bitmapPositions(nonce);
        uint256 bit = 1 << bitPos;
        uint256 flipped = nonceBitmap[wordPos] ^= bit;

        if (flipped & bit == 0) revert InvalidNonce();
    }

    /// @notice Returns the index of the bitmap and the bit position within the bitmap. Used for unordered nonces
    /// @param nonce The nonce to get the associated word and bit positions
    /// @return wordPos The word position or index into the nonceBitmap
    /// @return bitPos The bit position
    /// @dev The first 248 bits of the nonce value is the index of the desired bitmap
    /// @dev The last 8 bits of the nonce value is the position of the bit in the bitmap
    function bitmapPositions(uint256 nonce) internal pure returns (uint256 wordPos, uint256 bitPos) {
        wordPos = uint248(nonce >> 8);
        bitPos = uint8(nonce);
    }
}
