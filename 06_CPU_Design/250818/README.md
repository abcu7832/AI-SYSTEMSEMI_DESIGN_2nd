## **RISC-V INSTRUCTION SET 구현**
![RISC_V_INSTRUCTIONSET](/images/RISC_V_INSTRUCTIONSET.png)
### ***L-TYPE, I-TYPE, S-TYPE***
- `opcode` = `0000011`
- 주소 계산: `addr = rs1 + signext(imm[11:0])`
- 결과 저장: `rd <= 메모리에서 읽은 값 (확장 규칙 적용)`

### 명령어 표
| Mnemonic | funct3 |               Operation               |               Note              |
| :------: | :----: | :-----------------------------------: | :-----------------------------: |
|  **LB**  |   000  |        rd = M$rs1 + imm$\[0:7]        |  Load 8-bit with sign extension |
|  **LH**  |   001  |        rd = M$rs1 + imm$\[0:15]       | Load 16-bit with sign extension |
|  **LW**  |   010  |           rd = M$rs1 + imm$           |           Load 32-bit           |
|  **LBU** |   100  |  rd = zero-extend(M$rs1 + imm$\[0:7]) |  Load 8-bit with zero extension |
|  **LHU** |   101  | rd = zero-extend(M$rs1 + imm$\[0:15]) | Load 16-bit with zero extension |

|  Mnemonic | funct3 |         Operation        |                Note                |
| :-------: | :----: | :----------------------: | :--------------------------------: |
|  **ADDI** |   000  |      rd = rs1 + imm      |            Add immediate           |
|  **SLTI** |   010  | rd = (rs1 < imm) ? 1 : 0 |  Set less than immediate (signed)  |
| **SLTIU** |   011  | rd = (rs1 < imm) ? 1 : 0 | Set less than immediate (unsigned) |
|  **XORI** |   100  |      rd = rs1 ^ imm      |            XOR immediate           |
|  **ORI**  |   110  |      rd = rs1 \| imm     |            OR immediate            |
|  **ANDI** |   111  |      rd = rs1 & imm      |            AND immediate           |
|  **SLLI** |   001  |     rd = rs1 << shamt    |    Shift left logical immediate    |
|  **SRLI** |   101  |     rd = rs1 >> shamt    |    Shift right logical immediate   |
|  **SRAI** |   101  |    rd = rs1 >>> shamt    |  Shift right arithmetic immediate  |

| Mnemonic | funct3 |             Operation             |     Note     |
| :------: | :----: | :-------------------------------: | :----------: |
|  **SB**  |   000  |  M$rs1 + imm$\[0:7]   = rs2\[0:7] |  Store 8-bit |
|  **SH**  |   001  | M$rs1 + imm$\[0:15]  = rs2\[0:15] | Store 16-bit |
|  **SW**  |   010  |     M$rs1 + imm$\[0:31]  = rs2    | Store 32-bit |

### 어셈블리 예시
```riscv
lb   x7, 0(x5)     # x7 = signext( M8[x5 + 0] )
lbu  x7, 8(x5)     # x7 = zeroext( M8[x5 + 8] )
lh   x7, 4(x5)     # x7 = signext( M16[x5 + 4] )
lhu  x7, 6(x5)     # x7 = zeroext( M16[x5 + 6] )
lw   x7, 12(x5)    # x7 = M32[x5 + 12]
```
