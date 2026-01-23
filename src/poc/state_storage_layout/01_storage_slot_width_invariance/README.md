# PoC: Slot Width Invariance (Single Storage Slot 256-bit Limit)

---

## 1. 🔬 Hypothesis

**Problem:**  
Verify that each storage slot in the EVM has a strict maximum capacity of 256 bits (32 bytes). The focus is on whether exceeding 32 bytes spills into the next slot.

**Assumption:**  
The experiment explicitly tests a single data-containing slot of a dynamic `bytes` variable. It is assumed that **all other storage slots have the same size**, based on EVM storage slot specifications.

**Expectation:**

- A 32-byte sequence should fully fit in a single slot.
- A 33-byte sequence should spill into the next slot.
- No single slot can store more than 256 bits.
- `vm.load` can be used to inspect slot contents directly.

---

## 2. 🏗️ Architecture

**Mechanism:**

- Solidity dynamic `bytes` storage follows:
    - The first slot of a dynamic `bytes` variable stores its length
    - Actual byte data begins at `keccak256(slot)`
- Each storage slot is fixed at 256 bits; overflow spills into subsequent slots

**Core Code:**

```solidity
// Store arbitrary-length bytes
function set(bytes calldata b) external {
    data = b;
}

// Retrieve the starting storage slot for the dynamic data
function dataSlot() external pure returns (uint256) {
    return uint256(keccak256(abi.encode(uint256(0))));
}
```

---

## 3. ⚡ Execution

**Command:**

```bash
forge test --match-test test_bytes32_fits_single_slot -vv
forge test --match-test test_bytes33_spills_into_two_slots -vv
```

---

## 4. 📊 Observation

**Storage Trace:**

- `bytes32` fully stored in the verified data slot
- `bytes33` first 32 bytes in the verified slot, last byte in the next slot, remaining bytes zero

---

## 5. 🎓 Conclusion

**Final Verdict:**

- Experiment confirms that a single storage slot can hold at most 256 bits
- Dynamic bytes exceeding 32 bytes spill into the next slot
