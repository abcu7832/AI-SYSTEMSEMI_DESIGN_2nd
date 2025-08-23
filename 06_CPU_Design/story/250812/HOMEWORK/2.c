#include<stdio.h>

int main(){
  R1 = 1;
  R2 = 0;
  R3 = 0;
  R4 = 0;
  
  while (1) {
      R2 = R1 + R1;
      R3 = R2 + R1;
      R4 = R3 - R1;
      R1 = R1 | R2;
  
      if (R4 < R2) {
          R4 = R4 & R3;
          R4 = R2 + R3;
      }
  
      if (R4 > R2) {
          break; // halt
      }
  }
  return 0;
}
