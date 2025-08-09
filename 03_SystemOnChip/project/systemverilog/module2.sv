`timescale 1ns / 1ps

module module2 #(
    parameter TOTAL_SIZE   = 512,
    parameter WIDTH_BF_IN  = 12,   // Input bit width
    parameter WIDTH_BF_OUT = 12,   // Output bit width
    parameter WIDTH_TEST   = 26    // For debug/test output
) (
    input logic clk,
    input logic rstn,
    input logic valid_input, // valid from previous stage (bfly02 done)

    input logic signed [WIDTH_BF_IN-1:0] bfly12_i[0:TOTAL_SIZE-1],
    input logic signed [WIDTH_BF_IN-1:0] bfly12_q[0:TOTAL_SIZE-1],

    input logic [4:0] index1_re [0:511],
    input logic [4:0] index1_im [0:511],
    input logic [4:0] index2_re [0:511],
    input logic [4:0] index2_im [0:511],

    output logic valid_output,  // valid for next stage
    output logic signed [12:0] bfly22_i[0:TOTAL_SIZE-1],
    output logic signed [12:0] bfly22_q[0:TOTAL_SIZE-1]
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

    logic signed [12:0] bfly20_tmp_i[0:TOTAL_SIZE-1];
    logic signed [12:0] bfly20_tmp_q[0:TOTAL_SIZE-1];

    // ============================================
    // Butterfly Stage
    // ============================================
    genvar kk;
    generate
        for (kk = 0; kk < 64; kk++) begin : GEN_BF2_STAGE10   
            always @(posedge clk, negedge rstn) begin
                if(~rstn) begin
                    for(int mm = 0;mm<4;mm++) begin
                        bfly20_tmp_i[kk*8+mm] <= 0;
                        bfly20_tmp_q[kk*8+mm] <= 0;
                        bfly20_tmp_i[kk*8+4+mm] <= 0;
                        bfly20_tmp_q[kk*8+4+mm] <= 0;
                    end
                end else if(valid_input)begin
                    for(int nn = 0;nn<4;nn++) begin
                        bfly20_tmp_i[kk*8+nn] <= bfly12_i[kk*8+nn] + bfly12_i[kk*8+4+nn];
                        bfly20_tmp_q[kk*8+nn] <= bfly12_q[kk*8+nn] + bfly12_q[kk*8+4+nn];
                        bfly20_tmp_i[kk*8+4+nn] <= bfly12_i[kk*8+nn] - bfly12_i[kk*8+4+nn];
                        bfly20_tmp_q[kk*8+4+nn] <= bfly12_q[kk*8+nn] - bfly12_q[kk*8+4+nn];
                    end
                end
            end
        end
    endgenerate

    logic valid_bf0_out;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) valid_bf0_out <= 0;
        else valid_bf0_out <= valid_pipe_vector[0];
    end

    // ============================================
    // Stage: bfly20_tmp(nn)*fac8_0(ceil(nn/2)) 1 1 1 -j
    // ============================================
    logic signed [12:0] bfly20_i[0:TOTAL_SIZE-1];
    logic signed [12:0] bfly20_q[0:TOTAL_SIZE-1];
    localparam WIDTH_BF2 = 14;

    genvar j;
    generate
        for (j = 0; j < TOTAL_SIZE; j = j + 1) begin : GEN_FAC8_0
            fac8_0 #(
                .WIDTH(13),
                .INDEX_WIDTH($clog2(TOTAL_SIZE))
            ) u1_fac8_0 (
                .clk  (clk),
                .rstn (rstn),
                .index(j[2]&j[1]?384:0),
                .a_re (bfly20_tmp_i[j]),
                .a_im (bfly20_tmp_q[j]),
                .b_re ({WIDTH_BF2{1'b0}}),
                .b_im ({WIDTH_BF2{1'b0}}),
                .y0_re(bfly20_i[j]),
                .y0_im(bfly20_q[j]),
                .y1_re(),                           // unused
                .y1_im()                            // unused
            );
        end
    endgenerate

    logic valid_fac8_0_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_fac8_0_out <= 0;
        end else begin
            valid_fac8_0_out <= valid_pipe_vector[2]; 
        end
    end

    // ============================================
    // Stage: bfly21_tmp
    // ============================================
    logic signed [13:0] bfly21_tmp_i[TOTAL_SIZE-1:0];
    logic signed [13:0] bfly21_tmp_q[TOTAL_SIZE-1:0];

    genvar blk, i;
    generate
        for (blk = 0; blk < 128; blk++) begin
            for (i = 0; i < 2; i++) begin
                bf2_module #(
                    .WIDTH_IN (13),
                    .WIDTH_OUT(14)
                ) u2_bf2 (
                    .clk       (clk),
                    .rstn      (rstn),
                    .a_re      (bfly20_i[blk*4+i]),
                    .a_im      (bfly20_q[blk*4+i]),
                    .b_re      (bfly20_i[blk*4+i+2]),
                    .b_im      (bfly20_q[blk*4+i+2]),
                    .valid_data(valid_fac8_0_out),
                    .y0_re     (bfly21_tmp_i[blk*4+i]),
                    .y0_im     (bfly21_tmp_q[blk*4+i]),
                    .y1_re     (bfly21_tmp_i[blk*4+i+2]),
                    .y1_im     (bfly21_tmp_q[blk*4+i+2])
                );
            end
        end
    endgenerate

    logic valid_bfly01_tmp_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_bfly01_tmp_out <= 0;
        end else begin
            valid_bfly01_tmp_out <= valid_pipe_vector[7];  // one cycle 
        end
    end

    // ============================================
    // Saturation Stage (bfly02_tmp → sat_out)
    // ============================================
    logic signed [13:0] sat_out_i [0:TOTAL_SIZE-1];
    logic signed [13:0] sat_out_q [0:TOTAL_SIZE-1];

    genvar s;
    generate
        for (s = 0; s < TOTAL_SIZE; s++) begin : GEN_SAT1
            saturation #(
                .WIDTH_IN(14), // 입력: bfly02_tmp 비트폭 (13bit)
                .WIDTH_OUT(14),  // 출력: 동일 (13bit)
                .EXTRA_DELAY(3)  // 파이프라인 여유 //2, 3이 맞게 나옴                                 
            ) u1_sat (
                .clk      (clk),
                .rstn     (rstn),
                .din_re   (bfly21_tmp_i[s]),
                .din_im   (bfly21_tmp_q[s]),
                .valid_in (valid_bfly01_tmp_out),
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
            valid_saturation_out <= valid_pipe_vector[11];
        end
    end

    // ============================================
    // Stage: temp_bfly01
    // ============================================
    logic signed [9:0] w_re_arr [0:TOTAL_SIZE-1];
    logic signed [9:0] w_im_arr [0:TOTAL_SIZE-1];
    logic signed [23:0] temp_bfly21_i [0:TOTAL_SIZE-1];
    logic signed [23:0] temp_bfly21_q [0:TOTAL_SIZE-1];

    generate
        for (i = 0; i < 512; i = i + 1) begin : MUL_STAGE_1
            fac8_1_rom u_rom (
                .clk (clk),
                .rstn(rstn),
                .addr(i[2:0]),       // i % 8
                .w_re(w_re_arr[i]),
                .w_im(w_im_arr[i])
            );

            multiply #(
                .WIDTH_IN (14),
                .WIDTH_W  (10),
                .WIDTH_OUT(24)
            ) u1_mul (
                .clk     (clk),
                .rstn    (rstn),
                .valid_in(valid_saturation_out),
                .a_re    (sat_out_i[i]),
                .a_im    (sat_out_q[i]),
                .w_re    (w_re_arr[i]),
                .w_im    (w_im_arr[i]),
                .y_re    (temp_bfly21_i[i]),
                .y_im    (temp_bfly21_q[i])
            );
        end
    endgenerate

    logic valid_temp_bfly21_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_temp_bfly21_out <= 0;
        end else begin
            valid_temp_bfly21_out <= valid_pipe_vector[14];
        end
    end

    // ============================================
    // Stage: Scaled output storage for bfly21
    // ============================================ 
    logic signed [14:0] bfly21_i[0:TOTAL_SIZE-1];
    logic signed [14:0] bfly21_q[0:TOTAL_SIZE-1];

    genvar idx;
    generate
        for (idx = 0; idx < TOTAL_SIZE; idx++) begin : GEN_SCALE_SHIFT_ROUND
            scale_shift_round #(
                .WIDTH_IN (24),
                .WIDTH_OUT(15),
                .SHIFT    (8),
                .ROUND    (1)
            ) u1_scale_shift_round (
                .clk      (clk),
                .rstn     (rstn),
                .din_re   (temp_bfly21_i[idx]),
                .din_im   (temp_bfly21_q[idx]),
                .valid_in (valid_temp_bfly21_out),
                .dout_re  (bfly21_i[idx]),
                .dout_im  (bfly21_q[idx]),
                .valid_out()                        // Not used
            );
        end
    endgenerate
    logic valid_bfly21_out;

    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_bfly21_out <= 0;
        end else begin
            valid_bfly21_out <= valid_pipe_vector[15];
        end
    end

    // ============================================
    // Stage: bfly22_tmp
    // ============================================
    logic signed [15:0] bfly22_tmp_i[0:TOTAL_SIZE-1];
    logic signed [15:0] bfly22_tmp_q[0:TOTAL_SIZE-1];

    genvar kkk, nnn;
    generate
        for (kkk = 0; kkk < 256; kkk++) begin : GEN_BF2_STAGE02
            bf2_module #(
                .WIDTH_IN (15),
                .WIDTH_OUT(16)
            ) u3_bf2 (
                .clk       (clk),
                .rstn      (rstn),
                .a_re      (bfly21_i[kkk*2]),
                .a_im      (bfly21_q[kkk*2]),
                .b_re      (bfly21_i[kkk*2+1]),
                .b_im      (bfly21_q[kkk*2+1]),
                .valid_data(valid_bfly21_out),
                .y0_re     (bfly22_tmp_i[kkk*2]),
                .y0_im     (bfly22_tmp_q[kkk*2]),
                .y1_re     (bfly22_tmp_i[kkk*2+1]),
                .y1_im     (bfly22_tmp_q[kkk*2+1])
            );
        end
    endgenerate

    logic valid_bfly22_tmp_out;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_bfly22_tmp_out <= 0;
        end else begin
            valid_bfly22_tmp_out <= valid_pipe_vector[20];
        end
    end

    // ============================================
    // Saturation Stage (bfly02_tmp → sat_out)
    // ============================================
    logic signed [15:0] sat_out_i_1 [0:TOTAL_SIZE-1];
    logic signed [15:0] sat_out_q_1 [0:TOTAL_SIZE-1];

    genvar ss;
    generate
        for (ss = 0; ss < TOTAL_SIZE; ss++) begin : GEN_SAT2
            saturation #(
                .WIDTH_IN(16),
                .WIDTH_OUT(16), 
                .EXTRA_DELAY(3)
            ) u1_sat (
                .clk      (clk),
                .rstn     (rstn),
                .din_re   (bfly22_tmp_i[ss]),
                .din_im   (bfly22_tmp_q[ss]),
                .valid_in (valid_bfly22_tmp_out),
                .dout_re  (sat_out_i_1[ss]),// 16비트
                .dout_im  (sat_out_q_1[ss]),
                .valid_out()                // not in use
            );
        end
    endgenerate

    logic valid_saturation_out_1;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            valid_saturation_out_1 <= 0;
        end else begin
            valid_saturation_out_1 <= valid_pipe_vector[24];
        end
    end
/*
/////////////////////////////////////////////////
    always @(*) begin
        for(int i = 0;i<512;i++) begin
            test_out_i[i] = sat_out_i_1[i];
            test_out_q[i] = sat_out_q_1[i];
            bfly22_i[i] = sat_out_i_1[i];
            bfly22_q[i] = sat_out_q_1[i];
        end
    end
*/
    logic signed [6:0] indexsum_re [0:511];
    logic signed [6:0] indexsum_im [0:511];

    logic [4:0] cnt_idx;
    logic shift_ing, shift_over;

    always @(posedge clk, negedge rstn) begin
        if(~rstn) begin
            for(int finv = 0; finv < 512; finv++) begin
                indexsum_re[finv] <= 0;
                indexsum_im[finv] <= 0;
            end
            shift_over <= 0;
            shift_ing <= 0;
            cnt_idx <= 0;
        end else if(valid_input) begin
            for(int inv = 0; inv < 512; inv++) begin
                indexsum_re[inv] <= index1_re[inv] + index2_re[inv];
                indexsum_im[inv] <= index1_im[inv] + index2_im[inv];
            end
        end else if(valid_saturation_out_1 | shift_ing) begin
            for(int shift = 0;shift<16;shift++) begin
                /*integer tmp_i, tmp_q;
                if(indexsum_re[shift + cnt_idx*16]>=23) begin
                    bfly22_i[shift + cnt_idx*16] <= 0;
                end else if(9-indexsum_re[shift + cnt_idx*16]>=0) begin
                    tmp_i = (sat_out_i_1[shift + cnt_idx*16] <<< (9-indexsum_re[shift + cnt_idx*16]));
                    bfly22_i[shift + cnt_idx*16] <= tmp_i[12:0];
                end else begin
                    tmp_i <= (sat_out_i_1[shift + cnt_idx*16] >>> (indexsum_re[shift + cnt_idx*16]-9));
                    bfly22_i[shift + cnt_idx*16] <= tmp_i[12:0];
                end
                if(indexsum_im[shift + cnt_idx*16]>=23) begin
                    bfly22_q[shift + cnt_idx*16] <= 0;
                end else if(9-indexsum_im[shift + cnt_idx*16]>=0) begin
                    tmp_q <= (sat_out_q_1[shift + cnt_idx*16] <<< (9-indexsum_im[shift + cnt_idx*16]));
                    bfly22_q[shift + cnt_idx*16] <= tmp_q[12:0];
                end else begin
                    tmp_q <= (sat_out_q_1[shift + cnt_idx*16] >>> (indexsum_im[shift + cnt_idx*16]-9));
                    bfly22_q[shift + cnt_idx*16] <= tmp_q[12:0];
                end*/
                if(indexsum_re[shift + cnt_idx*16]>=23) begin
                    bfly22_i[shift + cnt_idx*16] <= 0;
                end else if(9-indexsum_re[shift + cnt_idx*16]>=0) begin
                    bfly22_i[shift + cnt_idx*16] <= (sat_out_i_1[shift + cnt_idx*16] <<< (9-indexsum_re[shift + cnt_idx*16]));
                end else begin
                    bfly22_i[shift + cnt_idx*16] <= (sat_out_i_1[shift + cnt_idx*16] >>> (indexsum_re[shift + cnt_idx*16]-9));
                end
                if(indexsum_im[shift + cnt_idx*16]>=23) begin
                    bfly22_q[shift + cnt_idx*16] <= 0;
                end else if(9-indexsum_im[shift + cnt_idx*16]>=0) begin
                    bfly22_q[shift + cnt_idx*16] <= (sat_out_q_1[shift + cnt_idx*16] <<< (9-indexsum_im[shift + cnt_idx*16]));
                end else begin
                    bfly22_q[shift + cnt_idx*16] <= (sat_out_q_1[shift + cnt_idx*16] >>> (indexsum_im[shift + cnt_idx*16]-9));
                end
            end
            if(cnt_idx == 31) begin
                shift_ing <= 0;
                shift_over <= 1;
            end else begin
                cnt_idx <= cnt_idx + 1;
                shift_ing <= 1;
            end
        end else begin
            if(shift_over == 1) begin
                shift_over <= 0;
            end
        end
    end

    assign valid_output = shift_over;
/////////////////////////////////////////////////
endmodule
