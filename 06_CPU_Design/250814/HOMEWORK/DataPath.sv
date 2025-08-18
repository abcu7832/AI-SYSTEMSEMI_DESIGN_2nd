`timescale 1ns / 1ps

module DataPath (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAdr,
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl
);
    logic signed [31:0] aluResult, RFData1, RFData2;
    logic [31:0] PCSrcData, PCOutData;

    assign instrMemAdr = PCOutData;

    RegisterFile U_RegFile (
        .clk(clk),
        .we (regFileWe),
        .RA1(instrCode[19:15]),
        .RA2(instrCode[24:20]),
        .WA (instrCode[11:7]),
        .WD (aluResult),
        .RD1(RFData1),
        .RD2(RFData2)
    );

    alu U_ALU (
        .aluControl(aluControl),
        .a         (RFData1),
        .b         (RFData2),
        .result    (aluResult)
    );

    register U_PC (
        .clk  (clk),
        .reset(reset),
        .en   (1'b1),
        .d    (PCSrcData),
        .q    (PCOutData)
    );

    adder U_PC_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PCSrcData)
    );

endmodule

module alu (
    input  logic        [ 3:0] aluControl,
    input  logic signed [31:0] a,
    input  logic signed [31:0] b,
    output logic signed [31:0] result
);

    always_comb begin
        result = 32'bx;
        case (aluControl)
            4'b0000: result = a + b;  //add
            4'b1000: result = a - b;  //sub
            4'b0001: result = a << b;  //sll
            4'b0101: result = a >> b;  //srl
            4'b1101: result = a >>> b;  //sra
            4'b0010: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;  //slt
            4'b0011:
            result = ($unsigned(a) < $unsigned(b)) ? 32'd1 : 32'd0;  //sltu
            4'b0100:
            result = a ^ b;  //xor                                                           
            4'b0110: result = a | b;  //or
            4'b0111: result = a & b;  //and
            default: result = 32'bx;
        endcase
    end
endmodule

module RegisterFile (
    input  logic               clk,
    input  logic               we,
    input  logic        [ 4:0] RA1,
    input  logic        [ 4:0] RA2,
    input  logic        [ 4:0] WA,
    input  logic signed [31:0] WD,
    output logic signed [31:0] RD1,
    output logic signed [31:0] RD2
);

    logic signed [31:0] mem[0:2**5-1];

    initial begin  //for simulation test 임의값
        mem[0] = -1;
        mem[1] = -1;
        for (int i = 2; i < 32; i++) begin
            mem[i] = 10 + i;
        end
    end

    always_ff @(posedge clk) begin
        if (we) begin
            mem[WA] <= WD;
        end
    end

    assign RD1 = (RA1 != 0) ? mem[RA1] : 32'b0;
    assign RD2 = (RA2 != 0) ? mem[RA2] : 32'b0;
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,
    input  logic [31:0] d,
    output logic [31:0] q
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

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);

    assign y = a + b;

endmodule
