# CPU APB 

# AMBA APB (Advanced Peripheral Bus) Protocol

## 📌 Overview
- **APB**는 AMBA(Advanced Microcontroller Bus Architecture)의 일부로,
  **저전력, 저비용, 단순성**에 최적화된 버스 프로토콜임:contentReference[oaicite:0]{index=0}.
- **비파이프라인(non-pipelined)**, **동기식(synchronous)** 구조.
- 모든 전송은 최소 2 클럭 이상 소요:contentReference[oaicite:1]{index=1}.
- 주로 **주변장치(Peripheral Device) 제어 레지스터 접근**에 사용.
- AXI/AHB와 연결 시 **APB Bridge**를 통해 연결:contentReference[oaicite:2]{index=2}.

---

## 🔑 Key Concepts
- **Requester (APB Bridge)**: 전송을 요청하는 쪽.
- **Completer (Peripheral)**: 요청을 받아 응답하는 쪽:contentReference[oaicite:3]{index=3}.

---

## 📡 Signals
주요 APB 인터페이스 신호들:contentReference[oaicite:4]{index=4}:

| Signal   | Source     | Description |
|----------|------------|-------------|
| **PCLK** | Clock      | APB 클럭, rising edge 기준 |
| **PRESETn** | System Reset | Active-LOW 리셋 신호 |
| **PADDR** | Requester | 주소 버스 (최대 32bit) |
| **PWRITE** | Requester | HIGH = Write, LOW = Read |
| **PWDATA** | Requester | Write 데이터 (8/16/32bit) |
| **PRDATA** | Completer | Read 데이터 (8/16/32bit) |
| **PSELx** | Requester | 특정 Peripheral 선택 |
| **PENABLE** | Requester | Access Phase 활성화 |
| **PREADY** | Completer | 전송 완료 여부 표시 |
| **PSLVERR** | Completer | 전송 오류 표시 |
| **PSTRB** | Requester | Byte 단위 Write strobe |
| **PPROT** | Requester | Access 보호 속성 (Normal/Privileged, Secure/Non-secure, Data/Instruction) |

---

### FSM
![FSM](/images/250827_FSM.png)

## 🔄 Transfer Types
### 1. Write Transfer
- **Setup phase**: `PSEL=1`, 주소와 데이터 유효.
- **Access phase**: `PENABLE=1`, `PREADY=1` 시 완료:contentReference[oaicite:5]{index=5}.

### 2. Read Transfer
- Write와 동일한 순서, 다만 `PRDATA`를 Completer가 반환.
- `PREADY`로 대기 상태(Wait states) 삽입 가능:contentReference[oaicite:6]{index=6}.

### 3. Error Response
- `PSLVERR=1`일 때 에러 발생.
- 읽기/쓰기 모두 에러 가능. 데이터 무효일 수 있음:contentReference[oaicite:7]{index=7}.

---

## ⚙️ Operating States
APB는 단순한 **3상태 FSM**으로 동작:contentReference[oaicite:8]{index=8}:

1. **IDLE**: 기본 상태 (`PSEL=0`).
2. **SETUP**: 전송 시작 (`PSEL=1, PENABLE=0`).
3. **ACCESS**: 실제 전송 진행 (`PENABLE=1`), `PREADY`에 따라 IDLE 또는 다음 SETUP으로 전환.

---

## 🔒 Additional Features (APB4/5 확장)
- **APB3**: `PREADY`, `PSLVERR` 추가.
- **APB4**: `PPROT`, `PSTRB` (보호/희소 전송).
- **APB5**: `PWAKEUP` (Wake-up), User Signal, Parity Check 추가:contentReference[oaicite:9]{index=9}.

---

## ✅ Summary
- APB는 **저속 주변장치 제어에 최적화된 단순 버스**.
- 모든 전송은 최소 2 클럭, 비파이프라인 구조.
- AXI/AHB 고속 버스와 주변장치를 연결하는 데 사용.
- 버전이 올라가면서 **오류 처리, 보호 속성, 저전력 기능**이 강화됨.

## Memory map
