`timescale 1ns / 1ps

module button_detector (
    input logic clk,  // system clk 100MHz
    input logic reset,
    input logic in_button,
    output logic rising_edge,
    output logic fallng_edge,
    output logic both_edge
);
    logic debounce;
    logic [7:0] sh_reg;
    logic clk_1khz;
    logic [$clog2(100_000)-1:0] div_count;

    // clk_div를 통해 분주해서 들어감 1kHzv
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            div_count <= 0;
            clk_1khz  <= 1'b0;
        end else begin
            if (div_count == 100_000 - 1) begin
                div_count <= 0;
                clk_1khz  <= 1'b1;
            end else begin
                div_count <= div_count + 1;
                clk_1khz  <= 1'b0;
            end
        end
    end

    shift_register U_0 (
        .clk(clk_1khz),
        .reset(reset),
        .in_data(in_button),
        .out_data(sh_reg)
    );

    assign debounce = &sh_reg;

    logic [1:0] edge_reg;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            edge_reg <= 0;
        end else begin
            edge_reg[0] <= debounce;
            edge_reg[1] <= edge_reg[0];
        end
    end

    assign rising_edge = edge_reg[0] & ~edge_reg[1];
    assign fallng_edge = ~edge_reg[0] & edge_reg[1];
    assign both_edge   = rising_edge | fallng_edge;

endmodule

module shift_register (
    input logic clk,
    input logic reset,
    input logic in_data,
    output logic [7:0] out_data
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            out_data <= 0;
        end else begin
            out_data <= {in_data, out_data[7:1]};  // right shift
            // out_data <= {out_data[6:0], in_data}; // left shift
        end
    end
endmodule

