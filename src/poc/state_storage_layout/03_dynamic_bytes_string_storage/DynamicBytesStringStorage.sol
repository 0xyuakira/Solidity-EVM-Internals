// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title DynamicBytesStringStorage
/// @notice Experimental contract to demonstrate how dynamic-length byte sequences
///         (`bytes` and `string`) are stored in EVM storage
/// @dev Proof-of-concept (PoC) contract with dynamic-length byte sequences state variables:
///      - `bytes`
///      - `string`
///      - Variables are initialized through the constructor for testing purposes
contract DynamicBytesStringStorage {
    // ==== Define dynamic-length byte sequences state variables ====

    bytes public b31; //used to store a 31-byte value
    string public s31; //used to store a 31-byte value

    bytes public b32; //used to store a 32-byte value
    string public s32; //used to store a 32-byte value

    bytes public b33; //used to store a 33-byte value
    string public s33; //used to store a 33-byte value

    /// @notice Constructor: initialize dynamic-length byte sequences variables
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
