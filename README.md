# MIPS-Pipelined-Processor
___________________________________________________

This is a simplified 32-bit canonical MIPS pipelined processor implementation in MIPS
Stages for the processor are:
Fetch -> Decode -> Execute -> Memory -> Writeback

The processor implements a hazard unit

## Supported Instructions

This processor implements the following instructions:
```
add, sub, and, or, slt, lw, sw, beq, addi, j and jal instructions
```

## Diagram

![PipelineDatapath](https://github.com/mrowaha/MIPS-Pipelined-Processor/assets/91381790/da49762b-3248-49da-a0fd-b645752a4bd9)
