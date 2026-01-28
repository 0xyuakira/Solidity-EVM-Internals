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
}
