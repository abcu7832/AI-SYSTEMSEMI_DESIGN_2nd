`timescale 1ns / 1ps

module module1 #(
    parameter TOTAL_SIZE   = 512,
    parameter WIDTH_BF_IN  = 11,   // Input bit width
    parameter WIDTH_BF_OUT = 12   // Output bit width 
) (
    input logic clk,
    input logic rstn,
    input logic valid_input, // valid from previous stage (bfly02 done)

    input logic signed [WIDTH_BF_IN-1:0] bfly02_i[0:TOTAL_SIZE-1],
    input logic signed [WIDTH_BF_IN-1:0] bfly02_q[0:TOTAL_SIZE-1],

    output logic valid_output,  // valid for next stage
    output logic signed [WIDTH_BF_OUT-1:0] bfly12_i[0:TOTAL_SIZE-1],
    output logic signed [WIDTH_BF_OUT-1:0] bfly12_q[0:TOTAL_SIZE-1],

    output logic [4:0] index2_re [0:511],
    output logic [4:0] index2_im [0:511]
);

    // ============================================
    // VALID PIPELINE (PIPE_WIDTH same as stage latency)
    // ============================================
    localparam PIPE_WIDTH = 30;  // bf2 stage latency (1 cycle) + output reg
    logic [PIPE_WIDTH-1:0] valid_pipe_vector;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) valid_pipe_vector <= 0;
        else
            valid_pipe_vector <= {
                valid_pipe_vector[PIPE_WIDTH-2:0], valid_input
            };
    end

    logic signed [11:0] bfly10_i[0:TOTAL_SIZE-1];
    logic signed [11:0] bfly10_q[0:TOTAL_SIZE-1];
    
    // ============================================
    // Butterfly Stage: 8 blocks × 32 pairs = 256 butterflies
    // ============================================
    genvar kk, nn;
    generate
        for (kk = 0; kk < 8; kk++) begin : GEN_BF2_STAGE10
            for (nn = 0; nn < 32; nn++) begin : GEN_BF2_PAIR
                bf2_module #(
                    .WIDTH_IN (WIDTH_BF_IN),
                    .WIDTH_OUT(WIDTH_BF_OUT)
                ) u_bf2_stage10 (
                    .clk       (clk),
                    .rstn      (rstn),
                    .a_re      (bfly02_i[kk*64+nn]),
                    .a_im      (bfly02_q[kk*64+nn]),
                    .b_re      (bfly02_i[kk*64+32+nn]),
                    .b_im      (bfly02_q[kk*64+32+nn]),
                    .valid_data(valid_pipe_vector),
                    .y0_re     (bfly10_i[kk*64+nn]),
                    .y0_im     (bfly10_q[kk*64+nn]),
                    .y1_re     (bfly10_i[kk*64+32+nn]),
                    .y1_im     (bfly10_q[kk*64+32+nn])
                );
            end
        end
    endgenerate

    logic valid_bf0_out;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) valid_bf0_out <= 0;
        else valid_bf0_out <= valid_pipe_vector[1];
    end


    // ============================================
    // Saturation Stage (bfly02_tmp → sat_out)
    // ============================================
    localparam WIDTH_BF4_OUT = WIDTH_BF_IN + 1;  // 11 + 1
    logic signed [WIDTH_BF4_OUT-1:0] sat_out_i [0:TOTAL_SIZE-1];
    logic signed [WIDTH_BF4_OUT-1:0] sat_out_q [0:TOTAL_SIZE-1];
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
                .din_re   (bfly10_i[s]),
                .din_im   (bfly10_q[s]),
                .valid_in (valid_bf0_out),
                .dout_re  (sat_out_i[s]),
                .dout_im  (sat_out_q[s]),
                .valid_out()                // not in use
            );
        end
    endgenerate

    logic valid_saturation_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_saturation_out <= 0;
        end else begin
            valid_saturation_out <= valid_pipe_vector[2];
        end
    end

    // ============================================
    // Stage: bfly10((kk-1)*64+nn) = bfly10_tmp((kk-1)*64+nn)*fac8_0(ceil(nn/16));  %  (12 bit)
    // ============================================
    logic signed [WIDTH_BF4_OUT-1:0] bfly10_tmp_out_i[0:TOTAL_SIZE-1];
    logic signed [WIDTH_BF4_OUT-1:0] bfly10_tmp_out_q[0:TOTAL_SIZE-1];

    genvar j;
    generate
        for (j = 0; j < TOTAL_SIZE; j = j + 1) begin : GEN_FAC8_0
            fac8_0 #(
                .WIDTH(WIDTH_BF4_OUT),
                .INDEX_WIDTH($clog2(TOTAL_SIZE))
            ) u1_fac8_0 (
                .clk  (clk),
                .rstn (rstn),
                .index(((j % 64) >> 4) * 128),
                .a_re (sat_out_i[j]),
                .a_im (sat_out_q[j]),
                .b_re ({WIDTH_BF4_OUT{1'b0}}),
                .b_im ({WIDTH_BF4_OUT{1'b0}}),
                .y0_re(bfly10_tmp_out_i[j]),
                .y0_im(bfly10_tmp_out_q[j]),
                .y1_re(),
                .y1_im()
            );
        end
    endgenerate

    //valid for fac8_0 
    logic valid_fac8_0_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_fac8_0_out <= 0;
        end else begin
            valid_fac8_0_out <= valid_pipe_vector[5];  // one cycle 
        end
    end
    // ============================================
    // Stage: bfly11_tmp (BF2 operation on 32-point blocks)
    // ============================================
    logic signed [WIDTH_BF_OUT:0] bfly11_tmp_i[0:TOTAL_SIZE-1];  // +1 bit
    logic signed [WIDTH_BF_OUT:0] bfly11_tmp_q[0:TOTAL_SIZE-1];

    generate
        for (kk = 0; kk < 16; kk++) begin : GEN_BF11_STAGE
            for (nn = 0; nn < 16; nn++) begin : GEN_BF11_PAIR
                bf2_module #(
                    .WIDTH_IN (WIDTH_BF4_OUT),  // 입력: bfly10_tmp_out 비트폭
                    .WIDTH_OUT(WIDTH_BF_OUT + 1)  // 출력: +1 bit (ex: 12->13)
                ) u_bf2 (
                    .clk(clk),
                    .rstn(rstn),
                    .a_re(bfly10_tmp_out_i[kk*32+nn]),
                    .a_im(bfly10_tmp_out_q[kk*32+nn]),
                    .b_re(bfly10_tmp_out_i[kk*32+16+nn]),
                    .b_im(bfly10_tmp_out_q[kk*32+16+nn]),
                    .valid_data(valid_fac8_0_out),
                    .y0_re(bfly11_tmp_i[kk*32+nn]),
                    .y0_im(bfly11_tmp_q[kk*32+nn]),
                    .y1_re(bfly11_tmp_i[kk*32+16+nn]),
                    .y1_im(bfly11_tmp_q[kk*32+16+nn])
                );
            end
        end
    endgenerate

    logic valid_bfly11_tmp;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) valid_bfly11_tmp <= 1'b0;
        else valid_bfly11_tmp <= valid_pipe_vector[7];  // BF2 valid 연결
    end

    // ============================================
    // Stage: temp_bfly11
    // ============================================
    localparam WIDTH_TEMP = 23;  // 11 + 10 = 21
    logic signed [           9:0] w_re_arr              [0:TOTAL_SIZE-1];
    logic signed [           9:0] w_im_arr              [0:TOTAL_SIZE-1];
    logic signed [WIDTH_TEMP-1:0] temp_bfly11_i         [0:TOTAL_SIZE-1];
    logic signed [WIDTH_TEMP-1:0] temp_bfly11_q         [0:TOTAL_SIZE-1];
    logic        [TOTAL_SIZE-1:0] valid_temp_bfly01_vec;

    genvar i;
    generate
        for (i = 0; i < 512; i = i + 1) begin : MUL_STAGE_1
            fac8_1_rom u_rom (
                .clk (clk),
                .rstn(rstn),
                .addr((i % 64) >> 3),  // i / 64
                .w_re(w_re_arr[i]),
                .w_im(w_im_arr[i])
            );

            multiply #(
                .WIDTH_IN (13),
                .WIDTH_W  (10),
                .WIDTH_OUT(23)
            ) u1_mul (
                .clk     (clk),
                .rstn    (rstn),
                .valid_in(valid_bfly11_tmp),
                .a_re    (bfly11_tmp_i[i]),
                .a_im    (bfly11_tmp_q[i]),
                .w_re    (w_re_arr[i]),
                .w_im    (w_im_arr[i]),
                .y_re    (temp_bfly11_i[i]),
                .y_im    (temp_bfly11_q[i])
            );
        end
    endgenerate

    logic valid_temp_bfly11_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_temp_bfly11_out <= 0;
        end else begin
            valid_temp_bfly11_out <= valid_pipe_vector[11];
        end
    end


    // ============================================
    // Stage: Scaled output storage for bfly11
    // ============================================ 
    localparam WIDTH_BFLY_OUT = 14;  // scale_shift_round output bit width
    logic signed [WIDTH_BFLY_OUT-1:0] bfly11_i[0:TOTAL_SIZE-1];
    logic signed [WIDTH_BFLY_OUT-1:0] bfly11_q[0:TOTAL_SIZE-1];

    genvar idx;
    generate
        for (idx = 0; idx < TOTAL_SIZE; idx++) begin : GEN_SCALE_SHIFT_ROUND
            scale_shift_round #(
                .WIDTH_IN (WIDTH_TEMP),  // 23bit
                .WIDTH_OUT(14),
                .SHIFT    (8),
                .ROUND    (1)
            ) u1_scale_shift_round (
                .clk      (clk),
                .rstn     (rstn),
                .din_re   (temp_bfly11_i[idx]),
                .din_im   (temp_bfly11_q[idx]),
                .valid_in (valid_temp_bfly11_out),
                .dout_re  (bfly11_i[idx]),
                .dout_im  (bfly11_q[idx]),
                .valid_out()                        // Not used
            );
        end
    endgenerate
    logic valid_bfly11_out;

    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_bfly11_out <= 0;
        end else begin
            valid_bfly11_out <= valid_pipe_vector[14];
        end
    end


    // ============================================
    // Stage: bfly12_tmp
    // ============================================

    localparam WIDTH_BF12_IN = 14;
    localparam WIDTH_BF12_OUT = 15;

    logic signed [WIDTH_BF12_OUT-1:0] bfly12_tmp_i[0:TOTAL_SIZE-1];
    logic signed [WIDTH_BF12_OUT-1:0] bfly12_tmp_q[0:TOTAL_SIZE-1];

    genvar kkk, nnn;
    generate
        for (kkk = 0; kkk < 32; kkk++) begin : GEN_BF2_STAGE02
            for (nnn = 0; nnn < 8; nnn++) begin
                bf2_module #(
                    .WIDTH_IN (WIDTH_BF12_IN),
                    .WIDTH_OUT(WIDTH_BF12_OUT)
                ) u3_bf2 (
                    .clk       (clk),
                    .rstn      (rstn),
                    .a_re      (bfly11_i[kkk*16+nnn]),
                    .a_im      (bfly11_q[kkk*16+nnn]),
                    .b_re      (bfly11_i[kkk*16+8+nnn]),
                    .b_im      (bfly11_q[kkk*16+8+nnn]),
                    .valid_data(valid_bfly11_out),
                    .y0_re     (bfly12_tmp_i[kkk*16+nnn]),
                    .y0_im     (bfly12_tmp_q[kkk*16+nnn]),
                    .y1_re     (bfly12_tmp_i[kkk*16+8+nnn]),
                    .y1_im     (bfly12_tmp_q[kkk*16+8+nnn])
                );
            end
        end
    endgenerate

    logic valid_bfly12_tmp_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_bfly12_tmp_out <= 0;
        end else begin
            valid_bfly12_tmp_out <= valid_pipe_vector[15];
        end
    end

    // ============================================
    // Stage: pre_bfly02 = bfly02_tmp * twf_m0
    // ============================================
    localparam WIDTH_TWF = 10;  // Twiddle width
    localparam WIDTH_MULIN = 15;
    localparam WIDTH_MULOUT = 25;  // Multiply output width 

    logic signed [WIDTH_TWF-1:0] twf_re_arr[0:TOTAL_SIZE-1];
    logic signed [WIDTH_TWF-1:0] twf_im_arr[0:TOTAL_SIZE-1];

    logic signed [WIDTH_MULOUT-1:0] pre_bfly12_i[0:TOTAL_SIZE-1];
    logic signed [WIDTH_MULOUT-1:0] pre_bfly12_q[0:TOTAL_SIZE-1];

    genvar m;
    generate
        for (m = 0; m < TOTAL_SIZE; m++) begin : GEN_PRE_BFLY12
            // Twiddle Factor ROM instance
            twf_m1_rom u1_rom (
                .clk (clk),
                .addr((m % 64)),
                .w_re(twf_re_arr[m]),
                .w_im(twf_im_arr[m])
            );

            // Multiply instance
            multiply #(
                .WIDTH_IN (WIDTH_MULIN),
                .WIDTH_W  (WIDTH_TWF),
                .WIDTH_OUT(WIDTH_MULOUT)
            ) u3_mul (
                .clk(clk),
                .rstn(rstn),
                .valid_in(valid_bfly12_tmp_out),
                .a_re(bfly12_tmp_i[m]),
                .a_im(bfly12_tmp_q[m]),
                .w_re(twf_re_arr[m]),
                .w_im(twf_im_arr[m]),
                .y_re(pre_bfly12_i[m]),
                .y_im(pre_bfly12_q[m])
            );
        end
    endgenerate

    logic valid_mul_twf_m1_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_mul_twf_m1_out <= 0;
        end else begin
            valid_mul_twf_m1_out <= valid_pipe_vector[19];
        end
    end

    // ============================================
    // Flaten from BF MUL TO CBFP_02
    // ============================================
    logic signed [24:0] pre_bfly12_real_buf[0:511];
    logic signed [24:0] pre_bfly12_imag_buf[0:511];

    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < TOTAL_SIZE; i++) begin
                pre_bfly12_real_buf[i] <= 0;
                pre_bfly12_imag_buf[i] <= 0;
            end
        end else begin
            if (valid_mul_twf_m1_out) begin
                for (int i = 0; i < TOTAL_SIZE; i++) begin
                    pre_bfly12_real_buf[i] <= pre_bfly12_i[i];
                    pre_bfly12_imag_buf[i] <= pre_bfly12_q[i];
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
    // Stage: CBFP_12 (Post pre_bfly12 → Scaling)
    // ============================================
    CBFP_12 u1_cbfp_12 (
        .clk(clk),
        .rstn(rstn),
        .start(valid_mul_twf_m1_out),  // twiddle multiply stage 완료 후 시작
        .pre_bfly12_real(pre_bfly12_real_buf),  // 이전 스테이지 출력
        .pre_bfly12_imag(pre_bfly12_imag_buf),  // 이전 스테이지 출력
        .re_bfly12(bfly12_i),  // 최종 출력 (Real)
        .im_bfly12(bfly12_q),  // 최종 출력 (Imag)
        .index2_re(index2_re),  // CBFP 인덱스 (Real)
        .index2_im(index2_im),  // CBFP 인덱스 (Imag)
        .over(valid_output)  // 완료 플래그
    );

endmodule
