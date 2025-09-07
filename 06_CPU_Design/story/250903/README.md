## SystemVerilog 검증
### RAM Episode
![250903_ram](/images/250903_RAM_DuT.png)
![250903_testbench](/images/250903_testbench.png)

* Testbench scenario
```
monitor에서 보낸 결과와 비교해서 같으면 Pass, 다르면 Fail
```
![250903_tcl](/images/250903_tcl2.png)

-----------------------------------
### FndControl Peripheral
![250903_FndControl_pheriph](/images/250903_FndControl_pheriph.png)


* Memory Map



![250903_Memory_Map](/images/250903_Memory_Map.png)

### 검증

* ***Test Scenario***
```
count -> delay -> count -> ... -> ..
```

<details>
  <summary>🧩 C: TEST CODE (클릭해 펼치기)</summary>
  
```c
#include<stdint.h>

typedef struct {
    uint32_t CR;
    uint32_t ODR;
} FND_TypeDef;

#define APB_BASE    0x10000000
/*
#define GPO_BASE    (APB_BASE + 0x1000)
#define GPO_CR      (*(uint32_t *)(GPO_BASE + 0x00))
#define GPO_ODR     (*(uint32_t *)(GPO_BASE + 0x04))

#define GPI_BASE    (APB_BASE + 0x2000)
#define GPI_CR      (*(uint32_t *)(GPI_BASE + 0x00))
#define GPI_IDR     (*(uint32_t *)(GPI_BASE + 0x04))

#define GPIO_BASE   (APB_BASE + 0x3000)
#define GPIO_CR     (*(uint32_t *)(GPIO_BASE + 0x00))
#define GPIO_IDR    (*(uint32_t *)(GPIO_BASE + 0x04))
#define GPIO_ODR    (*(uint32_t *)(GPIO_BASE + 0x08))
*/
#define FND_BASE    (APB_BASE + 0x4000)
//#define FND_CR      *(uint32_t *)(FND_BASE + 0x00)
//#define FND_ODR     *(uint32_t *)(FND_BASE + 0x04)  
#define FND         ((FND_TypeDef *)(FND_BASE))

void FND_Init(FND_TypeDef *fnd);
void FND_WriteData(FND_TypeDef *fnd, uint32_t data);
void delay(uint32_t t);

int main()
{
    // FND_CR = 0x01;
    // FND_ODR = 1234;

    FND_Init(FND);
    //FND->CR = 0x01;

    uint32_t data = 0;
    uint32_t fnd_count = 0;  // FND 카운터 추가

    while (1)
    {
        FND_WriteData(FND, data);
        data++;
        delay(1000);
    }

    return 0;
}

void FND_Init(FND_TypeDef *fnd) {
    fnd->CR = 0x01;
}

void FND_WriteData(FND_TypeDef *fnd, uint32_t data) {
    fnd->ODR = data;
}

void delay(uint32_t t)
{
    for(uint32_t i=0;i<t;i++){
        for(uint32_t j=0;j<1000;j++);
    }
}
```
</details>
