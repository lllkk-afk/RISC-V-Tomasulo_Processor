# RISC-V-Tomasulo_Processor

```asm
## Testcase 1 (Correct! Out-of-order execution)
ADDI x1, x0, 3       0x00300093
ADDI x2, x0, 5       0x00500113
ADD x3, x1, x2       0x002081b3
ADDI x6, x0, 6       0x00600313   # This one should execute first
ADD x4, x3, x2       0x00218233
SUB x5, x4, x1       0x401202b3
ADD x7, x6, x5       0x005303b3

## Testcase 2 (Correct! Multiply works)
ADDI x1, x0, 3       0x00300093
ADDI x2, x0, 5       0x00500113
MUL x8, x1, x2       0x02208433
MUL x9, x8, x1       0x021404b3   # Should wait for many cycles
ADD x3, x1, x2       0x002081b3
ADDI x6, x0, 6       0x00600313   # This one should execute first
ADD x4, x3, x2       0x00218233
SUB x5, x4, x1       0x401202b3
ADD x7, x6, x5       0x005303b3

## Testcase 3 (Correct! Load/store with address offset)
ADDI x1, x0, 3       0x00300093
ADDI x2, x0, 5       0x00500113
SW x1, 0(x2)         0x00112023
LW x3, 0(x2)         0x00012183   # x3 should be 3
ADDI x4, x0, 1       0x00100213
SW x1, 4(x4)         0x00122223
LW x5, 4(x4)         0x00422283   # x5 should be 3 (this tests the address offset)

## Testcase 4 (Correct! Division with dependency)
ADDI x1, x0, 8       0x00800093   # x1 = 8 
ADDI x2, x0, 5       0x00500113   # x2 = 5
MUL  x3, x1, x2      0x022081b3   # x3 = x1 * x2 = 8 * 5 = 40  
DIV  x8, x1, x2      0x0220c433   # x8 = x1 / x2 = 8 / 5 = 1   (Should wait for many cycles)
MUL  x4, x3, x1      0x02118233   # x4 = x3 * x1 = 40 * 8 = 320 
DIV  x9, x8, x1      0x021444b3   # x9 = x8 / x1 = 1 / 8 = 0   (Should wait for `DIV x8, x1, x2`)
MUL  x5, x4, x2      0x022202b3   # x5 = x4 * x2 = 320 * 5 = 1600

## Testcase 5 (Correct! ADD & SUB execution)
ADDI x1, x0, 3       0x00300093   # x1 = 3  
ADDI x2, x0, 7       0x00700113   # x2 = 7
SUB  x3, x1, x2      0x402081b3   # x3 = x1 - x2 = 3 - 7 = -4  
ADDI x6, x0, 6       0x00600313   # x6 = 6 (This one should execute first)
SUB  x4, x3, x2      0x40218233   # x4 = x3 - x2 = -4 - 7 = -11

## Testcase 6 (Correct! Mix of ADD, SUB, MUL, and DIV)
ADDI x1, x0, 10     0x00a00093  # x1 = 10
ADDI x2, x0, 3      0x00300113  # x2 = 3
ADDI x3, x1, 4      0x00408193  # x3 = x1 + 4 = 14  
ADDI x6, x0, 7      0x00700313  # x6 = 7
ADD  x4, x3, x2     0x00218233  # x4 = x3 + x2 = 14 + 3 = 17 
SUB  x5, x4, x1     0x401202b3  # x5 = x4 - x1 = 17 - 10 = 7  
MUL  x7, x3, x2     0x022183b3  # x7 = x3 * x2 = 14 * 3 = 42  
DIV  x8, x7, x1     0x0213c433  # x8 = x7 / x1 = 42 / 10 = 4 
SUB  x9, x5, x6     0x4072c4b3  # x9 = x5 - x6 = 7 - 7 = 0 
MUL  x10, x9, x2    0x02248533  # x10 = x9 * x2 = 0 * 3 = 0 
DIV  x11, x10, x1   0x021545b3  # x11 = x10 / x1 = 0 / 10 = 0  

## Testcase 7 (Correct! Advanced & Most Comprehensive)
ADDI x1, x0, 10      0x00a00093   # x1 = 10
ADDI x2, x0, 4       0x00400113   # x2 = 4
ADDI x3, x0, 100     0x06400193   # x3 = 100
ADD  x4, x2, x3      0x00310233   # x4 = x2 + x3 = 4 + 100 = 104
ADD  x5, x1, x2      0x002082b3   # x5 = x1 + x2 = 10 + 4 = 14
SW   x1, 0(x3)       0x0011a023   # memory[100] = 10
SW   x2, 4(x3)       0x0021a223   # memory[104] = 4
LW   x6, 0(x3)       0x0001a303   # x6 = memory[100] = 10
LW   x7, 4(x3)       0x0041a383   # x7 = memory[104] = 4
ADD  x8, x6, x7      0x00730433   # x8 = x6 + x7 = 10 + 4 = 14
SUB  x9, x8, x2      0x402404b3   # x9 = x8 - x2 = 14 - 4 = 10
MUL  x10, x9, x2     0x02248533   # x10 = x9 * x2 = 10 * 4 = 40
DIV  x11, x10, x2    0x022545b3   # x11 = x10 / x2 = 40 / 4 = 10
MUL  x12, x9, x10    0x02a48633   # x12 = x9 * x10 = 10 * 40 = 400
ADD  x13, x6, x7     0x007306b3   # x13 = x6 + x7 = 10 + 4 = 14
ADDI x14, x0, -5      0xffb00713   # x14 = -5
ADD  x15, x14, x1    0x001707b3   # x15 = x14 + x1 = -5 + 10 = 5
SUB  x16, x14, x2    0x40270833   # x16 = x14 - x2 = -5 - 4 = -9
MUL  x17, x14, x2    0x022708b3   # x17 = x14 * x2 = -5 * 4 = -20
DIV  x18, x17, x2    0x0228c933   # x18 = x17 / x2 = -20 / 4 = -5
