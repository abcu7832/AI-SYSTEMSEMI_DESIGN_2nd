`timescale 1ns / 1ps

module serial_to_parallel #(
    parameter P_SIZE = 16
) (
    input  logic              clk,
    input  logic              rstn,
    input  logic signed [8:0] data_in_i,
    input  logic signed [8:0] data_in_q,
    output logic signed [8:0] data_out_i[15:0],
    output logic signed [8:0] data_out_q[15:0],
    output logic              valid_out
);

    localparam CNT_WIDTH = $clog2(P_SIZE);

    logic        [CNT_WIDTH-1:0] counter;
    logic                        dout_valid_r;

    logic signed [          8:0] data_i       [P_SIZE-1:0];
    logic signed [          8:0] data_q       [P_SIZE-1:0];

    // === Counter ===
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) counter <= 0;
        else if (counter == P_SIZE - 1) counter <= 0;
        else counter <= counter + 1;
    end

    // === Shift Register (I/Q) ===
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (int i = 0; i < P_SIZE; i = i + 1) begin
                data_i[i] <= 0;
                data_q[i] <= 0;
            end
        end else begin
            for (int i = P_SIZE - 1; i > 0; i = i - 1) begin
                data_i[i] <= data_i[i-1];
                data_q[i] <= data_q[i-1];
            end
            data_i[0] <= data_in_i;
            data_q[0] <= data_in_q;
        end
    end
    genvar k;
    generate
        for (k = 0; k < P_SIZE; k++) begin
            assign data_out_i[k] = data_i[P_SIZE-1-k];
            assign data_out_q[k] = data_q[P_SIZE-1-k];
        end
    endgenerate
    // === dout_valid ===
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) dout_valid_r <= 0;
        else dout_valid_r <= (counter == P_SIZE - 1);
    end
    assign valid_out = dout_valid_r;

endmodule
