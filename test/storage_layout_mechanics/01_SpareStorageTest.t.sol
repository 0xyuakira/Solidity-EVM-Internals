// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

import "forge-std/Test.sol";
import "../../src/poc/storage_layout_mechanics/01_sparse_storage_address_space/SparseStorage.sol";

/// @title SparseStorageTest
/// @notice Observe EVM storage behavior under extreme slot addressing
contract SparseStorageTest is Test {
    SparseStorage storageProbe;

    uint256 constant SLOT_ZERO = 0;
    uint256 constant SLOT_MAX = type(uint256).max;

    function setUp() external {
        storageProbe = new SparseStorage();
    }

    /// @notice Verify that extreme storage slots are writable and readable
    function test_extreme_slot_addressing_independence() external {
        // write distinct values into extreme slots
        storageProbe.write(SLOT_ZERO, 111);
        storageProbe.write(SLOT_MAX, 999);

        // read back
        uint256 v0 = storageProbe.read(SLOT_ZERO);
        uint256 vmax = storageProbe.read(SLOT_MAX);

        // assert correctness
        assertEq(v0, 111);
        assertEq(vmax, 999);
    }

    /// @notice Verify that writing to an extreme slot does not affect other slots
    function test_extreme_slot_no_collision() external {
        // write only to max slot
        storageProbe.write(SLOT_MAX, 12345);

        // zero slot must remain untouched
        uint256 v0 = storageProbe.read(SLOT_ZERO);
        assertEq(v0, 0);
    }
}
