// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title DynamicArrayStorage
/// @notice Experimental contract to demonstrate how dynamic arrays are stored in EVM storage
/// @dev Proof-of-concept (PoC) contract declaring multiple array state variables:
/// - Dynamic arrays of value types (uint256[], uint128[])
/// - Dynamic array of dynamic types (bytes[])
/// - Arrays are populated in tests via explicit `push` operations
contract DynamicArrayStorage {
    // ==== Dynamic arrays of value types ====

    uint256[] public u256Array; // each element occupies a full slot
    uint128[] public u128Array; // elements are packed within slots

    // ==== Dynamic array of dynamic types ====

    bytes[] public bytesArray; // each element is a dynamic bytes object

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
