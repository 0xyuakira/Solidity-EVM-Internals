# Storage: uint256-keyed EVM storage space

## Question
- How are Solidity state variables mapped to EVM storage slots?
- What is the maximum slot index in EVM?

## Hypothesis
EVM storage is a key-value space:
- key: uint256 (slot index)
- value: 256-bit word

## Experiment 1: Slot Width
- Declare multiple uint256 variables
- Observe slot alignment and width

## Experiment 2: Slot Index Space
- Use assembly in tests to write to an extreme slot index
- Observe read/write behavior

## Observation
- Variables occupy consecutive slots starting from 0
- Each slot holds exactly 256 bits
- Assembly can write to extremely high slot numbers (up to type(uint256).max)

## Conclusion
- Each storage slot = 256 bits
- Slot index space = uint256 (theoretical maximum 2^256 slots)
- Practical deployment cannot occupy extreme slots, but testing proves the concept

## Run the test

# Run all tests
forge test -vvv

# Run individual tests
forge test -vvv -m "test_slot_width_is_256bit"
forge test -vvv -m "test_storage_index_space_is_uint256"