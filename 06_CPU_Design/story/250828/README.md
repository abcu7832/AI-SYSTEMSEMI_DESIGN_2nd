# AMBA APB 설계
- SLAVE 모듈로 RAM 연결
## ControlUnit 변경
```
ready, transfer 신호 추가: APB Master에 어떤 slave 모듈을 활성화시킬지 결정하기 위함.
```
- test ROM 1+2 연산
```assembly
		li		sp,0x10001000
main:
        addi    sp,sp,-32
        sw      ra,28(sp)
        sw      s0,24(sp)
        addi    s0,sp,32
        li      a5,1
        sw      a5,-20(s0)
        li      a5,2
        sw      a5,-24(s0)
        lw      a4,-20(s0)
        lw      a5,-24(s0)
        add     a5,a4,a5
        sw      a5,-28(s0)
        li      a5,0
        mv      a0,a5
        lw      ra,28(sp)
        lw      s0,24(sp)
        addi    sp,sp,32
        jr      ra
```
### RegisterFile 변화 index:15는 a5를 가리킴
![250828_RegFile_](/images/250828_RegFile_.png)
### ControlUnit 수정 후, 상태 변화 과정
![250828_state_trans](/images/250828_state_trans.png)
```
ready신호가 들어온 뒤, S_MEM상태에서 FETCH로 넘어간다.
```
### RAM
![250828_RAM_1plus2](/images/250828_RAM_1plus2.png)
```
1+2 연산 후, 3이 RAM에 store 된 시뮬레이션
```
---
# APB GPO, GPI, GPIO, FND 연결
![250828_MCU](/images/250828_MCU.png)


### APB Master
```
FSM: IDLE -(transfer)> SETUP -(temp_write_reg)> ACCESS -(ready)> IDLE
APB_Mux: mux_sel 값에 따라 RDATA를 결정하고 또한 ready 신호까지 결정
APB_Decoder: pselx, mux_sel을 결정하는 디코더
pselx: 어떤 slave 모듈이 선택되는지 결정하는 select신호
```
### Memory Map
```
0x0000_0000   ROM

------------------
0x1000_0000   RAM

------------------
0x1000_1000   GPO

------------------
0x1000_2000   GPI

------------------
0x1000_3000   GPIO

------------------
0x1000_4000	  FND Controller

------------------
```
### 특이했던점
```systemverilog
    genvar i;
    generate
        for (i = 0; i < $clog2(10_000); i++) begin
            assign number[i] = cr[i] ? odr[i] : 1'bz;
        end
    endgenerate
```
* control register를 활성화시키지 않는다면 high impedance 상태로 바뀌도록 설계됨.
