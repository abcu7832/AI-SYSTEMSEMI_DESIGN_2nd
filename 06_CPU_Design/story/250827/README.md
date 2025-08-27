# CPU APB 

# About the APB protocol
![TIMING_DIAGRAM](/images/250827_TIMING_DIAGRAM.png)
![FSM](/images/250827_FSM.png)
## Overview
- **APB**는 **저전력, 저비용**에 최적화된 단순 버스 프로토콜.
- 인터페이스 복잡성을 줄이고, **minimal power consumption**을 목표로 설계됨.
- **Non-pipelined**, **simple**, **synchronous protocol** → 전송에 최소 2 클럭 이상 소요.

## Purpose
- **주변장치(Peripheral Device)**의 **제어 레지스터 접근**에 사용.
- 메인 메모리 시스템과는 보통 **APB Bridge**를 통해 연결됨.
  - 예: AXI → APB 브리지
 
## Characteristics
- 비파이프라인 구조 → 단순하고 저속 주변장치에 적합
- 주로 **UART, GPIO, Timer, SPI, I²C** 같은 저속 장치 제어용

## Transfer Model
- **APB Bridge**가 요청을 시작 (**Requester**)
- 주변장치가 응답 (**Completer**)

## Key Points
- 단순하고 동기식 구조
- 저속 주변장치 전용
- AXI/AHB와 같은 고속 버스와 연결 시 **Bridge** 사용
- 전송마다 최소 2 클럭 필요

## Memory map
