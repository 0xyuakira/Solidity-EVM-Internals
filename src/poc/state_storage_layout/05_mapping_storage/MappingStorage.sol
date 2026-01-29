// SPDX-License-Identifier: MIT
pragma solidity ^0.8.33;

/// @title MappingStorage
/// @notice Experimental contract to demonstrate how `mapping` are stored in EVM storage
/// @dev Proof-of-concept (PoC) contract declaring multiple mapping state variables:
/// - Simple value-type mapping (uint256 → uint256)
/// - Address-keyed mapping (address → uint128)
/// - Mapping to dynamic array (bytes32 → bytes[]):
/// Mappings are left empty; elements will be set during tests.
contract MappingStorage {
    mapping(uint256 => uint256) public uintToUint;
    mapping(address => uint128) public addressToUint;
    mapping(bytes32 => bytes[]) public bytes32ToArray;

    function setUintToUint(uint256 key, uint256 value) external {
        uintToUint[key] = value;
    }

    function setAddressToUint(address key, uint128 value) external {
        addressToUint[key] = value;
    }

    function setBytes32ToArray(bytes32 key, bytes calldata value) external {
        bytes32ToArray[key].push(value);
    }
}
