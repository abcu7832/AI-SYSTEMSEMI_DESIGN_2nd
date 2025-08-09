`timescale 1ns / 1ps

module golden_top #(
    parameter P_SIZE       = 16,
    parameter TOTAL_SIZE   = 512,  // 512 POINTS
    parameter WIDTH_INPUT  = 9,    // DATA INPUT TO MODULE WIDTH
    parameter WIDTH_OUTPUT = 13,    // FFT RESULT DATA  WIDTH 13
    parameter WIDTH_TEST   = 26
) (
    input  logic                             clk,
    input  logic                             rstn,
    input  logic signed [8:0] data_in_i,
    input  logic signed [8:0] data_in_q,
    output logic signed [12:0] data_out_i[0:511],
    output logic signed [12:0] data_out_q[0:511],
    output logic do_en
);

    logic signed [8:0] s_to_p_i  [0:15];
    logic signed [8:0] s_to_p_q  [0:15];
    logic s2p_valid;

    serial_to_parallel #(
        .P_SIZE(P_SIZE)
    ) u1_s_to_p (
        .clk       (clk),
        .rstn      (rstn),
        .data_in_i (data_in_i),
        .data_in_q (data_in_q),
        .data_out_i(s_to_p_i),
        .data_out_q(s_to_p_q),
        .valid_out (s2p_valid)
    );

    fft_top #(
        .TOTAL_SIZE  (512),
        .INPUT_LENGHT(16),
        .WIDTH_INPUT (9),
        .WIDTH_OUTPUT(13)
    ) u1_fft_top (
        .clk       (clk),
        .rstn      (rstn),
        .data_valid(s2p_valid),   //input enable
        .din_i     (s_to_p_i),
        .din_q     (s_to_p_q),
        .do_en     (do_en),            //output enable
        .do_re     (data_out_i),
        .do_im     (data_out_q)
    );
endmodule
