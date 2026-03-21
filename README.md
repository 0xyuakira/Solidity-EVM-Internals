# Solidity-EVM-Internals

## 📄 Project Overview
## 📄 项目概览

- This repository contains a series of PoC experiments aimed at experimentally verifying the mapping between Solidity semantics and EVM internals.
- Each PoC is intentionally kept atomic, focusing on a single Solidity behavior.
- The experiments expose raw execution results and derived conclusions, enabling developers to understand how Solidity semantics are concretely realized at the EVM level.

- 本仓库包含一系列 PoC 实验，用于实验性验证 Solidity 语义与 EVM 底层之间的映射关系。
- 每个 PoC 尽量保持原子化，聚焦单一 Solidity 行为。
- 实验直接输出原始执行结果与总结性结论，使开发者能够基于可复现证据理解 Solidity 语义在 EVM 层的执行机制。

---

## 🧪 Usage
## 🧪 使用方法

```bash
git clone https://github.com/0xyuakira/Solidity-EVM-Internals.git
cd Solidity-EVM-Internals
forge install
```

Run a specific PoC:
```bash
forge test --match-test test_fixed_length_storage -vv
```

---

## ⚠️ Notes
## ⚠️ 注意事项

- The main branch uses Solidity version **0.8.33** or above.
- New branches will be created for future Solidity versions to validate corresponding behaviors.

- 主分支使用 Solidity 版本为 0.8.33 及以上。
- 若未来发布新版本，将会为每个新版本创建对应分支以验证相应行为。
