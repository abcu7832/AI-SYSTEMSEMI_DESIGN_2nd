### 250807 class note

## 조합회로(Combinational circuit) 순차회로(Sequential Circuit) 비교
| 구분 | 조합회로 (Combinational Circuit) | 순차회로 (Sequential Circuit) |
|------|-----------------------------------|--------------------------------|
| **출력 결정 방식** | 현재 입력 값만으로 출력이 결정됨 | 현재 입력 값 + 이전 상태(메모리)에 의해 출력이 결정됨 |
| **기억 소자** | 없음 | 있음 (플립플롭, 래치 등) |
| **동작 예시** | 논리게이트 | 레지스터, 카운터, 상태머신(FSM) |
| **시간 요소** | X | clk |
| **출력 변화 시점** | 입력 변화 시 즉시 변경 | 클럭 신호에 동기되어 변경 (동기식) 또는 조건 발생 시 변경 (비동기식) |
| **설계 난이도** | 비교적 단순 | 상대적으로 복잡 |
| **응용 분야** | 단순 데이터 처리, 연산 | 데이터 저장, 순서 제어, 상태 기반 동작 |

---
# Latch - Flip Flop

## 개념
- **Latch**와 **Flip-Flop**은 출력 상태를 유지할 수 있는 **메모리 기능**을 가짐
- 기본 구조: 출력의 피드백을 이용하여 이전 상태를 저장

## 1. 초기 Latch
* 기본 인버터 피드백 형태
- 출력이 다시 입력으로 연결되어 상태를 유지

<p align="center">
  <img src="/images/250806_5.png" alt="Inverter Latch Diagram" width="200">
</p>

## 2. SR Latch
* NOR 게이트 기반 SR Latch





<p align="center">
  <img src="/images/250806_4.png" alt="SR Latch Diagram" width="400">
</p>
```
두 개의 NOR 게이트를 교차 연결하여 구성
```
* 진리표



| R (Reset) | S (Set) | Q   | Q̅  | 동작 |
|-----------|---------|-----|-----|------|
| 0         | 0       | 유지 | 유지 | 현재 상태 유지 |
| 0         | 1       | 1   | 0   | Set (Q=1) |
| 1         | 0       | 0   | 1   | Reset (Q=0) |
| 1         | 1       | 0   | 0   | **발진 → 금지 상태** |
* 요약
```
SR Latch는 입력 R, S에 따라 Q 출력이 결정되고 상태를 유지
`R=1, S=1` 상태는 사용하지 않음 (발진 위험)  cf) R=1, S=1에서 R=0, S=0으로 바뀔 때 문제가 됨.
순차회로 설계의 기본 요소로, 플립플롭의 기초가 됨
```
---
## 3. D Latch
- **D (Data) Latch**는 SR Latch의 변형으로, 입력 D 값을 그대로 출력 Q에 저장
- D 입력이 1이면 Q=1, D 입력이 0이면 Q=0
- SR Latch의 **R=~D, S=D**로 구성하여 `R=1, S=1`의 금지 상태를 방지
<p align="center">
  <img src="/images/250806_6.png" alt="Inverter Latch Diagram" width="400">
</p>



### 3-1. Gated D Latch
- **Gate(Enable)** 신호를 추가하여, Gate가 1일 때만 입력 D가 출력 Q로 전달
- Gate가 0이면 현재 Q 상태를 유지
- level sensitive 동작: Gate=1 상태 동안 D 값이 변하면 Q도 변함
<p align="center">
  <img src="/images/250806_7.png" alt="Inverter Latch Diagram" width="400">
</p>



* 진리표


| En | D | Q (출력) | Q̅ | 동작 |
|------|---|----------|----|------|
| 0    | X | 유지     | 유지 | 현재 상태 유지 |
| 1    | 0 | 0        | 1  | Reset |
| 1    | 1 | 1        | 0  | Set |
* 요약
```
- D Latch: SR Latch의 입력을 단일 데이터 입력 D로 단순화
- Gated D Latch: Enable 신호로 데이터 입력 시점을 제어
- 동기식 회로에서 데이터 저장, 레지스터 구성 등에 사용
```
## 4. Master-Slave D F/F
- **Master Latch**: 클럭 신호가 **High**일 때 입력 `D` 값을 받아 저장.
- **Slave Latch**: 클럭 신호가 **Low**일 때 Master의 출력을 받아 최종 출력 `Q`로 전달.
- 결과적으로, 입력 데이터는 클럭의 **상승 에지**에서만 출력에 반영.
- Master-Slave 조합은 일반적인 **엣지 트리거 D 플립플롭**과 동일하게 동작.(synchronizer)
<p align="center">
  <img src="/images/250806_8.png" alt="D F/F from D latch x2" width="400">
</p>
* 특징
- 클럭 상승 에지에서만 데이터가 출력 Q로 반영됨.
- 글리치(glitch) 방지에 유리. cf) glitch: 의도하지 않은 짧은 신호 변화
- 레벨 민감형 래치를 조합하여 엣지 트리거 동작을 구현.
