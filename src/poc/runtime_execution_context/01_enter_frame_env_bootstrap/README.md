# PoC: Frame Entry Environment Bootstrap

---

## 1. 🔬 Objective

Observe how execution-environment variables are initialized at call-frame entry, and whether they remain stable within the lifetime of the same call frame.

---

## 2. 🏗️ Architecture

### Subject

Call-frame entry and intra-frame execution behavior for execution-environment variables during:

- A root call frame
- A forwarded child call frame
- Multiple observations within the same call frame

### Method

1. Perform a root call from an EOA into `FrameEnvBootstrap.snapshot`.
2. Perform a forwarded call from an EOA through `FrameEnvBootstrapForwarder` into `FrameEnvBootstrap.snapshot`.
3. Within a single call frame, invoke `snapshotPair` to capture two environment snapshots sequentially.
4. Compare captured environment fields across:
   - Different call frames
   - Multiple captures within the same call frame

### Observation Surface

- **env_context**
  - `address(this)`
  - `msg.sender`
  - `msg.value`
  - `msg.data` length
  - `msg.data` hash

---

## 3. 📊 Observation

```bash
forge test --match-path test/runtime_execution_context/01_FrameEnvBootstrapTest.t.sol -vv
```

- In the root call frame, `msg.sender` equals the originating EOA, and `address(this)` equals the target contract.
- In the forwarded call frame, `msg.sender` equals the forwarder contract, while `address(this)` remains the target contract.
- Across multiple captures within the same call frame:
  - `address(this)`, `msg.sender`, `msg.value`, and `msg.data` length/hash remain identical.
  - Only payload-specific views differ.

---

## 4. 🎓 Conclusion

Execution-environment variables are initialized when a call frame is entered and remain stable throughout the lifetime of that call frame, while being re-bound at call-frame boundaries.

