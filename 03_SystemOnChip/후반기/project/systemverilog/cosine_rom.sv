`timescale 1ns / 1ps

module cosine_rom #(
    parameter DATA_WIDTH = 9,
    parameter BURST_SIZE = 16,
    parameter ADDR_WIDTH = 5
) (
    input  logic clk,
    input  logic rstn,
    input  logic [ADDR_WIDTH-1:0] addr,
    output logic signed [DATA_WIDTH-1:0] dout_i [0:BURST_SIZE-1],
    output logic signed [DATA_WIDTH-1:0] dout_q [0:BURST_SIZE-1]
);

    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dout_i <= '{default:0};
            dout_q <= '{default:0};
        end else begin
            case (addr)
                5'd0: begin
                    dout_i <= '{9'sd63,9'sd64,9'sd64,9'sd64,9'sd64,9'sd64,9'sd64,9'sd64,9'sd64,9'sd64,9'sd64,9'sd63,9'sd63,9'sd63,9'sd63,9'sd63};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd1: begin
                    dout_i <= '{9'sd63,9'sd63,9'sd62,9'sd62,9'sd62,9'sd62,9'sd62,9'sd61,9'sd61,9'sd61,9'sd61,9'sd61,9'sd60,9'sd60,9'sd60,9'sd59};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd2: begin
                    dout_i <= '{9'sd59,9'sd59,9'sd59,9'sd58,9'sd58,9'sd58,9'sd57,9'sd57,9'sd56,9'sd56,9'sd56,9'sd55,9'sd55,9'sd54,9'sd54,9'sd54};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd3: begin
                    dout_i <= '{9'sd53,9'sd53,9'sd52,9'sd52,9'sd51,9'sd51,9'sd50,9'sd50,9'sd49,9'sd49,9'sd48,9'sd48,9'sd47,9'sd47,9'sd46,9'sd46};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd4: begin
                    dout_i <= '{9'sd45,9'sd45,9'sd44,9'sd44,9'sd43,9'sd42,9'sd42,9'sd41,9'sd41,9'sd40,9'sd39,9'sd39,9'sd38,9'sd37,9'sd37,9'sd36};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd5: begin
                    dout_i <= '{9'sd36,9'sd35,9'sd34,9'sd34,9'sd33,9'sd32,9'sd32,9'sd31,9'sd30,9'sd29,9'sd29,9'sd28,9'sd27,9'sd27,9'sd26,9'sd25};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd6: begin
                    dout_i <= '{9'sd24,9'sd24,9'sd23,9'sd22,9'sd22,9'sd21,9'sd20,9'sd19,9'sd19,9'sd18,9'sd17,9'sd16,9'sd16,9'sd15,9'sd14,9'sd13};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd7: begin
                    dout_i <= '{9'sd12,9'sd12,9'sd11,9'sd10,9'sd9,9'sd9,9'sd8,9'sd7,9'sd6,9'sd5,9'sd5,9'sd4,9'sd3,9'sd2,9'sd2,9'sd1};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd8: begin
                    dout_i <= '{9'sd0,-9'sd1,-9'sd2,-9'sd2,-9'sd3,-9'sd4,-9'sd5,-9'sd5,-9'sd6,-9'sd7,-9'sd8,-9'sd9,-9'sd9,-9'sd10,-9'sd11,-9'sd12};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd9: begin
                    dout_i <= '{-9'sd12,-9'sd13,-9'sd14,-9'sd15,-9'sd16,-9'sd16,-9'sd17,-9'sd18,-9'sd19,-9'sd19,-9'sd20,-9'sd21,-9'sd22,-9'sd22,-9'sd23,-9'sd24};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd10: begin
                    dout_i <= '{-9'sd24,-9'sd25,-9'sd26,-9'sd27,-9'sd27,-9'sd28,-9'sd29,-9'sd29,-9'sd30,-9'sd31,-9'sd32,-9'sd32,-9'sd33,-9'sd34,-9'sd34,-9'sd35};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd11: begin
                    dout_i <= '{-9'sd36,-9'sd36,-9'sd37,-9'sd37,-9'sd38,-9'sd39,-9'sd39,-9'sd40,-9'sd41,-9'sd41,-9'sd42,-9'sd42,-9'sd43,-9'sd44,-9'sd44,-9'sd45};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd12: begin
                    dout_i <= '{-9'sd45,-9'sd46,-9'sd46,-9'sd47,-9'sd47,-9'sd48,-9'sd48,-9'sd49,-9'sd49,-9'sd50,-9'sd50,-9'sd51,-9'sd51,-9'sd52,-9'sd52,-9'sd53};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd13: begin
                    dout_i <= '{-9'sd53,-9'sd54,-9'sd54,-9'sd54,-9'sd55,-9'sd55,-9'sd56,-9'sd56,-9'sd56,-9'sd57,-9'sd57,-9'sd58,-9'sd58,-9'sd58,-9'sd59,-9'sd59};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd14: begin
                    dout_i <= '{-9'sd59,-9'sd59,-9'sd60,-9'sd60,-9'sd60,-9'sd61,-9'sd61,-9'sd61,-9'sd61,-9'sd61,-9'sd62,-9'sd62,-9'sd62,-9'sd62,-9'sd62,-9'sd63};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd15: begin
                    dout_i <= '{-9'sd63,-9'sd63,-9'sd63,-9'sd63,-9'sd63,-9'sd63,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd16: begin
                    dout_i <= '{-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd64,-9'sd63,-9'sd63,-9'sd63,-9'sd63,-9'sd63};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd17: begin
                    dout_i <= '{-9'sd63,-9'sd63,-9'sd62,-9'sd62,-9'sd62,-9'sd62,-9'sd62,-9'sd61,-9'sd61,-9'sd61,-9'sd61,-9'sd61,-9'sd60,-9'sd60,-9'sd60,-9'sd59};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd18: begin
                    dout_i <= '{-9'sd59,-9'sd59,-9'sd59,-9'sd58,-9'sd58,-9'sd58,-9'sd57,-9'sd57,-9'sd56,-9'sd56,-9'sd56,-9'sd55,-9'sd55,-9'sd54,-9'sd54,-9'sd54};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd19: begin
                    dout_i <= '{-9'sd53,-9'sd53,-9'sd52,-9'sd52,-9'sd51,-9'sd51,-9'sd50,-9'sd50,-9'sd49,-9'sd49,-9'sd48,-9'sd48,-9'sd47,-9'sd47,-9'sd46,-9'sd46};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd20: begin
                    dout_i <= '{-9'sd45,-9'sd45,-9'sd44,-9'sd44,-9'sd43,-9'sd42,-9'sd42,-9'sd41,-9'sd41,-9'sd40,-9'sd39,-9'sd39,-9'sd38,-9'sd37,-9'sd37,-9'sd36};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd21: begin
                    dout_i <= '{-9'sd36,-9'sd35,-9'sd34,-9'sd34,-9'sd33,-9'sd32,-9'sd32,-9'sd31,-9'sd30,-9'sd29,-9'sd29,-9'sd28,-9'sd27,-9'sd27,-9'sd26,-9'sd25};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd22: begin
                    dout_i <= '{-9'sd24,-9'sd24,-9'sd23,-9'sd22,-9'sd22,-9'sd21,-9'sd20,-9'sd19,-9'sd19,-9'sd18,-9'sd17,-9'sd16,-9'sd16,-9'sd15,-9'sd14,-9'sd13};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd23: begin
                    dout_i <= '{-9'sd12,-9'sd12,-9'sd11,-9'sd10,-9'sd9,-9'sd9,-9'sd8,-9'sd7,-9'sd6,-9'sd5,-9'sd5,-9'sd4,-9'sd3,-9'sd2,-9'sd2,-9'sd1};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd24: begin
                    dout_i <= '{9'sd0,9'sd1,9'sd2,9'sd2,9'sd3,9'sd4,9'sd5,9'sd5,9'sd6,9'sd7,9'sd8,9'sd9,9'sd9,9'sd10,9'sd11,9'sd12};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd25: begin
                    dout_i <= '{9'sd12,9'sd13,9'sd14,9'sd15,9'sd16,9'sd16,9'sd17,9'sd18,9'sd19,9'sd19,9'sd20,9'sd21,9'sd22,9'sd22,9'sd23,9'sd24};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd26: begin
                    dout_i <= '{9'sd24,9'sd25,9'sd26,9'sd27,9'sd27,9'sd28,9'sd29,9'sd29,9'sd30,9'sd31,9'sd32,9'sd32,9'sd33,9'sd34,9'sd34,9'sd35};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd27: begin
                    dout_i <= '{9'sd36,9'sd36,9'sd37,9'sd37,9'sd38,9'sd39,9'sd39,9'sd40,9'sd41,9'sd41,9'sd42,9'sd42,9'sd43,9'sd44,9'sd44,9'sd45};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd28: begin
                    dout_i <= '{9'sd45,9'sd46,9'sd46,9'sd47,9'sd47,9'sd48,9'sd48,9'sd49,9'sd49,9'sd50,9'sd50,9'sd51,9'sd51,9'sd52,9'sd52,9'sd53};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd29: begin
                    dout_i <= '{9'sd53,9'sd54,9'sd54,9'sd54,9'sd55,9'sd55,9'sd56,9'sd56,9'sd56,9'sd57,9'sd57,9'sd58,9'sd58,9'sd58,9'sd59,9'sd59};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd30: begin
                    dout_i <= '{9'sd59,9'sd59,9'sd60,9'sd60,9'sd60,9'sd61,9'sd61,9'sd61,9'sd61,9'sd61,9'sd62,9'sd62,9'sd62,9'sd62,9'sd62,9'sd63};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                5'd31: begin
                    dout_i <= '{9'sd63,9'sd63,9'sd63,9'sd63,9'sd63,9'sd63,9'sd64,9'sd64,9'sd64,9'sd64,9'sd64,9'sd64,9'sd64,9'sd64,9'sd64,9'sd64};
                    dout_q <= '{9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0,9'sd0};
                end
                default: begin
                    dout_i <= '{default:0};
                    dout_q <= '{default:0};
                end
            endcase
        end
    end
endmodule
