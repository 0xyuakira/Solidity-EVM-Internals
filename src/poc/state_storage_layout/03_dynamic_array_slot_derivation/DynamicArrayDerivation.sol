// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title DynamicArrayDerivation
/// @notice Experimental contract to demonstrate how dynamic arrays are stored in EVM storage
/// @dev Proof-of-concept (PoC) contract declaring multiple array state variables:
///      - `u256Array` Dynamic arrays of value types (non-packable)
///      - `u128Array` Dynamic arrays of value types (packable)
///      - `bytesArray` Dynamic arrays of dynamic types
///      Arrays are populated in tests via explicit `push` operations
contract DynamicArrayDerivation {
    uint256[] public u256Array;

    uint128[] public u128Array;

    bytes[] public bytesArray;

    function pushU256(uint256 v) external {
        u256Array.push(v);
    }

    function pushU128(uint128 v) external {
        u128Array.push(v);
    }

    function pushBytes(bytes calldata v) external {
        bytesArray.push(v);
    }
}
