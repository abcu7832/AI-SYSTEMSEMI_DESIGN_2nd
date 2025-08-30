module twf_m1_rom (
    input  logic        [8:0] addr,
    output logic signed [9:0] w_re,
    output logic signed [9:0] w_im
);

    always_comb begin
        case (addr&6'b111111)
            9'd0: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd1: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd2: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd3: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd4: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd5: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd6: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd7: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd8: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd9: begin
                w_re = 10'sd118;
                w_im = -10'sd49;
            end
            9'd10: begin
                w_re = 10'sd91;
                w_im = -10'sd91;
            end
            9'd11: begin
                w_re = 10'sd49;
                w_im = -10'sd118;
            end
            9'd12: begin
                w_re = 10'sd0;
                w_im = -10'sd128;
            end
            9'd13: begin
                w_re = -10'sd49;
                w_im = -10'sd118;
            end
            9'd14: begin
                w_re = -10'sd91;
                w_im = -10'sd91;
            end
            9'd15: begin
                w_re = -10'sd118;
                w_im = -10'sd49;
            end
            9'd16: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd17: begin
                w_re = 10'sd126;
                w_im = -10'sd25;
            end
            9'd18: begin
                w_re = 10'sd118;
                w_im = -10'sd49;
            end
            9'd19: begin
                w_re = 10'sd106;
                w_im = -10'sd71;
            end
            9'd20: begin
                w_re = 10'sd91;
                w_im = -10'sd91;
            end
            9'd21: begin
                w_re = 10'sd71;
                w_im = -10'sd106;
            end
            9'd22: begin
                w_re = 10'sd49;
                w_im = -10'sd118;
            end
            9'd23: begin
                w_re = 10'sd25;
                w_im = -10'sd126;
            end
            9'd24: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd25: begin
                w_re = 10'sd106;
                w_im = -10'sd71;
            end
            9'd26: begin
                w_re = 10'sd49;
                w_im = -10'sd118;
            end
            9'd27: begin
                w_re = -10'sd25;
                w_im = -10'sd126;
            end
            9'd28: begin
                w_re = -10'sd91;
                w_im = -10'sd91;
            end
            9'd29: begin
                w_re = -10'sd126;
                w_im = -10'sd25;
            end
            9'd30: begin
                w_re = -10'sd118;
                w_im = 10'sd49;
            end
            9'd31: begin
                w_re = -10'sd71;
                w_im = 10'sd106;
            end
            9'd32: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd33: begin
                w_re = 10'sd127;
                w_im = -10'sd13;
            end
            9'd34: begin
                w_re = 10'sd126;
                w_im = -10'sd25;
            end
            9'd35: begin
                w_re = 10'sd122;
                w_im = -10'sd37;
            end
            9'd36: begin
                w_re = 10'sd118;
                w_im = -10'sd49;
            end
            9'd37: begin
                w_re = 10'sd113;
                w_im = -10'sd60;
            end
            9'd38: begin
                w_re = 10'sd106;
                w_im = -10'sd71;
            end
            9'd39: begin
                w_re = 10'sd99;
                w_im = -10'sd81;
            end
            9'd40: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd41: begin
                w_re = 10'sd113;
                w_im = -10'sd60;
            end
            9'd42: begin
                w_re = 10'sd71;
                w_im = -10'sd106;
            end
            9'd43: begin
                w_re = 10'sd13;
                w_im = -10'sd127;
            end
            9'd44: begin
                w_re = -10'sd49;
                w_im = -10'sd118;
            end
            9'd45: begin
                w_re = -10'sd99;
                w_im = -10'sd81;
            end
            9'd46: begin
                w_re = -10'sd126;
                w_im = -10'sd25;
            end
            9'd47: begin
                w_re = -10'sd122;
                w_im = 10'sd37;
            end
            9'd48: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd49: begin
                w_re = 10'sd122;
                w_im = -10'sd37;
            end
            9'd50: begin
                w_re = 10'sd106;
                w_im = -10'sd71;
            end
            9'd51: begin
                w_re = 10'sd81;
                w_im = -10'sd99;
            end
            9'd52: begin
                w_re = 10'sd49;
                w_im = -10'sd118;
            end
            9'd53: begin
                w_re = 10'sd13;
                w_im = -10'sd127;
            end
            9'd54: begin
                w_re = -10'sd25;
                w_im = -10'sd126;
            end
            9'd55: begin
                w_re = -10'sd60;
                w_im = -10'sd113;
            end
            9'd56: begin
                w_re = 10'sd128;
                w_im = 10'sd0;
            end
            9'd57: begin
                w_re = 10'sd99;
                w_im = -10'sd81;
            end
            9'd58: begin
                w_re = 10'sd25;
                w_im = -10'sd126;
            end
            9'd59: begin
                w_re = -10'sd60;
                w_im = -10'sd113;
            end
            9'd60: begin
                w_re = -10'sd118;
                w_im = -10'sd49;
            end
            9'd61: begin
                w_re = -10'sd122;
                w_im = 10'sd37;
            end
            9'd62: begin
                w_re = -10'sd71;
                w_im = 10'sd106;
            end
            9'd63: begin
                w_re = 10'sd13;
                w_im = 10'sd127;
            end
            default: begin
                w_re = 10'sd0;
                w_im = 10'sd0;
            end
        endcase
    end
endmodule
