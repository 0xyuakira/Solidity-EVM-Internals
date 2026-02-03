# PoC: Fixed-Length Variable - Packing and Alignment

---

## 1. 🔬 Objective

Verify EVM storage layout invariants for fixed-length state variables:

- Basic types: `bool`, `uint16`, `uint256`, `bytes31`, `bytes32`, `address`, `enum`.
- Fixed-length arrays: `uint128[3]`.
- Structs with mixed integer types.
- Observe packing and slot alignment of consecutive variables.

---

## 2. 🏗️ Architecture

### Subject

- Contract declares multiple fixed-length state variables sequentially:

  - Single-slot types: `uint256`, `bytes32`, `address`.
  - Packable small types: `bool`, `uint16`, `enum`.
  - Large bytes: `bytes31`.
  - Fixed-length array: `uint128[3]`.
  - Struct: `PackedStruct { int128, int64, int64 }`.

### Method

- Deploy contract and initialize all variables via constructor.
- Use a unified test function to assert variable values and read all storage slots sequentially with `vm.load`.

### Observation Surface

- Declaration slot (`slot n`) for each variable.
- Consecutive slots for multi-slot variables (arrays, structs).

---

## 3. 📊 Observation

```bash
forge test --match-test test_fixed_length_storage -vv
```

The following table lists the raw 32-byte values of each storage slot as obtained from `vm.load` in tests:

| Slot | Raw bytes32 value                                                  |
| ---- | ------------------------------------------------------------------ |
| 0    | 0x0000000000000000000000000000000000000000000000000000000000000001 |
| 1    | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef |
| 2    | 0x0000000000000000000000000000000000000000000000000000000000001234 |
| 3    | 0x001234567890abcdef1234567890abcdef1234567890abcdef1234567890abce |
| 4    | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1 |
| 5    | 0x0000000000000000000000021234567890123456789012345678901234567890 |
| 6    | 0x2222222222222222222222222222222211111111111111111111111111111111 |
| 7    | 0x0000000000000000000000000000000033333333333333333333333333333333 |
| 8    | 0x3333333333333333222222222222222211111111111111111111111111111111 |

Observed phenomena:

- Storage slots are allocated sequentially according to variable declaration order.
- Variables that occupy fewer than 32 bytes (e.g., `bool`, `address`, `uint16`, `bytes31`) have their data stored in the lower-order bytes of a slot, with  higher-order bytes filled with zeros.
- `Slot 5` contains data from both variables `addr_20` and `enum_1`.
- Some slots contain only a single variable, which occupies the entire slot (e.g., `uint256` or `bytes32`).
- Fixed-length array `u128Array`:
  - First two elements packed into a single slot (`slot 6`).
  - Third element occupies next slot (`slot 7`).
- Struct PackedStruct:Three fields (`int128`, `int64`, `int64`) are packed into a single slot (`slot 8`).

---

## 4. 🎓 Conclusion

- Storage slots are allocated sequentially following the declaration order of Fixed-length variables.
- Fixed-length variables that do not occupy the full 32 bytes are right-aligned within a storage slot, with unused higher-order bytes padded with zeros.
- Adjacent fixed-length variables are packed into the same storage slot when their combined size does not exceed 32 bytes.
- Fixed-length variables that occupy the full 32 bytes, or cannot be packed with an adjacent variable due to size constraints, each occupy a dedicated storage slot.
