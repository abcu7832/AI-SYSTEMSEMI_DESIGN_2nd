### 250808 class note

## UART vs I2C vs SPI 비교
<p align="center">
  <img src="/images/250808_1.png" alt="통신" width="1000">
</p>



| 구분         | UART         | I2C          | SPI          |
|--------------|--------------|--------------|--------------|
| **동기/비동기** | 비동기       | 동기         | 동기         |
| **관계 수**   | 1:1          | 1:N          | 1:N          |
| **선 수**     | 2 (TX, RX)  | 2 (SDA, SCL) | 4 (SCK, MISO, MOSI, SS) |
| **이중통신**  | full       | half       | full       |
| **전송 거리** | long           | shorter than UART | shorter than UART |
| **전송 속도** | slow         | slower than SPI  | fast        |



## UART
<p align="center">
  <img src="/images/250808_2.png" alt="UART" width="1000">
</p>

```
- UART: clk이 연결되어있지 않는 비동기 통신 방식
- 대신 내부 시간으로 신호를 처리(baudrate)
- Frame단위: 1byte(START state부터 STOP state까지)
```
* error를 줄이기 위한 방법: sampling
```
baud tick이 16번 들어오는 동안 중간시점에서 data를 read
```
* RTL 구현
```
baudrate 생성 방법:
count: 0 ~ System_Frequency/Baudrate/sampling - 1

receiver: rx
transmitter: tx
- rx
input: rx(1bit value), baud_tick
output: done, rx_data(8bit value)
- tx
input: start, tx(8bit value), baud_tick
output: done, busy, tx(1bit value)
```
