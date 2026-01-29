// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../src/poc/state_storage_layout/04_mapping_storage/MappingStorage.sol";

contract MappingStorageTest is Test {
    MappingStorage storageContract;

    function setUp() public {
        storageContract = new MappingStorage();
    }

    /// ------------------------------------------------------------
    /// Test 1: mapping(uint256 => uint256)
    /// ------------------------------------------------------------
    function test_uintToUint_storage_location() public {
        // === Write ===
        storageContract.setUintToUint(0, 0x1111);
        storageContract.setUintToUint(1, 0x2222);
        storageContract.setUintToUint(2, 0x3333);

        // ==== Dump declaration slot ====
        bytes32 slotValue = vm.load(address(storageContract), bytes32(uint256(0)));
        emit log_named_uint("Slot", 0);
        emit log_named_bytes32("Raw bytes32 value", slotValue);

        // ==== Dump data slot ====
        bytes32 dataSlot;
        bytes32 dataValue;
        for (uint256 i = 0; i < 3; i++) {
            dataSlot = keccak256(abi.encode(0 + i, 0));
            dataValue = vm.load(address(storageContract), dataSlot);
            emit log_named_uint("Slot", uint256(dataSlot));
            emit log_named_bytes32("Raw bytes32 value", dataValue);
        }
    }

    function test_addressToUint_storage_location() public {
        // === Write ===
        storageContract.setAddressToUint(0x1234567890123456789012345678901234567890, 0xaaaa);
        storageContract.setAddressToUint(0x1234567890123456789012345678901234567891, 0xbbbb);
        storageContract.setAddressToUint(0x1234567890123456789012345678901234567892, 0xcccc);

        // ==== Dump declaration slot ====
        bytes32 slotValue = vm.load(address(storageContract), bytes32(uint256(1)));
        emit log_named_uint("Slot", 1);
        emit log_named_bytes32("Raw bytes32 value", slotValue);

        // ==== Dump data slot ====
        bytes32 dataSlot;
        bytes32 dataValue;
        for (uint160 i = 0; i < 3; i++) {
            dataSlot = keccak256(abi.encode(address(uint160(0x1234567890123456789012345678901234567890) + i), 1));
            dataValue = vm.load(address(storageContract), dataSlot);
            emit log_named_uint("Slot", uint256(dataSlot));
            emit log_named_bytes32("Raw bytes32 value", dataValue);
        }
    }

    function test_bytes32ToArray_storage_location() public {
        // === Write ===
        storageContract.setBytes32ToArray(
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1",
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce"
        );
        storageContract.setBytes32ToArray(
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1",
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1"
        );
        storageContract.setBytes32ToArray(
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1",
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef123"
        );

        // ==== Dump declaration slot ====
        bytes32 slotValue = vm.load(address(storageContract), bytes32(uint256(2)));
        emit log_named_uint("Slot", 2);
        emit log_named_bytes32("Raw bytes32 value", slotValue);

        // ==== Dump data slot ====
        bytes32 declarationSlot =
            keccak256(abi.encode(bytes32(hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1"), 2));
        emit log_named_uint("Slot", uint256(declarationSlot));
        emit log_named_bytes32("Raw bytes32 value", vm.load(address(storageContract), declarationSlot));
        uint256 startArraySlot = uint256(keccak256(abi.encode(declarationSlot)));
        bytes32 dataSlot;
        bytes32 dataValue;
        for (uint160 i = 0; i < 3; i++) {
            i == 0 ? startArraySlot : startArraySlot++;
            dataValue = vm.load(address(storageContract), bytes32(startArraySlot));
            emit log_named_uint("Slot", startArraySlot);
            emit log_named_bytes32("Raw bytes32 value", dataValue);

            if (i > 0) {
                dataSlot = keccak256(abi.encode(startArraySlot));
                dataValue = vm.load(address(storageContract), dataSlot);
                emit log_named_uint("Slot", uint256(dataSlot));
                emit log_named_bytes32("Raw bytes32 value", dataValue);
            }
            if (i > 1) {
                dataSlot = bytes32(uint256(dataSlot) + 1);

                dataValue = vm.load(address(storageContract), dataSlot);
                emit log_named_uint("Slot", uint256(dataSlot));
                emit log_named_bytes32("Raw bytes32 value", dataValue);
            }
        }
    }
}
