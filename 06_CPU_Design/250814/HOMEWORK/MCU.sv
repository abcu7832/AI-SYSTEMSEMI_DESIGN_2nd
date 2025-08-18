`timescale 1ns / 1ps
module MCU (
    input logic clk,
    input logic reset
);

    logic [31:0] instrCode;
    logic [31:0] instrMemAdr;

    ROM U_ROM (
        .addr(instrMemAdr),
        .data(instrCode)
    );

    CPU_RV32I U_CPU_RVA32I (.*);
    
endmodule
