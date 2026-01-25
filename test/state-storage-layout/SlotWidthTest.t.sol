// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../src/poc/state_storage_layout/01_storage_slot_width_invariance/SlotWidth.sol";

/// @title SlotWidthTest
/// @notice Test suite for demonstrating that a single storage slot cannot exceed 256 bits in EVM.
contract SlotWidthTest is Test {
    SlotWidth slotContract;

    function setUp() public {
        slotContract = new SlotWidth();
    }

    /// @notice Verify that 32-byte sequence fits entirely within a single storage slot
    function test_bytes32_fits_single_slot() public {
        bytes memory b32 = new bytes(32);
        for (uint i = 0; i < 32; i++) {
            b32[i] = bytes1(uint8(i + 1));
        }

        slotContract.set(b32);

        // Load the starting slot of the dynamic data
        bytes32 slot0 = vm.load(
            address(slotContract),
            bytes32(slotContract.dataSlot())
        );

        // Verify each byte matches the original array
        for (uint i = 0; i < 32; i++) {
            assertEq(slot0[i], b32[i]);
        }
    }

    /// @notice Verify that a 33-byte sequence spills into two storage slots
    function test_bytes33_spills_into_two_slots() public {
        bytes memory b33 = new bytes(33);
        for (uint i = 0; i < 33; i++) {
            b33[i] = bytes1(uint8(i + 1));
        }

        slotContract.set(b33);

        // Load the first slot containing the first 32 bytes
        bytes32 slot1 = vm.load(
            address(slotContract),
            bytes32(slotContract.dataSlot())
        );
        for (uint i = 0; i < 32; i++) {
            assertEq(slot1[i], b33[i]);
        }

        // Load the second slot containing the last byte
        bytes32 slot2 = vm.load(
            address(slotContract),
            bytes32(slotContract.dataSlot() + 1)
        );
        assertEq(slot2[0], b33[32]);

        // Verify remaining bytes in slot2 are zero
        for (uint i = 1; i < 32; i++) {
            assertEq(slot2[i], bytes1(0));
        }
    }
}
