`timescale 1ns / 1ps

module DedicatedProcessor (
    input  logic       clk,
    input  logic       reset,
    output logic [7:0] OutPort
);

    logic [2:0] RAddr1;
    logic [2:0] RAddr2;
    logic [2:0] WAddr;
    logic RFSrcMuxSel, we, R1Le10, OutPortEn;

    DataPath U_DataPath (
        .clk        (clk),
        .reset      (reset),
        .RFSrcMuxSel(RFSrcMuxSel),
        .RAddr1     (RAddr1),
        .RAddr2     (RAddr2),
        .WAddr      (WAddr),
        .we         (we),
        .R1Le10     (R1Le10),
        .OutPortEn  (OutPortEn),
        .OutPort    (OutPort)
    );

    ControlUnit U_ControlUnit (
        .clk        (clk),
        .reset      (reset),
        .RFSrcMuxSel(RFSrcMuxSel),
        .RAddr1     (RAddr1),
        .RAddr2     (RAddr2),
        .WAddr      (WAddr),
        .we         (we),
        .R1Le10     (R1Le10),
        .OutPortEn  (OutPortEn)
    );

endmodule

