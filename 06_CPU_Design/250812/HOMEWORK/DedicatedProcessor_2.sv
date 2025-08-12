`timescale 1ns / 1ps

module DedicatedProcessor(
    input logic         clk,
    input logic reset,
    output logic [7:0] OutPort
);

    logic       RFSrcMuxSel;
    logic [2:0] RAddr1;
    logic [2:0] RAddr2;
    logic [2:0] WAddr;
    logic       we;
    logic       Lt;
    logic [1:0] alu_op;
    logic       OutPortEn;

    DataPath U_DataPath (
        .clk(clk),
        .reset(reset),
        .RFSrcMuxSel(RFSrcMuxSel),
        .RAddr1(RAddr1),
        .RAddr2(RAddr2),
        .WAddr(WAddr),
        .we(we),
        .Lt(Lt),
        .alu_op(alu_op),
        .OutPortEn(OutPortEn),
        .OutPort(OutPort)
    );

    ControlUnit U_ControlUnit (
        .clk(clk),
        .reset(reset),
        .RFSrcMuxSel(RFSrcMuxSel),
        .RAddr1(RAddr1),
        .RAddr2(RAddr2),
        .WAddr(WAddr),
        .we(we),
        .Lt(Lt),
        .alu_op(alu_op),
        .OutPortEn(OutPortEn)
    );
endmodule
