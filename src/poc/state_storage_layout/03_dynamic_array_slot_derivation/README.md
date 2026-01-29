# PoC: Dynamic Array Storage — Layout and Slot Derivation

---

## 1. 🔬 Objective

Verify the storage layout invariants of EVM dynamic arrays, specifically:

- declaration slot semantics,
- element base slot derivation,
- packing behavior for value types,
- nested slot derivation for dynamic elements.

---

## 2. 🏗️ Architecture

### Subject

Three dynamic arrays declared sequentially:

- `uint256[]` (non-packable value type)
- `uint128[]` (packable value type)
- `bytes[]` (dynamic type)

### Method

- Elements are appended via `push`.
- Storage is inspected post-write using `vm.load`.
- Each test isolates a single array to avoid cross-effects.

### Observation Surface

- Declaration slot (`slot n`)
- Element base slot (`keccak256(n)`)
- Derived slots for packed or dynamic elements

---

## 3. 📊 Observation

### `uint256[]` — Dynamic arrays of value types (non-packable)

```bash
forge test --match-test test_dynamic_u256_array_storage -vv
```

The following table lists the raw 32-byte values of each storage slot as obtained from `vm.load` in tests:

| Slot              | Raw bytes32 value                                                  |
| ------------------|--------------------------------------------------------------------|
| 0                 | 0x0000000000000000000000000000000000000000000000000000000000000003 |
| keccak256(0)      | 0x0000000000000000000000000000000000000000000000000000000000001111 |
| keccak256(0) + 1  | 0x0000000000000000000000000000000000000000000000000000000000002222 |
| keccak256(0) + 2  | 0x0000000000000000000000000000000000000000000000000000000000003333 |

Observed phenomena:

- The length of the dynamic array is stored directly in its declaration slot `(slot 0)`.
- Array elements are stored sequentially starting from the storage slot `keccak256(0)`.
- Each `uint256` element occupies a full storage slot.

### `uint128[]` — Dynamic arrays of value types (packable)

```bash
forge test --match-test test_dynamic_u128_array_storage -vv
```

The following table lists the raw 32-byte values of each storage slot as obtained from `vm.load` in tests:

| Slot              | Raw bytes32 value                                                  |
| ------------------|--------------------------------------------------------------------|
| 1                 | 0x0000000000000000000000000000000000000000000000000000000000000003 |
| keccak256(1)      | 0x0000000000000000000000000000bbbb0000000000000000000000000000aaaa |
| keccak256(1) + 1  | 0x000000000000000000000000000000000000000000000000000000000000cccc |

Observed phenomena:

- The length of the dynamic array is stored directly in its declaration slot `(slot 1)`.
- Array elements are stored sequentially starting from the storage slot `keccak256(1)`.
- Two consecutive `uint128` elements are packed into a single storage slot.

### `bytes[]` - Dynamic arrays of dynamic types

```bash
forge test --match-test test_dynamic_bytes_array_storage -vv
```

The following table lists the raw 32-byte values of each storage slot as obtained from `vm.load` in tests:

| Slot              | Raw bytes32 value                                                  |
| ------------------|--------------------------------------------------------------------|
| 2                 | 0x0000000000000000000000000000000000000000000000000000000000000003 |
| keccak256(2)      | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce3e |
| keccak256(2) + 1  | 0x0000000000000000000000000000000000000000000000000000000000000041 |
| keccak(keccak256(2) + 1)     | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1 |
| keccak256(2) + 2  | 0x0000000000000000000000000000000000000000000000000000000000000043 |
| keccak(keccak256(2) + 2)     | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1 |
| keccak(keccak256(2) + 2) + 1 | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1 |

Observed phenomena:

- The length of the bytes[] dynamic array is stored in its declaration slot `(slot 2)`.

- Array elements are stored sequentially starting from the storage slot `keccak256(2)`, each element occupying its own declaration slot.

- The content stored in each element’s declaration slot depends on the actual length of the bytes element.

- The storage layout of each element follows the same rules as shown in **02_dynamic_bytes_inline_spill**, adapting between inline storage and external slots depending on the element length.

---

## 4. 🎓 Conclusion

- The declaration slots of dynamic arrays are allocated strictly in the order they are declared in the contract.

- The declaration slot stores only the length of the array.

- Array elements are not stored in the declaration slot; they are stored consecutively starting from the slot at `keccak256(declaration_slot)`.

- Each element is stored adaptively according to its own characteristics, and its packing behavior is determined by its size.