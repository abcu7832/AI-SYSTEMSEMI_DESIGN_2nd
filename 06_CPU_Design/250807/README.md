### ***Review duration***
* button debounce using shift register

### HOMEWORK
```
********************FSM******************
start → Stop
Stop → run (run_stop 버튼)
run → Stop (run_stop 버튼)
Stop → clear (clear 버튼)
clear → Stop

*****************************************
button 3개

run_stop 버튼
clear 버튼
mode 버튼

*****************************************
mode = 0 → up counting
mode = 1 → down counting

LED에 mode 상태 출력

up counter: led0(ON), led1(OFF)
down counter: led0(OFF), led1(ON)

상태별 LED 출력

Stop: led2(ON), led3(OFF)
Run: led2(OFF), led3(ON)
```
