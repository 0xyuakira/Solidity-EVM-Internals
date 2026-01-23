// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../contracts/SlotWidth.sol";

contract SlotWidthTest is Test {
    SlotWidth slotContract;

    function setUp() public {
        slotContract = new SlotWidth();
    }

    /// @notice Verify that bytes32 fits completely in a single slot
    function test_bytes32_fits_single_slot() public {
        bytes memory b32 = new bytes(32);
        for (uint i = 0; i < 32; i++) {
            b32[i] = bytes1(uint8(i + 1));
        }

        slotContract.set(b32);

        // slot0 存储实际数据
        bytes32 slot0 = vm.load(address(slotContract), slotContract.dataSlot());

        // 验证每个字节
        for (uint i = 0; i < 32; i++) {
            assertEq(slot0[i], b32[i]);
        }
    }

    /// @notice Verify that bytes33 spans two slots
    function test_bytes33_spills_into_two_slots() public {
        bytes memory b33 = new bytes(33);
        for (uint i = 0; i < 33; i++) {
            b33[i] = bytes1(uint8(i + 1));
        }

        slotContract.set(b33);

        // slot1: 前 32 bytes
        bytes32 slot1 = vm.load(address(slotContract), slotContract.dataSlot());
        for (uint i = 0; i < 32; i++) {
            assertEq(slot1[i], b33[i]);
        }

        // slot2: 最后一字节
        bytes32 slot2 = vm.load(address(slotContract), slotContract.dataSlot() + 1);
        assertEq(slot2[0], b33[32]);

        // slot2 剩余部分应为 0
        for (uint i = 1; i < 32; i++) {
            assertEq(slot2[i], bytes1(0));
        }
    }
}
