`timescale 1ns / 1ps
`include "defines.sv"

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl,
    output logic        AluSrcMuxSel,
    output logic        busWe,
    output logic        RFWDSrcMuxSel
);

    wire  [6:0] opcode = instrCode[6:0];
    wire  [3:0] operator = {instrCode[30], instrCode[14:12]};
    logic [3:0] signals;
    assign {regFileWe, AluSrcMuxSel, busWe, RFWDSrcMuxSel} = signals;

    always_comb begin
        signals = 4'b0;
        case (opcode)
            // {regFileWe, AluSrcMuxSel, busWe, RFWDSrcMuxSel} = signals;
            `OP_TYPE_R: signals = 4'b1_0_0_0;
            `OP_TYPE_L: signals = 4'b1_1_0_1;
            `OP_TYPE_I: signals = 4'b1_1_0_0;
            `OP_TYPE_S: signals = 4'b0_1_1_0;
        endcase
    end

    always_comb begin
        aluControl = 4'bxxxx;
        case (opcode)
            `OP_TYPE_R: aluControl = operator;
            `OP_TYPE_L: aluControl = `ADD;
            `OP_TYPE_I: begin 
                if(operator[2:0] == 3'b101) begin
                    aluControl = operator;     
                end else begin
                    aluControl = {1'b0, operator[2:0]};
                end
            end
            `OP_TYPE_S: aluControl = `ADD;
        endcase
    end
endmodule
