// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20Permit, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error InvalidSignature();
error AuthorizationNotYetValid();
error AuthorizationExpired();
error AuthorizationAlreadyUsed();

/// @notice Advanced ERC-20 Token with Signature-Based Approvals
/// @dev ERC-20 token that supports both ERC-2612 (Permit) and
/// ERC-3009 (Transfer with Authorization) standards
contract AdvancedToken is ERC20Permit {
    /// @notice Mapping of authorization hash => used status
    mapping(bytes32 => bool) public authorizationState;

    event AuthorizationUsed(address indexed from, bytes32 indexed nonce);

    /// @notice EIP-712 typehash for `TransferWithAuthorization`
    /// @dev keccak256("TransferWithAuthorization(address from,address to,uint256 value,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
    bytes32 public constant TRANSFER_WITH_AUTHORIZATION_TYPEHASH =
        0x7c7c6cdb67a18743f49ec6fa9b35f50d52ed05cbed4cc592e13b44501c1a2267;

    constructor(string memory name_, string memory symbol_, uint256 initialSupply)
        ERC20(name_, symbol_)
        ERC20Permit(name_)
    {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Execute a transfer with a signed authorization
    /// @dev Consumes the authorization so it cannot be used again
    /// @param from The address to transfer tokens from
    /// @param to The address to transfer tokens to
    /// @param value The amount of tokens to transfer
    /// @param validAfter The timestamp after which the authorization is valid
    /// @param validBefore The timestamp before which the authorization is valid
    /// @param nonce Unique nonce to prevent replay attacks
    /// @param v The recovery ID (27 or 28)
    /// @param r The R component of the signature
    /// @param s The S component of the signature
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // Compute the authorization hash upfront
        bytes32 authorizationHash = _requireValidAuthorization(from, to, value, validAfter, validBefore, nonce);
        if (authorizationState[authorizationHash]) revert AuthorizationAlreadyUsed();

        if (block.timestamp < validAfter) revert AuthorizationNotYetValid();
        if (block.timestamp > validBefore) revert AuthorizationExpired();

        bytes32 structHash =
            keccak256(abi.encode(TRANSFER_WITH_AUTHORIZATION_TYPEHASH, from, to, value, validAfter, validBefore, nonce));
        bytes32 messageHash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(messageHash, v, r, s);
        if (signer != from) {
            revert InvalidSignature();
        }

        authorizationState[authorizationHash] = true;
        emit AuthorizationUsed(from, nonce);

        _transfer(from, to, value);
    }

    /// @notice Compute the authorization hash for a transfer
    /// @dev This hash uniquely identifies the authorization parameters
    /// @param from The address to transfer tokens from
    /// @param to The address to transfer tokens to
    /// @param value The amount of tokens to transfer
    /// @param validAfter The timestamp after which the authorization is valid
    /// @param validBefore The timestamp before which the authorization is valid
    /// @param nonce Unique nonce to prevent replay attacks
    /// @return The authorization hash
    function _requireValidAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(from, to, value, validAfter, validBefore, nonce));
    }
}
