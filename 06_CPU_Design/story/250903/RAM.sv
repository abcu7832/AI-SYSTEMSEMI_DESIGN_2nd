`timescale 1ns / 1ps

module RAM (
    input  logic       clk,
    input  logic [7:0] addr,
    input  logic       we,
    input  logic [7:0] wdata,
    output logic [7:0] rdata
);
    logic [7:0] mem[0:2**8-1];

    // 비동기 read
    assign rdata = mem[addr];

    always_ff @(posedge clk) begin
        if (we) begin
            mem[addr] <= wdata;
        end
    end
endmodule
