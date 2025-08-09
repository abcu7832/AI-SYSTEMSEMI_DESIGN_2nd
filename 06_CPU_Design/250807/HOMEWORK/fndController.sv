`timescale 1ns / 1ps

module fndController(
    input logic clk,
    input logic reset,
    input logic [$clog2(10_000)-1:0] number,
    output logic [3:0] fndCom,
    output logic [7:0] fndFont
);

    logic tick_1khz;
    logic [1:0] count;
    logic [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000, w_digit;

    clk_div_1khz U_clk_div_1khz (
        .clk(clk),
        .reset(reset),
        .tick_1khz(tick_1khz)
    );

    counter_2bit U_counter_2bit (
        .clk(clk),
        .reset(reset),
        .tick(tick_1khz),
        .count(count)
    );

    decoder_2x4 U_decoder_2x4 (
        .x(count),
        .y(fndCom)
    );

    digitSplitter U_digitSplitter (
        .number(number),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );

    mux_4x1 U_MUX_4x1(
        .sel(count),
        .x0(w_digit_1),
        .x1(w_digit_10),
        .x2(w_digit_100),
        .x3(w_digit_1000),
        .y(w_digit)
    );

    BCDtoFND_Decode U_BCDtoFND_Decode (
        .bcd(w_digit),
        .fnd(fndFont)
    );
endmodule

module clk_div_1khz (
    input logic clk,
    input logic reset,
    output logic tick_1khz
);
    logic [$clog2(100_000)-1:0] div_counter;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            div_counter <= 0;
            tick_1khz <= 1'b0;
        end else begin
            if(div_counter == 100_000 - 1) begin
                div_counter <= 0;
                tick_1khz <= 1'b1;
            end else begin
                div_counter <= div_counter + 1;
                tick_1khz <= 1'b0;
            end
        end
    end
endmodule

module counter_2bit (
    input logic clk,
    input logic reset,
    input logic tick,
    output logic [1:0] count
);
    always_ff @(posedge clk, posedge reset) begin
        if(reset) begin
            count <= 0;
        end else begin
            if(tick) begin
                count <= count + 1;
            end
        end
    end
endmodule

module decoder_2x4 (
    input logic [1:0] x,
    output logic [3:0] y
);
    
    always_comb begin
        y = 4'b1111; 
        case (x)
            2'b00: y = 4'b1110; 
            2'b01: y = 4'b1101; 
            2'b10: y = 4'b1011; 
            2'b11: y = 4'b0111; 
        endcase    
    end
endmodule

module digitSplitter (
    input logic [$clog2(10_000) - 1:0] number,
    output logic [3:0] digit_1,
    output logic [3:0] digit_10,
    output logic [3:0] digit_100,
    output logic [3:0] digit_1000
);
    assign digit_1 = number % 10;
    assign digit_10 = number / 10 % 10;
    assign digit_100 = number / 100 % 10;
    assign digit_1000 = number / 1000 % 10;
endmodule

module mux_4x1 (
    input logic [1:0] sel,
    input logic [3:0] x0,
    input logic [3:0] x1,
    input logic [3:0] x2,
    input logic [3:0] x3,
    output logic [3:0] y
);
    always_comb begin
        y = 4'b0000; // latch 방지용
        case (sel) 
            2'b00: y = x0;
            2'b01: y = x1;
            2'b10: y = x2;
            2'b11: y = x3;
        endcase
    end     
endmodule

module BCDtoFND_Decode (
    input logic [3:0] bcd,
    output logic [7:0] fnd
);
    always_comb begin
        case (bcd)
            4'h00:   fnd = 8'hc0;
            4'h01:   fnd = 8'hf9;
            4'h02:   fnd = 8'ha4;
            4'h03:   fnd = 8'hb0;
            4'h04:   fnd = 8'h99;
            4'h05:   fnd = 8'h92;
            4'h06:   fnd = 8'h82;
            4'h07:   fnd = 8'hf8;
            4'h08:   fnd = 8'h80;
            4'h09:   fnd = 8'h90;
            default: fnd = 8'hff;
        endcase
    end
endmodule
