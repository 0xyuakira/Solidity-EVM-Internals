// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../src/poc/state_storage_layout/02_fixed_length_variable_storage/FixedLengthVariableStorage.sol";

/// @title FixedLengthVariableStorageTest
/// @notice Verify how fixed-length variables are stored in EVM storage slots
contract FixedLengthVaiableStorageTest is Test {
    FixedLengthVariableStorage fixedLengthVariableStorage;

    /// @notice Deploy and initialize the contract before test
    function setUp() public {
        fixedLengthVariableStorage = new FixedLengthVariableStorage(
            true, // a: bool
            0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef, // b: uint256
            0x1234, // c: uint16
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce", // d: bytes31
            0x1234567890123456789012345678901234567890, // e: address
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1", // f: bytes32
            FixedLengthVariableStorage.MyEnum.TWO, // g: enum
            0x1234567890abcdef1234567890abcdef, // h: int128
            0x1234567890abcdef1234567890abcdef // i: int128
        );
    }

    /// @notice Main test function
    /// @dev Assert all variable values and print storage slot content
    function test_fixed_length_slot() public {
        // ==== Verify state variable getters ====
        assertEq(fixedLengthVariableStorage.a(), true);
        assertEq(
            fixedLengthVariableStorage.b(),
            0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef
        );
        assertEq(fixedLengthVariableStorage.c(), 0x1234);
        assertEq(
            fixedLengthVariableStorage.d(),
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce"
        );
        assertEq(
            fixedLengthVariableStorage.e(),
            0x1234567890123456789012345678901234567890
        );
        assertEq(
            fixedLengthVariableStorage.f(),
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1"
        );
        assertEq(uint(fixedLengthVariableStorage.g()), 2);
        assertEq(
            fixedLengthVariableStorage.h(),
            0x1234567890abcdef1234567890abcdef
        );
        assertEq(
            fixedLengthVariableStorage.i(),
            0x1234567890abcdef1234567890abcdef
        );

        // ==== Read storage slots one by one ====
        for (uint256 slotIndex = 0; slotIndex < 8; slotIndex++) {
            bytes32 slotValue = vm.load(
                address(fixedLengthVariableStorage),
                bytes32(slotIndex)
            );
            // Print slot index
            emit log_uint(slotIndex);
            // Print raw slot content
            emit log_bytes32(slotValue);
        }
    }
}
