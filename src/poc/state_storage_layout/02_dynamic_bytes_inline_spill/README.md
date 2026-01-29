# PoC: Dynamic Bytes — Inline Storage and Spill Mechanics

---

## 1. 🔬 Objective

Verify storage layout invariants of dynamic-length byte sequences (`bytes` and `string`) in EVM:

- Declaration slot semantics.
- Inline vs external storage boundaries (≤31 bytes vs ≥32 bytes).
- Multi-slot storage for >32 bytes.
- Type encoding differences between `bytes`/`string` and `bytesN`.

---

## 2. 🏗️ Architecture

### Subject

Six dynamic-length variables initialized with specific lengths:

- 31 bytes: `b31`, `s31`
- 32 bytes: `b32`, `s32`
- 33 bytes: `b33`, `s33`

### Method

- Constructor sets all variables.
- Unified test function reads all declaration slots sequentially via `vm.load`.
- Derived data slots computed via `keccak256(declaration_slot)` when needed.
- Observations come from a single consistent test run.

### Observation Surface

- Declaration slot (`slot n`)
- Derived data slot (`keccak256(slot n)`), multi-slot if necessary

---

## 3. 📊 Observation

```bash
forge test --match-test test_dynamic_bytes_string_storage -vv
```

The following table lists the raw 32-byte values of each storage slot as obtained from `vm.load` in tests:

| Slot              | Raw bytes32 value                                                  |
| ------------------|--------------------------------------------------------------------|
| 0                 | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce3e |
| 1                 | 0x6162636465666768696a6b6c6d6e6f707172737475767778797a41424344453e |
| 2                 | 0x0000000000000000000000000000000000000000000000000000000000000041 |
| keccak256(2)      | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1 |
| 3                 | 0x0000000000000000000000000000000000000000000000000000000000000041 |
| keccak256(3)      | 0x6162636465666768696a6b6c6d6e6f707172737475767778797a414243444546 |
| 4                 | 0x0000000000000000000000000000000000000000000000000000000000000043 |
| keccak256(4)      | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1 |
| keccak256(4) + 1  | 0x2300000000000000000000000000000000000000000000000000000000000000 |
| 5                 | 0x0000000000000000000000000000000000000000000000000000000000000043 |
| keccak256(5)      | 0x6162636465666768696a6b6c6d6e6f707172737475767778797a414243444546 |
| keccak256(5) + 1  | 0x4700000000000000000000000000000000000000000000000000000000000000 |

Observed phenomena:

- string and bytes follow identical storage layout rules in EVM storage.
- For `s31` and `b31` (length = 31 bytes):
    - The higher-order 31 bytes of the declaration slot store the raw byte data directly.
    - The lowest-order 1 byte stores the value `0x3e`, which equals `length × 2`.
- For `s32` and `b32` (length = 32 bytes):
    - The lowest-order 1 byte of the declaration slot stores the value `0x43`, which equals `length × 2 + 1`.
    - The raw byte data is stored in the storage slot at `keccak256(declaration_slot)`.
- For `s33` and `b33` (length = 33 bytes):
    - The lowest-order 1 byte of the declaration slot stores the value `0x47`, which equals `length × 2 + 1`.
    - The raw byte data starts at `keccak256(declaration_slot)` and spans two consecutive storage slots: `keccak256(declaration_slot)` and `keccak256(declaration_slot) + 1`.
    - The final storage slot is padded with zeros in its lower-order bytes.

---

## 4. 🎓 Conclusion

- `bytes` and `string` are both dynamic-length byte sequence types and follow identical storage layout rules at the EVM storage level. Any differences between them exist only at the type-semantic level, not in their underlying storage implementation.
- Dynamic-length state variables are still assigned storage slots strictly according to their declaration order within the contract. Each variable occupies a single, independent **declaration slot**.
- **Thirty-one bytes** represents the critical boundary in the storage layout of dynamic byte sequences:
    - When the data length ≤ 31 bytes, the raw byte data is stored inline in the **higher-order** 31 bytes of the declaration slot.
    - When the data length ≥ 32 bytes, the declaration slot no longer stores raw data. Instead, the raw byte data is stored starting at the storage slot derived from `keccak256(declaration_slot)`, potentially spanning multiple consecutive slots. Any unused bytes in the final slot are filled with zero padding in the **lower-order** bytes.   
- The lowest-order byte of the declaration slot can be uniformly abstracted as:
    - `length × 2` (even): inline storage mode
    - `length × 2 + 1` (odd): external storage mode
  This encoding simultaneously conveys both the length of the dynamic data and its storage location mode, allowing the data length and placement to be determined directly from the declaration slot.
- Even when storing the same number of bytes (e.g., 31 bytes), `bytesN` (fixed-length types) and `bytes` (dynamic types) exhibit fundamentally different storage layouts at the EVM level. This distinction arises from whether the type carries dynamic-length semantics, rather than from the data size itself.
