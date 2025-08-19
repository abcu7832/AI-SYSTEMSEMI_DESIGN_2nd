`timescale 1ns / 1ps

module CPU_RV32I (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    output logic        busWe,
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    input  logic [31:0] busRData
);

    logic       regFileWe;
    logic [3:0] aluControl;
    logic       aluSrcMuxSel;
    logic       RFWDSrcMuxSel;
    logic       branch;
    logic       wDataMuxSel;
    logic       imm_imm12_MuxSel;
    logic       ADDSrcMuxSel;
    logic       other_upMuxSel;
    logic       other_downMuxSel;
    logic       updownMuxSel;
    logic       PCSrcMuxSel_sel;

    ControlUnit U_ControlUnit (.*);
    DataPath U_DataPath (.*);
endmodule
