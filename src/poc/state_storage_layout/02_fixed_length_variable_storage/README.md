# PoC: Fixed-Length Variable Storage: Slot Packing and Boundary Conditions

---

## 1. 🔬 Objective

Demonstrate how fixed-length variables are stored in EVM storage slots. This PoC focuses on observing:

- Whether variables are allocated in slots following their declaration order.
- How small types (e.g., uint16, bool, enum) are padded within a slot.
- Whether multiple fixed-length variables whose combined size is less than or equal to 32 bytes are packed into the same storage slot.

---

## 2. 🏗️ Architecture

- The contract declares multiple fixed-length state variables of various types: bool, uint256, uint16, bytes31, address, bytes32, int128, and an enum.

- All variables are initialized via the constructor to allow flexible assignment in tests.

- Each storage slot in the EVM has a fixed size of 32 bytes (256 bits).

- `vm.load` can be used to inspect slot contents directly.

**Core Code:**

```solidity
// Constructor initializes multiple fixed-length variables
constructor(bool _a, uint256 _b, uint16 _c, bytes31 _d, address _e, bytes32 _f, MyEnum _g, int128 _h, int128 _i) {
    a = _a;
    b = _b;
    c = _c;
    d = _d;
    e = _e;
    f = _f;
    g = _g;
    h = _h;
    i = _i;
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
        FixedLengthVariableStorage.MyEnum.TWO, // g: enum
        0x1234567890abcdef1234567890abcdef, // h: int128
        0x1234567890abcdef1234567890abcdef, // i: int128
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
| 6    | 0x0000000000000000000000000000001234567890abcdef1234567890abcdef02 |
| 7    | 0x000000000000000000000000000000001234567890abcdef1234567890abcdef |

Observed phenomena:

- Storage slots appear to be allocated in the order of variable declarations.
- Variables that occupy fewer than 32 bytes (e.g., `bool`, `address`, `uint16`, `bytes31`, `int128`) have their data stored in the lower-order bytes of a slot, with higher-order bytes filled with zeros.
- Slot 6 contains data from both variables `g` and `h`.
- Some slots contain only a single variable, which occupies the entire slot (e.g., `uint256` or `bytes32`).

---

## 5. 🎓 Conclusion

- Storage slots are allocated sequentially following the declaration order of Fixed-length variables variables.
- Fixed-length variables that do not occupy the full 32 bytes are right-aligned within a storage slot, with unused higher-order bytes padded with zeros.
- Adjacent fixed-length variables are packed into the same storage slot when their combined size does not exceed 32 bytes.
- Fixed-length variables that occupy the full 32 bytes, or cannot be packed with an adjacent variable due to size constraints, each occupy a dedicated storage slot.
