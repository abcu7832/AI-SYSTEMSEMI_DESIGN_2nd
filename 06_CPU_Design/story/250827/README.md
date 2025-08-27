# CPU APB  

## AMBA APB (Advanced Peripheral Bus) Protocol

### 📌 Overview
- **APB**는 AMBA(Advanced Microcontroller Bus Architecture)의 일부로,  
  **저전력, 저비용, 단순성**에 최적화된 버스 프로토콜임.  
- **비파이프라인(non-pipelined)**, **동기식(synchronous)** 구조.  
- 모든 전송은 최소 2 클럭 이상 소요됨.  
- 주로 **주변장치(Peripheral Device) 제어 레지스터 접근**에 사용.  
- AXI/AHB와 연결 시 **APB Bridge**를 통해 연결됨.  

---

### 🔑 Key Concepts
- **Requester (APB Bridge)**: 전송을 요청하는 주체.  
- **Completer (Peripheral)**: 요청을 받아 응답하는 주체.  

---

### 📡 Signals
주요 APB 인터페이스 신호:

| Signal     | Source     | Description |
|------------|------------|-------------|
| **PCLK**   | Clock      | APB 클럭, rising edge 기준 |
| **PRESETn**| System Reset | Active-LOW 리셋 신호 |
| **PADDR**  | Requester  | 주소 버스 (최대 32bit) |
| **PWRITE** | Requester  | HIGH = Write, LOW = Read |
| **PWDATA** | Requester  | Write 데이터 (8/16/32bit) |
| **PRDATA** | Completer  | Read 데이터 (8/16/32bit) |
| **PSELx**  | Requester  | 특정 Peripheral 선택 |
| **PENABLE**| Requester  | Access Phase 활성화 |
| **PREADY** | Completer  | 전송 완료 여부 표시 |
| **PSLVERR**| Completer  | 전송 오류 표시 |
| **PSTRB**  | Requester  | Byte 단위 Write strobe |
| **PPROT**  | Requester  | Access 보호 속성 (Normal/Privileged, Secure/Non-secure, Data/Instruction) |

---

### 🔄 FSM
![FSM](/images/250827_FSM.png)

---

### 🔄 Transfer Types
1. **Write Transfer**
   - **Setup phase**: `PSEL=1`, 주소와 데이터 유효.  
   - **Access phase**: `PENABLE=1`, `PREADY=1` 시 완료.  

2. **Read Transfer**
   - Write와 동일한 순서, 다만 `PRDATA`를 Completer가 반환.  
   - `PREADY`로 대기 상태(Wait states) 삽입 가능.  

3. **Error Response**
   - `PSLVERR=1`일 때 에러 발생.  
   - 읽기/쓰기 모두 에러 가능, 데이터는 무효일 수 있음.  

---

### ⚙️ Operating States
APB는 단순한 **3상태 FSM**으로 동작:

1. **IDLE**: 기본 상태 (`PSEL=0`)  
2. **SETUP**: 전송 시작 (`PSEL=1, PENABLE=0`)  
3. **ACCESS**: 실제 전송 진행 (`PENABLE=1`)  
   - `PREADY=0` → ACCESS 유지  
   - `PREADY=1` → 다음 SETUP 또는 IDLE로 전환  

---

### ✅ Summary
- APB는 **저속 주변장치 제어에 최적화된 단순 버스**.  
- 모든 전송은 최소 2 클럭 이상 필요하며, 비파이프라인 구조.  
- AXI/AHB 고속 버스와 주변장치를 연결하는 데 사용.  
- 버전이 올라가면서 **오류 처리, 보호 속성, 저전력 기능** 강화됨.  

---

## Memory Map (메모리 맵)

### 🏗️ 구조
- **주소 공간(Address Space)**: CPU가 인식할 수 있는 전체 주소 범위 (예: 32-bit CPU → 4GB).  
- 이 주소 공간을 **영역별로 분리**하여 메모리, 주변장치, 레지스터 등을 배치.  
- 하드웨어 설계 시 **주소 디코더(Decoder)**가 특정 주소 범위에 어떤 장치가 연결될지 결정.  

---

### 📡 특징
- **일원화된 접근 방식**  
  CPU는 메모리 읽기/쓰기를 하듯이 I/O 장치에도 접근 가능.  

- **하드웨어-소프트웨어 인터페이스**  
  펌웨어/드라이버 개발 시, 특정 레지스터를 접근하기 위한 **주소 기반 프로그래밍** 가능.  

- **확장성**  
  새로운 장치를 추가할 때 특정 주소 영역을 할당하면 쉽게 확장 가능.  

---

### 🗂️ 예시 (32-bit Address Space)
| 주소 범위 (Hex)             | 할당 대상                  | 설명                        |
|-----------------------------|---------------------------|-----------------------------|
| `0x0000_0000 ~ 0x0FFF_FFFF` | Main Memory (DDR, SRAM)   | 프로그램/데이터 저장 |
| `0x1000_0000 ~ 0x1FFF_FFFF` | ROM / Flash               | 부트로더, 펌웨어 저장 |
| `0x2000_0000 ~ 0x20FF_FFFF` | Peripheral (UART, GPIO)   | 주변장치 제어 레지스터 |
| `0x3000_0000 ~ 0x30FF_FFFF` | Timer / Interrupt Ctrl    | 타이머 및 인터럽트 제어 |
| `0xFFFF_0000 ~ 0xFFFF_FFFF` | System Control / Debug    | 시스템 제어, 디버그 영역 |

---

### ✅ Summary
- **Memory Map = 주소와 장치/메모리 대응표**  
- CPU는 동일한 방식으로 **메모리, I/O, 레지스터**에 접근 가능.  
- 하드웨어 설계 단계에서 **주소 범위 할당**이 매우 중요.  
- 소프트웨어 개발 시 **레지스터 접근 코드**로 장치를 제어 가능.  
