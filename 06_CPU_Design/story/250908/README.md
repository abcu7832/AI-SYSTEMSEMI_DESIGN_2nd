# 강의 내용

# 🖥️ Display Timing 정리 (Front Porch / Sync / Back Porch / Horizontal & Vertical)

디지털 디스플레이 시스템(VGA, HDMI 등)에서는 화면을 구성하기 위해 **수평(Horizontal)** 및 **수직(Vertical)** 방향의 타이밍이 필수적입니다.  
이를 구성하는 기본 요소인 **Front Porch**, **Sync Pulse**, **Back Porch**, **Active Video**에 대해 설명합니다.

---

## 📘 1. 디스플레이 타이밍 개요

디스플레이는 한 프레임을 출력하기 위해 수많은 **라인(Line)**과 **픽셀(Pixel)**을 그립니다.  
각 줄과 프레임 사이에는 **동기화 신호(Sync Pulse)**와 **여유 구간(Porch)**이 존재하여,  
정확한 화면 출력과 디스플레이 장치의 안정적인 처리를 돕습니다.

---

## 🧱 2. 주요 용어 설명

![250908_VGA](/images/250908_VGA.png)

---

### VGA 640*480 -> 디스플레이 영역(porch와 sync 구간 제외) / 합치면 horizontal: 800 pixels, vertical: 525 lines

| 용어              | 설명 |
|-------------------|------|
| **Front Porch**   | 화면을 그리기 *전*의 짧은 여유 시간 |
| **Sync Pulse**    | 디스플레이에 “줄/프레임이 끝났다”는 신호를 보내는 구간 |
| **Back Porch**    | 동기 신호 이후 *본격적인 픽셀 데이터 전*의 여유 시간 |
| **Active Video**  | 실제로 화면에 **표시되는 유효한 픽셀** 데이터 |
| **Horizontal Timing** | 한 줄(Line)을 출력하기 위한 전체 시간 구성 |
| **Vertical Timing**   | 한 프레임(Frame)을 출력하기 위한 전체 시간 구성 |

---
### Standard Timing

http://tinyvga.com/vga-timing

## ⏱ 3. 수평 타이밍 (Horizontal Timing)

하나의 라인(Line)을 출력하는 전체 타이밍 구조는 다음과 같습니다:

←------------ One Line ------------→

[ Front Porch ] → [ Sync Pulse ] → [ Back Porch ] → [ Active Video ]


### ✅ VGA 640x480 @ 60Hz 기준 수평 타이밍

| 구간         | 클럭 수 (픽셀 기준) |
|--------------|---------------------|
| Front Porch  | 16 px               |
| Sync Pulse   | 96 px               |
| Back Porch   | 48 px               |
| Active Video | 640 px              |
| **총합**     | **800 px**          |

---

## ⬇️ 4. 수직 타이밍 (Vertical Timing)

하나의 **프레임(Frame)**을 구성하기 위한 줄(Line) 단위 타이밍:


### ✅ VGA 640x480 @ 60Hz 기준 수직 타이밍

| 구간         | 줄 수 (Line 기준) |
|--------------|------------------|
| Front Porch  | 10 lines         |
| Sync Pulse   | 2 lines          |
| Back Porch   | 33 lines         |
| Active Video | 480 lines        |
| **총합**     | **525 lines**     |

---

## 📊 5. 전체 타이밍 요약

| 구분         | 수평 타이밍 (px) | 수직 타이밍 (줄) |
|--------------|------------------|------------------|
| Front Porch  | 16               | 10               |
| Sync Pulse   | 96               | 2                |
| Back Porch   | 48               | 33               |
| Active Video | 640              | 480              |
| **총합**     | **800**          | **525**          |

---

### <주파수 계산>

ex) 1초 -> 800px * 525 line * 60 frame = 25.2MHz

pixel을 기준으로 계산!!

---

## 🤔 6. 왜 이런 타이밍이 필요한가?

- 디스플레이 장치는 픽셀을 출력하기 전에 **준비 시간이 필요**합니다.
- **Sync Pulse**를 통해 **줄의 시작/끝**, **프레임의 시작/끝**을 정확히 알립니다.
- **Porch 구간**은 장치가 데이터를 안정적으로 처리하도록 **여유 시간을 제공**합니다.

---

## 🧾 7. 타이밍 구조 다이어그램

```text
[ Horizontal Timing ]
|<--Front-->|<--Sync-->|<--Back-->|<--Active Video-->|
    16 px      96 px      48 px         640 px

[ Vertical Timing ]
|<--Front-->|<--Sync-->|<--Back-->|<--Active Video-->|
    10 lines    2 lines    33 lines      480 lines
```

## ✅ 8. 핵심 요약

Front Porch: 다음 Sync 전에 잠깐 대기 (줄/프레임 시작 전)

Sync Pulse: “줄/프레임 시작”을 알리는 동기 신호

Back Porch: Sync 이후 데이터 출력 전의 안정 대기

Active Video: 실제로 디스플레이에 보여지는 픽셀들

---

# VGA
### VGA BLOCK DIAGRAM

![250908_VGA_module](/images/250908_VGA_Module.png)

RGB 444 format

### VGA 실습

![250908_VGA_화면조정](/images/250908_VGA_화면조정.png)

<details>
  <summary>🧩 Verilog: S00_AXI_v1_0_S00_AXI (클릭해 펼치기)</summary>

```verilog

`timescale 1ns / 1ps

module VGA_Display_Switch (
    input  logic       clk,
    input  logic       reset,
    input  logic [3:0] sw_red,
    input  logic [3:0] sw_green,
    input  logic [3:0] sw_blue,
    output logic       h_sync,
    output logic       v_sync,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port
);
    logic DE;
    logic [$clog2(525)-1:0] x_pixel;
    logic [$clog2(800)-1:0] y_pixel;

    VGA_RGB_Switch U_VGA_RGB_Switch (.*);
    VGA_Decoder U_VGA_Decoder (.*);
endmodule

module VGA_Decoder #(
    parameter int H_MAX = 800,
    parameter int V_MAX = 525
) (
    input  logic                     clk,
    input  logic                     reset,
    output logic                     h_sync,
    output logic                     v_sync,
    output logic [$clog2(V_MAX)-1:0] x_pixel,
    output logic [$clog2(H_MAX)-1:0] y_pixel,
    output logic                     DE
);

    logic pclk;
    logic [$clog2(V_MAX)-1:0] v_counter;
    logic [$clog2(H_MAX)-1:0] h_counter;

    Pixel_clk_gen U_Pixel_clk_gen (.*);
    pixel_counter U_pixel_counter (.*);
    vga_decoder U_vga_decoder (.*);

endmodule

module Pixel_clk_gen (
    input  logic clk,
    input  logic reset,
    output logic pclk
);

    logic [1:0] p_counter;

    always_ff @(posedge clk) begin
        if (reset) begin
            p_counter <= 0;
            pclk      <= 1'b0;
        end else begin
            p_counter <= p_counter + 1;
            if (p_counter == 3) begin
                pclk <= 1'b1;
            end else begin
                pclk <= 1'b0;
            end
        end
    end
endmodule

module pixel_counter #(
    parameter int H_MAX = 800,
    parameter int V_MAX = 525
) (
    input  logic                     pclk,
    input  logic                     reset,
    output logic [$clog2(V_MAX)-1:0] v_counter,
    output logic [$clog2(H_MAX)-1:0] h_counter
);

    always_ff @(negedge pclk, posedge reset) begin
        if (reset) begin
            h_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                h_counter <= 0;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    always_ff @(negedge pclk, posedge reset) begin
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                if (v_counter == V_MAX - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end
        end
    end
endmodule

module vga_decoder #(
    parameter int H_MAX = 800,
    parameter int V_MAX = 525
) (
    input  logic [$clog2(V_MAX)-1:0] v_counter,
    input  logic [$clog2(H_MAX)-1:0] h_counter,
    output logic                     h_sync,
    output logic                     v_sync,
    output logic [$clog2(V_MAX)-1:0] x_pixel,
    output logic [$clog2(H_MAX)-1:0] y_pixel,
    output logic                     DE
);
    // 640*480 기준
    localparam H_Visible_area = 640;
    localparam H_Front_porch = 16;
    localparam H_Sync_pulse = 96;
    localparam H_Back_porch = 48;
    localparam H_Whole_line = 800;

    localparam V_Visible_area = 480;
    localparam V_Front_porch = 10;
    localparam V_Sync_pulse = 2;
    localparam V_Back_porch = 33;
    localparam V_Whole_line = 525;

    assign h_sync = !((h_counter >= (H_Visible_area + H_Front_porch)) && (h_counter <= (H_Visible_area + H_Front_porch + H_Sync_pulse)));
    assign v_sync = !((v_counter >= (V_Visible_area + V_Front_porch)) && (v_counter <= (V_Visible_area + V_Front_porch + V_Sync_pulse)));
    assign DE = ((h_counter < H_Visible_area) && (v_counter < V_Visible_area));
    assign x_pixel = h_counter;
    assign y_pixel = v_counter;

endmodule

module VGA_RGB_Switch (
    input  logic [            3:0] sw_red,
    input  logic [            3:0] sw_green,
    input  logic [            3:0] sw_blue,
    input  logic                   DE,
    input  logic [$clog2(800)-1:0] x_pixel,
    input  logic [$clog2(525)-1:0] y_pixel,
    output logic [            3:0] r_port,
    output logic [            3:0] g_port,
    output logic [            3:0] b_port
);
/*
    assign r_port = DE ? sw_red : 4'b0;
    assign g_port = DE ? sw_green : 4'b0;
    assign b_port = DE ? sw_blue : 4'b0;

*/
    logic [11:0] color;

    assign r_port = DE ? color[11:8] : 4'b0;
    assign g_port = DE ? color[7:4] : 4'b0;
    assign b_port = DE ? color[3:0] : 4'b0;

    always_comb begin
        if (y_pixel < 330) begin
            if (x_pixel <= 91) begin
                color = 12'hBBB;//흰
            end else if(x_pixel <= 182) begin
                color = 12'hBB0;//노
            end else if(x_pixel <= 273) begin
                color = 12'h0BB;//하늘
            end else if(x_pixel <= 364) begin
                color = 12'h0B0;//연두
            end else if(x_pixel <= 455) begin
                color = 12'hB0B;//핑크
            end else if(x_pixel <= 546) begin
                color = 12'hB00;//빨
            end else begin
                color = 12'h00B;//파
            end
        end else if(y_pixel < 360) begin
            if (x_pixel <= 91) begin
                color = 12'h00F;//파
            end else if(x_pixel <= 182) begin
                color = 12'h000;//검
            end else if(x_pixel <= 273) begin
                color = 12'hB0B;//핑크
            end else if(x_pixel <= 364) begin
                color = 12'h000;//검
            end else if(x_pixel <= 455) begin
                color = 12'h07F;//하늘
            end else if(x_pixel <= 546) begin
                color = 12'h000;//검
            end else begin
                color = 12'hBBB;//흰
            end
        end else begin
            if(x_pixel <= 119) begin
                color = 12'h006;//남
            end else if(x_pixel <= 239) begin
                color = 12'hFFF;//흰
            end else if(x_pixel <= 359) begin
                color = 12'h70F;//보라
            end else if(x_pixel <= 479) begin
                color = 12'h000;//검
            end else if(x_pixel <= 559) begin
                color = 12'h101;//연검
            end else begin
                color = 12'h001;//파검
            end
        end
    end
endmodule
```
</details>
