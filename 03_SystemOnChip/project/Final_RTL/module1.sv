`timescale 1ns / 1ps

module module1 (
    input  logic                          clk,
    input  logic        [$clog2(100)-1:0] count,
    input  logic signed [           10:0] din_i    [0:15],
    input  logic signed [           10:0] din_q    [0:15],
    output logic signed [           24:0] dout_i   [0:15],
    output logic signed [           24:0] dout_q   [0:15],
    output logic                          valid_out
);
    logic signed [10:0] din10_i_reg [0:15];
    logic signed [10:0] din10_q_reg [0:15];
    logic signed [10:0] w_stage10_BF_in_i[0:15];
    logic signed [10:0] w_stage10_BF_in_q[0:15];
    logic signed [11:0] w_stage10_BF_out_1_i[0:15];
    logic signed [11:0] w_stage10_BF_out_1_q[0:15];
    logic signed [11:0] w_stage10_SR_back_in_i[0:15];
    logic signed [11:0] w_stage10_SR_back_in_q[0:15];
    logic signed [11:0] w_stage10_SR_back_out_i[0:15];
    logic signed [11:0] w_stage10_SR_back_out_q[0:15];
    logic signed [11:0] w_stage10_tmp_i[0:15];
    logic signed [11:0] w_stage10_tmp_q[0:15];
    logic signed [11:0] bfly10_i[0:15];
    logic signed [11:0] bfly10_q[0:15];

    assign valid_out = (count >= 39 && count <= 70) ? 1 : 0;

    Shift_Register #(
        .Din_bit(11),
        .Length (32)
    ) stage_10_sr_front (
        .clk   (clk),
        .din_i (din_i),
        .din_q (din_q),
        .dout_i(w_stage10_BF_in_i),
        .dout_q(w_stage10_BF_in_q)
    );

    ButterFly #(
        .Din_bit(11)
    ) stage10_BF (
        .valid (1'b1),
        .din1_i(w_stage10_BF_in_i),
        .din1_q(w_stage10_BF_in_q),
        .din2_i(din_i),
        .din2_q(din_q),
        .do1_i (w_stage10_BF_out_1_i),
        .do1_q (w_stage10_BF_out_1_q),
        .do2_i (w_stage10_SR_back_in_i),
        .do2_q (w_stage10_SR_back_in_q)
    );

    Shift_Register #(
        .Din_bit(12),
        .Length (32)
    ) stage_10_sr_back (
        .clk   (clk),
        .din_i (w_stage10_SR_back_in_i),
        .din_q (w_stage10_SR_back_in_q),
        .dout_i(w_stage10_SR_back_out_i),
        .dout_q(w_stage10_SR_back_out_q)
    );

    wire mux_sel_stage10_back = count[1];

    MUX_2x1 #(
        .Din_bit(12)
    ) stage_10_back (
        .sel   (mux_sel_stage10_back),
        .din1_i(w_stage10_BF_out_1_i),
        .din1_q(w_stage10_BF_out_1_q),
        .din2_i(w_stage10_SR_back_out_i),
        .din2_q(w_stage10_SR_back_out_q),
        .dout_i(w_stage10_tmp_i),
        .dout_q(w_stage10_tmp_q)
    );

    wire [1:0] stage10_fac8_0_sel = count[1:0] + 2;

    genvar z;

    generate
        for (z = 0; z<8;z++ ) begin
            fac8_0_V2 #(
                .Din_bit(12)
            ) stage10_fac8_0 (
                .sel   (stage10_fac8_0_sel==3?3:0),
                .din_i (w_stage10_tmp_i[z]),
                .din_q (w_stage10_tmp_q[z]),
                .dout_i(bfly10_i[z]),
                .dout_q(bfly10_q[z])
            );            
        end
        for (z = 8; z<16;z++ ) begin
            fac8_0_V2 #(
                .Din_bit(12)
            ) stage10_fac8_0 (
                .sel   (stage10_fac8_0_sel==3?3:0),
                .din_i (w_stage10_tmp_i[z]),
                .din_q (w_stage10_tmp_q[z]),
                .dout_i(bfly10_i[z]),
                .dout_q(bfly10_q[z])
            );            
        end        
    endgenerate

    logic signed [11:0] w_stage11_BF_in_i[0:15];
    logic signed [11:0] w_stage11_BF_in_q[0:15];
    logic signed [12:0] w_stage11_BF_out_1_i[0:15];
    logic signed [12:0] w_stage11_BF_out_1_q[0:15];
    logic signed [12:0] w_stage11_SR_back_in_i[0:15];
    logic signed [12:0] w_stage11_SR_back_in_q[0:15];
    logic signed [12:0] w_stage11_SR_back_out_i[0:15];
    logic signed [12:0] w_stage11_SR_back_out_q[0:15];
    logic signed [12:0] w_stage11_tmp_i[0:15];
    logic signed [12:0] w_stage11_tmp_q[0:15];
    logic signed [9:0] fac8_1_i[0:15];
    logic signed [9:0] fac8_1_q[0:15];
    logic signed [22:0] temp_bfly11_i[0:15];
    logic signed [22:0] temp_bfly11_q[0:15];
    logic signed [13:0] bfly11_i[0:15];
    logic signed [13:0] bfly11_q[0:15];

    Shift_Register #(
        .Din_bit(12),
        .Length (16)
    ) stage_11_sr_front (
        .clk   (clk),
        .din_i (bfly10_i),
        .din_q (bfly10_q),
        .dout_i(w_stage11_BF_in_i),
        .dout_q(w_stage11_BF_in_q)
    );

    ButterFly #(
        .Din_bit(12)
    ) stage11_BF (
        .valid (1'b1),
        .din1_i(w_stage11_BF_in_i),
        .din1_q(w_stage11_BF_in_q),
        .din2_i(bfly10_i),
        .din2_q(bfly10_q),
        .do1_i (w_stage11_BF_out_1_i),
        .do1_q (w_stage11_BF_out_1_q),
        .do2_i (w_stage11_SR_back_in_i),
        .do2_q (w_stage11_SR_back_in_q)
    );

    Shift_Register #(
        .Din_bit(13),
        .Length (16)
    ) stage_11_sr_back (
        .clk   (clk),
        .din_i (w_stage11_SR_back_in_i),
        .din_q (w_stage11_SR_back_in_q),
        .dout_i(w_stage11_SR_back_out_i),
        .dout_q(w_stage11_SR_back_out_q)
    );

    wire mux_sel_stage11_back = ~count[0];

    MUX_2x1 #(
        .Din_bit(13)
    ) stage_11_back (
        .sel   (mux_sel_stage11_back),
        .din1_i(w_stage11_SR_back_out_i),
        .din1_q(w_stage11_SR_back_out_q),
        .din2_i(w_stage11_BF_out_1_i),
        .din2_q(w_stage11_BF_out_1_q),
        .dout_i(w_stage11_tmp_i),
        .dout_q(w_stage11_tmp_q)
    );

    logic [2:0] stage01_fac8_1_sel [1:0];
    
    always_comb begin
        stage01_fac8_1_sel[0]= ((count - 39)<<1);    
        stage01_fac8_1_sel[1]= (((count - 39)<<1)) + 1;    
    end

    genvar a;

    generate
        for (a = 0; a < 8; a++) begin
            fac8_1_rom FAC8_1_1 (
                .addr(stage01_fac8_1_sel[0]),
                .w_re(fac8_1_i[a]),
                .w_im(fac8_1_q[a])
            );
        end
        for (a = 8; a < 16; a++) begin
            fac8_1_rom FAC8_1_1 (
                .addr(stage01_fac8_1_sel[1]),
                .w_re(fac8_1_i[a]),
                .w_im(fac8_1_q[a])
            );
        end
    endgenerate

    Multiplier #(
        .Din_bit (13),
        .Dout_bit(23)
    ) stage11_fac8_1_multiplier (
        .din_i   (w_stage11_tmp_i),
        .din_q   (w_stage11_tmp_q),
        .weight_i(fac8_1_i),
        .weight_q(fac8_1_q),
        .dout_i  (temp_bfly11_i),
        .dout_q  (temp_bfly11_q)
    );

    round #(
        .Din_bit(23),
        .round_size(8),
        .Dout_bit(14)
    ) stage11_round (
        .din_i (temp_bfly11_i),
        .din_q (temp_bfly11_q),
        .dout_i(bfly11_i),
        .dout_q(bfly11_q)
    );

    logic signed [14:0] w_stage12_BF_out_i[0:15];
    logic signed [14:0] w_stage12_BF_out_q[0:15];
    logic signed [9:0] twf_m1_i[0:15];
    logic signed [9:0] twf_m1_q[0:15];
    logic signed [24:0] pre_bfly12_i[0:15];
    logic signed [24:0] pre_bfly12_q[0:15];
    logic [8:0] twf_m1_idx [0:15];

    always_comb begin
        for (int i =0 ;i<16 ;i++ ) begin
            twf_m1_idx[i] = ((count - 39) << 4) + i; 
        end
    end

    ButterFly_V2 #(
        .Din_bit(14),
        .Block  (1)
    ) stage12_bf (
        .din_i(bfly11_i),
        .din_q(bfly11_q),
        .do_i (w_stage12_BF_out_i),
        .do_q (w_stage12_BF_out_q)
    );

    genvar b;

    generate
        for (b = 0; b < 16; b++) begin
            twf_m1_rom stage12_twf_rom_1 (
                .addr(twf_m1_idx[b]),
                .w_re(twf_m1_i[b]),
                .w_im(twf_m1_q[b])
            );
        end
    endgenerate

    Multiplier #(
        .Din_bit (15),
        .Dout_bit(25)
    ) stage12_twf_m1_multiplier (
        .din_i   (w_stage12_BF_out_i),
        .din_q   (w_stage12_BF_out_q),
        .weight_i(twf_m1_i),
        .weight_q(twf_m1_q),
        .dout_i  (pre_bfly12_i),
        .dout_q  (pre_bfly12_q)
    );

    always_comb begin
        for (int i = 0; i < 16; i++) begin
            dout_i[i] = pre_bfly12_i[i];
            dout_q[i] = pre_bfly12_q[i];
        end
    end
endmodule
