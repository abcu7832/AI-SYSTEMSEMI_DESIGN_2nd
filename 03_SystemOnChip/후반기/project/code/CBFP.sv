module CBFP_02(
    input  logic clk,
    input  logic rstn,
    input  logic start,
    input  logic signed [22:0] pre_bfly02_real [0:511],
    input  logic signed [22:0] pre_bfly02_imag [0:511],
    output logic signed [10:0] re_bfly02 [0:511],
    output logic signed [10:0] im_bfly02 [0:511],
    output logic [4:0] index1_re [0:511],
    output logic [4:0] index1_im [0:511],
    output logic over
);

    typedef enum logic [2:0] {IDLE, COLLECT, COMPUTE, SCALE, COMPUTE_V2} state_t;
    state_t state;

    logic [4:0] ll;
    logic started;
    logic [4:0] tmp1_re [0:15], tmp1_im [0:15];
    logic [15:0] headroom_tick_1, headroom_tick_2;
    logic ready;

    logic [4:0] tmp_min_re, tmp_min_im;
    logic [4:0] temp_re [0:31], temp_im [0:31];
    logic [4:0] cnt2_re [0:7], cnt2_im [0:7];
    logic [4:0] local_min_re [0:7], local_min_im [0:7];
    logic [4:0] min_cnt [0:7];

    assign ready = (&headroom_tick_1) && (&headroom_tick_2);

    always_comb begin
       tmp_min_re = tmp1_re[0];
        tmp_min_im = tmp1_im[0];
        for (int i = 1; i < 16; i++) begin
           if (tmp1_re[i] < tmp_min_re) tmp_min_re = tmp1_re[i];
                if (tmp1_im[i] < tmp_min_im) tmp_min_im = tmp1_im[i];
        end
        
   for (int g = 0; g < 8; g++) begin
           local_min_re[g] = temp_re[g*4];
                local_min_im[g] = temp_im[g*4];
                for (int i = 1; i < 4; i++) begin
                   if (temp_re[g*4 + i] < local_min_re[g])
                            local_min_re[g] = temp_re[g*4 + i];
                    if (temp_im[g*4 + i] < local_min_im[g])
                            local_min_im[g] = temp_im[g*4 + i];
                end
        end
   for (int ii=0;ii<8;ii=ii+1) begin
      min_cnt[ii] = (cnt2_re[ii] < cnt2_im[ii]) ? cnt2_re[ii] : cnt2_im[ii];
   end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= IDLE;
            ll <= 0;
            started <= 0;
            over <= 0;
            for(int i = 0; i < 32; i=i+1) begin
                temp_re[i] <= 0;
                temp_im[i] <= 0;
            end
        end else begin
            case (state)
                IDLE: begin
                    over <= 0;
                    if (start) begin
                        started <= 1;
                        ll <= 0;
                        state <= COLLECT;
                    end 
                end

                COLLECT: begin
                    if (ready) begin
                        state <= COMPUTE; 
                    end
                end

                COMPUTE: begin
                    temp_re[ll] <= tmp_min_re;
                    temp_im[ll] <= tmp_min_im;

                    if (ll == 31) begin
                        started <= 0;
                        state <= COMPUTE_V2;
                    end else begin
                        ll <= ll + 1;
                        state <= COLLECT; 
                    end
                end

                COMPUTE_V2: begin
                    for (int g = 0; g < 8; g++) begin
                        cnt2_re[g] <= local_min_re[g];
                        cnt2_im[g] <= local_min_im[g];
                    end
                    state <= SCALE; 
                end

                SCALE: begin
                    for (int ii = 0; ii < 8; ii++) begin
                        for (int jj = 0; jj < 64; jj++) begin
                            index1_re[64*ii + jj] <= min_cnt[ii];
                            index1_im[64*ii + jj] <= min_cnt[ii];

                            if (min_cnt[ii] > 12)
                                re_bfly02[64*ii + jj] <= (pre_bfly02_real[64*ii + jj] <<< min_cnt[ii]) >>> 12;
                            else
                                re_bfly02[64*ii + jj] <= pre_bfly02_real[64*ii + jj] >>> (12 - min_cnt[ii]);

                            if (min_cnt[ii] > 12)
                                im_bfly02[64*ii + jj] <= (pre_bfly02_imag[64*ii + jj] <<< min_cnt[ii]) >>> 12;
                            else
                                im_bfly02[64*ii + jj] <= pre_bfly02_imag[64*ii + jj] >>> (12 - min_cnt[ii]);
                        end
                    end
                    over <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : GEN_HEADROOM
            headroom_detect_23 u_hd_re (
                .clk(clk),
                .rstn(rstn),
                .start(started),
                .data_in(pre_bfly02_real[16 * ll + i]),
                .headroom(tmp1_re[i]),
                .over(headroom_tick_1[i])
            );

            headroom_detect_23 u_hd_im (
                .clk(clk),
                .rstn(rstn),
                .start(started),
                .data_in(pre_bfly02_imag[16 * ll + i]),
                .headroom(tmp1_im[i]),
                .over(headroom_tick_2[i])
            );
        end
    endgenerate 
endmodule

module CBFP_12 (
    input  logic clk,
    input  logic rstn,
    input  logic start,
    input  logic signed [24:0] pre_bfly12_real [0:511],
    input  logic signed [24:0] pre_bfly12_imag [0:511],
    output logic signed [11:0] re_bfly12 [0:511],
    output logic signed [11:0] im_bfly12 [0:511],
    output logic [4:0] index2_re [0:511],
    output logic [4:0] index2_im [0:511],
    output logic over
);

    typedef enum logic [2:0] {IDLE, COLLECT, COMPUTE, SCALE} state_t;
    state_t state;

    logic [5:0] ll;
    logic started;
    logic [4:0] tmp1_re [0:7], tmp1_im [0:7];
    logic [7:0] headroom_tick_1, headroom_tick_2;
    logic ready;

    logic [4:0] tmp_min_re, tmp_min_im;
    logic [4:0] cnt2_re [0:63], cnt2_im [0:63];
    logic [4:0] min_cnt [0:63];

    assign ready = (&headroom_tick_1) && (&headroom_tick_2);

    always_comb begin
        tmp_min_re = tmp1_re[0];
        tmp_min_im = tmp1_im[0];
        for (int i = 1; i < 8; i++) begin
           if (tmp1_re[i] < tmp_min_re) tmp_min_re = tmp1_re[i];
                if (tmp1_im[i] < tmp_min_im) tmp_min_im = tmp1_im[i];
        end
        for (int ii = 0; ii < 64; ii++) begin
                min_cnt[ii] = (cnt2_re[ii] < cnt2_im[ii]) ? cnt2_re[ii] : cnt2_im[ii];
        end
    end

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state <= IDLE;
            ll <= 0;
            started <= 0;
            over <= 0;
        end else begin
            case (state)
                IDLE: begin
                    over <= 0;
                    if (start) begin
                        started <= 1;
                        ll <= 0;
                        state <= COLLECT;
                    end
                end

                COLLECT: begin
                    if (ready) begin
                        state <= COMPUTE; 
                    end
                end

                COMPUTE: begin
                    cnt2_re[ll] <= tmp_min_re;
                    cnt2_im[ll] <= tmp_min_im;

                    if (ll == 63) begin
                        started <= 0;
                        state <= SCALE;
                    end else begin
                        ll <= ll + 1;
                        state <= COLLECT; 
                    end
                end

                SCALE: begin
                    for (int ii = 0; ii < 64; ii++) begin
                        for (int jj = 0; jj < 8; jj++) begin
                            index2_re[8*ii + jj] <= min_cnt[ii];
                            index2_im[8*ii + jj] <= min_cnt[ii];

                            if (min_cnt[ii] > 13)
                                re_bfly12[8*ii + jj] <= (pre_bfly12_real[8*ii + jj] <<< min_cnt[ii]) >>> 13;
                            else
                                re_bfly12[8*ii + jj] <= pre_bfly12_real[8*ii + jj] >>> (13 - min_cnt[ii]);

                            if (min_cnt[ii] > 13)
                                im_bfly12[8*ii + jj] <= (pre_bfly12_imag[8*ii + jj] <<< min_cnt[ii]) >>> 13;
                            else
                                im_bfly12[8*ii + jj] <= pre_bfly12_imag[8*ii + jj] >>> (13 - min_cnt[ii]);
                        end
                    end
                    over <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

    genvar i;
    generate
        for (i = 0; i < 8; i++) begin : GEN_HEADROOM
            headroom_detect_25 u_hd_re (
                .clk(clk),
                .rstn(rstn),
                .start(started),
                .data_in(pre_bfly12_real[8 * ll + i]),
                .headroom(tmp1_re[i]),
                .over(headroom_tick_1[i])
            );

            headroom_detect_25 u_hd_im (
                .clk(clk),
                .rstn(rstn),
                .start(started),
                .data_in(pre_bfly12_imag[8 * ll + i]),
                .headroom(tmp1_im[i]),
                .over(headroom_tick_2[i])
            );
        end
    endgenerate
endmodule

module headroom_detect_25 #(
    parameter int DATAWIDTH = 24
)(
    input logic clk,
    input logic rstn,
    input logic start,
    input logic signed [DATAWIDTH:0] data_in,
    output logic [4:0] headroom,
    output logic over
);

    logic signed [DATAWIDTH:0] r_data_in;

    always @(posedge clk, negedge rstn) begin
        if(~rstn) begin
            over <= 0;
        end else begin
            r_data_in <= data_in;
            if ((data_in[DATAWIDTH] == 1) && (start)) begin
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
                    default: headroom <= DATAWIDTH + 1;
                endcase
                over <= 1;
            end else if ((data_in[DATAWIDTH] == 0) && (start)) begin
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
                    default: headroom <= DATAWIDTH + 1;
                endcase
                over <= 1;
            end else begin
                headroom <= 0;
                over <= 0;
            end
        end 
    end
endmodule

module headroom_detect_23 (
    input logic clk,
    input logic rstn,
    input logic start,
    input  logic signed [22:0] data_in,
    output logic [4:0] headroom,
    output logic over
);

    logic signed [22:0] r_data_in;

    always @(posedge clk, negedge rstn) begin
        if(~rstn) begin
            over <= 0;
        end else begin
            r_data_in <= data_in;
            if ((data_in[22] == 1)&&(start)) begin
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
            end else if((data_in[22] == 0)&&(start)) begin
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
                headroom <= 0; 
                over <= 0;
            end
        end
    end
endmodule

