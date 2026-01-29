// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../src/poc/state_storage_layout/01_fixed_layout_packing/FixedLayoutPacking.sol";

/// @title FixedLayoutPackingTest
/// @notice Verify how fixed-length variables are stored in EVM storage slots
contract FixedLayoutPackingTest is Test {
    FixedLayoutPacking fixedLayoutPacking;

    /// @notice Deploy and initialize the contract before test
    function setUp() public {
        // Initialize fixed-size array in memory
        uint128[3] memory tempArray;
        tempArray[0] = 0x11111111111111111111111111111111;
        tempArray[1] = 0x22222222222222222222222222222222;
        tempArray[2] = 0x33333333333333333333333333333333;

        // Initialize PackedStruct in memory
        FixedLayoutPacking.PackedStruct memory tempStruct = FixedLayoutPacking.PackedStruct({
            a_16bytes: int128(0x11111111111111111111111111111111),
            b_8bytes: int64(0x2222222222222222),
            c_8bytes: int64(0x3333333333333333)
        });
        fixedLayoutPacking = new FixedLayoutPacking(
            true, // bool
            0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef, // uint256
            0x1234, // uint16
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce", // bytes31
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1", // bytes32
            0x1234567890123456789012345678901234567890, // address
            FixedLayoutPacking.MyEnum.TWO, // enum
            tempArray, // u128Array
            tempStruct // packedStruct
        );
    }

    /// @notice Main test function
    /// @dev Assert all variable values and dump raw storage slots
    function test_fixed_length_storage() public {
        // ==== Verify state variable getters ====
        assertEq(fixedLayoutPacking.bool_1(), true);
        assertEq(fixedLayoutPacking.uint256_32(), 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef);
        assertEq(fixedLayoutPacking.uint16_2(), 0x1234);
        assertEq(fixedLayoutPacking.bytes31_31(), hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce");
        assertEq(fixedLayoutPacking.bytes32_32(), hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1");
        assertEq(fixedLayoutPacking.addr_20(), 0x1234567890123456789012345678901234567890);
        assertEq(uint256(fixedLayoutPacking.enum_1()), 2);
        assertEq(fixedLayoutPacking.u128Array(0), 0x11111111111111111111111111111111);
        assertEq(fixedLayoutPacking.u128Array(1), 0x22222222222222222222222222222222);
        assertEq(fixedLayoutPacking.u128Array(2), 0x33333333333333333333333333333333);
        (int128 struct_a, int64 struct_b, int64 struct_c) = fixedLayoutPacking.packedStruct();
        assertEq(struct_a, int128(0x11111111111111111111111111111111));
        assertEq(struct_b, int64(0x2222222222222222));
        assertEq(struct_c, int64(0x3333333333333333));

        // ==== Read storage slots one by one ====
        for (uint256 slotIndex = 0; slotIndex < 9; slotIndex++) {
            bytes32 slotValue = vm.load(address(fixedLayoutPacking), bytes32(slotIndex));
            // Print slot index
            emit log_named_uint("Slot", slotIndex);
            // Print raw slot content
            emit log_named_bytes32("Raw bytes32 value", slotValue);
        }
    }
}
