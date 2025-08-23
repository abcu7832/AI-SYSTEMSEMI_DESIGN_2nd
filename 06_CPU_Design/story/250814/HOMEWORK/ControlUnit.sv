`timescale 1ns / 1ps

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic [ 3:0] aluControl
);

    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operator = {instrCode[30], instrCode[14:12]};

    always_comb begin
        regFileWe = 1'b0;
        case (opcode)
            7'b0110011: regFileWe = 1'b1;  //R-Tpye
        endcase
    end

    always_comb begin
        aluControl = 4'bxxxx;
        case (opcode)
            7'b0110011: begin
                case (operator)
                    4'b0000: aluControl = 4'b0000;  //add
                    4'b1000: aluControl = 4'b1000;  //sub
                    4'b0001: aluControl = 4'b0001;  //sll
                    4'b0101: aluControl = 4'b0101;  //srl
                    4'b1101: aluControl = 4'b1101;  //sra
                    4'b0010: aluControl = 4'b0010;  //slt
                    4'b0011: aluControl = 4'b0011;  //sltu
                    4'b0100: aluControl = 4'b0100;  //xor                                                           
                    4'b0110: aluControl = 4'b0110;  //or
                    4'b0111: aluControl = 4'b0111;  //and
                    default: aluControl = 4'bxxxx;
                endcase
            end
        endcase
    end
endmodule
