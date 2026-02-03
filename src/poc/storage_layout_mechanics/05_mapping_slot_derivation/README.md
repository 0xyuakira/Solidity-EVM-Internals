# PoC: Mapping — Sparse Hashing and Slot Derivation

---

## 1. 🔬 Objective

Demonstrate how `mapping` state variables are laid out in EVM storage and how their **data slots are deterministically derived**.

This PoC focuses on verifying:

- Whether a `mapping` declaration slot stores any data.
- How mapping value slots are derived from `(key, declaration slot)`.
- Whether different key types affect slot derivation.
- How nested dynamic types behave when used as mapping values.

---

## 2. 🏗️ Architecture

### Subject

Three mapping state variables declared sequentially:

- `mapping(uint256 => uint256)` (value-type mapping)
- `mapping(address => uint128)` (non-32-byte value mapping)
- `mapping(bytes32 => bytes[])` (mapping to dynamic array of dynamic type)

---

### Method

- Mapping entries are written explicitly via setter functions.
- No mapping is pre-initialized at deployment time.
- Storage is inspected post-write using `vm.load`.
- Slot indices are derived manually using `keccak256(abi.encode(key, slot))`.

---

### Observation Surface

- Declaration slot (`slot n`)
- Mapping entry slot (`keccak256(key, n)`)
- For nested mapping values:
  - Dynamic array declaration slot
  - Array element base slot (`keccak256(declaration_slot)`)
  - Derived slots for dynamic byte data

---

## 3. 📊 Observation

### `mapping(uint256 => uint256)` — Simple value-type mapping

```bash
forge test --match-test test_basicMap_storage -vv
```

The following table lists the raw 32-byte values of each storage slot as obtained from `vm.load` in tests:

| Slot              | Raw bytes32 value                                                  |
| ------------------|--------------------------------------------------------------------|
| 0                 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
| keccak256(0, 0)     | 0x0000000000000000000000000000000000000000000000000000000000001111 |
| keccak256(1, 0)     | 0x0000000000000000000000000000000000000000000000000000000000002222 |
| keccak256(2, 0)     | 0x0000000000000000000000000000000000000000000000000000000000003333 |

Observed phenomena:

- The declaration slot (`slot 0`) remains zero after writes.
- Each key-value pair is stored at a slot derived from `keccak256(key, declaration_slot)`.
- Each value(`uint256`) occupies exactly one full 32-byte and non-contiguous storage slot.

### `mapping(address => uint128)` — Address-keyed mapping

```bash
forge test --match-test test_addrMap_storage -vv
```

The following table lists the raw 32-byte values of each storage slot as obtained from `vm.load` in tests:

| Slot              | Raw bytes32 value                                                  |
| ------------------|--------------------------------------------------------------------|
| 1                 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
| keccak256(0x1234567890123456789012345678901234567890, 1)     | 0x000000000000000000000000000000000000000000000000000000000000aaaa |
| keccak256(0x1234567890123456789012345678901234567891, 1)     | 0x000000000000000000000000000000000000000000000000000000000000bbbb |
| keccak256(0x1234567890123456789012345678901234567892, 1)     | 0x000000000000000000000000000000000000000000000000000000000000cccc |

Observed phenomena:

- The declaration slot (`slot 1`) remains zero after writes.
- Each key-value pair is stored at a slot derived from `keccak256(key, declaration_slot)`.
- The stored `uint128` values are right-aligned within a 32-byte slot.
- Higher-order bytes in each slot are zero-padded.


### `mapping(bytes32 => bytes[])` — Mapping to dynamic array

```bash
forge test --match-test test_nestedMap_storage -vv
```

The following table lists the raw 32-byte values of each storage slot as obtained from `vm.load` in tests:

| Slot              | Raw bytes32 value                                                  |
| ------------------|--------------------------------------------------------------------|
| 2                 | 0x0000000000000000000000000000000000000000000000000000000000000000 |
| keccak256(key, 2)      | 0x0000000000000000000000000000000000000000000000000000000000000003 |
| keccak256(keccak256(key, 2))       | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce3e |
| keccak256(keccak256(key, 2)) + 1   | 0x0000000000000000000000000000000000000000000000000000000000000041 |
| keccak256(keccak256(keccak256(key, 2)) + 1)     | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1 |
| keccak256(keccak256(key, 2)) + 2  | 0x0000000000000000000000000000000000000000000000000000000000000043 |
| keccak256(keccak256(keccak256(key, 2)) + 2)     | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1 |
| keccak256(keccak256(keccak256(key, 2)) + 2) + 1 | 0x2300000000000000000000000000000000000000000000000000000000000000 |

Observed phenomena:

- The declaration slot (`slot 2`) remains zero after writes.
- The slot derived from `keccak256(key, declaration_slot)` serves as the declaration slot of the dynamic array and stores the array length.
- The storage layout of each element in the dynamic array follows the same rules as shown in **04_dynamic_array_slot_derivation**.

## 4. 🎓 Conclusion

- Each `mapping` variable occupies its own `declaration slot`, which does not store any bytes and serves only to identify the mapping’s location in contract storage.
- The slots for mapping elements are derived via `keccak256(key, declaration_slot)`, ensuring that each key maps to a unique and independent storage location.
- When a mapping’s `value` is a dynamic type, its data is adaptively nested starting from the derived slot, following the storage rules of the dynamic type itself.
- The mapping, its elements, and the spaces between elements are fully isolated, ensuring precise access and updates for any key.