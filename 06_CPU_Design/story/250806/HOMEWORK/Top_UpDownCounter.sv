`timescale 1ns / 1ps

module Top_UpDownCounter(
    input logic clk,
    input logic reset,
    input logic btnU, // mode 버튼
    input logic btnL, // run_stop 버튼
    input logic btnR, // clear 버튼
    output logic [3:0] fndCom,
    output logic [7:0] fndFont,
    output logic [3:0] led 
);
    // mode = 0 up counting
    // mode = 1 down counting
    // up counter: led0(on) led1(off)
    // down counter: led0(off) led1(on)
    // stop: led2(on) led3(off)
    // run: led2(off) led3(on)

    logic [$clog2(10_000) - 1:0] count;
    logic button_edge_U, button_edge_L, button_edge_R;
    logic mode;
    logic [1:0] fsm;

    always_comb begin
        if(mode == 0) begin
            led[1:0] = 2'b01;
        end else begin
            led[1:0] = 2'b10;
        end
        if(fsm==0) begin
            led[3:2] = 2'b01;
        end else if(fsm==1) begin
            led[3:2] = 2'b10;
        end else begin
            led[3:2] = 2'b00;
        end
    end

    button_detector U_ButtonDetector_U (
        .clk(clk),  // system clk 100MHz
        .reset(reset),
        .in_button(btnU),
        .rising_edge(),
        .fallng_edge(button_edge_U),
        .both_edge()
    );

    button_detector U_ButtonDetector_L (
        .clk(clk),  // system clk 100MHz
        .reset(reset),
        .in_button(btnL),
        .rising_edge(),
        .fallng_edge(button_edge_L),
        .both_edge()
    );
        
    button_detector U_ButtonDetector_R (
        .clk(clk),  // system clk 100MHz
        .reset(reset),
        .in_button(btnR),
        .rising_edge(),
        .fallng_edge(button_edge_R),
        .both_edge()
    );

    UpDownCounter U_UpDownCounter (
        .clk(clk),
        .reset(reset),
        .button_up(button_edge_U),
        .button_left(button_edge_L),
        .button_right(button_edge_R),
        .count(count),
        .o_mode(mode),
        .o_fsm(fsm)
    );

    fndController U_FND(
        .clk(clk),
        .reset(reset),
        .number(count),
        .fndCom(fndCom),
        .fndFont(fndFont)
    );
endmodule
