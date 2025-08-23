`timescale 1ns / 1ps

module testbench ();

    logic clk;
    logic reset;

    MCU dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        reset = 1;
        #10 reset = 0;
        #300 $finish;
    end
endmodule
