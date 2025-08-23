`timescale 1ns / 1ps

module DataPath (
    input  logic       clk,
    input  logic       reset,
    input  logic       RFSrcMuxSel,
    input  logic [2:0] RAddr1,
    input  logic [2:0] RAddr2,
    input  logic [2:0] WAddr,
    input  logic       we,
    output logic       R1Le10,
    input  logic       OutPortEn,
    output logic [7:0] OutPort
);

    logic [7:0] AdderResult, RFSrcMuxOut;
    logic [7:0] RData1, RData2;

    mux_2x1 U_RFSrcMUX (
        .sel(RFSrcMuxSel),
        .x0 (AdderResult),
        .x1 (8'd1),
        .y  (RFSrcMuxOut)
    );

    RegFile U_RegFile (
        .clk   (clk),
        .RAddr1(RAddr1),
        .RAddr2(RAddr2),
        .WAddr (WAddr),
        .we    (we),
        .WData (RFSrcMuxOut),
        .RData1(RData1),
        .RData2(RData2)
    );

    comparator U_R1Le10 (
        .a  (RData1),
        .b  (8'd10),
        .lte(R1Le10)
    );

    adder U_Adder (
        .a  (RData1),
        .b  (RData2),
        .sum(AdderResult)
    );

    register U_OutPort (
        .clk  (clk),
        .reset(reset),
        .en   (OutPortEn),
        .d    (RData1),
        .q    (OutPort)
    );
endmodule

module RegFile (
    input  logic       clk,
    input  logic [2:0] RAddr1,
    input  logic [2:0] RAddr2,
    input  logic [2:0] WAddr,
    input  logic       we,
    input  logic [7:0] WData,
    output logic [7:0] RData1,
    output logic [7:0] RData2
);
    logic [7:0] mem[0:2**3-1];  // 2^3

    assign RData1 = (RAddr1 == 0) ? 8'b0 : mem[RAddr1];
    assign RData2 = (RAddr2 == 0) ? 8'b0 : mem[RAddr2];

    always_ff @(posedge clk) begin
        if (we) begin
            mem[WAddr] <= WData;
        end
    end
endmodule

module register (
    input  logic       clk,
    input  logic       reset,
    input  logic       en,
    input  logic [7:0] d,
    output logic [7:0] q
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            if (en) begin
                q <= d;
            end
        end
    end
endmodule

module mux_2x1 (
    input  logic       sel,
    input  logic [7:0] x0,
    input  logic [7:0] x1,
    output logic [7:0] y
);
    always_comb begin
        y = 0;
        case (sel)
            1'b0: begin
                y = x0;
            end
            1'b1: begin
                y = x1;
            end
        endcase
    end
endmodule

module adder (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic [7:0] sum
);
    assign sum = a + b;
endmodule

module comparator (
    input  logic [7:0] a,
    input  logic [7:0] b,
    output logic       lte
);
    assign lte = (a <= b);
endmodule
