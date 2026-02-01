// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../src/poc/storage_layout_mechanics/04_mapping_slot_derivation/MappingSlotDerivation.sol";

contract MappingSlotDerivationTest is Test {
    MappingSlotDerivation mappingSlotDerivation;

    function setUp() public {
        mappingSlotDerivation = new MappingSlotDerivation();
    }

    /// @notice Observe storage layout of mapping(uint256 => uint256)
    function test_basicMap_storage() public {
        // === Write ===
        mappingSlotDerivation.setBasicMap(0, 0x1111);
        mappingSlotDerivation.setBasicMap(1, 0x2222);
        mappingSlotDerivation.setBasicMap(2, 0x3333);

        // ==== Dump declaration slot ====
        emit log_named_uint("Slot", 0);
        emit log_named_bytes32("Raw bytes32 value", vm.load(address(mappingSlotDerivation), bytes32(0)));

        // ==== Dump data slot ====
        bytes32 dataSlot;
        bytes32 dataValue;
        for (uint256 i = 0; i < 3; i++) {
            dataSlot = keccak256(abi.encode(0 + i, 0));
            dataValue = vm.load(address(mappingSlotDerivation), dataSlot);
            emit log_named_uint("Slot", uint256(dataSlot));
            emit log_named_bytes32("Raw bytes32 value", dataValue);
        }
    }

    /// @notice Observe storage layout of mapping(address => uint128)
    function test_addrMap_storage() public {
        // === Write ===
        mappingSlotDerivation.setAddrMap(0x1234567890123456789012345678901234567890, 0xaaaa);
        mappingSlotDerivation.setAddrMap(0x1234567890123456789012345678901234567891, 0xbbbb);
        mappingSlotDerivation.setAddrMap(0x1234567890123456789012345678901234567892, 0xcccc);

        // ==== Dump declaration slot ====
        emit log_named_uint("Slot", 1);
        emit log_named_bytes32("Raw bytes32 value", vm.load(address(mappingSlotDerivation), bytes32(uint256(1))));

        // ==== Dump data slot ====
        bytes32 dataSlot;
        bytes32 dataValue;
        for (uint160 i = 0; i < 3; i++) {
            dataSlot = keccak256(abi.encode(address(uint160(0x1234567890123456789012345678901234567890) + i), 1));
            dataValue = vm.load(address(mappingSlotDerivation), dataSlot);
            emit log_named_uint("Slot", uint256(dataSlot));
            emit log_named_bytes32("Raw bytes32 value", dataValue);
        }
    }

    /// @notice Observe storage layout of mapping(bytes32 => bytes[])
    function test_nestedMap_storage() public {
        // === Write ===
        mappingSlotDerivation.setNestedMap(
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1",
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce"
        );
        mappingSlotDerivation.setNestedMap(
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1",
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1"
        );
        mappingSlotDerivation.setNestedMap(
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1",
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef123"
        );

        // ==== Dump declaration slot ====
        emit log_named_uint("Slot", 2);
        emit log_named_bytes32("Raw bytes32 value", vm.load(address(mappingSlotDerivation), bytes32(uint256(2))));

        // ==== Dump data slot ====
        // dump bytes[] declaration slot
        bytes32 declarationSlot =
            keccak256(abi.encode(bytes32(hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1"), 2));
        emit log_named_uint("Slot", uint256(declarationSlot));
        emit log_named_bytes32("Raw bytes32 value", vm.load(address(mappingSlotDerivation), declarationSlot));

        // dump bytes[] data slot
        uint256 startArraySlot = uint256(keccak256(abi.encode(declarationSlot)));
        bytes32 dataSlot;
        bytes32 dataValue;
        for (uint160 i = 0; i < 3; i++) {
            i == 0 ? startArraySlot : startArraySlot++;
            dataValue = vm.load(address(mappingSlotDerivation), bytes32(startArraySlot));
            emit log_named_uint("Slot", startArraySlot);
            emit log_named_bytes32("Raw bytes32 value", dataValue);

            if (i > 0) {
                dataSlot = keccak256(abi.encode(startArraySlot));
                dataValue = vm.load(address(mappingSlotDerivation), dataSlot);
                emit log_named_uint("Slot", uint256(dataSlot));
                emit log_named_bytes32("Raw bytes32 value", dataValue);
            }
            if (i > 1) {
                dataSlot = bytes32(uint256(dataSlot) + 1);
                dataValue = vm.load(address(mappingSlotDerivation), dataSlot);
                emit log_named_uint("Slot", uint256(dataSlot));
                emit log_named_bytes32("Raw bytes32 value", dataValue);
            }
        }
    }
}
