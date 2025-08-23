`timescale 1ns / 1ps
`include "defines.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    input  logic        regFileWe,
    input  logic [ 3:0] aluControl,
    input  logic        aluSrcMuxSel,
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    input  logic [31:0] busRData,
    input  logic        RFWDSrcMuxSel,
    input  logic        branch,
    input  logic        wDataMuxSel,
    input  logic        imm_imm12_MuxSel,
    input  logic        ADDSrcMuxSel,
    input  logic        other_upMuxSel,
    input  logic        other_downMuxSel,
    input  logic        updownMuxSel,
    input  logic        PCSrcMuxSel_sel
);

    logic [31:0] aluResult, RFData1, RFData2;
    logic [31:0] PCOutData;
    logic [31:0] aluSrcMuxOut, immExt, RFWDSrcMuxOut;
    logic [31:0] PC_4_AdderResult, PC_Imm_AdderResult, PCSrcMuxOut;
    logic [31:0] immExt_12, immExt_immExt_12_out, ADDSrcMuxOut;
    logic [31:0] otherData, other_upData, other_downData;
    logic [31:0] RF_wData;
    logic btaken, PCSrcMuxSel;

    assign instrMemAddr = PCOutData;
    assign busAddr = aluResult;
    assign busWData = RFData2;

    RegisterFile U_RegFile (
        .clk(clk),
        .we (regFileWe),
        .RA1(instrCode[19:15]),
        .RA2(instrCode[24:20]),
        .WA (instrCode[11:7]),
        .WD (RF_wData),
        .RD1(RFData1),
        .RD2(RFData2)
    );

    mux_2x1 U_AluSrcMux (
        .sel(aluSrcMuxSel),
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

    mux_2x1 U_other_upDataMux (
        .sel(other_upMuxSel),
        .x0 (immExt_12),
        .x1 (PC_Imm_AdderResult),
        .y  (other_upData)
    );

    mux_2x1 U_other_downDataMux (
        .sel(other_downMuxSel),
        .x0 (PC_4_AdderResult),
        .x1 (PC_Imm_AdderResult),
        .y  (other_downData)
    );

    mux_2x1 U_otherDataMux (
        .sel(updownMuxSel),
        .x0 (other_upData),
        .x1 (other_downData),
        .y  (otherData)
    );

    mux_2x1 U_wDataSrcMux (
        .sel(wDataMuxSel),
        .x0 (RFWDSrcMuxOut),
        .x1 (otherData),
        .y  (RF_wData)
    );

    alu U_ALU (
        .aluControl(aluControl),
        .a         (RFData1),
        .b         (aluSrcMuxOut),
        .result    (aluResult),
        .btaken    (btaken)
    );

    immExtend U_ImmExtend (
        .instrCode(instrCode),
        .immExt   (immExt)
    );

    shift_12 U_shift_12 (
        .din (immExt),
        .dout(immExt_12)
    );

    mux_2x1 U_imm_imm12_mux (
        .sel(imm_imm12_MuxSel),
        .x0 (immExt_12),
        .x1 (immExt),
        .y  (immExt_immExt_12_out)
    );

    adder U_PC_4_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PC_4_AdderResult)
    );

    mux_2x1 U_rs1_pc_mux (
        .sel(ADDSrcMuxSel),
        .x0 (PCOutData),
        .x1 (RFData1),
        .y  (ADDSrcMuxOut)
    );

    adder U_PC_Imm_Adder (
        .a(ADDSrcMuxOut),
        .b(immExt_immExt_12_out),
        .y(PC_Imm_AdderResult)
    );

    assign PCSrcMuxSel = (instrCode[6:0] == `OP_TYPE_B) ? (branch & btaken) : PCSrcMuxSel_sel;

    mux_2x1 U_PCSrcMux (
        .sel(PCSrcMuxSel),
        .x0 (PC_4_AdderResult),
        .x1 (PC_Imm_AdderResult),
        .y  (PCSrcMuxOut)
    );

    register U_PC (
        .clk  (clk),
        .reset(reset),
        .en   (1'b1),
        .d    (PCSrcMuxOut),
        .q    (PCOutData)
    );
endmodule

module shift_12 (
    input  logic [31:0] din,
    output logic [31:0] dout
);
    assign dout = din << 12;
endmodule

module alu (
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result,
    output logic        btaken
);
    always_comb begin
        result = 32'bx;
        case (aluControl)
            `ADD:  result = a + b;
            `SUB:  result = a - b;
            `SLL:  result = a << b;
            `SRL:  result = a >> b;
            `SRA:  result = $signed(a) >>> b;
            `SLT:  result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLTU: result = (a < b) ? 1 : 0;
            `XOR:  result = a ^ b;
            `OR:   result = a | b;
            `AND:  result = a & b;
        endcase
    end

    always_comb begin : branch
        btaken = 1'b0;
        case (aluControl[2:0])
            `BEQ:    btaken = (a == b);
            `BNE:    btaken = (a != b);
            `BLT:    btaken = ($signed(a) < $signed(b));
            `BGE:    btaken = ($signed(a) >= $signed(b));
            `BLTU:   btaken = (a < b);
            `BGEU:   btaken = (a >= b);
            default: btaken = 1'b0;
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

    initial begin  // for simulation test
        for (int i = 0; i < 32; i++) begin
            mem[i] = 10 + i;
        end
    end

    always_ff @(posedge clk) begin
        if (we) mem[WA] <= WD;
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
            if (en) q <= d;
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
    always_comb begin
        y = 32'bx;
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
        endcase
    end
endmodule

module immExtend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];
    wire [2:0] func3 = instrCode[14:12];

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_R: immExt = 32'bx;
            `OP_TYPE_L: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_S:
            immExt = {{20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]};
            `OP_TYPE_I: begin
                case (func3)
                    3'b011:  immExt = {20'b0, instrCode[31:20]};  // SLTIU
                    3'b001:  immExt = {27'b0, instrCode[24:20]};  // SLLI
                    3'b101:  immExt = {27'b0, instrCode[24:20]};  // SRLI, SRAI
                    default: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
                endcase
            end
            `OP_TYPE_B:
            immExt = {
                {20{instrCode[31]}},
                instrCode[7],
                instrCode[30:25],
                instrCode[11:8],
                1'b0
            };
            `OP_TYPE_LU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_AU: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_J:
            immExt = {
                {11{instrCode[31]}},  //31~21
                instrCode[31],  //20
                instrCode[19:12],  //19~12
                instrCode[20],  //11
                instrCode[30:21]  //10~1
            };
            `OP_TYPE_JL: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
        endcase
    end
endmodule
