# PoC: Dynamic-Length Byte Sequences Storage: bytes and string Encoding Boundaries

---

## 1. 🔬 Objective

Demonstrate how dynamic-length byte sequence types (`bytes` and `string`) are stored in EVM storage slots.

This PoC focuses on observing:

- How storage slots are assigned to dynamic-length state variables based on declaration order.
- What is stored in the declaration slot of bytes and string.
- How the storage layout changes at the 31-byte / 32-byte / 33-byte boundary.
- Whether bytes and string share the same storage encoding rules.
- The difference in storage behavior between `bytesN` (fixed-length) and `bytes` (dynamic-length), even when holding the same number of bytes.

---

## 2. 🏗️ Architecture

- The contract declares multiple dynamic-length state variables of type bytes and string.

- Each variable is initialized via the constructor with a specific byte length:
    - 31 bytes
    - 32 bytes
    - 33 bytes

- Each storage slot in the EVM has a fixed size of 32 bytes (256 bits).

- `vm.load` is used to inspect:
    - The declaration slot of each variable.
    - The derived data slot (keccak256(declaration_slot)) when applicable.

**Core Code:**

```solidity
    // Constructor initializes multiple fixed-length variables
    constructor(
        bytes memory _b31,
        string memory _s31,
        bytes memory _b32,
        string memory _s32,
        bytes memory _b33,
        string memory _s33
    ) {
        b31 = _b31;
        s31 = _s31;
        b32 = _b32;
        s32 = _s32;
        b33 = _b33;
        s33 = _s33;
    }

    // Deploy and initialize the contract
    function setUp() public {
        storageContract = new DynamicBytesStringStorage(
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce", // b31 31 bytes
            "abcdefghijklmnopqrstuvwxyzABCDE", // s31 31 bytes
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1", // b32  32 bytes
            "abcdefghijklmnopqrstuvwxyzABCDEF", // s32 32 bytes
            hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef123", // b33 33 bytes
            "abcdefghijklmnopqrstuvwxyzABCDEFG" // s33 33 bytes
        );
    }

    // Use vm.load in tests to read the raw slot value
    for (uint256 slotIndex = 0; slotIndex < 6; slotIndex++) {
            bytes32 slotValue = vm.load(address(storageContract), bytes32(slotIndex));

            emit log_uint(slotIndex);
            emit log_bytes32(slotValue);
            bytes32 dataSlot;
            bytes32 dataValue;
            if (slotIndex > 1) {
                dataSlot = keccak256(abi.encode(slotIndex));
                dataValue = vm.load(address(storageContract), dataSlot);
                emit log_uint(uint256(dataSlot));
                emit log_bytes32(dataValue);
            }
            if (slotIndex > 3) {
                dataSlot = bytes32(uint256(dataSlot) + 1);
                dataValue = vm.load(address(storageContract), dataSlot);
                emit log_uint(uint256(dataSlot));
                emit log_bytes32(dataValue);
            }
        }
```

## 3. ⚡ Execution

**Command:**

```bash
forge test --match-test test_dynamic_bytes_string_storage -vv
```

---

## 4. 📊 Observation

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

## 5. 🎓 Conclusion

- `bytes` and `string` are both dynamic-length byte sequence types and follow identical storage layout rules at the EVM storage level. Any differences between them exist only at the type-semantic level, not in their underlying storage implementation.
- Dynamic-length state variables are still assigned storage slots strictly according to their declaration order within the contract. Each variable occupies a single, independent **declaration slot**, and no slot reordering or deferred allocation occurs as a result of the variable being dynamic.
- **Thirty-one bytes** represents the critical boundary in the storage layout of dynamic byte sequences:
    - When the data length ≤ 31 bytes, the raw byte data is stored inline in the **higher-order** 31 bytes of the declaration slot.
    - When the data length ≥ 32 bytes, the declaration slot no longer stores raw data. Instead, the raw byte data is stored starting at the storage slot derived from `keccak256(declaration_slot)`, potentially spanning multiple consecutive slots. Any unused bytes in the final slot are filled with zero padding in the **lower-order** bytes.   
- The lowest-order byte of the declaration slot can be uniformly abstracted as:
    - `length × 2` (even): inline storage mode
    - `length × 2 + 1` (odd): external storage mode
  This encoding simultaneously conveys both the length of the dynamic data and its storage location mode, allowing the data length and placement to be determined directly from the declaration slot.
- Even when storing the same number of bytes (e.g., 31 bytes), `bytesN` (fixed-length types) and `bytes` (dynamic types) exhibit fundamentally different storage layouts at the EVM level. This distinction arises from whether the type carries dynamic-length semantics, rather than from the data size itself.
