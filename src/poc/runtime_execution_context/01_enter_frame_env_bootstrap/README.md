# PoC: Frame Entry Environment Bootstrap

---

## 1. 🔬 Objective

Observe how execution-environment variables are initialized at call-frame entry, and whether they remain stable within the lifetime of the same call frame.

---

## 2. 🏗️ Architecture

### Subject

Call-frame entry and intra-frame execution behavior for execution-environment variables during:

- A root call frame
- Two observations around one internal call within the same call frame

### Method

1. Perform a root call from an EOA into `FrameEnvBootstrap.snapshot` to capture initialization bindings.
2. Within one call frame, invoke `snapshotAroundInternal`, execute one internal function call, and capture snapshots before and after the internal call.
3. Compare captured environment fields across two observations in the same call frame.

### Observation Surface

- **env_context**
  - `address(this)`
  - `msg.sender`
  - `msg.value`
  - `msg.sig`
  - `tx.origin`
  - `tx.gasprice`
  - `block.number`
  - `block.timestamp`
  - `block.basefee`
  - `block.chainid`
  - `msg.data` length
  - `msg.data` hash

---

## 3. 📊 Observation

```bash
forge test --match-path test/runtime_execution_context/01_FrameEnvBootstrapTest.t.sol -vv
```

- In the root call frame, all captured execution-environment variables are initialized with the root-call context values.
- Across two captures around one internal call in the same call frame:
  - `address(this)`, `msg.sender`, `msg.value`, `msg.sig`
  - `tx.origin`, `tx.gasprice`
  - `block.number`, `block.timestamp`, `block.basefee`, `block.chainid`
  - `msg.data` length/hash
  remain identical.

---

## 4. 🎓 Conclusion

Execution-environment variables are initialized when a root call frame is entered and remain stable across internal execution within the same call frame.
