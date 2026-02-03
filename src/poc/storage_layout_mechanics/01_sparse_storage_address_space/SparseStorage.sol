// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title SparseStorage
/// @notice Minimal contract for probing extreme storage slot addressing
contract SparseStorage {
    function write(uint256 slot, uint256 value) external {
        assembly {
            sstore(slot, value)
        }
    }

    function read(uint256 slot) external view returns (uint256 value) {
        assembly {
            value := sload(slot)
        }
    }
}
