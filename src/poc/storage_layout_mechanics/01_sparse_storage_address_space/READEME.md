# PoC: EVM Storage — sparse storage address space

---

## 1. 🔬 Objective

Verify that EVM Storage allows consistent read and write operations on **arbitrary `uint256` slot indices**, including indices at extreme numeric boundaries.

---

## 2. 🏗️ Architecture

### Subject

A minimal contract exposing raw Storage access capabilities:

- Allows writing a value to an explicitly specified `uint256` storage slot
- Allows reading a value from an explicitly specified `uint256` storage slot

### Method

- Two storage slot indices are selected in the test:
  - `slot = 0`
  - `slot = type(uint256).max`
- Within a single test execution:
  - Non-zero values are written to both slots
  - The written values are read back and compared
- Storage contents are observed directly via `vm.load` or equivalent read interfaces

### Observation Surface

- Storage slots corresponding to explicitly specified indices
- Data isolation between distinct storage slots
- Read/write reachability at extreme slot index values

---

## 3. 📊 Observation

```bash
forge test --match-test test_sparse_storage_slot_addressing -vv
forge test --match-test test_extreme_slot_no_collision -vv
```

Observed phenomena:

- After writing a value to `slot 0`, the value can be successfully read back from `slot 0`.
- After writing a value to slot `type(uint256).max`, the value can be successfully read back from that slot.
- Writing to the extreme slot index does not alter the value stored in `slot 0`.
- Read and write operations on both slots complete without errors or reverts.

---

4. 🎓 Conclusion

- EVM Storage behaviorally supports direct addressing across the full `uint256` slot index space.
- Storage slots are logically independent and exhibit no observable interference based on index magnitude.
- Extreme slot indices do not affect the correctness of reads or writes to other storage slots.