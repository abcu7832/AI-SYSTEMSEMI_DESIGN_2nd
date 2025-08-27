`timescale 1ns / 1ps

module RAM (
    input  logic        clk,
    input  logic [ 9:0] PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY
);
    logic [31:0] mem[0:2**8-1];

    always_ff @(posedge clk) begin
        PREADY <= 1'b0;
        if (PSEL && PENABLE) begin
            PREADY <= 1'b1;
            if (PWRITE) begin
                mem[PADDR[9:2]] <= PWDATA;
            end
        end
    end

    assign PRDATA = mem[PADDR[9:2]];
endmodule
