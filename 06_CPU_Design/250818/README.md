## **RISC-V INSTRUCTION SET 구현**
![RISC_V_INSTRUCTIONSET](/images/RISC_V_INSTRUCTIONSET.png)
### L-TYPE, I-TYPE, S-TYPE 
- `opcode` = `0000011`
- 주소 계산: `addr = rs1 + signext(imm[11:0])`
- 결과 저장: `rd <= 메모리에서 읽은 값 (확장 규칙 적용)`

### 명령어 표
| Mnemonic | funct3 | 동작(의사코드) | 비고 |
|---|---|---|---|
| `LB`  | 000 | `rd = signext( M8[addr] )`  | 8비트 로드, 부호 확장 |
| `LH`  | 001 | `rd = signext( M16[addr] )` | 16비트 로드, 부호 확장 |
| `LW`  | 010 | `rd = M32[addr]`            | 32비트 로드 |
| `LBU` | 100 | `rd = zeroext( M8[addr] )`  | 8비트 로드, 0 확장 |
| `LHU` | 101 | `rd = zeroext( M16[addr] )` | 16비트 로드, 0 확장 |

### 어셈블리 예시
```riscv
lb   x7, 0(x5)     # x7 = signext( M8[x5 + 0] )
lbu  x7, 8(x5)     # x7 = zeroext( M8[x5 + 8] )
lh   x7, 4(x5)     # x7 = signext( M16[x5 + 4] )
lhu  x7, 6(x5)     # x7 = zeroext( M16[x5 + 6] )
lw   x7, 12(x5)    # x7 = M32[x5 + 12]
```
