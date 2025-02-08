# RISC-V-Tomasulo_Processor

## Testcase 1 (Correct! Out-of-order execution)
```asm
ADDI x1, x0, 3       0x00300093
ADDI x2, x0, 5       0x00500113
ADD x3, x1, x2       0x002081b3
ADDI x6, x0, 6       0x00600313   # This one should execute first
ADD x4, x3, x2       0x00218233
SUB x5, x4, x1       0x401202b3
ADD x7, x6, x5       0x005303b3

ADDI x1, x0, 3       0x00300093
ADDI x2, x0, 5       0x00500113
MUL x8, x1, x2       0x02208433
MUL x9, x8, x1       0x021404b3   # Should wait for many cycles
ADD x3, x1, x2       0x002081b3
ADDI x6, x0, 6       0x00600313   # This one should execute first
ADD x4, x3, x2       0x00218233
SUB x5, x4, x1       0x401202b3
ADD x7, x6, x5       0x005303b3

ADDI x1, x0, 3       0x00300093
ADDI x2, x0, 5       0x00500113
SW x1, 0(x2)         0x00112023
LW x3, 0(x2)         0x00012183   # x3 should be 3
ADDI x4, x0, 1       0x00100213
SW x1, 4(x4)         0x00122223
LW x5, 4(x4)         0x00422283   # x5 should be 3 (this tests the address offset)
