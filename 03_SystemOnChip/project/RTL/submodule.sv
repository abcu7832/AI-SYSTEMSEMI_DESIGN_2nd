`timescale 1ns / 1ps

module Shift_Register #(
    parameter int Din_bit = 9,
    parameter int Length  = 256
) (
    input logic clk,
    input logic signed [Din_bit-1:0] din_i[0:15],
    input logic signed [Din_bit-1:0] din_q[0:15],
    output logic signed [Din_bit-1:0] dout_i[0:15],
    output logic signed [Din_bit-1:0] dout_q[0:15]
);
    logic signed [Din_bit-1:0] data_i[0:Length-1];
    logic signed [Din_bit-1:0] data_q[0:Length-1];
    logic signed [Din_bit-1:0] temp_i[0:Length-1];
    logic signed [Din_bit-1:0] temp_q[0:Length-1];

    always_comb begin
        for (int i = 0; i < 16; i++) begin
            dout_i[i] = data_i[Length-16+i];
            dout_q[i] = data_q[Length-16+i];
            temp_i[i] = din_i[i];
            temp_q[i] = din_q[i];
        end
    end

    always_ff @(posedge clk) begin
        for (int j = Length - 16; j >= 16; j = j - 16) begin
            for (int i = 0; i < 16; i++) begin
                data_i[i+j] <= data_i[i+j-16];
                data_q[i+j] <= data_q[i+j-16];
            end
        end
        for (int i = 0; i < 16; i++) begin
            data_i[i] = temp_i[i];
            data_q[i] = temp_q[i];
        end
    end
endmodule

module ButterFly #(
    parameter int Din_bit = 9
) (
    input  logic                      valid,
    input  logic signed [Din_bit-1:0] din1_i[0:15],
    input  logic signed [Din_bit-1:0] din1_q[0:15],
    input  logic signed [Din_bit-1:0] din2_i[0:15],
    input  logic signed [Din_bit-1:0] din2_q[0:15],
    output logic signed [  Din_bit:0] do1_i [0:15],
    output logic signed [  Din_bit:0] do1_q [0:15],
    output logic signed [  Din_bit:0] do2_i [0:15],
    output logic signed [  Din_bit:0] do2_q [0:15]
);
    always_comb begin
        if (valid) begin
            for (int i = 0; i < 16; i++) begin
                do1_i[i] = din1_i[i] + din2_i[i];
                do1_q[i] = din1_q[i] + din2_q[i];
                do2_i[i] = din1_i[i] - din2_i[i];
                do2_q[i] = din1_q[i] - din2_q[i];
            end
        end else begin
            for (int i = 0; i < 16; i++) begin
                do1_i[i] = 1'bx;
                do1_q[i] = 1'bx;
                do2_i[i] = 1'bx;
                do2_q[i] = 1'bx;
            end
        end
    end
endmodule

module ButterFly_V2 #(
    parameter int Din_bit = 9,
    parameter int Block   = 2   // 몇 쌍(block)으로 나눌지
) (
    input  logic signed [Din_bit-1:0] din_i[0:15],
    input  logic signed [Din_bit-1:0] din_q[0:15],
    output logic signed [  Din_bit:0] do_i [0:15],
    output logic signed [  Din_bit:0] do_q [0:15]
);
    // 블록당 묶이는 개수
    localparam int loop = 16 / Block;

    logic [8:0] idxA, idxB;

    always_comb begin
        for (int j = 0; j < Block; j++) begin
            for (int i = 0; i < loop / 2; i++) begin
                idxA = j * loop + i;
                idxB = j * loop + i + loop / 2;

                // 버터플라이 연산
                do_i[idxA] = din_i[idxA] + din_i[idxB];
                do_q[idxA] = din_q[idxA] + din_q[idxB];

                do_i[idxB] = din_i[idxA] - din_i[idxB];
                do_q[idxB] = din_q[idxA] - din_q[idxB];
            end
        end
    end
endmodule

module MUX_2x1 #(
    parameter int Din_bit = 9
) (
    input logic sel,
    input logic signed [Din_bit-1:0] din1_i[0:15],
    input logic signed [Din_bit-1:0] din1_q[0:15],
    input logic signed [Din_bit-1:0] din2_i[0:15],
    input logic signed [Din_bit-1:0] din2_q[0:15],
    output logic signed [Din_bit-1:0] dout_i[0:15],
    output logic signed [Din_bit-1:0] dout_q[0:15]
);
    always_comb begin
        for (int i = 0; i < 16; i++) begin
            dout_i[i] = (sel) ? din1_i[i] : din2_i[i];
            dout_q[i] = (sel) ? din1_q[i] : din2_q[i];
        end
    end
endmodule

module INNER_COUNTER #(
    parameter int cnt = 64
) (
    input logic clk,
    input logic valid_in,
    output logic [$clog2(cnt)-1:0] count
);
    always_ff @(posedge clk) begin
        if (valid_in == 0) begin
            count <= 0;
        end else begin
            if (count == cnt) begin
                count <= 1;
            end else begin
                count <= count + 1;
            end
        end
    end
endmodule

module Multiplier #(
    parameter int Din_bit  = 11,
    parameter int Dout_bit = 21
) (
    input logic signed [Din_bit-1:0] din_i[0:15],
    input logic signed [Din_bit-1:0] din_q[0:15],
    input logic signed [9:0] weight_i[0:15],
    input logic signed [9:0] weight_q[0:15],
    output logic signed [Dout_bit-1:0] dout_i[0:15],
    output logic signed [Dout_bit-1:0] dout_q[0:15]
);

    always_comb begin
        for (int i = 0; i < 16; i++) begin
            dout_i[i] = din_i[i] * weight_i[i] - din_q[i] * weight_q[i];
            dout_q[i] = din_i[i] * weight_q[i] + din_q[i] * weight_i[i];
        end
    end
endmodule

module fac8_0 #(
    parameter int Din_bit = 10
) (
    input logic [1:0] sel,
    input logic signed [Din_bit-1:0] din_i[0:15],
    input logic signed [Din_bit-1:0] din_q[0:15],
    output logic signed [Din_bit-1:0] dout_i[0:15],
    output logic signed [Din_bit-1:0] dout_q[0:15]
);
    always_comb begin
        case (sel)
            0: begin
                for (int i = 0; i < 16; i++) begin
                    dout_i[i] = din_i[i];
                    dout_q[i] = din_q[i];
                end
            end
            1: begin
                for (int i = 0; i < 16; i++) begin
                    dout_i[i] = din_i[i];
                    dout_q[i] = din_q[i];
                end
            end
            2: begin
                for (int i = 0; i < 16; i++) begin
                    dout_i[i] = din_i[i];
                    dout_q[i] = din_q[i];
                end
            end
            3: begin
                for (int i = 0; i < 16; i++) begin
                    dout_i[i] = din_q[i];
                    dout_q[i] = -din_i[i];
                end
            end
        endcase
    end
endmodule

module fac8_0_V2 #(
    parameter int Din_bit = 10
) (
    input logic [1:0] sel,
    input logic signed [Din_bit-1:0] din_i,
    input logic signed [Din_bit-1:0] din_q,
    output logic signed [Din_bit-1:0] dout_i,
    output logic signed [Din_bit-1:0] dout_q
);
    always_comb begin
        case (sel)
            0: begin
                dout_i = din_i;
                dout_q = din_q;
            end
            1: begin
                dout_i = din_i;
                dout_q = din_q;
            end
            2: begin
                dout_i = din_i;
                dout_q = din_q;
            end
            3: begin
                dout_i = din_q;
                dout_q = -din_i;
            end
        endcase
    end
endmodule

module fac8_1_rom (
    input  logic        [2:0] addr,  // index (0~7)
    output logic signed [9:0] w_re,  // 10-bit
    output logic signed [9:0] w_im
);

    logic signed [9:0] w_re_reg, w_im_reg;

    always_comb begin
        case (addr)
            3'd0: begin
                w_re_reg = 10'd256;
                w_im_reg = 10'd0;
            end
            3'd1: begin
                w_re_reg = 10'd256;
                w_im_reg = 10'd0;
            end
            3'd2: begin
                w_re_reg = 10'd256;
                w_im_reg = 10'd0;
            end
            3'd3: begin
                w_re_reg = 10'd0;
                w_im_reg = -10'd256;
            end
            3'd4: begin
                w_re_reg = 10'd256;
                w_im_reg = 10'd0;
            end
            3'd5: begin
                w_re_reg = 10'd181;
                w_im_reg = -10'd181;
            end
            3'd6: begin
                w_re_reg = 10'd256;
                w_im_reg = 10'd0;
            end
            3'd7: begin
                w_re_reg = -10'd181;
                w_im_reg = -10'd181;
            end
        endcase
    end

    assign w_re = w_re_reg;
    assign w_im = w_im_reg;

endmodule

module round #(
    parameter int Din_bit    = 21,
    parameter int round_size = 9,
    parameter int Dout_bit   = 12
) (
    input  logic signed [ Din_bit-1:0] din_i [0:15],
    input  logic signed [ Din_bit-1:0] din_q [0:15],
    output logic signed [Dout_bit-1:0] dout_i[0:15],
    output logic signed [Dout_bit-1:0] dout_q[0:15]
);

    logic signed [   Din_bit-1:0] abs_i[0:15];
    logic signed [  Dout_bit-1:0] q_i  [0:15];
    logic        [round_size-1:0] r_i  [0:15];

    logic signed [   Din_bit-1:0] abs_q[0:15];
    logic signed [  Dout_bit-1:0] q_q  [0:15];
    logic        [round_size-1:0] r_q  [0:15];

    always_comb begin
        for (int k = 0; k < 16; k++) begin
            abs_i[k] = (din_i[k] < 0) ? -din_i[k] : din_i[k];
            q_i[k] = abs_i[k] >>> round_size;
            r_i[k] = abs_i[k] & ((1 << round_size) - 1);

            dout_i[k] = (din_i[k] < 0) ? -q_i[k] : q_i[k];

            if (r_i[k] > (1 << (round_size-1)) ||
               (r_i[k] == (1 << (round_size-1)) && abs_i[k] != 0)) begin
                dout_i[k] = (din_i[k] < 0) ? dout_i[k] - 1 : dout_i[k] + 1;
            end

            abs_q[k] = (din_q[k] < 0) ? -din_q[k] : din_q[k];
            q_q[k] = abs_q[k] >>> round_size;
            r_q[k] = abs_q[k] & ((1 << round_size) - 1);

            dout_q[k] = (din_q[k] < 0) ? -q_q[k] : q_q[k];

            if (r_q[k] > (1 << (round_size-1)) ||
               (r_q[k] == (1 << (round_size-1)) && abs_q[k] != 0)) begin
                dout_q[k] = (din_q[k] < 0) ? dout_q[k] - 1 : dout_q[k] + 1;
            end
        end
    end
endmodule

