`timescale 1ns / 1ps

module fft_top #(
    parameter TOTAL_SIZE   = 512,
    parameter INPUT_LENGHT = 16,
    parameter WIDTH_INPUT  = 9,
    parameter WIDTH_OUTPUT = 13
) (
    input                                  clk,
    input                                  rstn,
    input                                  data_valid,
    input  signed       [ WIDTH_INPUT-1:0] din_i     [0:INPUT_LENGHT - 1],
    input  signed       [ WIDTH_INPUT-1:0] din_q     [0:INPUT_LENGHT - 1],
    output logic                           do_en,
    output logic signed [WIDTH_OUTPUT-1:0] do_re     [  0:TOTAL_SIZE - 1],
    output logic signed [WIDTH_OUTPUT-1:0] do_im     [  0:TOTAL_SIZE - 1]
);

    // ============================================
    // Wires between modules
    // ============================================
    localparam WIDTH_BFLY02 = 11;  // module0 output width
    localparam WIDTH_BFLY10 = 12;  // module1 output width

    // Outputs of module0
    logic signed [WIDTH_BFLY02-1:0] bfly02_i[0:TOTAL_SIZE-1];
    logic signed [WIDTH_BFLY02-1:0] bfly02_q[0:TOTAL_SIZE-1];
    logic                            module_0_valid;

    // Outputs of module1
    logic signed [WIDTH_BFLY10-1:0] bfly12_i[0:TOTAL_SIZE-1];
    logic signed [WIDTH_BFLY10-1:0] bfly12_q[0:TOTAL_SIZE-1];
    logic                            module_1_valid;

    logic signed [12:0] bfly22_i [0:511];
    logic signed [12:0] bfly22_q [0:511];
    logic module_2_valid;

    logic [4:0] index1_re [0:511], index2_re [0:511];
    logic [4:0] index1_im [0:511], index2_im [0:511]; 
    // ============================================
    // Instance: module0
    // ============================================
    module0 u1_module0 (
        .clk         (clk),
        .rstn        (rstn),
        .valid_input (data_valid),
        .data_input_i(din_i),
        .data_input_q(din_q),
        .valid_output(module_0_valid),
        .bfly02_i    (bfly02_i),
        .bfly02_q    (bfly02_q),
        .index1_re(index1_re),
        .index1_im(index1_im)
    );

    // ============================================
    // Instance: module1 (bfly10 stage)
    // ============================================
    module1 u2_module1 (
        .clk          (clk),
        .rstn         (rstn),
        .valid_input  (module_0_valid),
        .bfly02_i     (bfly02_i),
        .bfly02_q     (bfly02_q),
        .valid_output (module_1_valid),
        .bfly12_i     (bfly12_i),
        .bfly12_q     (bfly12_q),
        .index2_re(index2_re),
        .index2_im(index2_im)
    );

    module2 u2_module2 (
        .clk(clk),
        .rstn(rstn),
        .valid_input(module_1_valid), // valid from previous stage (bfly02 done)

        .bfly12_i(bfly12_i),
        .bfly12_q(bfly12_q),
        .index1_re(index1_re),
        .index1_im(index1_im),
        .index2_re(index2_re),
        .index2_im(index2_im),
        .valid_output(module_2_valid),  // valid for next stage
        .bfly22_i(bfly22_i),
        .bfly22_q(bfly22_q)
    );

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            do_en <= 0;
        end else begin
            do_en <= module_2_valid; // module_2_valid가 HIGH였던 다음 클럭에 do_en HIGH
        end
    end

    reverse u2_reverse (
        .re_bfly22(bfly22_i),
        .im_bfly22(bfly22_q),
        .re_dout(do_re),
        .im_dout(do_im)
    );
endmodule
