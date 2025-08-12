### CPU practice
* RegisterFile (Address)

### HOMEWORK
1. Dedicated Processor: 0~9 count + ADD => 구조 변경(Register => RegisterFile, address 제어)
ex) 0 + 1(0+1) + 2(1+1) + 3(2+1) + ... + 10(9+1) = 55
2. Operation(FSM) Simulation
---
## 요구사항 1

1. **C언어 구현**
   - `while` 문을 이용하여 0부터 10까지의 합을 계산하는 프로그램 작성.

2. **Data Path 구조 설계**
   - 누적 합산을 위한 데이터 경로(Data Path) 구성.

3. **Control Unit 설계**
   - 연산의 순서를 ASM(Algorithmic State Machine) Chart로 작성.
   - ASM Chart를 기반으로 Control Unit 설계.

4. **Top Level**
   - 전체 시스템을 통합하여 동작 확인.
   - **코드**, **시뮬레이션**, **동작 영상**을 Classroom에 업로드.
---
## 요구사항 2

1. **C언어 구현**
   - 주어진 연산을 처리하시오.

2. **Data Path 구조 설계**
   - 누적 합산을 위한 데이터 경로(Data Path) 구성.

3. **Control Unit 설계**
   - 연산의 순서를 ASM(Algorithmic State Machine) Chart로 작성.
   - ASM Chart를 기반으로 Control Unit 설계.

4. **Top Level**
   - 전체 시스템을 통합하여 동작 확인.
   - **코드**, **시뮬레이션**을 Classroom에 업로드.
  
# 알고리즘 흐름 정리

### 📌 초기값
- R1 = 1
- R2 = 0
- R3 = 0
- R4 = 0

---

### 🔹 알고리즘 단계

1. `R2 = R1 + R1`
2. `R3 = R2 + R1`
3. `R4 = R3 - R1`
4. `R1 = R1 | R2`  <!-- 비트 OR 연산 -->
5. **조건 검사:** `R4 < R2`  
   - **Yes** → 6단계 진행  
   - **No** → 8단계 진행
6. `R4 = R4 & R3`  <!-- 비트 AND 연산 -->
7. `R4 = R2 + R3`
8. **조건 검사:** `R4 > R2`  
   - **No** → 1단계로 반복  
   - **Yes** → `halt` (종료)

---

## 제출물
- Systemverilog 코드(1, 2)
- 시뮬레이션 결과(1, 2)
- 동작 영상(FND 출력)(1)
