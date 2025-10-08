`timescale 1ns / 1ps

module CBFP02 #(
    parameter WIDTH_IN = 23,
    parameter WIDTH_OUT = 11,
    parameter NUM = 16
) (
    input  logic                        clk,
    input  logic                        rstn,
    input  logic                        en,
    input  logic signed [ WIDTH_IN-1:0] in_re    [0:NUM-1],
    input  logic signed [ WIDTH_IN-1:0] in_im    [0:NUM-1],
    output logic signed [WIDTH_OUT-1:0] out_re   [0:NUM-1],
    output logic signed [WIDTH_OUT-1:0] out_im   [0:NUM-1],
    output logic        [          4:0] cnt,
    output logic                        valid_out
);
    logic [5:0] count;

    // ------------------------
    // Stage 1: Headroom Detect
    // ------------------------
    logic [4:0] tmp1_re[0:NUM-1];
    logic [4:0] tmp1_im[0:NUM-1];

    genvar i;
    generate
        for (i = 0; i < NUM; i++) begin : GEN_HEADROOM
            headroom_detect_23 u_hd_re (
                .clk     (clk),
                .rstn    (rstn),
                .start   (en),
                .data_in (in_re[i]),
                .headroom(tmp1_re[i])
            );
            headroom_detect_23 u_hd_im (
                .clk     (clk),
                .rstn    (rstn),
                .start   (en),
                .data_in (in_im[i]),
                .headroom(tmp1_im[i])
            );
        end
    endgenerate

    logic signed [WIDTH_IN-1:0] buffer_reg_re_1[0:NUM-1];
    logic signed [WIDTH_IN-1:0] buffer_reg_im_1[0:NUM-1];
    logic signed [WIDTH_IN-1:0] buffer_reg_re_2[0:NUM-1];
    logic signed [WIDTH_IN-1:0] buffer_reg_im_2[0:NUM-1];
    logic signed [WIDTH_IN-1:0] buffer_reg_re_3[0:NUM-1];
    logic signed [WIDTH_IN-1:0] buffer_reg_im_3[0:NUM-1];
    logic signed [WIDTH_IN-1:0] buffer_reg_re_4[0:NUM-1];
    logic signed [WIDTH_IN-1:0] buffer_reg_im_4[0:NUM-1];
    logic signed [WIDTH_IN-1:0] buffer_reg_re_5[0:NUM-1];
    logic signed [WIDTH_IN-1:0] buffer_reg_im_5[0:NUM-1];
    logic signed [WIDTH_IN-1:0] buffer_reg_re_6[0:NUM-1];
    logic signed [WIDTH_IN-1:0] buffer_reg_im_6[0:NUM-1];
    logic valid_b1;
    logic valid_b2;
    logic valid_b3;
    logic valid_b4;
    logic valid_b5;
    logic valid_b6;
    logic valid_b7;

    assign valid_out = valid_b7;

    always @(posedge clk, negedge rstn) begin
        if (en || valid_b6) begin
            for (int b1 = 0; b1 < 16; b1 = b1 + 1) begin
                buffer_reg_re_1[b1] <= in_re[b1];
                buffer_reg_im_1[b1] <= in_im[b1];
                buffer_reg_re_2[b1] <= buffer_reg_re_1[b1];
                buffer_reg_im_2[b1] <= buffer_reg_im_1[b1];
                buffer_reg_re_3[b1] <= buffer_reg_re_2[b1];
                buffer_reg_im_3[b1] <= buffer_reg_im_2[b1];
                buffer_reg_re_4[b1] <= buffer_reg_re_3[b1];
                buffer_reg_im_4[b1] <= buffer_reg_im_3[b1];
                buffer_reg_re_5[b1] <= buffer_reg_re_4[b1];
                buffer_reg_im_5[b1] <= buffer_reg_im_4[b1];
                buffer_reg_re_6[b1] <= buffer_reg_re_5[b1];
                buffer_reg_im_6[b1] <= buffer_reg_im_5[b1];
            end
        end
        valid_b1 <= en;
        valid_b2 <= valid_b1;
        valid_b3 <= valid_b2;
        valid_b4 <= valid_b3;
        valid_b5 <= valid_b4;
        valid_b6 <= valid_b5;
        valid_b7 <= valid_b6;
    end
    // ------------------------
    // Stage 2: Block Min
    // ------------------------
    logic [4:0] temp1_re, temp1_im;
    always_comb begin
        temp1_re = tmp1_re[0];
        temp1_im = tmp1_im[0];
        for (int j = 1; j < NUM; j++) begin
            if (tmp1_re[j] < temp1_re) temp1_re = tmp1_re[j];
            if (tmp1_im[j] < temp1_im) temp1_im = tmp1_im[j];
        end
    end

    // ------------------------
    // Stage 3: Group Min (collect 4 blocks)
    // ------------------------
    logic [4:0] group_min [0:3];
    logic [1:0] group_idx;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int k = 0; k < 4; k++) begin
                group_min[k] <= 5'd31;  // max value
            end
        end else if ((count >= 1) && (en || valid_b7)) begin
            group_min[group_idx] <= (temp1_re < temp1_im) ? temp1_re : temp1_im;
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if(!rstn) begin
            count <= 0;
        end else if (en || valid_b7) begin
            count <= count + 1;
        end
    end

    // ------------------------
    // Stage 4: Final Min
    // ------------------------
    logic [4:0] final_min;
    always_comb begin
        group_idx = (count - 1);
        if (group_idx == 0) begin
            final_min = group_min[0];
            for (int k = 1; k < 4; k++) begin
                if ((group_min[k] < final_min)) final_min = group_min[k];
            end
        end
    end

    logic [4:0] final_min_reg;
    logic [4:0] final_min_reg_bf;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            final_min_reg_bf <= 0;
        end else if ((group_idx == 0) && (en || valid_b7) && (count >= 2)) begin
            final_min_reg_bf <= final_min;
        end
    end

    always_ff @(posedge clk) begin
        final_min_reg <= final_min_reg_bf;
    end
    
    assign cnt = final_min_reg;

    // ------------------------
    // Stage 5: Scaling
    // ------------------------
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int n = 0; n < NUM; n++) begin
                out_re[n] <= 0;
                out_im[n] <= 0;
            end
        end else if (valid_b6) begin
            for (int n = 0; n < NUM; n++) begin
                if (final_min_reg_bf > 12) begin
                    out_re[n] <= (buffer_reg_re_6[n] <<< (final_min_reg_bf - 12));
                    out_im[n] <= (buffer_reg_im_6[n] <<< (final_min_reg_bf - 12));
                end else begin
                    out_re[n] <= (buffer_reg_re_6[n] >>> (12 - final_min_reg_bf));
                    out_im[n] <= (buffer_reg_im_6[n] >>> (12 - final_min_reg_bf));
                end
            end
        end else begin
            for (int n = 0; n < NUM; n++) begin
                out_re[n] <= 1'bx;
                out_im[n] <= 1'bx;
            end
        end
    end
endmodule

module CBFP12 #(
    parameter WIDTH_IN  = 25,  // 25-bit signed input
    parameter WIDTH_OUT = 12,  // 12-bit signed output
    parameter NUM       = 16   // 16-point block (2 groups of 8)
) (
    input  logic                        clk,
    input  logic                        rstn,
    input  logic                        en,
    input  logic signed [ WIDTH_IN-1:0] in_re      [0:NUM-1],
    input  logic signed [ WIDTH_IN-1:0] in_im      [0:NUM-1],
    output logic signed [WIDTH_OUT-1:0] out_re     [0:NUM-1],
    output logic signed [WIDTH_OUT-1:0] out_im     [0:NUM-1],
    output logic        [          4:0] min_hr_grp0,           // shift count
    output logic        [          4:0] min_hr_grp1,
    output logic                        valid_out
);
    // Stage 1: Headroom detection (real & imag)
    logic        [         4:0] headroom_re[0:NUM-1];
    logic        [         4:0] headroom_im[0:NUM-1];

    logic signed [24:0] d_re [0:15];
    logic signed [24:0] d_im [0:15];

    genvar i;
    generate
        for (i = 0; i < NUM; i++) begin : GEN_HEADROOM
            headroom_detect_25 u_hd_re (
                .clk     (clk),
                .rstn    (rstn),
                .start   (en),
                .data_in (in_re[i]),
                .headroom(headroom_re[i]),
                .over    ()
            );
            headroom_detect_25 u_hd_im (
                .clk     (clk),
                .rstn    (rstn),
                .start   (en),
                .data_in (in_im[i]),
                .headroom(headroom_im[i]),
                .over    ()
            );
        end
    endgenerate

    always_ff @( posedge clk ) begin
        for (int s=0; s<16;s++ ) begin
            d_re[s] <= in_re[s];
            d_im[s] <= in_im[s];
        end
    end
    // Stage 2: Compute group-wise minimum headroom (8-point per group)
    logic [4:0] min_hr_grp0_re, min_hr_grp0_im;
    logic [4:0] min_hr_grp1_re, min_hr_grp1_im;
    integer j;

    always_comb begin
        min_hr_grp0_re = headroom_re[0];
        min_hr_grp0_im = headroom_im[0];
        for (j = 1; j < 8; j++) begin
            if (headroom_re[j] < min_hr_grp0_re) begin
                min_hr_grp0_re = headroom_re[j];
            end
            if (headroom_im[j] < min_hr_grp0_im) begin
                min_hr_grp0_im = headroom_im[j];
            end
        end
        min_hr_grp0 = (min_hr_grp0_re < min_hr_grp0_im) ? min_hr_grp0_re : min_hr_grp0_im;

        min_hr_grp1_re = headroom_re[8];
        min_hr_grp1_im = headroom_im[8];
        for (j = 9; j < 16; j++) begin
            if (headroom_re[j] < min_hr_grp1_re) begin
                min_hr_grp1_re = headroom_re[j];
            end
            if (headroom_im[j] < min_hr_grp1_im) begin
                min_hr_grp1_im = headroom_im[j];
            end
        end
        min_hr_grp1 = (min_hr_grp1_re < min_hr_grp1_im) ? min_hr_grp1_re : min_hr_grp1_im;
    end

    // Stage 3: Shift 
    integer k;
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (k = 0; k < NUM; k++) begin
                out_re[k] <= 0;
                out_im[k] <= 0;
            end
            valid_out <= 0;
        end else if (en) begin
            for (k = 0; k < 8; k++) begin
                logic signed [WIDTH_IN-1:0] scaled_re, scaled_im;
                if (min_hr_grp0 > 13) begin
                    out_re[k] <= d_re[k] <<< (min_hr_grp0 - 13);
                    out_im[k] <= d_im[k] <<< (min_hr_grp0 - 13);
                end else if (min_hr_grp0 <= 13) begin
                    out_re[k] <= d_re[k] >>> (13 - min_hr_grp0);
                    out_im[k] <= d_im[k] >>> (13 - min_hr_grp0);
                end else begin
                    out_re[k] <= d_re[k];
                    out_im[k] <= d_im[k];
                end
            end
            for (k = 8; k < 16; k++) begin
                logic signed [WIDTH_IN-1:0] scaled_re, scaled_im;
                if (min_hr_grp1 > 13) begin
                    out_re[k] <= d_re[k] <<< (min_hr_grp1 - 13);
                    out_im[k] <= d_im[k] <<< (min_hr_grp1 - 13);
                end else if (min_hr_grp1 < 13) begin
                    out_re[k] <= d_re[k] >>> (13 - min_hr_grp1);
                    out_im[k] <= d_im[k] >>> (13 - min_hr_grp1);
                end else begin
                    out_re[k] <= d_re[k];
                    out_im[k] <= d_im[k];
                end
            end
            valid_out <= 1'b1;
        end
    end
endmodule

module headroom_detect_23 (
    input logic clk,
    input logic rstn,
    input logic start,
    input logic signed [22:0] data_in,
    output logic [4:0] headroom,
    output logic over
);

    logic signed [22:0] r_data_in;

    always @(posedge clk, negedge rstn) begin
        if (~rstn) begin
            over <= 0;
        end else begin
            r_data_in <= data_in;
            if ((data_in[22] == 1) && (start)) begin
                casez (data_in)
                    23'b11111111111111111111111: headroom <= 22;
                    23'b1111111111111111111111?: headroom <= 21;
                    23'b111111111111111111111??: headroom <= 20;
                    23'b11111111111111111111???: headroom <= 19;
                    23'b1111111111111111111????: headroom <= 18;
                    23'b111111111111111111?????: headroom <= 17;
                    23'b11111111111111111??????: headroom <= 16;
                    23'b1111111111111111???????: headroom <= 15;
                    23'b111111111111111????????: headroom <= 14;
                    23'b11111111111111?????????: headroom <= 13;
                    23'b1111111111111??????????: headroom <= 12;
                    23'b111111111111???????????: headroom <= 11;
                    23'b11111111111????????????: headroom <= 10;
                    23'b1111111111?????????????: headroom <= 9;
                    23'b111111111??????????????: headroom <= 8;
                    23'b11111111???????????????: headroom <= 7;
                    23'b1111111????????????????: headroom <= 6;
                    23'b111111?????????????????: headroom <= 5;
                    23'b11111??????????????????: headroom <= 4;
                    23'b1111???????????????????: headroom <= 3;
                    23'b111????????????????????: headroom <= 2;
                    23'b11?????????????????????: headroom <= 1;
                    23'b1??????????????????????: headroom <= 0;
                    default: headroom <= 23;
                endcase
                over <= 1;
            end else if ((data_in[22] == 0) && (start)) begin
                casez (data_in)
                    23'b00000000000000000000000: headroom <= 22;
                    23'b0000000000000000000000?: headroom <= 21;
                    23'b000000000000000000000??: headroom <= 20;
                    23'b00000000000000000000???: headroom <= 19;
                    23'b0000000000000000000????: headroom <= 18;
                    23'b000000000000000000?????: headroom <= 17;
                    23'b00000000000000000??????: headroom <= 16;
                    23'b0000000000000000???????: headroom <= 15;
                    23'b000000000000000????????: headroom <= 14;
                    23'b00000000000000?????????: headroom <= 13;
                    23'b0000000000000??????????: headroom <= 12;
                    23'b000000000000???????????: headroom <= 11;
                    23'b00000000000????????????: headroom <= 10;
                    23'b0000000000?????????????: headroom <= 9;
                    23'b000000000??????????????: headroom <= 8;
                    23'b00000000???????????????: headroom <= 7;
                    23'b0000000????????????????: headroom <= 6;
                    23'b000000?????????????????: headroom <= 5;
                    23'b00000??????????????????: headroom <= 4;
                    23'b0000???????????????????: headroom <= 3;
                    23'b000????????????????????: headroom <= 2;
                    23'b00?????????????????????: headroom <= 1;
                    23'b0??????????????????????: headroom <= 0;
                    default: headroom <= 23;
                endcase
                over <= 1;
            end else begin
                headroom <= 23;
                over <= 0;
            end
        end
    end
endmodule

module headroom_detect_25 (
    input  logic               clk,
    input  logic               rstn,
    input  logic               start,
    input  logic signed [24:0] data_in,   // 25bit 입력
    output logic        [ 4:0] headroom,  // 남은 여유 비트
    output logic               over
);

    logic signed [24:0] r_data_in;

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            over     <= 0;
            headroom <= 25;
        end else begin
            r_data_in <= data_in;
            if (start) begin
                // 음수일 경우
                if (data_in[24] == 1) begin
                    casez (data_in)
                        25'b1111111111111111111111111: headroom <= 24;
                        25'b111111111111111111111111?: headroom <= 23;
                        25'b11111111111111111111111??: headroom <= 22;
                        25'b1111111111111111111111???: headroom <= 21;
                        25'b111111111111111111111????: headroom <= 20;
                        25'b11111111111111111111?????: headroom <= 19;
                        25'b1111111111111111111??????: headroom <= 18;
                        25'b111111111111111111???????: headroom <= 17;
                        25'b11111111111111111????????: headroom <= 16;
                        25'b1111111111111111?????????: headroom <= 15;
                        25'b111111111111111??????????: headroom <= 14;
                        25'b11111111111111???????????: headroom <= 13;
                        25'b1111111111111????????????: headroom <= 12;
                        25'b111111111111?????????????: headroom <= 11;
                        25'b11111111111??????????????: headroom <= 10;
                        25'b1111111111???????????????: headroom <= 9;
                        25'b111111111????????????????: headroom <= 8;
                        25'b11111111?????????????????: headroom <= 7;
                        25'b1111111??????????????????: headroom <= 6;
                        25'b111111???????????????????: headroom <= 5;
                        25'b11111????????????????????: headroom <= 4;
                        25'b1111?????????????????????: headroom <= 3;
                        25'b111??????????????????????: headroom <= 2;
                        25'b11???????????????????????: headroom <= 1;
                        25'b1????????????????????????: headroom <= 0;
                        default: headroom <= 25;
                    endcase
                    over <= 1;
                end  // 양수일 경우
                else begin
                    casez (data_in)
                        25'b0000000000000000000000000: headroom <= 24;
                        25'b000000000000000000000000?: headroom <= 23;
                        25'b00000000000000000000000??: headroom <= 22;
                        25'b0000000000000000000000???: headroom <= 21;
                        25'b000000000000000000000????: headroom <= 20;
                        25'b00000000000000000000?????: headroom <= 19;
                        25'b0000000000000000000??????: headroom <= 18;
                        25'b000000000000000000???????: headroom <= 17;
                        25'b00000000000000000????????: headroom <= 16;
                        25'b0000000000000000?????????: headroom <= 15;
                        25'b000000000000000??????????: headroom <= 14;
                        25'b00000000000000???????????: headroom <= 13;
                        25'b0000000000000????????????: headroom <= 12;
                        25'b000000000000?????????????: headroom <= 11;
                        25'b00000000000??????????????: headroom <= 10;
                        25'b0000000000???????????????: headroom <= 9;
                        25'b000000000????????????????: headroom <= 8;
                        25'b00000000?????????????????: headroom <= 7;
                        25'b0000000??????????????????: headroom <= 6;
                        25'b000000???????????????????: headroom <= 5;
                        25'b00000????????????????????: headroom <= 4;
                        25'b0000?????????????????????: headroom <= 3;
                        25'b000??????????????????????: headroom <= 2;
                        25'b00???????????????????????: headroom <= 1;
                        25'b0????????????????????????: headroom <= 0;
                        default: headroom <= 25;
                    endcase
                    over <= 1;
                end
            end else begin
                headroom <= 25;
                over     <= 0;
            end
        end
    end
endmodule
