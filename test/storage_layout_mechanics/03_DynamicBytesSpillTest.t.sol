// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../src/poc/storage_layout_mechanics/03_dynamic_bytes_inline_spill/DynamicBytesSpill.sol";

/// @title DynamicBytesSpillTest
/// @notice Verify how `bytes` and `string` are stored in EVM storage under different lengths
contract DynamicBytesSpillTest is Test {
    DynamicBytesSpill dynamicBytesSpill;

    /// @notice Deploy and initialize the contract before test
    function setUp() public {
        dynamicBytesSpill = new DynamicBytesSpill(
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce", // b31 31 bytes
            "abcdefghijklmnopqrstuvwxyzABCDE", // s31 31 bytes
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1", // b32  32 bytes
            "abcdefghijklmnopqrstuvwxyzABCDEF", // s32 32 bytes
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef123", // b33 33 bytes
            "abcdefghijklmnopqrstuvwxyzABCDEFG" // s33 33 bytes
        );
    }

    /// @notice Main test function
    /// @dev Assert all variable values and dump raw storage slots
    function test_dynamic_bytes_string_storage() public {
        // ==== Verify state variable getters ====
        assertEq(dynamicBytesSpill.b31(), hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce");
        assertEq(dynamicBytesSpill.s31(), "abcdefghijklmnopqrstuvwxyzABCDE");
        assertEq(dynamicBytesSpill.b32(), hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1");
        assertEq(dynamicBytesSpill.s32(), "abcdefghijklmnopqrstuvwxyzABCDEF");
        assertEq(dynamicBytesSpill.b33(), hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef123");
        assertEq(dynamicBytesSpill.s33(), "abcdefghijklmnopqrstuvwxyzABCDEFG");

        // ==== Dump slots ====
        for (uint256 slotIndex = 0; slotIndex < 6; slotIndex++) {
            // ==== Dump declaration slot ====
            bytes32 slotValue = vm.load(address(dynamicBytesSpill), bytes32(slotIndex));
            emit log_named_uint("Slot", slotIndex);
            emit log_named_bytes32("Raw bytes32 value", slotValue);

            bytes32 dataSlot;
            bytes32 dataValue;
            // ==== Dump data slot ====
            if (slotIndex > 1) {
                dataSlot = keccak256(abi.encode(slotIndex));
                dataValue = vm.load(address(dynamicBytesSpill), dataSlot);
                emit log_named_uint("Slot", uint256(dataSlot));
                emit log_named_bytes32("Raw bytes32 value", dataValue);
            }
            if (slotIndex > 3) {
                dataSlot = bytes32(uint256(dataSlot) + 1);
                dataValue = vm.load(address(dynamicBytesSpill), dataSlot);
                emit log_named_uint("Slot", uint256(dataSlot));
                emit log_named_bytes32("Raw bytes32 value", dataValue);
            }
        }
    }
}
