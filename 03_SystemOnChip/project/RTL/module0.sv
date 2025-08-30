`timescale 1ns / 1ps

module module0 (
    input  logic                          clk,
    input  logic                          valid_in,
    input  logic        [$clog2(100)-1:0] count,
    input  logic signed [            8:0] din_i    [0:15],
    input  logic signed [            8:0] din_q    [0:15],
    output logic signed [           22:0] dout_i   [0:15],
    output logic signed [           22:0] dout_q   [0:15],
    output logic                          valid_out
);
    logic signed [8:0] din00_i_reg[0:15];
    logic signed [8:0] din00_q_reg[0:15];
    logic signed [8:0] w_stage00_BF_in_i[0:15];
    logic signed [8:0] w_stage00_BF_in_q[0:15];
    logic signed [9:0] w_stage00_BF_out_1_i[0:15];
    logic signed [9:0] w_stage00_BF_out_1_q[0:15];
    logic signed [9:0] w_stage00_SR_back_in_i[0:15];
    logic signed [9:0] w_stage00_SR_back_in_q[0:15];
    logic signed [9:0] w_stage00_SR_back_out_i[0:15];
    logic signed [9:0] w_stage00_SR_back_out_q[0:15];
    logic signed [9:0] w_stage00_tmp_i[0:15];
    logic signed [9:0] w_stage00_tmp_q[0:15];
    logic signed [9:0] bfly00_i[0:15];
    logic signed [9:0] bfly00_q[0:15];
    logic mux_sel_stage00_back;

    assign valid_out = ((count >= 29) && (count <= 60)) ? 1 : 0;

    always @(posedge clk) begin
        if (valid_in) begin
            for (int i = 0; i < 16; i++) begin
                din00_i_reg[i] <= din_i[i];
                din00_q_reg[i] <= din_q[i];
            end
        end
    end

    Shift_Register #(
        .Din_bit(9),
        .Length (256)
    ) stage_00_sr_front (
        .clk   (clk),
        .din_i (din00_i_reg),
        .din_q (din00_q_reg),
        .dout_i(w_stage00_BF_in_i),
        .dout_q(w_stage00_BF_in_q)
    );

    ButterFly #(
        .Din_bit(9)
    ) stage00_BF (
        .valid (1'b1),
        .din1_i(w_stage00_BF_in_i),
        .din1_q(w_stage00_BF_in_q),
        .din2_i(din_i),
        .din2_q(din_q),
        .do1_i (w_stage00_BF_out_1_i),
        .do1_q (w_stage00_BF_out_1_q),
        .do2_i (w_stage00_SR_back_in_i),  // 뺄셈 결과
        .do2_q (w_stage00_SR_back_in_q)
    );

    Shift_Register #(
        .Din_bit(10),
        .Length (256)
    ) stage_00_sr_back (
        .clk   (clk),
        .din_i (w_stage00_SR_back_in_i),
        .din_q (w_stage00_SR_back_in_q),
        .dout_i(w_stage00_SR_back_out_i),
        .dout_q(w_stage00_SR_back_out_q)
    );

    assign mux_sel_stage00_back = ((count >= 33) && (count <= 48)) ? 1 : 0;
    
    MUX_2x1 #(  // sel이 1이면 1, 0이면 2
        .Din_bit(10)
    ) stage_00_back (
        .sel   (mux_sel_stage00_back),
        .din1_i(w_stage00_SR_back_out_i),
        .din1_q(w_stage00_SR_back_out_q),
        .din2_i(w_stage00_BF_out_1_i),
        .din2_q(w_stage00_BF_out_1_q),
        .dout_i(w_stage00_tmp_i),
        .dout_q(w_stage00_tmp_q)
    );

    logic [1:0] stage00_fac8_0_sel;

    always_comb begin
        if (count <= 24) begin
            stage00_fac8_0_sel = 0;
        end else if (count <= 32) begin
            stage00_fac8_0_sel = 1;
        end else if (count <= 40) begin
            stage00_fac8_0_sel = 2;
        end else begin
            stage00_fac8_0_sel = 3;
        end
    end

    fac8_0 #(
        .Din_bit(10)
    ) stage00_fac8_0 (
        .sel   (stage00_fac8_0_sel),
        .din_i (w_stage00_tmp_i),
        .din_q (w_stage00_tmp_q),
        .dout_i(bfly00_i),
        .dout_q(bfly00_q)
    );

    logic signed [9:0] w_stage01_BF_in_i[0:15];
    logic signed [9:0] w_stage01_BF_in_q[0:15];
    logic signed [10:0] w_stage01_BF_out_1_i[0:15];
    logic signed [10:0] w_stage01_BF_out_1_q[0:15];
    logic signed [10:0] w_stage01_SR_back_in_i[0:15];
    logic signed [10:0] w_stage01_SR_back_in_q[0:15];
    logic signed [10:0] w_stage01_SR_back_out_i[0:15];
    logic signed [10:0] w_stage01_SR_back_out_q[0:15];
    logic signed [10:0] w_stage01_tmp_i[0:15];
    logic signed [10:0] w_stage01_tmp_q[0:15];
    logic signed [20:0] temp_bfly01_i[0:15];
    logic signed [20:0] temp_bfly01_q[0:15];
    logic signed [9:0] fac8_1_i[0:15];
    logic signed [9:0] fac8_1_q[0:15];
    logic signed [11:0] bfly01_i[0:15];
    logic signed [11:0] bfly01_q[0:15];
    logic [2:0] stage01_fac8_1_sel;
    logic mux_sel_stage01_back;

    Shift_Register #(
        .Din_bit(10),
        .Length (128)
    ) stage_01_sr_front (
        .clk   (clk),
        .din_i (bfly00_i),
        .din_q (bfly00_q),
        .dout_i(w_stage01_BF_in_i),
        .dout_q(w_stage01_BF_in_q)
    );

    ButterFly #(
        .Din_bit(10)
    ) stage01_BF (
        .valid (~mux_sel_stage01_back),
        .din1_i(w_stage01_BF_in_i),
        .din1_q(w_stage01_BF_in_q),
        .din2_i(bfly00_i),
        .din2_q(bfly00_q),
        .do1_i (w_stage01_BF_out_1_i),
        .do1_q (w_stage01_BF_out_1_q),
        .do2_i (w_stage01_SR_back_in_i),
        .do2_q (w_stage01_SR_back_in_q)
    );

    Shift_Register #(
        .Din_bit(11),
        .Length (128)
    ) stage_01_sr_back (
        .clk   (clk),
        .din_i (w_stage01_SR_back_in_i),
        .din_q (w_stage01_SR_back_in_q),
        .dout_i(w_stage01_SR_back_out_i),
        .dout_q(w_stage01_SR_back_out_q)
    );

    always_comb begin
        if (count <= 32) begin
            mux_sel_stage01_back = 0;
        end else if (count <= 40) begin
            mux_sel_stage01_back = 1;
        end else if (count <= 48) begin
            mux_sel_stage01_back = 0;
        end else if (count <= 56) begin
            mux_sel_stage01_back = 1;
        end else if (count <= 64) begin
            mux_sel_stage01_back = 0;
        end else begin
            mux_sel_stage01_back = 1;
        end
    end

    MUX_2x1 #(
        .Din_bit(11)
    ) stage_01_back (
        .sel   (mux_sel_stage01_back),
        .din1_i(w_stage01_SR_back_out_i),
        .din1_q(w_stage01_SR_back_out_q),
        .din2_i(w_stage01_BF_out_1_i),
        .din2_q(w_stage01_BF_out_1_q),
        .dout_i(w_stage01_tmp_i),
        .dout_q(w_stage01_tmp_q)
    );

    always_comb begin
        if (count <= 28) begin
            stage01_fac8_1_sel = 0;
        end else if (count <= 32) begin
            stage01_fac8_1_sel = 1;
        end else if (count <= 36) begin
            stage01_fac8_1_sel = 2;
        end else if (count <= 40) begin
            stage01_fac8_1_sel = 3;
        end else if (count <= 44) begin
            stage01_fac8_1_sel = 4;
        end else if (count <= 48) begin
            stage01_fac8_1_sel = 5;
        end else if (count <= 52) begin
            stage01_fac8_1_sel = 6;
        end else begin
            stage01_fac8_1_sel = 7;
        end
    end

    genvar a;

    generate
        for (a = 0; a < 16; a++) begin
            fac8_1_rom FAC8_1 (
                .addr(stage01_fac8_1_sel),
                .w_re(fac8_1_i[a]),
                .w_im(fac8_1_q[a])
            );
        end
    endgenerate

    Multiplier #(
        .Din_bit (11),
        .Dout_bit(21)
    ) stage01_fac8_1_multiplier (
        .din_i   (w_stage01_tmp_i),
        .din_q   (w_stage01_tmp_q),
        .weight_i(fac8_1_i),
        .weight_q(fac8_1_q),
        .dout_i  (temp_bfly01_i),
        .dout_q  (temp_bfly01_q)
    );

    round #(
        .Din_bit(21),
        .round_size(8),
        .Dout_bit(12)
    ) stage01_round (
        .din_i (temp_bfly01_i),
        .din_q (temp_bfly01_q),
        .dout_i(bfly01_i),
        .dout_q(bfly01_q)
    );

    logic signed [11:0] w_stage02_BF_in_i[0:15];
    logic signed [11:0] w_stage02_BF_in_q[0:15];
    logic signed [12:0] w_stage02_BF_out_1_i[0:15];
    logic signed [12:0] w_stage02_BF_out_1_q[0:15];
    logic signed [12:0] w_stage02_SR_back_in_i[0:15];
    logic signed [12:0] w_stage02_SR_back_in_q[0:15];
    logic signed [12:0] w_stage02_SR_back_out_i[0:15];
    logic signed [12:0] w_stage02_SR_back_out_q[0:15];
    logic signed [12:0] w_stage02_tmp_i[0:15];
    logic signed [12:0] w_stage02_tmp_q[0:15];
    logic signed [9:0] twf_m0_i[0:15];
    logic signed [9:0] twf_m0_q[0:15];
    logic signed [22:0] pre_bfly02_i[0:15];
    logic signed [22:0] pre_bfly02_q[0:15];
    logic [8:0] twf_m0_idx[0:15];
    logic mux_sel_stage02_back;

    Shift_Register #(
        .Din_bit(12),
        .Length (64)
    ) stage_02_sr_front (
        .clk   (clk),
        .din_i (bfly01_i),
        .din_q (bfly01_q),
        .dout_i(w_stage02_BF_in_i),
        .dout_q(w_stage02_BF_in_q)
    );

    ButterFly #(
        .Din_bit(12)
    ) stage02_BF (
        .valid (1'b1),
        .din1_i(w_stage02_BF_in_i),
        .din1_q(w_stage02_BF_in_q),
        .din2_i(bfly01_i),
        .din2_q(bfly01_q),
        .do1_i (w_stage02_BF_out_1_i),
        .do1_q (w_stage02_BF_out_1_q),
        .do2_i (w_stage02_SR_back_in_i),
        .do2_q (w_stage02_SR_back_in_q)
    );

    Shift_Register #(
        .Din_bit(13),
        .Length (64)
    ) stage_02_sr_back (
        .clk   (clk),
        .din_i (w_stage02_SR_back_in_i),
        .din_q (w_stage02_SR_back_in_q),
        .dout_i(w_stage02_SR_back_out_i),
        .dout_q(w_stage02_SR_back_out_q)
    );

    always_comb begin
        for (int i = 0; i < 16; i++) begin
            twf_m0_idx[i] = ((count - 29) << 4) + i;
        end
        if (count <= 32) begin
            mux_sel_stage02_back = 0;
        end else if (count <= 36) begin
            mux_sel_stage02_back = 1;
        end else if (count <= 40) begin
            mux_sel_stage02_back = 0;
        end else if (count <= 44) begin
            mux_sel_stage02_back = 1;
        end else if (count <= 48) begin
            mux_sel_stage02_back = 0;
        end else if (count <= 52) begin
            mux_sel_stage02_back = 1;
        end else if (count <= 56) begin
            mux_sel_stage02_back = 0;
        end else if (count <= 60) begin
            mux_sel_stage02_back = 1;
        end else begin
            mux_sel_stage02_back = 1'bx;
        end
    end

    MUX_2x1 #(
        .Din_bit(13)
    ) stage_02_back (
        .sel   (mux_sel_stage02_back),
        .din1_i(w_stage02_SR_back_out_i),
        .din1_q(w_stage02_SR_back_out_q),
        .din2_i(w_stage02_BF_out_1_i),
        .din2_q(w_stage02_BF_out_1_q),
        .dout_i(w_stage02_tmp_i),
        .dout_q(w_stage02_tmp_q)
    );

    genvar b;

    generate
        for (b = 0; b < 16; b++) begin
            twf_m0_rom stage02_twf_rom (
                .addr(twf_m0_idx[b]),
                .w_re(twf_m0_i[b]),
                .w_im(twf_m0_q[b])
            );
        end
    endgenerate

    Multiplier #(
        .Din_bit (13),
        .Dout_bit(23)
    ) stage02_twf_m0_multiplier (
        .din_i   (w_stage02_tmp_i),
        .din_q   (w_stage02_tmp_q),
        .weight_i(twf_m0_i),
        .weight_q(twf_m0_q),
        .dout_i  (pre_bfly02_i),
        .dout_q  (pre_bfly02_q)
    );

    always_comb begin
        for (int i = 0; i < 16; i++) begin
            dout_i[i] = pre_bfly02_i[i];
            dout_q[i] = pre_bfly02_q[i];
        end
    end
endmodule
