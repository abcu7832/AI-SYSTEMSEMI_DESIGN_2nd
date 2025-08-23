`timescale 1ns / 1ps

module ControlUnit (
    input  logic       clk,
    input  logic       reset,
    output logic       RFSrcMuxSel,
    output logic [2:0] RAddr1,
    output logic [2:0] RAddr2,
    output logic [2:0] WAddr,
    output logic       we,
    input  logic       R1Le10,
    output logic       OutPortEn
);

    typedef enum {
        S0,
        S1,
        S2,
        S3,
        S4,
        S5,
        S6,
        S7
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
        next_state  = state;
        RFSrcMuxSel = 0;
        RAddr1      = 0;
        RAddr2      = 0;
        WAddr       = 0;
        we          = 0;
        OutPortEn   = 0;
        case (state)
            S0: begin
                RFSrcMuxSel = 0;
                RAddr1      = 0;
                RAddr2      = 0;
                WAddr       = 1;
                we          = 1;
                OutPortEn   = 0;
                next_state  = S1;
            end
            S1: begin
                RFSrcMuxSel = 0;
                RAddr1      = 0;
                RAddr2      = 0;
                WAddr       = 2;
                we          = 1;
                OutPortEn   = 0;
                next_state  = S2;
            end
            S2: begin
                RFSrcMuxSel = 1;
                RAddr1      = 0;
                RAddr2      = 0;
                WAddr       = 3;
                we          = 1;
                OutPortEn   = 0;
                next_state  = S3;
            end
            S3: begin
                RFSrcMuxSel = 0;
                RAddr1      = 1;
                RAddr2      = 0;
                WAddr       = 0;
                we          = 0;
                OutPortEn   = 0;
                if (R1Le10) begin
                    next_state = S4;
                end else begin
                    next_state = S7;
                end
            end
            S4: begin
                RFSrcMuxSel = 0;
                RAddr1      = 1;
                RAddr2      = 2;
                WAddr       = 2;
                we          = 1;
                OutPortEn   = 0;
                next_state  = S5;
            end
            S5: begin
                RFSrcMuxSel = 0;
                RAddr1      = 1;
                RAddr2      = 3;
                WAddr       = 1;
                we          = 1;
                OutPortEn   = 0;
                next_state  = S6;
            end
            S6: begin
                RFSrcMuxSel = 0;
                RAddr1      = 2;
                RAddr2      = 0;
                WAddr       = 0;
                we          = 0;
                OutPortEn   = 1;
                next_state  = S3;
            end
            S7: begin
                RFSrcMuxSel = 0;
                RAddr1      = 0;
                RAddr2      = 0;
                WAddr       = 0;
                we          = 0;
                OutPortEn   = 0;
                next_state  = S7;
            end
        endcase
    end
endmodule
