`timescale 1ns / 1ps

module module0 #(
    parameter P_SIZE      = 16,
    parameter TOTAL_SIZE  = 512,  // 512 POINTS
    parameter WIDTH_INPUT = 9    // DATA INPUT TO MODULE WIDTH
) (
    //module input and output ports
    input clk,
    input rstn,
    input valid_input,
    input logic signed [WIDTH_INPUT-1:0] data_input_i[P_SIZE -1:0],
    input logic signed [WIDTH_INPUT-1:0] data_input_q[P_SIZE -1:0],
    output valid_output,
    output logic signed [10:0] bfly02_i[TOTAL_SIZE-1:0],  // 11bit [512]
    output logic signed [10:0] bfly02_q[TOTAL_SIZE-1:0],
    output logic [4:0] index1_re [0:511],
    output logic [4:0] index1_im [0:511]
);
    localparam WIDTH_BF2 = 10;
    // Detect edge
    logic s2p_valid_pulse;
    edge_detect u1_edge_detect (
        .clk      (clk),
        .rstn     (rstn),
        .sig_in   (valid_input),
        .pulse_out(s2p_valid_pulse)
    );
    // ============================================
    // Stage: Memory for 512-point data, every 16 data points are stored parallel and then output 512 at once.
    // ============================================
    logic signed [WIDTH_INPUT-1:0] mem_i[TOTAL_SIZE-1:0];
    logic signed [WIDTH_INPUT-1:0] mem_q[TOTAL_SIZE-1:0];
    logic mem_valid;

    temp_mem #(
        .P_SIZE    (P_SIZE),
        .TOTAL_SIZE(TOTAL_SIZE),
        .WIDTH     (WIDTH_INPUT)
    ) u1_temp_mem (
        .clk      (clk),
        .rstn     (rstn),
        .s_to_p_i (data_input_i),
        .s_to_p_q (data_input_q),
        .valid_in (s2p_valid_pulse),
        .mem_i    (mem_i),
        .mem_q    (mem_q),
        .valid_out(mem_valid)
    );

    // VALID REGISTER PIPES
    //Below are the Valid pipe timings
    /*
    |===============================================|
    |NUM|   Modules                          Cycles |
    |===|===========================================|
    |1  |BF2 First BF (GEN_BF2)               1 cycle |
    |2  |fac8_0                               1 cycle |
    |3  |BF2(bfly01)                       1 cycle |
    |4  |Multiply (fac8_1)                   3 cycle |
    |5  |scale_shift_round                   3 cycle |
    |6  |BF2 Stage02 (bfly02_tmp)           1 cycle |
    |7  |Saturation   1 + EXTRA_DELAY(3) =    4 cycle |
    |8  |Twiddle Multiply                   3 cycle |
    |===============================================|
    */
    localparam PIPE_WIDTH = 21;  //Total Cycle of Module0
    logic [PIPE_WIDTH - 1:0] valid_pipe_vector;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_pipe_vector <= 0;
        end else begin
            valid_pipe_vector <= {valid_pipe_vector[PIPE_WIDTH-2:0], mem_valid};
        end
    end

    // ============================================
    // Stage: BF2 stage: 256 pairs, WIDTH_BF2   = 10, WIDTH_INPUT = 9
    // ============================================
    localparam HALF = TOTAL_SIZE / 2;  // (512 / 2) = 256
    logic signed [WIDTH_BF2-1:0] processed_i[TOTAL_SIZE-1:0];
    logic signed [WIDTH_BF2-1:0] processed_q[TOTAL_SIZE-1:0];
    logic        [     HALF-1:0] valid_vec;

    genvar i;
    generate
        for (i = 0; i < HALF; i = i + 1) begin : GEN_BF2
            bf2_module #(
                .WIDTH_IN (WIDTH_INPUT),
                .WIDTH_OUT(WIDTH_BF2)
            ) u1_bf2 (
                .clk       (clk),
                .rstn      (rstn),
                .a_re      (mem_i[i]),
                .a_im      (mem_q[i]),
                .b_re      (mem_i[i+HALF]),
                .b_im      (mem_q[i+HALF]),
                .valid_data(mem_valid),
                .y0_re     (processed_i[i]),       // a+b
                .y0_im     (processed_q[i]),
                .y1_re     (processed_i[i+HALF]),  // a-b
                .y1_im     (processed_q[i+HALF])
            );
        end
    endgenerate

    //valid for bf module
    logic valid_bf2_out;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) valid_bf2_out <= 1'b0;
        else
            valid_bf2_out <= valid_pipe_vector[0];  // temp_mem의 done(512개 샘플 완료)
    end

    // ============================================
    // Stage: bfly00_tmp(nn)*fac8_0(ceil(nn/128)) 1 1 1 -j  WIDTH_BF2   = 10, WIDTH_INPUT = 9
    // ============================================
    logic signed [WIDTH_BF2-1:0] bfly00_tmp_out_i[TOTAL_SIZE-1:0];
    logic signed [WIDTH_BF2-1:0] bfly00_tmp_out_q[TOTAL_SIZE-1:0];

    genvar j;
    generate
        for (j = 0; j < TOTAL_SIZE; j = j + 1) begin : GEN_FAC8_0
            fac8_0 #(
                .WIDTH(WIDTH_BF2),
                .INDEX_WIDTH($clog2(TOTAL_SIZE))
            ) u1_fac8_0 (
                .clk  (clk),
                .rstn (rstn),
                .index(j[$clog2(TOTAL_SIZE)-1:0]),
                .a_re (processed_i[j]),
                .a_im (processed_q[j]),
                .b_re ({WIDTH_BF2{1'b0}}),
                .b_im ({WIDTH_BF2{1'b0}}),
                .y0_re(bfly00_tmp_out_i[j]),
                .y0_im(bfly00_tmp_out_q[j]),
                .y1_re(),                           // unused
                .y1_im()                            // unused
            );
        end
    endgenerate

    //valid for fac8_0 
    logic valid_fac8_0_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_fac8_0_out <= 0;
        end else begin
            valid_fac8_0_out <= valid_pipe_vector[1];  // one cycle 
        end
    end

    // ============================================
    // Stage: bfly01_tmp
    // ============================================
    localparam WIDTH_BF3 = WIDTH_BF2 + 1;  // 10+1 = 11

    logic signed [WIDTH_BF3-1:0] bfly01_tmp_i[TOTAL_SIZE-1:0];
    logic signed [WIDTH_BF3-1:0] bfly01_tmp_q[TOTAL_SIZE-1:0];

    genvar blk;
    generate
        for (blk = 0; blk < 2; blk++) begin
            for (i = 0; i < 128; i++) begin
                bf2_module #(
                    .WIDTH_IN (WIDTH_BF2),
                    .WIDTH_OUT(WIDTH_BF3)
                ) u2_bf2 (
                    .clk       (clk),
                    .rstn      (rstn),
                    .a_re      (bfly00_tmp_out_i[blk*256+i]),
                    .a_im      (bfly00_tmp_out_q[blk*256+i]),
                    .b_re      (bfly00_tmp_out_i[blk*256+i+128]),
                    .b_im      (bfly00_tmp_out_q[blk*256+i+128]),
                    .valid_data(valid_fac8_0_out),
                    .y0_re     (bfly01_tmp_i[blk*256+i]),
                    .y0_im     (bfly01_tmp_q[blk*256+i]),
                    .y1_re     (bfly01_tmp_i[blk*256+i+128]),
                    .y1_im     (bfly01_tmp_q[blk*256+i+128])
                );
            end
        end
    endgenerate

    logic valid_bfly01_tmp_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_bfly01_tmp_out <= 0;
        end else begin
            valid_bfly01_tmp_out <= valid_pipe_vector[2];  // one cycle 
        end
    end

    // ============================================
    // Stage: temp_bfly01
    // ============================================
    localparam WIDTH_TEMP = 21;  // 11 + 10 = 21
    logic signed [           9:0] w_re_arr              [TOTAL_SIZE-1:0];
    logic signed [           9:0] w_im_arr              [TOTAL_SIZE-1:0];
    logic signed [WIDTH_TEMP-1:0] temp_bfly01_i         [TOTAL_SIZE-1:0];
    logic signed [WIDTH_TEMP-1:0] temp_bfly01_q         [TOTAL_SIZE-1:0];
    logic        [TOTAL_SIZE-1:0] valid_temp_bfly01_vec;

    generate
        for (i = 0; i < 512; i = i + 1) begin : MUL_STAGE_1
            fac8_1_rom u_rom (
                .clk (clk),
                .rstn(rstn),
                .addr(i[8:6]),       // i / 64
                .w_re(w_re_arr[i]),
                .w_im(w_im_arr[i])
            );

            multiply #(
                .WIDTH_IN (11),
                .WIDTH_W  (10),
                .WIDTH_OUT(21)
            ) u1_mul (
                .clk     (clk),
                .rstn    (rstn),
                .valid_in(valid_bfly01_tmp_out),
                .a_re    (bfly01_tmp_i[i]),
                .a_im    (bfly01_tmp_q[i]),
                .w_re    (w_re_arr[i]),
                .w_im    (w_im_arr[i]),
                .y_re    (temp_bfly01_i[i]),
                .y_im    (temp_bfly01_q[i])
            );
        end
    endgenerate

    logic valid_temp_bfly01_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_temp_bfly01_out <= 0;
        end else begin
            valid_temp_bfly01_out <= valid_pipe_vector[4];
        end
    end

    // ============================================
    // Stage: Scaled output storage for bfly01
    // ============================================ 
    localparam WIDTH_BFLY_OUT = 12;  // scale_shift_round output bit width
    logic signed [WIDTH_BFLY_OUT-1:0] bfly01_i[TOTAL_SIZE-1:0];
    logic signed [WIDTH_BFLY_OUT-1:0] bfly01_q[TOTAL_SIZE-1:0];

    genvar idx;
    generate
        for (idx = 0; idx < TOTAL_SIZE; idx++) begin : GEN_SCALE_SHIFT_ROUND
            scale_shift_round #(
                .WIDTH_IN (WIDTH_TEMP),  // 21bit
                .WIDTH_OUT(12),
                .SHIFT    (8),
                .ROUND    (1)
            ) u1_scale_shift_round (
                .clk      (clk),
                .rstn     (rstn),
                .din_re   (temp_bfly01_i[idx]),
                .din_im   (temp_bfly01_q[idx]),
                .valid_in (valid_temp_bfly01_out),
                .dout_re  (bfly01_i[idx]),
                .dout_im  (bfly01_q[idx]),
                .valid_out() // Not used
            );
        end
    endgenerate
    logic valid_bfly01_out;

    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_bfly01_out <= 0;
        end else begin
            valid_bfly01_out <= valid_pipe_vector[5];
        end
    end

    // ============================================
    // Stage: bfly02_tmp
    // ============================================

    localparam WIDTH_BF4_IN = WIDTH_BF3 + 1;  // 이전 단계 출력 (예: 12bit) 11+ 1
    localparam WIDTH_BF4_OUT = WIDTH_BF3 + 2;  // add/sub 결과 (예: 13bit)13 = 11 + 2 

    logic signed [WIDTH_BF4_OUT-1:0] bfly02_tmp_i[TOTAL_SIZE-1:0];
    logic signed [WIDTH_BF4_OUT-1:0] bfly02_tmp_q[TOTAL_SIZE-1:0];

    genvar kk, nn;
    generate
        for (kk = 0; kk < 4; kk++) begin : GEN_BF2_STAGE02
            for (nn = 0; nn < 64; nn++) begin
                bf2_module #(
                    .WIDTH_IN (WIDTH_BF4_IN),
                    .WIDTH_OUT(WIDTH_BF4_OUT)
                ) u3_bf2 (
                    .clk       (clk),
                    .rstn      (rstn),
                    .a_re      (bfly01_i[kk*128+nn]),
                    .a_im      (bfly01_q[kk*128+nn]),
                    .b_re      (bfly01_i[kk*128+64+nn]),
                    .b_im      (bfly01_q[kk*128+64+nn]),
                    .valid_data(valid_bfly01_out),
                    .y0_re     (bfly02_tmp_i[kk*128+nn]),
                    .y0_im     (bfly02_tmp_q[kk*128+nn]),
                    .y1_re     (bfly02_tmp_i[kk*128+64+nn]),
                    .y1_im     (bfly02_tmp_q[kk*128+64+nn])
                );
            end
        end
    endgenerate

    logic valid_bfly02_tmp_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_bfly02_tmp_out <= 0;
        end else begin
            valid_bfly02_tmp_out <= valid_pipe_vector[8];
        end
    end

    // ============================================
    // Saturation Stage (bfly02_tmp → sat_out)
    // ============================================
    logic signed [WIDTH_BF4_OUT-1:0] sat_out_i [TOTAL_SIZE-1:0];
    logic signed [WIDTH_BF4_OUT-1:0] sat_out_q [TOTAL_SIZE-1:0];
    logic                            valid_sat;

    genvar s;
    generate
        for (s = 0; s < TOTAL_SIZE; s++) begin : GEN_SAT
            saturation #(
                .WIDTH_IN   (WIDTH_BF4_OUT), // 입력: bfly02_tmp 비트폭 (13bit)
                .WIDTH_OUT(WIDTH_BF4_OUT),  // 출력: 동일 (13bit)
                .EXTRA_DELAY(3)  // 파이프라인 여유 //2, 3이 맞게 나옴                                 
            ) u1_sat (
                .clk      (clk),
                .rstn     (rstn),
                .din_re   (bfly02_tmp_i[s]),
                .din_im   (bfly02_tmp_q[s]),
                .valid_in (valid_bfly02_tmp_out),
                .dout_re  (sat_out_i[s]),
                .dout_im  (sat_out_q[s]),
                .valid_out()                       // not in use
            );
        end
    endgenerate

    logic valid_saturation_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_saturation_out <= 0;
        end else begin
            valid_saturation_out <= valid_pipe_vector[13];
        end
    end

    // ============================================
    // Stage: pre_bfly02 = bfly02_tmp * twf_m0
    // ============================================
    localparam WIDTH_TWF = 10;  // Twiddle width
    localparam WIDTH_MULOUT = 24;  // Multiply output width (13+10)

    logic signed [WIDTH_TWF-1:0] twf_re_arr[TOTAL_SIZE-1:0];
    logic signed [WIDTH_TWF-1:0] twf_im_arr[TOTAL_SIZE-1:0];

    logic signed [WIDTH_MULOUT-1:0] pre_bfly02_i[TOTAL_SIZE-1:0];
    logic signed [WIDTH_MULOUT-1:0] pre_bfly02_q[TOTAL_SIZE-1:0];

    genvar m;
    generate
        for (m = 0; m < TOTAL_SIZE; m++) begin : GEN_PRE_BFLY02
            // Twiddle Factor ROM instance
            twf_m0_rom u_rom (
                .clk (clk),
                .addr(m[8:0]),
                .w_re(twf_re_arr[m]),
                .w_im(twf_im_arr[m])
            );

            // Multiply instance
            multiply #(
                .WIDTH_IN (WIDTH_BF4_OUT),
                .WIDTH_W  (WIDTH_TWF),
                .WIDTH_OUT(WIDTH_MULOUT)
            ) u3_mul (
                .clk(clk),
                .rstn(rstn),
                .valid_in(valid_saturation_out),
                .a_re(sat_out_i[m]),
                .a_im(sat_out_q[m]),
                .w_re(twf_re_arr[m]),
                .w_im(twf_im_arr[m]),
                .y_re(pre_bfly02_i[m]),
                .y_im(pre_bfly02_q[m])
            );
        end
    endgenerate

    logic valid_mul_twf_m0_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_mul_twf_m0_out <= 0;
        end else begin
            valid_mul_twf_m0_out <= valid_pipe_vector[19];
        end
    end

    // ============================================
    // Flaten from BF MUL TO CBFP_02
    // ============================================
    logic signed [22:0] pre_bfly02_real_buf[0:511];
    logic signed [22:0] pre_bfly02_imag_buf[0:511];

    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < TOTAL_SIZE; i++) begin
                pre_bfly02_real_buf[i] <= 0;
                pre_bfly02_imag_buf[i] <= 0;
            end
        end else begin
            if (valid_mul_twf_m0_out) begin
                for (int i = 0; i < TOTAL_SIZE; i++) begin
                    pre_bfly02_real_buf[i] <= pre_bfly02_i[i];
                    pre_bfly02_imag_buf[i] <= pre_bfly02_q[i];
                end
            end
        end
    end

    logic valid_start_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_start_out <= 0;
        end else begin
            valid_start_out <= valid_pipe_vector[20];
        end
    end

    // ============================================
    // CBFP_02 Instance (Scaling + Index outputs)
    // ============================================
    //logic signed [WIDTH_BF3-1:0] bfly02_i[TOTAL_SIZE-1:0];  // 11bit [512]
    //logic signed [WIDTH_BF3-1:0] bfly02_q[TOTAL_SIZE-1:0];

    CBFP_02 u1_cbfp02 (
        .clk            (clk),
        .rstn           (rstn),
        .start          (valid_start_out),      // 파이프라인 맞춘 start
        .pre_bfly02_real(pre_bfly02_real_buf),  // [0:511] 연결
        .pre_bfly02_imag(pre_bfly02_imag_buf),  // [0:511] 연결
        .re_bfly02      (bfly02_i),             // test 출력 11bit
        .im_bfly02      (bfly02_q),             // test 출력
        .index1_re      (index1_re),                     // 필요 시 연결
        .index1_im      (index1_im),                     // 필요 시 연결
        .over           (valid_output)             // 최종 valid 역할
    );
endmodule

// ===================================================
// Module: saturation
// Description: saturation
// ===================================================
module saturation #(
    parameter int WIDTH_IN    = 13,   // 입력 비트폭 (예: multiply 결과)
    parameter int WIDTH_OUT   = 13,   // 출력 비트폭 (sat 적용 후)
    parameter int EXTRA_DELAY = 2     // 추가 pipeline 단계
) (
    input  logic                        clk,
    input  logic                        rstn,
    input  logic signed [ WIDTH_IN-1:0] din_re,
    input  logic signed [ WIDTH_IN-1:0] din_im,
    input  logic                        valid_in,
    output logic signed [WIDTH_OUT-1:0] dout_re,
    output logic signed [WIDTH_OUT-1:0] dout_im,
    output logic                        valid_out
);

    // ===================================================
    // Saturation 기준값 계산
    // MAX = 2^(WIDTH_OUT-1) - 1
    // MIN = -2^(WIDTH_OUT-1)
    // ===================================================
    localparam signed [WIDTH_IN-1:0] MAX_VAL = (1 <<< (WIDTH_OUT - 1)) - 1;
    localparam signed [WIDTH_IN-1:0] MIN_VAL = -(1 <<< (WIDTH_OUT - 1));

    // ===================================================
    // Pipeline Stage 1: 입력 레지스터링
    // ===================================================
    logic signed [WIDTH_IN-1:0] stage1_re, stage1_im;
    logic stage1_valid;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            stage1_re    <= '0;
            stage1_im    <= '0;
            stage1_valid <= 1'b0;
        end else begin
            stage1_re    <= din_re;
            stage1_im    <= din_im;
            stage1_valid <= valid_in;
        end
    end

    // ===================================================
    // Pipeline Stage 2: Saturation 적용
    // ===================================================
    logic signed [WIDTH_OUT-1:0] stage2_re, stage2_im;
    logic stage2_valid;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            stage2_re    <= '0;
            stage2_im    <= '0;
            stage2_valid <= 1'b0;
        end else begin
            // Real part
            if (stage1_re > MAX_VAL) stage2_re <= MAX_VAL[WIDTH_OUT-1:0];
            else if (stage1_re < MIN_VAL) stage2_re <= MIN_VAL[WIDTH_OUT-1:0];
            else stage2_re <= stage1_re[WIDTH_OUT-1:0];

            // Imag part
            if (stage1_im > MAX_VAL) stage2_im <= MAX_VAL[WIDTH_OUT-1:0];
            else if (stage1_im < MIN_VAL) stage2_im <= MIN_VAL[WIDTH_OUT-1:0];
            else stage2_im <= stage1_im[WIDTH_OUT-1:0];

            stage2_valid <= stage1_valid;
        end
    end

    // ===================================================
    // Pipeline Stage 3: Extra Delay (타이밍 개선용)
    // ===================================================
    logic signed [WIDTH_OUT-1:0] stage_extra_re[EXTRA_DELAY-1:0];
    logic signed [WIDTH_OUT-1:0] stage_extra_im[EXTRA_DELAY-1:0];
    logic stage_extra_valid[EXTRA_DELAY-1:0];

    integer i;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < EXTRA_DELAY; i++) begin
                stage_extra_re[i]    <= '0;
                stage_extra_im[i]    <= '0;
                stage_extra_valid[i] <= 1'b0;
            end
        end else begin
            stage_extra_re[0]    <= stage2_re;
            stage_extra_im[0]    <= stage2_im;
            stage_extra_valid[0] <= stage2_valid;

            for (i = 1; i < EXTRA_DELAY; i++) begin
                stage_extra_re[i]    <= stage_extra_re[i-1];
                stage_extra_im[i]    <= stage_extra_im[i-1];
                stage_extra_valid[i] <= stage_extra_valid[i-1];
            end
        end
    end

    // ===================================================
    // 최종 출력
    // ===================================================
    assign dout_re   = stage_extra_re[EXTRA_DELAY-1];
    assign dout_im   = stage_extra_im[EXTRA_DELAY-1];
    assign valid_out = stage_extra_valid[EXTRA_DELAY-1];

endmodule


// ===================================================
// Module: scale_shift_round
// Description: scale shift and round
// ===================================================
module scale_shift_round #(
    parameter WIDTH_IN  = 21,
    parameter WIDTH_OUT = 11,
    parameter SHIFT     = 8,   //How many shifts
    parameter ROUND     = 1    //1 for round, 0 for no round operation
) (
    input  logic                        clk,
    input  logic                        rstn,
    input  logic signed [ WIDTH_IN-1:0] din_re,
    input  logic signed [ WIDTH_IN-1:0] din_im,
    input  logic                        valid_in,
    output logic signed [WIDTH_OUT-1:0] dout_re,
    output logic signed [WIDTH_OUT-1:0] dout_im,
    output logic                        valid_out
);

    // Stage 1: ROUND add offset
    logic signed [WIDTH_IN-1:0] stage1_re;
    logic signed [WIDTH_IN-1:0] stage1_im;
    logic                       stage1_valid;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            stage1_re    <= '0;
            stage1_im    <= '0;
            stage1_valid <= 1'b0;
        end else begin
            if (ROUND) begin
                stage1_re <= din_re + (1 <<< (SHIFT - 1));
                stage1_im <= din_im + (1 <<< (SHIFT - 1));
            end else begin
                stage1_re <= din_re;
                stage1_im <= din_im;
            end
            stage1_valid <= valid_in;
        end
    end

    // Stage 2: SHIFT
    logic signed [WIDTH_IN-1:0] stage2_re, stage2_im;
    logic stage2_valid;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            stage2_re    <= '0;
            stage2_im    <= '0;
            stage2_valid <= 1'b0;
        end else begin
            stage2_re    <= stage1_re >>> SHIFT;
            stage2_im    <= stage1_im >>> SHIFT;
            stage2_valid <= stage1_valid;
        end
    end

    // Stage 3: TRUNCATE to WIDTH_OUT
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout_re   <= '0;
            dout_im   <= '0;
            valid_out <= 1'b0;
        end else begin
            dout_re   <= stage2_re[WIDTH_OUT-1:0];
            dout_im   <= stage2_im[WIDTH_OUT-1:0];
            valid_out <= stage2_valid;
        end
    end

endmodule

// ===================================================
// Module: multiply
// Description: 
// ===================================================

module multiply #(
    parameter WIDTH_IN  = 11,
    parameter WIDTH_W   = 10,
    parameter WIDTH_OUT = 21
) (
    input                               clk,
    input                               rstn,
    input  logic                        valid_in,
    input  logic signed [ WIDTH_IN-1:0] a_re,
    input  logic signed [ WIDTH_IN-1:0] a_im,
    input  logic signed [  WIDTH_W-1:0] w_re,
    input  logic signed [  WIDTH_W-1:0] w_im,
    output logic signed [WIDTH_OUT-1:0] y_re,
    output logic signed [WIDTH_OUT-1:0] y_im
);
    logic signed [WIDTH_IN-1:0] a_re_reg;
    logic signed [WIDTH_IN-1:0] a_im_reg;
    logic signed [ WIDTH_W-1:0] w_re_reg;
    logic signed [ WIDTH_W-1:0] w_im_reg;
    //input values
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            a_re_reg <= 0;
            a_im_reg <= 0;
        end else begin
            a_re_reg <= a_re;
            a_im_reg <= a_im;
        end
    end
    //W values
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            w_re_reg <= 0;
            w_im_reg <= 0;
        end else begin
            w_re_reg <= w_re;
            w_im_reg <= w_im;
        end
    end

    logic signed [WIDTH_OUT-1:0] mul_rr_reg;
    logic signed [WIDTH_OUT-1:0] mul_ri_reg;
    logic signed [WIDTH_OUT-1:0] mul_ir_reg;
    logic signed [WIDTH_OUT-1:0] mul_ii_reg;

    //complex multiplication
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            mul_rr_reg <= 0;
            mul_ri_reg <= 0;
            mul_ir_reg <= 0;
            mul_ii_reg <= 0;
        end else begin
            mul_rr_reg <= a_re_reg * w_re_reg;
            mul_ri_reg <= a_re_reg * w_im_reg;
            mul_ir_reg <= a_im_reg * w_re_reg;
            mul_ii_reg <= a_im_reg * w_im_reg;
        end
    end

    logic signed [WIDTH_OUT-1:0] y_re_temp;
    logic signed [WIDTH_OUT-1:0] y_im_temp;

    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            y_re_temp <= 0;
            y_im_temp <= 0;
        end else begin
            y_re_temp <= mul_rr_reg - mul_ii_reg;
            y_im_temp <= mul_ri_reg + mul_ir_reg;
        end
    end

    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            y_re <= 0;
            y_im <= 0;
        end else begin
            y_re <= y_re_temp;
            y_im <= y_im_temp;
        end
    end
endmodule

// ===================================================
// Module: fac8_1_rom
// Description: fac8_rom => fac8_1 = [256, 256, 256, -j*256, 256, 181-j*181, 256, -181-j*181]
// ===================================================
module fac8_1_rom (
    input  logic              clk,
    input  logic              rstn,
    input  logic        [2:0] addr,  // index (0~7)
    output logic signed [9:0] w_re,  // 10-bit
    output logic signed [9:0] w_im
);

    logic signed [9:0] w_re_reg, w_im_reg;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            w_re_reg <= 10'sd0;
            w_im_reg <= 10'sd0;
        end else begin
            case (addr)
                3'd0: begin
                    w_re_reg <= 256;
                    w_im_reg <= 0;
                end
                3'd1: begin
                    w_re_reg <= 256;
                    w_im_reg <= 0;
                end
                3'd2: begin
                    w_re_reg <= 256;
                    w_im_reg <= 0;
                end
                3'd3: begin
                    w_re_reg <= 0;
                    w_im_reg <= -256;
                end
                3'd4: begin
                    w_re_reg <= 256;
                    w_im_reg <= 0;
                end
                3'd5: begin
                    w_re_reg <= 181;
                    w_im_reg <= -181;
                end
                3'd6: begin
                    w_re_reg <= 256;
                    w_im_reg <= 0;
                end
                3'd7: begin
                    w_re_reg <= -181;
                    w_im_reg <= -181;
                end
            endcase
        end
    end

    assign w_re = w_re_reg;
    assign w_im = w_im_reg;

endmodule

// ===================================================
// Module: fac8_0 selector
// Description: addition and subtraction bf module
// ===================================================
module fac8_0 #(
    parameter int WIDTH = 10,
    parameter int INDEX_WIDTH = 9
) (
    input                                 clk,
    input                                 rstn,
    input  logic        [INDEX_WIDTH-1:0] index,
    input  logic signed [      WIDTH-1:0] a_re,   // a+b
    input  logic signed [      WIDTH-1:0] a_im,   // a+b
    input  logic signed [      WIDTH-1:0] b_re,   // a-b
    input  logic signed [      WIDTH-1:0] b_im,   // a-b
    output logic signed [      WIDTH-1:0] y0_re,  // a+b
    output logic signed [      WIDTH-1:0] y0_im,  // a+b
    output logic signed [      WIDTH-1:0] y1_re,  // a-b
    output logic signed [      WIDTH-1:0] y1_im   // a-b
);

    logic                    fac8_0_select;
    logic signed [WIDTH-1:0] a_re_reg;
    logic signed [WIDTH-1:0] a_im_reg;
    logic signed [WIDTH-1:0] b_re_reg;
    logic signed [WIDTH-1:0] b_im_reg;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            a_re_reg <= 0;
            a_im_reg <= 0;
            b_re_reg <= 0;
            b_im_reg <= 0;
            fac8_0_select <= 0;
        end else begin
            a_re_reg <= a_re;
            a_im_reg <= a_im;
            b_re_reg <= b_re;
            b_im_reg <= b_im;
            fac8_0_select <= (index >= 384);  // 384부터 swap(-j) 적용!
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            y0_re <= 0;
            y0_im <= 0;
            y1_re <= 0;
            y1_im <= 0;
        end else begin
            if (fac8_0_select == 1) begin
                y0_re <= a_im_reg;  // swap(-j): Real = Imag
                y0_im <= -a_re_reg;  // Imag = -Real
                y1_re <= b_im_reg;
                y1_im <= -b_re_reg;
            end else begin
                y0_re <= a_re_reg;
                y0_im <= a_im_reg;
                y1_re <= b_re_reg;
                y1_im <= b_im_reg;
            end
        end
    end

endmodule

// ===================================================
// Module: bf module
// Description: addition and subtraction bf module
// ===================================================

module bf2_module #(
    parameter WIDTH_IN  = 9,
    parameter WIDTH_OUT = 10
) (
    input                               clk,
    input                               rstn,
    input  logic signed [ WIDTH_IN-1:0] a_re,
    input  logic signed [ WIDTH_IN-1:0] a_im,
    input  logic signed [ WIDTH_IN-1:0] b_re,
    input  logic signed [ WIDTH_IN-1:0] b_im,
    input                               valid_data,
    output logic signed [WIDTH_OUT-1:0] y0_re,       // a+b
    output logic signed [WIDTH_OUT-1:0] y0_im,       // a+b
    output logic signed [WIDTH_OUT-1:0] y1_re,       // a-b
    output logic signed [WIDTH_OUT-1:0] y1_im        // a-b
);

    logic signed [WIDTH_OUT-1:0] sum_re;
    logic signed [WIDTH_OUT-1:0] sum_im;
    logic signed [WIDTH_OUT-1:0] diff_re;
    logic signed [WIDTH_OUT-1:0] diff_im;
    logic                        valid_reg;

    assign sum_re  = a_re + b_re;
    assign sum_im  = a_im + b_im;
    assign diff_re = a_re - b_re;
    assign diff_im = a_im - b_im;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            y0_re     <= 0;
            y0_im     <= 0;
            y1_re     <= 0;
            y1_im     <= 0;
            valid_reg <= 0;
        end else begin
            y0_re     <= sum_re;
            y0_im     <= sum_im;
            y1_re     <= diff_re;
            y1_im     <= diff_im;
            valid_reg <= valid_data;
        end
    end

    assign valid_out = valid_reg;

endmodule

// ===================================================
// Module: temp_mem
// Description: Stores 16 parallel inputs into memory, block by block
// ===================================================
module temp_mem #(
    parameter P_SIZE     = 16,
    parameter TOTAL_SIZE = 512,
    parameter WIDTH      = 9
) (
    input clk,
    input rstn,
    input logic signed [WIDTH-1:0] s_to_p_i[P_SIZE-1:0],
    input logic signed [WIDTH-1:0] s_to_p_q[P_SIZE-1:0],
    input logic valid_in,  // s_to_p.valid_out
    output logic signed [WIDTH-1:0] mem_i[TOTAL_SIZE-1:0],
    output logic signed [WIDTH-1:0] mem_q[TOTAL_SIZE-1:0],
    output logic valid_out
);

    localparam BLOCKS = TOTAL_SIZE / P_SIZE;  // 512/16 = 32 blocks
    localparam ADDR_WIDTH = $clog2(TOTAL_SIZE);  // $clog2(512) = 9
    logic [ADDR_WIDTH-1:0] write_ptr;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            write_ptr <= 0;
            valid_out <= 0;
            for (int k = 0; k < TOTAL_SIZE; k++) begin
                mem_i[k] <= 0;
                mem_q[k] <= 0;
            end
        end else begin
            valid_out <= 0;
            if (valid_in) begin
                for (int i = 0; i < P_SIZE; i++) begin
                    mem_i[write_ptr+i] <= s_to_p_i[i];
                    mem_q[write_ptr+i] <= s_to_p_q[i];
                end
                write_ptr <= write_ptr + P_SIZE;

                if (write_ptr + P_SIZE >= TOTAL_SIZE) begin
                    valid_out <= 1;
                    write_ptr <= 0;
                end
            end
        end
    end
endmodule

// ===================================================
// Module: edge_detect
// Description: Detects rising edge of input signal and outputs 1-cycle pulse
// ===================================================
module edge_detect (
    input  logic clk,
    input  logic rstn,
    input  logic sig_in,
    output logic pulse_out
);

    logic sig_d;  // previous state

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) sig_d <= 0;
        else sig_d <= sig_in;
    end

    assign pulse_out = (sig_in && !sig_d);  // rising edge detect

endmodule
