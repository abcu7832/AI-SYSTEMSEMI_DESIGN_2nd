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
| **이중통신**  | full duplex       | half duplex       | full duplex       |
| **전송 거리** | long           | shorter than UART | shorter than UART |
| **전송 속도** | slow         | slower than SPI  | fast        |
