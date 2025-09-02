## 250902 수업내용

### Verilog vs SystemVerilog
| Signal     | Verilog     | SystemVerilog |
|------------|------------|-------------|
| **OOP(객체지향)**   |      X(class X)    |        O(class 문법 제공)                |
| **DataType**        | H/W 중심의 DataType | S/W 중심의 DataType(S/W기능 추가)        |
| **interface**       |           X         | O(S/W와 H/W를 연결하는 케이블 같은 느낌) |
| **randomization**   | randome(제한적기능) | 각 변수에 randome 생성과 contraint 기능(corner case 생성)  |

### SystemVerilog DataType
| 종류 | 설명 |
| ---- | ---- |
| 4-state(벡터) | 0,1,x,z logic,reg,wire |
| 2-state(벡터) | 0,1 bit |
| 4-state(정수) | integer(32-bit) |
| 2-state(정수) | byte(8-bit), shortint(16-bit), int(32-bit), longint(64-bit) |

### 배열
* 고정 길이 배열 (fixed-size array, static array): compile할때 크기 결정됨(runtime일때 배열크기 변경 불가).
```
  bit arr[8] -> 8-bit
  byte arr2[4] -> 8*4-bit
  int arr3[16] -> 32*16-bit
```
* 동적 배열 (dynamic array) like malloc (C): runtime일때 크기 결정됨(runtime일때 배열크기 변경 가능).
```
ex)
bit arr[]; arr = new[8]; -> bit arr[8];
byte arr2[]; arr2 = new[4]; -> byte arr2[4];
int arr3[]; arr3 = new[16]; -> int arr3[16];
```
