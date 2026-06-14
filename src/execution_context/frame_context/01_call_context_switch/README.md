# PoC: Frame Context — Call Context Across CALL Modes

---

## 1. 🔬 Objective

Verify how call context is observed in the root call frame and under three CALL-family modes:

- `CALL`
- `DELEGATECALL`
- `STATICCALL`

This PoC focuses only on call-context fields:

- `address(this)`
- `msg.sender`
- `msg.value`
- `msg.sig`
- `msg.data`

---

## 2. 🏗️ Architecture

### Subject

A minimal pair of contracts exposing call-context snapshots:

- `CallContextSwitch`
  - captures call context in the root call frame
  - invokes the target contract through `CALL`, `DELEGATECALL`, and `STATICCALL`
- `CallContextTarget`
  - captures call context from the code path reached by each call mode

### Method

- An EOA calls `CallContextSwitch.snapshotCallContextSwitch` with:
  - a non-empty `bytes` payload
  - `0.1 ether` as `msg.value`
- During one call to `CallContextSwitch.snapshotCallContextSwitch`, four snapshots are captured:
  - root call frame
  - target reached through `CALL`
  - target reached through `DELEGATECALL`
  - target reached through `STATICCALL`

### Observation Surface

- Contract identity observed by `address(this)`
- Caller identity observed by `msg.sender`
- Call value observed by `msg.value`
- Function selector observed by `msg.sig`
- Calldata shape observed through `msg.data.length` and `keccak256(msg.data)`

---

## 3. 📊 Observation

```bash
forge test --match-path test/execution_context/frame_context/01_CallContextSwitchTest.t.sol -vv
```

The following table lists the reference values printed before the call-context snapshots:

| Reference | Value |
| --------- | ----- |
| `EOA` | 0x00000000000000000000000000000000000A11cE |
| `address(callContextSwitch)` | 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f |
| `address(callContextTarget)` | 0x104fBc016F4bb334D775a19E8A6510109AC63E00 |
| `callContextSwitch.snapshotCallContextSwitch.selector` | 0xa6be8248 |
| `callContextTarget.snapshot.selector` | 0x044d23f2 |
| `keccak256(abi.encodeCall(callContextSwitch.snapshotCallContextSwitch, (payload)))` | 0x25d86ff02f37a6e322566b0fb318c7d43f22582f86d98fb82243607bb92b4f57 |
| `keccak256(abi.encodeCall(callContextTarget.snapshot, (payload)))` | 0x95f34db09c3edddfa8404c26047c43f143ea3242105c7b230dc6b6f69036a226 |

The following table lists the call-context snapshots printed by the test:

| Mode            | `address(this)`                              | `msg.sender`                                 | `msg.value` | `msg.sig`  | `msg.data` length | `keccak256(msg.data)`                                             |
| --------------- | -------------------------------------------- | -------------------------------------------- | ----------- | ---------- | ----------------- | ------------------------------------------------------------------ |
| Root call frame | 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f | 0x00000000000000000000000000000000000A11cE | 100000000000000000 | 0xa6be8248 | 100               | 0x25d86ff02f37a6e322566b0fb318c7d43f22582f86d98fb82243607bb92b4f57 |
| `CALL`          | 0x104fBc016F4bb334D775a19E8A6510109AC63E00 | 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f | 100000000000000000 | 0x044d23f2 | 100               | 0x95f34db09c3edddfa8404c26047c43f143ea3242105c7b230dc6b6f69036a226 |
| `DELEGATECALL`  | 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f | 0x00000000000000000000000000000000000A11cE | 100000000000000000 | 0x044d23f2 | 100               | 0x95f34db09c3edddfa8404c26047c43f143ea3242105c7b230dc6b6f69036a226 |
| `STATICCALL`    | 0x104fBc016F4bb334D775a19E8A6510109AC63E00 | 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f | 0           | 0x044d23f2 | 100               | 0x95f34db09c3edddfa8404c26047c43f143ea3242105c7b230dc6b6f69036a226 |

Observed phenomena:

- In the root call frame:
  - `address(this)` is the `CallContextSwitch` contract.
  - `msg.sender` is the EOA.
  - `msg.value` is the value supplied by the EOA call.
  - `msg.sig` and `msg.data` correspond to `snapshotCallContextSwitch(bytes)`.

- Under `CALL`:
  - `address(this)` is the `CallContextTarget` contract.
  - `msg.sender` is the `CallContextSwitch` contract.
  - `msg.value` is the value forwarded by `CallContextSwitch`.
  - `msg.sig` and `msg.data` correspond to `CallContextTarget.snapshot(bytes)`.

- Under `DELEGATECALL`:
  - `address(this)` remains the `CallContextSwitch` contract.
  - `msg.sender` remains the EOA.
  - `msg.value` remains the value supplied by the EOA call.
  - `msg.sig` and `msg.data` correspond to the calldata used for the delegated `snapshot(bytes)` code path.

- Under `STATICCALL`:
  - `address(this)` is the `CallContextTarget` contract.
  - `msg.sender` is the `CallContextSwitch` contract.
  - `msg.value` is `0`.
  - `msg.sig` and `msg.data` correspond to `CallContextTarget.snapshot(bytes)`.

---

## 4. 🎓 Conclusion

- `CALL` and `STATICCALL` bind identity fields to the target-side call frame: `address(this)` becomes the target contract, and `msg.sender` becomes the calling contract.
- `DELEGATECALL` preserves the caller-side identity fields while executing target code: `address(this)` and `msg.sender` remain aligned with the caller frame.
- `msg.value` follows different value-handling rules: `CALL` can forward native value, `DELEGATECALL` cannot send extra value and only preserves the current `msg.value`, while `STATICCALL` cannot transfer native value.
- `msg.sig` and `msg.data` always correspond to the calldata of the function currently being executed, regardless of whether it is entered through `CALL`, `DELEGATECALL`, or `STATICCALL`.
