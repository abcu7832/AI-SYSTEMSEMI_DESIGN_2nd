`timescale 1ns / 1ps
`include "defines.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAdr,
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl,
    input  logic        AluSrcMuxSel,
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    input  logic [31:0] busRData,
    input  logic        RFWDSrcMuxSel
);
    logic [31:0] aluResult, RFData1, RFData2;
    logic [31:0] PCSrcData, PCOutData;
    logic [31:0] aluSrcMuxOut, immExt, RFWDSrcMuxOut, RFWData;
    
    assign instrMemAdr = PCOutData;
    assign busAddr     = aluResult;

    always_comb begin
        case (instrCode[6:0])
            `OP_TYPE_R: RFWData = RFWDSrcMuxOut;
            `OP_TYPE_L: begin
                if (instrCode[14:12] == `LB) begin
                    RFWData = {{24{RFWDSrcMuxOut[7]}}, RFWDSrcMuxOut[7:0]};
                end else if (instrCode[14:12] == `LH) begin
                    RFWData = {{16{RFWDSrcMuxOut[15]}}, RFWDSrcMuxOut[15:0]};
                end else if (instrCode[14:12] == `LBU) begin
                    RFWData = {{24'b0}, RFWDSrcMuxOut[7:0]};
                end else if (instrCode[14:12] == `LHU) begin
                    RFWData[15:0] = {{16'b0}, RFWDSrcMuxOut[15:0]};
                end else begin // LW
                    RFWData = RFWDSrcMuxOut;
                end
            end
            `OP_TYPE_I: RFWData = RFWDSrcMuxOut;
            `OP_TYPE_S: begin
                if (instrCode[14:12] == `SB) begin
                    busWData[31:8] = busRData[31:8];
                    busWData[7:0] = RFData2[7:0];
                end else if (instrCode[14:12] == `SH) begin
                    busWData[31:16] = busRData[31:16];
                    busWData[15:0] = RFData2[15:0];
                end else begin
                    busWData = RFData2;
                end 
            end
            default: busWData = RFData2;
        endcase
    end

    RegisterFile U_RegFile (
        .clk(clk),
        .we (regFileWe),
        .RA1(instrCode[19:15]),
        .RA2(instrCode[24:20]),
        .WA (instrCode[11:7]),
        .WD (RFWData),
        .RD1(RFData1),
        .RD2(RFData2)
    );

    mux_2x1 U_AluSrcMux (
        .sel(AluSrcMuxSel),
        .x0 (RFData2),
        .x1 (immExt),
        .y  (aluSrcMuxOut)
    );

    mux_2x1 U_RFWDSrcMux (
        .sel(RFWDSrcMuxSel),
        .x0 (aluResult),
        .x1 (busRData),
        .y  (RFWDSrcMuxOut)
    );

    alu U_ALU (
        .aluControl(aluControl),
        .a         (RFData1),
        .b         (aluSrcMuxOut),
        .result    (aluResult)
    );

    immExtend U_ImmExtend (
        .instrCode(instrCode),
        .immExt   (immExt)
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
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result
);

    always_comb begin
        result = 32'bx;
        case (aluControl)
            `ADD:    result = a + b;
            `SUB:    result = a - b;
            `SLL:    result = a << b;
            `SRL:    result = a >> b;
            `SRA:    result = $signed(a) >>> b;
            `SLT:    result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `SLTU:   result = ($unsigned(a) < $unsigned(b)) ? 32'd1 : 32'd0;
            `XOR:    result = a ^ b;
            `OR:     result = a | b;
            `AND:    result = a & b;
            default: result = 32'bx;
        endcase
    end
endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RA1,
    input  logic [ 4:0] RA2,
    input  logic [ 4:0] WA,
    input  logic [31:0] WD,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);

    logic [31:0] mem[0:2**5-1];

    initial begin  //for simulation test 임의값
        mem[0] = -1;
        mem[1] = -1;
        for (int i = 2; i < 31; i++) begin
            mem[i] = 10 + i;
        end
        mem[31] = 2**30;
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

module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);
    assign y = (sel) ? x1 : x0;
endmodule

module immExtend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_R: immExt = 32'bx;
            // {20{instrCode[31]}} => instrCode[31]을 20번 copy하겠다.
            `OP_TYPE_L: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_I: immExt = (instrCode[14:12] == 3'b101) ? {27'b0, instrCode[24:20]} : {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_S: immExt = {{20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]};
        endcase
    end
endmodule
