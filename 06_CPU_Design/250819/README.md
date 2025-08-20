# **RISC-V INSTRUCTION SET 구현**
![RISC_V_INSTRUCTIONSET](/images/RISC_V_INSTRUCTIONSET.png)
## ***B-TYPE***
- `opcode` = `1100011`
---
## 📌 명령어 표
| Mnemonic | funct3 | 조건(참이면 분기) | 비교 종류 |
|---|---|---|---|
| `BEQ  rs1, rs2, imm` | 000 | `rs1 == rs2` | — |
| `BNE  rs1, rs2, imm` | 001 | `rs1 != rs2` | — |
| `BLT  rs1, rs2, imm` | 100 | `rs1 <  rs2` | **signed** |
| `BGE  rs1, rs2, imm` | 101 | `rs1 >= rs2` | **signed** |
| `BLTU rs1, rs2, imm` | 110 | `rs1 <  rs2` | **unsigned** |
| `BGEU rs1, rs2, imm` | 111 | `rs1 >= rs2` | **unsigned** |

## 📌 어셈블리 예시
```riscv
beq  x5, x6, label       # x5 == x6 이면 label로 분기
bne  x5, x6, label       # x5 != x6 이면 분기
blt  x5, x6, label       # signed 비교
bge  x5, x6, label
bltu x5, x6, label       # unsigned 비교
bgeu x5, x6, label
```
---
# HOMEWORK
* ***LU-TYPE, AU-TYPE, J-TYPE, JL-TYPE*** 구현
---

## ***format***
|**U-type** | [31:12] imm[31:12] | [11:7] rd | [6:0] opcode 
|**J-type(JAL)**|[31] imm[20] | [30:21] imm[10:1] | [20] imm[11] | [19:12] imm[19:12] | [11:7] rd | [6:0] opcode
|**JALR**| [31:20] imm[11:0] | [19:15] rs1 | [14:12] funct3=000 | [11:7] rd | [6:0] opcode=1100111

## 📦 U-type (Upper Immediate)
- `LUI rd, imm` → `rd = imm << 12`  
- `AUIPC rd, imm` → `rd = PC + (imm << 12)`  

### 명령어 표
| Mnemonic | opcode  | 동작(의사코드) | 설명 |
|---|---|---|---|
| `LUI rd, imm`   | 0110111 | `rd = imm << 12` | 상위 20비트 즉시값 로드 |
| `AUIPC rd, imm` | 0010111 | `rd = PC + (imm << 12)` | PC 상대 상위 즉시값 더하기 |

## 📦 J-type (Upper Immediate)
- `JAL rd, imm` → `rd = PC+4; PC = PC + signext(imm)`

### 명령어 표
| Mnemonic | opcode  | 동작(의사코드) | 설명 |
|---|---|---|---|
| `jal x1, imm`   | 0110111 | `x1=return addr, PC=imm` |
| `jal x0, imm`   | 0010111 | `return addr 저장 안 함, 무조건 점프` |

## 📦 JALR-type (Upper Immediate)
- `JALR rd, rs1, imm` → r`d = PC+4; PC = target`

### 명령어 표
| Mnemonic | opcode  | 동작(의사코드) | 설명 |
|---|---|---|---|
| `jalr x1, x5, 0`   | 0110111 | `x1=return addr, PC=(x5+0)&~1` |
| `jalr x0, x5, 4`   | 0010111 | `return addr 저장 안 함, PC=(x5+4)&~1` |

## 📌 어셈블리 예시
```riscv
lui   x5, 0x12345      # x5 = 0x12345000
auipc x6, 0x10         # x6 = PC + 0x10000
jal x1, label      # x1=return addr, PC=label
jal x0, label      # return addr 저장 안 함, 무조건 점프
jalr x1, x5, 0         # x1 = return addr, PC = (x5 + 0) & ~1
jalr x0, x5, 4         # return addr 무시, PC = (x5 + 4) & ~1
```
