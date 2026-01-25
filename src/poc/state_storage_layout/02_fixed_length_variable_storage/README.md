# PoC: Fixed-Length Variable Storage in EVM Slots

---

## 1. 🔬 Objective

Demonstrate how fixed-length Solidity variables are stored in individual EVM storage slots. The PoC allows observation of raw slot contents using `vm.load`.
Focus on observing:

- Whether variables are allocated in slots following their declaration order.
- How small types (e.g., uint16, bool, enum) are padded within a slot.

---

## 2. 🏗️ Architecture

- The contract declares multiple fixed-length state variables of various types: bool, uint256, uint16, bytes31, address, bytes32, and an enum.

- All variables are initialized via the constructor to allow flexible assignment in tests.

- Each storage slot in the EVM has a fixed size of 32 bytes (256 bits).

- `vm.load` can be used to inspect slot contents directly.

**Core Code:**

```solidity
// Constructor initializes multiple fixed-length variables
constructor(
    bool _a,
    uint256 _b,
    uint16 _c,
    bytes31 _d,
    address _e,
    bytes32 _f,
    MyEnum _g
) {
    a = _a;
    b = _b;
    c = _c;
    d = _d;
    e = _e;
    f = _f;
    g = _g;
}

// Deploy and initialize the contract
function setUp() public {
    fixedLengthVariableStorage = new FixedLengthVariableStorage(
        true, // a: bool
        0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef, // b: uint256
        0x1234, // c: uint16
        hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abce", // d: bytes31
        0x1234567890123456789012345678901234567890, // e: address
        hex"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1", // f: bytes32
        FixedLengthVariableStorage.MyEnum.TWO // g: enum
    );
    }

// Use vm.load in tests to read the raw slot value
bytes32 slotValue = vm.load(address(fixedLengthVariableStorage), bytes32(slotIndex));
```

## 3. ⚡ Execution

**Command:**

```bash
forge test --match-test test_fixed_length_slot -vv
```

---

## 4. 📊 Observation

The following table lists the raw 32-byte values of each storage slot as obtained from `vm.load` in tests:

| Slot | Raw bytes32 value                                                  |
| ---- | ------------------------------------------------------------------ |
| 0    | 0x0000000000000000000000000000000000000000000000000000000000000001 |
| 1    | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef |
| 2    | 0x0000000000000000000000000000000000000000000000000000000000001234 |
| 3    | 0x001234567890abcdef1234567890abcdef1234567890abcdef1234567890abce |
| 4    | 0x0000000000000000000000001234567890123456789012345678901234567890 |
| 5    | 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcef1 |
| 6    | 0x0000000000000000000000000000000000000000000000000000000000000002 |

These values represent the actual bytes stored in each EVM slot.  
Observation focuses on **slot allocation order** and **byte alignment/padding** of variables.

---

## 5. 🎓 Conclusion / 结论

- Each variable occupies storage slots according to the declaration order in the contract.
- Small types (`bool`, `uint16`, `enum`) are stored starting from the **lowest-order bytes** of a slot, leaving the higher-order bytes as padding (filled with zeros).
- Larger types (`uint256`, `bytes31`, `bytes32`, `address`) generally occupy a full slot.
