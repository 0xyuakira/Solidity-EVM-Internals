# PoC: Root Call Frame — Environment Binding and In-Frame Stability

---

## 1. 🔬 Objective

Observe how execution-environment variables are initialized at root-call-frame entry, and whether they remain stable within the lifetime of the same root call frame.

---

## 2. 🏗️ Architecture

### Subject

Root-call-frame entry and intra-frame execution behavior for execution-environment variables during:

- A root call frame
- Two observations around one internal call within the same root call frame

### Method

1. Perform a root call from an EOA into `RootFrameEnvBinding.snapshot` to capture initialization bindings.
2. Within one root call frame, invoke `snapshotAroundInternal`, execute one internal function call, and capture snapshots before and after the internal call.
3. Compare captured environment fields across two observations in the same root call frame.

### Observation Surface

- Initialization consistency: whether captured environment values match expected root-call input context.
- In-frame stability: whether captured environment values remain unchanged within the same root call frame.

---

## 3. 📊 Observation

```bash
forge test --match-path test/runtime_execution_context/01_RootFrameEnvBindingTest.t.sol -vv
```

- In the root call frame, all captured execution-environment variables are initialized with the root-call context values.
- Across two captures around one internal call in the same root call frame:
  - **call-frame level**: `address(this)`, `msg.sender`, `msg.value`, `msg.sig`, `msg.data` length/hash
  - **transaction level**: `tx.origin`, `tx.gasprice`
  - **block level**: `block.number`, `block.timestamp`, `block.basefee`, `block.chainid`
  remain identical.

---

## 4. 🎓 Conclusion

Execution-environment variables are initialized when a root call frame is entered and remain stable across internal execution within the same root call frame.
