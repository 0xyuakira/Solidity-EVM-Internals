// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title FixedLengthVariableStorage
/// @notice Experimental contract to demonstrate how fixed-length variables are stored in EVM storage slots
/// @dev Proof-of-concept (PoC) contract with multiple fixed-length state variables:
///      - bool, uint256, uint16, bytes31, address, bytes32, int128, and enum
///      - Variables are initialized through the constructor for testing purposes
contract FixedLengthVariableStorage {
    // ==== Define fixed-length storage variables ====

    bool public a; // 1 byte
    uint256 public b; // 32 bytes
    uint16 public c; // 2 bytes
    bytes31 public d; // 31 bytes
    address public e; // 20 bytes
    bytes32 public f; // 32 bytes
    MyEnum public g; // 1 byte, Enum stored as uint8
    int128 public h; // 16 bytes
    int128 public i; // 16 bytes

    enum MyEnum {
        ZERO,
        ONE,
        TWO
    }

    /// @notice Constructor: initialize all fixed-length variables
    constructor(bool _a, uint256 _b, uint16 _c, bytes31 _d, address _e, bytes32 _f, MyEnum _g, int128 _h, int128 _i) {
        a = _a;
        b = _b;
        c = _c;
        d = _d;
        e = _e;
        f = _f;
        g = _g;
        h = _h;
        i = _i;
    }
}
