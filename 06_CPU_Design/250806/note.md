### 250806 class note
FPGA board: Basys 3 (교육용 보드) based on Artix-7 FPGA, Xilinx(AMD)

## Basys 3 주요 특징

### 1. FPGA 칩
- **Xilinx Artix-7 XC7A35T-1CPG236C**
- 33,280 Logic Cells  
- 90 DSP Slices  
- 1,800 Kbits Block RAM  

### 2. 클럭
- **100 MHz** 온보드 크리스털 오실레이터  
- 추가로 외부 클럭 입력 가능  

### 3. 전원
- **Micro-USB 케이블** (PC 연결 시 전원 공급)  
- 외부 전원 공급 가능  

## Basys 3 입출력 구성 요소

| 구성 요소         | 수량  | 설명 |
|------------------|-------|------|
| 스위치(SW)       | 16개  | 슬라이드 타입, 이진 입력 실습 가능 |
| 푸시 버튼(BTN)   | 5개   | 4방향 + 중앙(센터) 버튼 |
| LED              | 16개  | 일반 LED 출력 |
| RGB LED          | 4개   | 각 LED당 3채널 제어 가능 |
| ***7-segment***       | 4자리 | 공통 애노드 방식, 시프트 레지스터 없이 직접 제어 |
| VGA 포트         | 1개   | 12-bit 컬러 출력(각 색 4bit) |
| USB-UART         | 1개   | PC와 시리얼 통신 |
| Pmod 포트        | 4개   | 추가 모듈 연결 가능(Pmod 센서, 모터, 디스플레이 등) |
| 오디오 잭        | 1개   | PWM 오디오 출력 가능 |

cf) FND = 7-segment


## FND Schematic
![Basys 3 FND Schematic](/images/250806_1.png)



-> 하드웨어 특성상 한꺼번에 각 자리의 값을 출력할 수 없음.



![Basys 3 FND Schematic](/images/250806_2.png)



-> Cathode 방식으로 1을 주면 OFF, 0을 주면 ON cf) Cathode <-> Anode



![Basys 3 FND Schematic](/images/250806_3.png)



-> 위의 하드웨어 특성을 극복하기 위해 어떤 자리를 출력시킬것인지 제어하기 위해 필요한 타이밍 다이어그램
## Basys 3 FND control module
* clock divider
```
1ms마다 FND 출력 자릿수 결정
system clock = 100Mhz
1ms = 1kHz ===> 100_000 counter 필요
```
* counter_2bit
```
4 count
```
* digitSplitter
```
1의 자리, 10의 자리, 100의 자리, 1000의 자리
FND에서 출력할 각 자릿수를 결정
```
* 4x1 MUX
```
counter_2bit의 값을 select신호로 하여 FND에 출력할 자리를 결정
```
* BCD to FND decoder
```
FND의 Schematic에 따른 0부터 9까지의 형식
```
