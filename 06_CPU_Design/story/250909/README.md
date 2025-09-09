# 강의내용

### VGA ColorBar + Switch VGA 

![250909_VGA_CB_SW](/images/250909_VGA_CB_SW.png)

### VGA 사진 in ROM

![250909_VGA_img](/images/250909_VGA_img.png)

-> ROM을 clk에 동기화 시켜 lut가 차지하는 용량을 감소시키고 bram으로 바뀜

![250909_hulk_red](/images/250909_hulk_red.jpg)

### VGA 사진 in ROM Switch 제어

![250909_VGA_img_ROM](/images/250909_VGA_img_ROM.png)

<details>
  <summary>🧩 SystemVerilog: switch Control Filter (클릭해 펼치기)</summary>

```verilog
`timescale 1ns / 1ps

module RGB_ControlFilter (
    input  logic       sw_R,
    input  logic       sw_G,
    input  logic       sw_B,
    input  logic [3:0] r_port_in,
    input  logic [3:0] g_port_in,
    input  logic [3:0] b_port_in,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port
);
    assign r_port = sw_R ? r_port_in : 4'b0;
    assign g_port = sw_G ? g_port_in : 4'b0;
    assign b_port = sw_B ? b_port_in : 4'b0;
endmodule

```
</details>

### VGA 사진 in ROM gray 필터

![250909_hulk_gray](/images/250909_hulk_gray.jpg)

<details>
  <summary>🧩 SystemVerilog: gray filter (클릭해 펼치기)</summary>

```verilog
`timescale 1ns / 1ps

module GrayScaleFilter (
    input  logic [3:0] i_r,
    input  logic [3:0] i_g,
    input  logic [3:0] i_b,
    output logic [3:0] o_r,
    output logic [3:0] o_g,
    output logic [3:0] o_b
);
    logic [11:0] gray;

    assign gray = 77*i_r + 154*i_g + 25*i_b;
    assign {o_r, o_g, o_b} = {gray[11:8], gray[11:8], gray[11:8]};
endmodule

```
</details>
