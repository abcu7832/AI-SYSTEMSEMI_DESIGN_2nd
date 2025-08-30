`timescale 1ns / 1ps

module fft_top (
    input  logic               clk,
    input  logic               rstn,
    input  logic               din_valid,
    input  logic signed [ 8:0] din_i    [ 0:15],
    input  logic signed [ 8:0] din_q    [ 0:15],
    output logic               do_en,
    output logic signed [12:0] do_re    [0:511],
    output logic signed [12:0] do_im    [0:511]
);

    logic signed [22:0] pre_bfly02_i[0:15];
    logic signed [22:0] pre_bfly02_q[0:15];
    logic signed [10:0] bfly02_i[0:15];
    logic signed [10:0] bfly02_q[0:15];
    logic signed [24:0] pre_bfly12_i[0:15];
    logic signed [24:0] pre_bfly12_q[0:15];
    logic signed [11:0] bfly12_i[0:15];
    logic signed [11:0] bfly12_q[0:15];
    logic signed [15:0] bfly22_tmp_i[0:15];
    logic signed [15:0] bfly22_tmp_q[0:15];
    logic signed [12:0] bfly22_i[0:511];
    logic signed [12:0] bfly22_q[0:511];
    logic module0_CBFP_GO, module1_CBFP_GO;
    logic module1_GO;
    logic [$clog2(100)-1:0] count;

    INNER_COUNTER #(
        .cnt(100)
    ) COUNT_CTRL (
        .clk     (clk),
        .valid_in(din_valid),
        .count   (count)
    );

    //count 29~60까지 valid_out
    module0 U_module0 (
        .clk      (clk),
        .valid_in (din_valid),
        .count    (count),
        .din_i    (din_i),
        .din_q    (din_q),
        .dout_i   (pre_bfly02_i),
        .dout_q   (pre_bfly02_q),
        .valid_out(module0_CBFP_GO)
    );

    logic [4:0] cnt1_mem[0:511];
    logic [4:0] cnt1;
    logic [1:0] count_CBFP02;
    logic [2:0] count_CBFP02_8;

    CBFP02 U_CBFP02 (
        .clk      (clk),
        .rstn     (rstn),
        .en       (module0_CBFP_GO),
        .in_re    (pre_bfly02_i),
        .in_im    (pre_bfly02_q),
        .out_re   (bfly02_i),
        .out_im   (bfly02_q),
        .cnt      (cnt1),             //8종류
        .valid_out(module1_GO)
    );
    // 6 delay
    always_ff @(posedge clk) begin
        if (!rstn) begin
            count_CBFP02   <= 0;
            count_CBFP02_8 <= 0;
        end else if (module1_GO) begin
            count_CBFP02 <= count_CBFP02 + 1;
            if (count_CBFP02 == 0) begin
                count_CBFP02_8 <= count_CBFP02_8 + 1;
                for (int i = 0; i < 64; i++) begin
                    cnt1_mem[i+(count_CBFP02_8<<6)] <= cnt1;
                end
            end
        end
    end
    // count 35~66in
    module1 U_module1 (
        .clk      (clk),
        .count    (count),
        .din_i    (bfly02_i),
        .din_q    (bfly02_q),
        .dout_i   (pre_bfly12_i),
        .dout_q   (pre_bfly12_q),
        .valid_out(module1_CBFP_GO)
    );

    logic module1_CBFP_GO_B;

    always_ff @(posedge clk) begin
        module1_CBFP_GO_B <= module1_CBFP_GO;
    end
    logic [4:0] cnt2_mem[0:511];
    logic [4:0] cnt2_min_hr_grp0, cnt2_min_hr_grp1;
    logic [5:0] count_CBFP12;
    logic module2_GO;

    CBFP12 #(
        .WIDTH_IN(25),
        .WIDTH_OUT(12),
        .NUM(16)
    ) U_CBFP12 (
        .clk        (clk),
        .rstn       (rstn),
        .en         (module1_CBFP_GO | module1_CBFP_GO_B),
        .in_re      (pre_bfly12_i),
        .in_im      (pre_bfly12_q),
        .out_re     (bfly12_i),
        .out_im     (bfly12_q),
        .min_hr_grp0(cnt2_min_hr_grp0),                     // 64종류
        .min_hr_grp1(cnt2_min_hr_grp1),
        .valid_out  (module2_GO)
    );

    always_ff @(posedge clk) begin
        if (!rstn) begin
            count_CBFP12 <= 0;
        end else if (module2_GO | (count_CBFP12 > 1 && count_CBFP12 < 32)) begin
            count_CBFP12 <= count_CBFP12 + 1;
            for (int i = 0; i < 8; i++) begin
                cnt2_mem[i+(count_CBFP12<<4)]   <= cnt2_min_hr_grp0;
                cnt2_mem[i+8+(count_CBFP12<<4)] <= cnt2_min_hr_grp1;
            end
        end
    end

    logic normalization_GO;

    module2 U_module2 (
        .clk      (clk),
        .count    (count),
        .din_i    (bfly12_i),
        .din_q    (bfly12_q),
        .dout_i   (bfly22_tmp_i),
        .dout_q   (bfly22_tmp_q),
        .valid_out(normalization_GO)
    );

    //////////////normalization//////////////
    logic [4:0] index_sum[0:15];
    logic [5:0] module2_out_cnt;
    logic [8:0] module2_idx;

    always_comb begin
        if (normalization_GO && (module2_out_cnt <= 31)) begin
            module2_idx = module2_out_cnt << 4;
            for (int i = 0; i < 16; i++) begin
                index_sum[i] = cnt1_mem[i + module2_idx] + cnt2_mem[i + module2_idx];
                if (index_sum[i] >= 23) begin
                    bfly22_i[i+module2_idx] = 0;
                    bfly22_q[i+module2_idx] = 0;
                end else if (index_sum[i] > 9) begin
                    bfly22_i[i+module2_idx] = bfly22_tmp_i[i] >>> (index_sum[i] - 9);
                    bfly22_q[i+module2_idx] = bfly22_tmp_q[i] >>> (index_sum[i] - 9);
                end else if (index_sum[i] == 9) begin
                    bfly22_i[i+module2_idx] = bfly22_tmp_i[i];
                    bfly22_q[i+module2_idx] = bfly22_tmp_q[i];
                end else begin
                    bfly22_i[i+module2_idx] = bfly22_tmp_i[i] <<< (9 - index_sum[i]);
                    bfly22_q[i+module2_idx] = bfly22_tmp_q[i] <<< (9 - index_sum[i]);
                end
            end
        end
    end

    always_ff @(posedge clk, negedge rstn) begin
        if (!rstn) begin
            module2_out_cnt <= 0;
        end else if (normalization_GO) begin
            module2_out_cnt <= module2_out_cnt + 1;
        end
    end

    assign do_en = (module2_out_cnt == 32);

    function automatic logic [8:0] bit_reverse;
        input logic [8:0] input_index;
        logic [8:0] reversed;
        begin
            reversed = input_index[8]*9'd1 + input_index[7]*9'd2 + input_index[6]*9'd4 + input_index[5]*9'd8 + input_index[4]*9'd16 + input_index[3]*9'd32 + input_index[2]*9'd64 + input_index[1]*9'd128 + input_index[0]*9'd256;
            bit_reverse = reversed;
        end
    endfunction

    logic [8:0] index;

    always_comb begin : reverse
        for (int i = 0;i<512 ;i++ ) begin
            index = bit_reverse(i);
            do_re[i] = bfly22_i[index];
            do_im[i] = bfly22_q[index];
        end        
    end
endmodule

