`timescale 1ns / 1ps

module DedicatedProcessor_Counter_V2 (
    input  logic       clk,
    input  logic       reset,
    output logic [7:0] Output
);
    logic       ASrcMuxSel;
    logic       AEn;
    logic       ALt10;
    logic       addMuxSel;
    logic       sumMuxSel;
    logic       SumEn;
    logic       OutputEn;

    DataPath U_DataPath (
        .clk(clk),
        .reset(reset),
        .ASrcMuxSel(ASrcMuxSel),
        .AEn(AEn),
        .ALt10(ALt10),
        .addMuxSel(addMuxSel),
        .sumMuxSel(sumMuxSel),
        .SumEn(SumEn),
        .OutputEn(OutputEn),
        .Outreg(Output)
    );

    ControlUnit U_ControlUnit(
        .clk(clk),
        .reset(reset),
        .ASrcMuxSel(ASrcMuxSel),
        .AEn(AEn),
        .ALt10(ALt10),
        .addMuxSel(addMuxSel),
        .sumMuxSel(sumMuxSel),
        .SumEn(SumEn),
        .OutputEn(OutputEn)
    );
endmodule

module DataPath (
    input  logic       clk,
    input  logic       reset,
    input  logic       ASrcMuxSel,
    input  logic       AEn,
    output logic       ALt10,
    input  logic       addMuxSel,
    input  logic       sumMuxSel,
    input  logic       SumEn,
    input  logic       OutputEn,
    output logic [7:0] Outreg
);

    logic [7:0] ASrcMuxOut, ARegOut, SumRegIn, SumRegOut;
    logic [7:0] Adder_in1, Adder_in2, AdderResult;

    mux_2x1 U_ASrcMux (
        .sel(ASrcMuxSel),
        .x0 (8'b0),
        .x1 (AdderResult),
        .y  (ASrcMuxOut)
    );

    register U_A_Reg (
        .clk  (clk),
        .reset(reset),
        .en   (AEn),
        .d    (ASrcMuxOut),
        .q    (Adder_in1)
    );

    comparator U_ALt10 (
        .a (Adder_in1),
        .b (8'd11),
        .lt(ALt10)
    );

    mux_2x1 U_AddMux (
        .sel(addMuxSel),
        .x0 (8'b1),
        .x1 (SumRegOut),
        .y  (Adder_in2)
    );

    adder U_Adder (
        .a  (Adder_in1),
        .b  (Adder_in2),
        .sum(AdderResult)
    );

    mux_2x1 U_SumMux (
        .sel(sumMuxSel),
        .x0 (8'b0),
        .x1 (AdderResult),
        .y  (SumRegIn)
    );

    register U_Sum_Reg (
        .clk  (clk),
        .reset(reset),
        .en   (SumEn),
        .d    (SumRegIn),
        .q    (SumRegOut)
    );

    register U_Reg_Output (
        .clk  (clk),
        .reset(reset),
        .en   (OutputEn),
        .d    (SumRegOut),
        .q    (Outreg)
    );
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
    output logic       lt
);
    assign lt = a < b;
endmodule

module ControlUnit (
    input  logic       clk,
    input  logic       reset,
    output logic       ASrcMuxSel,
    output logic       AEn,
    input  logic       ALt10,
    output logic       addMuxSel,
    output logic       sumMuxSel,
    output logic       SumEn,
    output logic       OutputEn
);
    typedef enum {
        S0,
        S1,
        S2,
        S3,
        S4,
        S5
    } state_e;

    state_e state, next_state;

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            state <= S0;
        end else begin
            state <= next_state;
        end
    end

    always_comb begin
        ASrcMuxSel = 0;
        AEn        = 0;
        addMuxSel  = 0;
        sumMuxSel  = 0;
        SumEn      = 0;
        OutputEn   = 0;
        next_state = state;
        case (state)
            S0: begin
                ASrcMuxSel = 0;
                AEn        = 1;
                addMuxSel  = 0;
                sumMuxSel  = 0;
                SumEn      = 1;
                OutputEn   = 0;
                next_state = S1;
            end
            S1: begin
                ASrcMuxSel = 0; // don't care
                AEn        = 0;
                addMuxSel  = 0;
                sumMuxSel  = 0;
                SumEn      = 0;
                OutputEn   = 0;
                if (ALt10) begin // 이하인 경우
                    next_state = S2;
                end else begin
                    next_state = S5;
                end
            end
            S2: begin
                ASrcMuxSel = 0; // don't care
                AEn        = 0;
                addMuxSel  = 0;
                sumMuxSel  = 1; // don't care
                SumEn      = 0;
                OutputEn   = 1;
                next_state = S3;
            end
            S3: begin
                ASrcMuxSel = 1; // don't care
                AEn        = 1;
                addMuxSel  = 0;
                sumMuxSel  = 1;
                SumEn      = 0;
                OutputEn   = 0;
                next_state = S4;
            end
            S4: begin
                ASrcMuxSel = 0; // don't care
                AEn        = 0;
                addMuxSel  = 1;
                sumMuxSel  = 1;
                SumEn      = 1;
                OutputEn   = 0;
                next_state = S1;
            end
            S5: begin
                ASrcMuxSel = 0; // don't care
                AEn        = 0;
                addMuxSel  = 0; // don't care
                sumMuxSel  = 1; // don't care
                SumEn      = 0;
                OutputEn   = 0;
                next_state = S5;                
            end
        endcase
    end
endmodule
