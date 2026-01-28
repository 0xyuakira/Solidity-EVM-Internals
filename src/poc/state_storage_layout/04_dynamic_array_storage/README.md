# PoC: Dynamic Array Storage: Storage Layout and Slot Derivation Rules

---

## 1. 🔬 Objective

This PoC aims to examine how **dynamic arrays** in EVM are laid out at the EVM storage level.

This PoC focuses on observing:

- Whether dynamic arrays are still assigned storage slots according to their declaration order.
- What exactly is stored in a dynamic array’s declaration slot.
- How dynamic arrays with different element types (**value types**, **packable value types**, **dynamic types**) differ in storage layout.
- How element storage slots are derived from the declaration slot using `keccak256`.
- Whether nested storage derivation occurs when array elements themselves are dynamic types.

---

## 2. 🏗️ Architecture

### Contract Design

The contract declares three forms of dynamic arrays to compare their storage behaviors:

- **Dynamic arrays of value types (non-packable)**
- `uint256[]`
- **Dynamic arrays of value types (packable)**
- `uint128[]`
- **Dynamic arrays of dynamic types**
- `bytes[]`

### Test Design

- All array elements are written explicitly in tests via push operations.
- Storage is inspected immediately after writes using `vm.load`.
- Each test focuses on one specific array type, avoiding cross-interference.

### Core Assumptions

- The declaration slot of a dynamic array:
   - does not store element data,
   - stores only the current array length.
-The storage location of array elements is derived starting from `keccak256(declaration_slot)` and proceeds sequentially according to the element index.

### **Core Code:**
```solidity
    // declares three forms of dynamic arrays
    contract DynamicArrayStorage {
        uint256[] public u256Array; 
        uint128[] public u128Array; 
        bytes[] public bytesArray; 
    }

    // Observe storage layout of uint256[] dynamic array 
    function test_dynamic_u256_array_storage() public {
        // === Write ===
        storageContract.pushU256(0x1111);
        storageContract.pushU256(0x2222);
        storageContract.pushU256(0x3333);

        // ==== Dump declaration slot ====
        bytes32 slotValue = vm.load(address(storageContract), bytes32(uint256(0)));
        emit log_named_uint("Slot", 0);
        emit log_named_bytes32("Raw bytes32 value", slotValue);

        // ==== Dump data slot ====
        bytes32 dataSlot = keccak256(abi.encode(0));
        bytes32 dataValue;
        for (uint256 i = 0; i < 3; i++) {
            dataValue = vm.load(address(storageContract), bytes32(uint256(dataSlot) + i));
            emit log_named_uint("Slot", uint256(dataSlot) + i);
            emit log_named_bytes32("Raw bytes32 value", dataValue);
        }
    }

    // Observe storage layout of uint128[] dynamic array
    function test_dynamic_u128_array_storage() public {
        // === Write ===
        storageContract.pushU128(0xaaaa);
        storageContract.pushU128(0xbbbb);
        storageContract.pushU128(0xcccc);

        // ==== Dump declaration slot ====
        bytes32 slotValue = vm.load(address(storageContract), bytes32(uint256(1)));
        emit log_named_uint("Slot", 1);
        emit log_named_bytes32("Raw bytes32 value", slotValue);

        // ==== Dump data slot ====
        bytes32 dataSlot = keccak256(abi.encode(1));
        bytes32 dataValue;
        for (uint256 i = 0; i < 2; i++) {
            dataValue = vm.load(address(storageContract), bytes32(uint256(dataSlot) + i));
            emit log_named_uint("Slot", uint256(dataSlot) + i);
            emit log_named_bytes32("Raw bytes32 value", dataValue);
        }
    }

    // Observe storage layout of bytes[] dynamic array
    function test_dynamic_bytes_array_storage() public {
        // === Write ===
        storageContract.pushBytes(hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce");
        storageContract.pushBytes(hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1");
        storageContract.pushBytes(hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef123");

        // ==== Dump bytes array declaration slot ====
        bytes32 slotValue = vm.load(address(storageContract), bytes32(uint256(2)));
        emit log_named_uint("Slot", 2);
        emit log_named_bytes32("Raw bytes32 value", slotValue);

        uint256 declarationSlot = uint256(keccak256(abi.encode(2)));
        bytes32 dataValue;
        bytes32 dataSlot;
        for (uint256 i = 0; i < 3; i++) {
            // ==== Dump bytes declaration slot ====
            i == 0 ? declarationSlot : declarationSlot++;
            dataValue = vm.load(address(storageContract), bytes32(declarationSlot));
            emit log_named_uint("Slot", uint256(declarationSlot));
            emit log_named_bytes32("Raw bytes32 value", dataValue);

            // ==== Dump data slot ====
            if (i > 0) {
                dataSlot = keccak256(abi.encode(declarationSlot));
                dataValue = vm.load(address(storageContract), bytes32(dataSlot));
                emit log_named_uint("Slot", uint256(dataSlot));
                emit log_named_bytes32("Raw bytes32 value", dataValue);
            }
            if (i > 1) {
                dataSlot = bytes32(uint256(dataSlot) + 1);
                dataValue = vm.load(address(storageContract), dataSlot);
                emit log_named_uint("Slot", uint256(dataSlot));
                emit log_named_bytes32("Raw bytes32 value", dataValue);
            }
        }
    }
```

---

## 3. ⚡ Execution && 📊 Observation

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

- The storage layout of each element follows the same rules as shown in **03_dynamic_bytes_string_storage**, adapting between inline storage and external slots depending on the element length.

---

## 5. 🎓 Conclusion

- The declaration slots of dynamic arrays are allocated strictly in the order they are declared in the contract.

- The declaration slot stores only the length of the array.

- Array elements are not stored in the declaration slot; they are stored consecutively starting from the slot at `keccak256(declaration_slot)`.

- Each element is stored adaptively according to its own characteristics, and its packing behavior is determined by its size.