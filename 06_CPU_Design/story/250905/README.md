## AXI4_Lite READ
![250905_simulation_read](/images/250905_simulation_read.png)

## AXI IP ANALYSIS
<details>
  <summary>🧩 Verilog: S00_AXI_v1_0_S00_AXI (클릭해 펼치기)</summary>

```verilog
`timescale 1 ns / 1 ps

module S00_AXI_v1_0_S00_AXI #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    // global signal
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    // Write Address
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    // Write
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB, // 4byte의 데이터 중, byte의 위치를 알려주는 strobe 데이터
// ex)
// WSTRB = 4'b1111 -> [31:0] 값 write
// WSTRB = 4'b0011 -> [15:0] 값 write
// WSTRB = 4'b1000 -> [31:24] 값 write
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,
    // Write Response
    output wire [1 : 0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire S_AXI_BREADY,
    // Read Address
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    // Read
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input wire S_AXI_RREADY
);

    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    reg axi_awready;
    reg axi_wready;
    reg [1 : 0] axi_bresp;
    reg axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    reg axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    reg [1 : 0] axi_rresp;
    reg axi_rvalid;

    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;// 2
    localparam integer OPT_MEM_ADDR_BITS = 1;

    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;
    wire slv_reg_rden;
    wire slv_reg_wren;

    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer byte_index;
    reg aw_en;

    // I/O Connections assignments
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awaddr <= 0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awaddr <= S_AXI_AWADDR;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID; // 모든 조건 만족 handshake -> write

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
        end else begin
            if (slv_reg_wren) begin
                case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]) // [3:2]
                    2'h0:
                    for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1; byte_index = byte_index + 1) begin
                        if (S_AXI_WSTRB[byte_index] == 1) begin
                            slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            // slv_reg[0+:8] == slv_reg[7:0] 0을 포함한 0부터 8개
                            // slv_reg[8+:8] == slv_reg[15:8] 8을 포함한 8부터 8개
                        end
                    end
                    2'h1:
                    for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1; byte_index = byte_index + 1) begin
                        if (S_AXI_WSTRB[byte_index] == 1) begin
                            slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end
                    end
                    2'h2:
                    for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1; byte_index = byte_index + 1) begin
                        if (S_AXI_WSTRB[byte_index] == 1) begin
                            slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end
                    end
                    2'h3:
                    for (byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1; byte_index = byte_index + 1) begin
                        if (S_AXI_WSTRB[byte_index] == 1) begin
                            slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                        end
                    end
                    default: begin
                        slv_reg0 <= slv_reg0;
                        slv_reg1 <= slv_reg1;
                        slv_reg2 <= slv_reg2;
                        slv_reg3 <= slv_reg3;
                    end
                endcase
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 0;
            axi_bresp  <= 2'b0;  // okay
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0;  // okay
            end else begin
                if (S_AXI_BREADY && axi_bvalid) begin
                    axi_bvalid <= 1'b0;
                end
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 32'b0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;  // okay
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin // axi_arready && S_AXI_ARVALID: (handshake) -> read
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;  // okay
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid; // 모든 조건 만족 (handshake) -> read
    always @(*) begin
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            2'h0   : reg_data_out <= slv_reg0;
            2'h1   : reg_data_out <= slv_reg1;
            2'h2   : reg_data_out <= slv_reg2;
            2'h3   : reg_data_out <= slv_reg3;
            default : reg_data_out <= 0;
        endcase
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 0;
        end else begin
            if (slv_reg_rden) begin 
                axi_rdata <= reg_data_out;
            end
        end
    end

    // Add user logic here

    // User logic ends

endmodule
```

## Block Design in Vivado
### MCU using ip of Xilinx
![250905_Block_Design](/images/250905_Block_Design.png)

### Block ip
![250905_Block](/images/250905_Block.png)

## vitis

<details>
  <summary>💻 C: main.c (클릭해 펼치기)</summary>

```c
#include <stdio.h>
#include <stdint.h>
#include "xil_printf.h"
#include "xparameters.h"// ctrl누르면 마우스 위로 올리면 link 나옴
#include "sleep.h"

typedef struct {
	uint32_t CR;
	uint32_t FDR;
}FND_TypeDef;

typedef struct {
	uint32_t CR;
	uint32_t ODR;
	uint32_t IDR;
}GPIO_TypeDef;

#define FND_BASEADDR		 XPAR_FNDCONTROLLER_0_S00_AXI_BASEADDR
#define GPIO_BASEADDR 		 XPAR_GPIO_0_S00_AXI_BASEADDR
#define FND					 ((FND_TypeDef *)(FND_BASEADDR))
#define GPIO				 ((GPIO_TypeDef *)(GPIO_BASEADDR))

void FND_Init(FND_TypeDef *fnd)
{
	fnd->CR = 0x01;
}

void FND_WriteData(FND_TypeDef *fnd, uint8_t data)
{
	fnd->FDR = data;
}

uint8_t FND_ReadData(FND_TypeDef *fnd)
{
	return fnd->FDR;
}

void GPIO_Init(GPIO_TypeDef *gpio, uint8_t data)
{
	gpio->CR = data;
}

void GPIO_WriteData(GPIO_TypeDef *gpio, uint8_t data)
{
	gpio->ODR = data;
}

uint8_t GPIO_ReadData(GPIO_TypeDef *gpio)
{
	return gpio->IDR;
}

int main()
{
	uint32_t counter = 0;
	uint8_t led = 0;

	FND_Init(FND);
	GPIO_Init(GPIO, 0x0f);

	while(1)
	{
		FND_WriteData(FND, counter);
		GPIO_WriteData(GPIO, led);
		counter++;
		led = led ^ 0x0f;
		usleep(100000);
	}

    return 0;
}
```
