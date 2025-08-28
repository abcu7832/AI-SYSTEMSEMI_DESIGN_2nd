#include<stdint.h>
#define APB_BASE    0x10000000
#define GPO_BASE    (APB_BASE + 0x1000)
#define GPO_CR      *(uint32_t *)(GPO_BASE + 0x00)
#define GPO_ODR     *(uint32_t *)(GPO_BASE + 0x04)
#define GPI_BASE    (APB_BASE + 0x2000)
#define GPI_CR      *(uint32_t *)(GPI_BASE + 0x00)
#define GPI_IDR     *(uint32_t *)(GPI_BASE + 0x04)
#define GPIO_BASE    (APB_BASE + 0x3000)
#define GPIO_CR      *(uint32_t *)(GPIO_BASE + 0x00)
#define GPIO_IDR     *(uint32_t *)(GPIO_BASE + 0x04)
#define GPIO_ODR     *(uint32_t *)(GPIO_BASE + 0x08)
#define FND_BASE    (APB_BASE + 0x4000)
#define FND_CR      *(uint32_t *)(FND_BASE + 0x00)
#define FND_ODR     *(uint32_t *)(FND_BASE + 0x04)  

void delay(uint32_t t);

int main()
{
    enum {LEFT, RIGHT};

    uint32_t data = 1;
    uint32_t fnd_count = 0;  // FND 카운터 추가

    GPO_CR = 0xff;
    GPI_CR = 0xff;
    GPIO_CR |= 0x0f;
    GPIO_CR &= ~(0x0f<<4);
    
    // FND 초기화
    FND_CR = 0x3FFF;  // 14비트 모두 활성화
    FND_ODR = fnd_count;  // 초기값 1 설정

    uint32_t state = LEFT;

    while (1)
    {
        switch(state)
        {
            case LEFT:
                data = (data >> 7) | (data << 1);
                if(GPIO_IDR & (1<<5)) state = RIGHT;
                break;
            case RIGHT:
                data = (data << 7) | (data >> 1);
                if(GPIO_IDR & (1<<6)) state = LEFT;
                break;
        }
        GPO_ODR = data;
        //data = GPI_IDR;
        GPIO_ODR = GPIO_IDR >>4;
        
        // FND 카운터 업데이트
        fnd_count++;
        if(fnd_count > 9999) fnd_count = 0;  // 9999 초과시 1로 리셋
        FND_ODR = fnd_count;
        
        delay(1000);
    }

    return 0;
}

void delay(uint32_t t)
{
    for(uint32_t i=0;i<t;i++){
        for(uint32_t j=0;j<1000;j++);
    }
}
