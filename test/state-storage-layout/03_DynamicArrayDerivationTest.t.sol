// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../src/poc/state_storage_layout/04_dynamic_array_slot_derivation/DynamicArrayDerivation.sol";

/// @title DynamicArrayDerivationTest
/// @notice Verify how dynamic arrays with different element types are stored in EVM storage
contract DynamicArrayDerivationTest is Test {
    DynamicArrayDerivation dynamicArrayDerivation;

    function setUp() public {
        dynamicArrayDerivation = new DynamicArrayDerivation();
    }

    /// @notice Observe storage layout of uint256[] dynamic array
    function test_dynamic_u256_array_storage() public {
        // === Write ===
        dynamicArrayDerivation.pushU256(0x1111);
        dynamicArrayDerivation.pushU256(0x2222);
        dynamicArrayDerivation.pushU256(0x3333);

        // ==== Dump declaration slot ====
        bytes32 slotValue = vm.load(address(dynamicArrayDerivation), bytes32(uint256(0)));
        emit log_named_uint("Slot", 0);
        emit log_named_bytes32("Raw bytes32 value", slotValue);

        // ==== Dump data slot ====
        bytes32 dataSlot = keccak256(abi.encode(0));
        bytes32 dataValue;
        for (uint256 i = 0; i < 3; i++) {
            dataValue = vm.load(address(dynamicArrayDerivation), bytes32(uint256(dataSlot) + i));
            emit log_named_uint("Slot", uint256(dataSlot) + i);
            emit log_named_bytes32("Raw bytes32 value", dataValue);
        }
    }

    /// @notice Observe storage layout of uint128[] dynamic array
    function test_dynamic_u128_array_storage() public {
        // === Write ===
        dynamicArrayDerivation.pushU128(0xaaaa);
        dynamicArrayDerivation.pushU128(0xbbbb);
        dynamicArrayDerivation.pushU128(0xcccc);

        // ==== Dump declaration slot ====
        bytes32 slotValue = vm.load(address(dynamicArrayDerivation), bytes32(uint256(1)));
        emit log_named_uint("Slot", 1);
        emit log_named_bytes32("Raw bytes32 value", slotValue);

        // ==== Dump data slot ====
        bytes32 dataSlot = keccak256(abi.encode(1));
        bytes32 dataValue;
        for (uint256 i = 0; i < 2; i++) {
            dataValue = vm.load(address(dynamicArrayDerivation), bytes32(uint256(dataSlot) + i));
            emit log_named_uint("Slot", uint256(dataSlot) + i);
            emit log_named_bytes32("Raw bytes32 value", dataValue);
        }
    }

    /// @notice Observe storage layout of bytes[] dynamic array
    function test_dynamic_bytes_array_storage() public {
        // === Write ===
        dynamicArrayDerivation.pushBytes(hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce");
        dynamicArrayDerivation.pushBytes(hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1");
        dynamicArrayDerivation.pushBytes(hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef123");

        // ==== Dump bytes array declaration slot ====
        bytes32 slotValue = vm.load(address(dynamicArrayDerivation), bytes32(uint256(2)));
        emit log_named_uint("Slot", 2);
        emit log_named_bytes32("Raw bytes32 value", slotValue);

        uint256 declarationSlot = uint256(keccak256(abi.encode(2)));
        bytes32 dataValue;
        bytes32 dataSlot;
        for (uint256 i = 0; i < 3; i++) {
            // ==== Dump bytes declaration slot ====
            i == 0 ? declarationSlot : declarationSlot++;
            dataValue = vm.load(address(dynamicArrayDerivation), bytes32(declarationSlot));
            emit log_named_uint("Slot", uint256(declarationSlot));
            emit log_named_bytes32("Raw bytes32 value", dataValue);

            // ==== Dump data slot ====
            if (i > 0) {
                dataSlot = keccak256(abi.encode(declarationSlot));
                dataValue = vm.load(address(dynamicArrayDerivation), bytes32(dataSlot));
                emit log_named_uint("Slot", uint256(dataSlot));
                emit log_named_bytes32("Raw bytes32 value", dataValue);
            }
            if (i > 1) {
                dataSlot = bytes32(uint256(dataSlot) + 1);
                dataValue = vm.load(address(dynamicArrayDerivation), dataSlot);
                emit log_named_uint("Slot", uint256(dataSlot));
                emit log_named_bytes32("Raw bytes32 value", dataValue);
            }
        }
    }
}

