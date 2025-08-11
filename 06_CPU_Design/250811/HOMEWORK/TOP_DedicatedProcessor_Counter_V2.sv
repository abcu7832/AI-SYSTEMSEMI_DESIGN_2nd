`timescale 1ns / 1ps

module TOP_DedicatedProcessor_Counter_V2 (
    input  logic       clk,
    input  logic       reset,
    output logic [3:0] fndCom,
    output logic [7:0] fndFont
);

    logic [13:0] number;
    logic clk_10hz;
    logic [$clog2(10_000_000)-1:0] div_counter;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            clk_10hz    <= 1'b0;
        end else begin
            if (div_counter == 10_000_000 - 1) begin  // 0.1s
                div_counter <= 0;
                clk_10hz    <= 1'b1;
            end else begin
                div_counter <= div_counter + 1;
                clk_10hz    <= 1'b0;
            end
        end
    end

    DedicatedProcessor_Counter_V2 A (
        .clk(clk_10hz),
        .reset(reset),
        .Output(number)
    );

    fndController B (
        .clk(clk),
        .reset(reset),
        .number(number),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );
endmodule
