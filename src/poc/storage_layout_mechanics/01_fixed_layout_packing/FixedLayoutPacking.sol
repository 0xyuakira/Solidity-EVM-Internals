// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title FixedLayoutPacking
/// @notice Experimental contract to demonstrate how fixed-length variables are stored in EVM storage slots
/// @dev Proof-of-concept (PoC) contract with multiple fixed-length state variables:
///      - bool, uint256, uint16, bytes31, address, bytes32, enum, uint128[3], struct
///      Variables are initialized through the constructor for testing purposes
contract FixedLayoutPacking {
    bool public bool_1;

    uint256 public uint256_32;

    uint16 public uint16_2;

    bytes31 public bytes31_31;

    bytes32 public bytes32_32;

    address public addr_20;

    MyEnum public enum_1;

    uint128[3] public u128Array;

    PackedStruct public packedStruct;

    enum MyEnum {
        ZERO,
        ONE,
        TWO
    }

    struct PackedStruct {
        int128 a_16bytes;
        int64 b_8bytes;
        int64 c_8bytes;
    }

    constructor(
        bool _bool,
        uint256 _uint256,
        uint16 _uint16,
        bytes31 _bytes31,
        bytes32 _bytes32,
        address _addr,
        MyEnum _enum,
        uint128[3] memory _u128Array,
        PackedStruct memory _packedStruct
    ) {
        bool_1 = _bool;
        uint256_32 = _uint256;
        uint16_2 = _uint16;
        bytes31_31 = _bytes31;
        bytes32_32 = _bytes32;
        addr_20 = _addr;
        enum_1 = _enum;
        u128Array = _u128Array;
        packedStruct = _packedStruct;
    }
}
