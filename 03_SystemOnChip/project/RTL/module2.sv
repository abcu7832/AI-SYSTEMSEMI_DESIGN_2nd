`timescale 1ns / 1ps

module module2 (
    input  logic                          clk,
    input  logic        [$clog2(100)-1:0] count,
    input  logic signed [           11:0] din_i    [0:15],
    input  logic signed [           11:0] din_q    [0:15],
    output logic signed [           15:0] dout_i   [0:15],
    output logic signed [           15:0] dout_q   [0:15],
    output logic                          valid_out
);

    logic signed [12:0] w_stage20_BF_out_i[0:15];
    logic signed [12:0] w_stage20_BF_out_q[0:15];
    logic signed [12:0] bfly20_i[0:15];
    logic signed [12:0] bfly20_q[0:15];

    assign valid_out = ((count >= 41) && (count <= 72));

    ButterFly_V2 #(
        .Din_bit(12),
        .Block  (2)
    ) stage20_bf (
        .din_i(din_i),
        .din_q(din_q),
        .do_i (w_stage20_BF_out_i),
        .do_q (w_stage20_BF_out_q)
    );

    genvar a;

    generate
        for (a = 0; a < 16; a++) begin
            fac8_0_V2 #(
                .Din_bit(13)
            ) U_stage20_fac8_0 (
                .sel   (a[2:1]),
                .din_i (w_stage20_BF_out_i[a]),
                .din_q (w_stage20_BF_out_q[a]),
                .dout_i(bfly20_i[a]),
                .dout_q(bfly20_q[a])
            );
        end
    endgenerate

    logic signed [13:0] w_stage21_BF_out_i[0:15];
    logic signed [13:0] w_stage21_BF_out_q[0:15];
    logic signed [9:0] fac8_1_i[0:15];
    logic signed [9:0] fac8_1_q[0:15];
    logic signed [23:0] temp_bfly21_i[0:15];
    logic signed [23:0] temp_bfly21_q[0:15];
    logic signed [14:0] bfly21_i[0:15];
    logic signed [14:0] bfly21_q[0:15];

    ButterFly_V2 #(
        .Din_bit(13),
        .Block  (4)
    ) stage21_bf (
        .din_i(bfly20_i),
        .din_q(bfly20_q),
        .do_i (w_stage21_BF_out_i),
        .do_q (w_stage21_BF_out_q)
    );

    genvar b;

    generate
        for (b = 0; b < 8; b++) begin
            fac8_1_rom FAC8_1_1 (
                .addr(b[2:0]),
                .w_re(fac8_1_i[b]),
                .w_im(fac8_1_q[b])
            );
            fac8_1_rom FAC8_1_2 (
                .addr(b[2:0]),
                .w_re(fac8_1_i[b+8]),
                .w_im(fac8_1_q[b+8])
            );
        end
    endgenerate

    Multiplier #(
        .Din_bit (14),
        .Dout_bit(24)
    ) stage21_fac8_1_multiplier (
        .din_i   (w_stage21_BF_out_i),
        .din_q   (w_stage21_BF_out_q),
        .weight_i(fac8_1_i),
        .weight_q(fac8_1_q),
        .dout_i  (temp_bfly21_i),
        .dout_q  (temp_bfly21_q)
    );

    round #(
        .Din_bit(24),
        .round_size(8),
        .Dout_bit(15)
    ) stage21_round (
        .din_i (temp_bfly21_i),
        .din_q (temp_bfly21_q),
        .dout_i(bfly21_i),
        .dout_q(bfly21_q)
    );

    logic signed [15:0] w_stage22_BF_out_i[0:15];
    logic signed [15:0] w_stage22_BF_out_q[0:15];

    ButterFly_V2 #(
        .Din_bit(15),
        .Block  (8)
    ) stage22_bf (
        .din_i(bfly21_i),
        .din_q(bfly21_q),
        .do_i (w_stage22_BF_out_i),
        .do_q (w_stage22_BF_out_q)
    );

    always_comb begin
        for (int i = 0; i < 16; i++) begin
            dout_i[i] = w_stage22_BF_out_i[i];
            dout_q[i] = w_stage22_BF_out_q[i];
        end
    end
endmodule
