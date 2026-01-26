# Solidity-EVM-Internals

## 📄 Project Overview

- This repository contains a series of PoC experiments demonstrating the mapping between Solidity semantics and EVM internals.
- Each PoC is designed to be atomic, focusing on a single aspect of Solidity behavior.
- The experiments provide raw outputs and conclusions, allowing developers to intuitively understand how Solidity semantics are executed at the EVM level.

---

## 🧪 Usage

```bash
git clone https://github.com/0xyuakira/Solidity-EVM-Internals.git
cd Solidity-EVM-Internals
forge install
```

Run a specific PoC:
```bash
forge test --match-test test_fixed_length_slot -vv
```

---

## ⚠️ Notes

- The main branch uses Solidity version **0.8.33** or above.

- New branches will be created for future Solidity versions to validate corresponding behaviors.

---

## 📄 项目概览

- 本仓库包含一系列 PoC 实验，用于展示 Solidity 语义与 EVM 底层执行之间的映射关系。
- 每个 PoC 尽量保持原子化，聚焦单一 Solidity 行为。
- 实验输出原始结果和结论，使开发者能够直观理解 Solidity 语义在 EVM 层的执行机制。

---

## 🧪 使用方法

```bash
git clone https://github.com/0xyuakira/Solidity-EVM-Internals.git
cd Solidity-EVM-Internals
forge install
```

运行指定PoC:
```bash
forge test --match-test test_fixed_length_slot -vv
```

---

## ⚠️ 注意事项

主分支使用 Solidity 版本 0.8.33 及以上。

若未来发布新版本，将会为每个新版本创建对应分支以验证相应行为。