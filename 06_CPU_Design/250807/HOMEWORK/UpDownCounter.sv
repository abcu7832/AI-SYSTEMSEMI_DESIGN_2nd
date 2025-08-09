`timescale 1ns / 1ps

module UpDownCounter (
    input  logic                      clk,
    input  logic                      reset,
    input  logic                      button_up,
    input  logic                      button_left,
    input  logic                      button_right,
    output logic [$clog2(10_000)-1:0] count,
    output logic                      o_mode,
    output logic [               1:0] o_fsm
);
    logic tick_10hz;
    logic mode;
    logic [1:0] fsm;

    assign o_mode = mode;
    assign o_fsm = fsm;
    
    clk_div_10hz U (
        .clk      (clk),
        .reset    (reset),
        .tick_10hz(tick_10hz)
    );

    up_down_counter K (
        .clk  (clk),
        .reset(reset),
        .tick (tick_10hz),
        .mode (mode),
        .fsm  (fsm),
        .count(count)
    );

    control_unit L (
        .clk         (clk),
        .reset       (reset),
        .button_up   (button_up),
        .button_left (button_left),
        .button_right(button_right),
        .fsm         (fsm),
        .mode        (mode)
    );
endmodule

module up_down_counter (
    input  logic                    clk,
    input  logic                    reset,
    input  logic                    tick,
    input  logic                    mode,
    input  logic [             1:0] fsm,
    output logic [$clog2(10_000):0] count
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
        end else begin
            if ((mode == 0) && (fsm == 1)) begin  // up counter
                if (tick) begin
                    if (count == 10_000 - 1) begin
                        count <= 0;
                    end else begin
                        count <= count + 1;
                    end
                end
            end else if ((mode == 1) && (fsm == 1)) begin  // down counter
                if (tick) begin
                    if (count == 0) begin
                        count <= 9999;
                    end else begin
                        count <= count - 1;
                    end
                end
            end else if (fsm == 2) begin
                count <= 0;
            end
        end
    end
endmodule

module clk_div_10hz (
    input  logic clk,
    input  logic reset,
    output logic tick_10hz
);

    logic [$clog2(10_000_000)-1:0] div_counter;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick_10hz   <= 1'b0;
        end else begin
            // 1초 1hz => 100MHz / 10^8
            // 10hz -> 0.1s 100MHz / 10^7
            if (div_counter == 10_000_000 - 1) begin
                div_counter <= 0;
                tick_10hz   <= 1'b1;
            end else begin
                div_counter <= div_counter + 1;
                tick_10hz   <= 1'b0;
            end
        end
    end
endmodule

module control_unit (
    input  logic       clk,
    input  logic       reset,
    input  logic       button_up,
    input  logic       button_left,
    input  logic       button_right,
    output logic [1:0] fsm,
    output logic       mode
);
    typedef enum {
        UP,
        DOWN
    } statge_e;

    typedef enum {
        STOP,
        RUN,
        CLEAR
    } statge_f;

    statge_e state, next_state;
    statge_f state_f, next_state_f;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state   <= UP;
            state_f <= STOP;
        end else begin
            state   <= next_state;  // state memory
            state_f <= next_state_f;
        end
    end

    always_comb begin
        next_state = state;
        next_state_f = state_f;
        mode = 0;
        fsm = 0;
        case (state)
            UP: begin
                mode = 0;
                if (button_up) begin
                    next_state = DOWN;
                end
            end
            DOWN: begin
                mode = 1;
                if (button_up) begin
                    next_state = UP;
                end
            end
        endcase

        case (state_f)
            STOP: begin
                fsm = 0;
                if (button_left) begin
                    next_state_f = RUN;
                end
                if (button_right) begin
                    next_state_f = CLEAR;
                end
            end
            RUN: begin
                fsm = 1;
                if (button_left) begin
                    next_state_f = STOP;
                end
            end
            CLEAR: begin
                fsm = 2;
                next_state_f = STOP;
            end
        endcase
    end

    // FSM (Moore Machine)
    // transition logic
    /*
    always_comb begin
        next_state = state;
        case (state)
            UP: begin
                if (button) begin
                    next_state = DOWN;
                end
            end
            DOWN: begin
                if (button) begin
                    next_state = UP;
                end
            end
        endcase
    end

    // Output Logic
    always_comb begin
        mode = 0;
        case (state)
            UP: begin
                mode = 0; 
            end
            DOWN: begin
                mode = 1;
            end
        endcase
    end*/
endmodule
