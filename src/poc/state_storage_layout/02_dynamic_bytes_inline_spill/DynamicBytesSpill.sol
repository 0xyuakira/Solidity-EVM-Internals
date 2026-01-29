// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title DynamicBytesSpill
/// @notice Experimental contract to demonstrate how dynamic-length byte sequences
///         (`bytes` and `string`) are stored in EVM storage
/// @dev Proof-of-concept (PoC) contract with dynamic-length byte sequences state variables:
///      - `bytes`
///      - `string`
///      - Variables are initialized through the constructor for testing purposes
contract DynamicBytesSpill {
    bytes public b31;

    string public s31;

    bytes public b32;

    string public s32;

    bytes public b33;

    string public s33;

    constructor(
        bytes memory _b31,
        string memory _s31,
        bytes memory _b32,
        string memory _s32,
        bytes memory _b33,
        string memory _s33
    ) {
        b31 = _b31;
        s31 = _s31;
        b32 = _b32;
        s32 = _s32;
        b33 = _b33;
        s33 = _s33;
    }
}
