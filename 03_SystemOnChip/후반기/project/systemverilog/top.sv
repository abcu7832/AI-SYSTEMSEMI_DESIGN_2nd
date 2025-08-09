`timescale 1ns / 1ps

module top #(
    parameter P_SIZE       	= 16,	// Parallel Port size
    parameter TOTAL_SIZE   	= 512,  // 512 POINTS
    parameter WIDTH_INPUT  	= 9,    // DATA INPUT TO MODULE WIDTH
    parameter WIDTH_OUTPUT 	= 13,    // FFT RESULT DATA  WIDTH 13
	parameter WIDTH_TEST   	= 26
) (
    input  logic clk
);
    logic signed [12:0] data_out_i[0:511];
    logic signed [12:0] data_out_q[0:511];
    logic do_en;
    
	logic [5:0] rst_cnt;
    logic rstn_vio;
	logic data_enable;
    logic [5:0] d_cnt;
	logic din_en;
    logic rstn_sync;
    //logic rstn = 1;

    assign rstn_sync = rstn_vio;

    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync)
			rst_cnt <= 6'd0;
		else if (rst_cnt < 10)
			rst_cnt <= rst_cnt + 1'b1;
		else
			rst_cnt <= rst_cnt;
	end
 
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync)
			d_cnt <= 6'd0;
		else if ((rst_cnt==6'd10) && (d_cnt < 39))
			d_cnt <= d_cnt + 1'b1;
		else
			d_cnt <= 6'd0;
	end
 
    always @(posedge clk or negedge rstn_sync) begin
        if (!rstn_sync)
			din_en <= 1'b0;
		else if ((rst_cnt==6'd10) && (d_cnt < 6'd32))
			din_en <= 1'b1;
		else
			din_en <= 1'b0;
	end
 
    logic signed [WIDTH_INPUT-1:0] din_i [0:P_SIZE-1];
    logic signed [WIDTH_INPUT-1:0] din_q [0:P_SIZE-1];

    cosine_rom #(
		.BURST_SIZE	(P_SIZE),
        .DATA_WIDTH (WIDTH_INPUT),
		.ADDR_WIDTH (5)
    ) u_cosine_rom (
        .clk      	(clk),
        .rstn     	(rstn_sync),
        .addr     	(d_cnt[4:0]),
        .dout_i   	(din_i),
        .dout_q  	(din_q)
    );

    fft_top #(
        .TOTAL_SIZE  (512),
        .INPUT_LENGHT(16),
        .WIDTH_INPUT (9),
        .WIDTH_OUTPUT(13)
    ) u1_fft_top (
        .clk       (clk),
        .rstn      (rstn_sync),
        .data_valid(din_en),   //input enable
        .din_i     (din_i),
        .din_q     (din_q),
        .do_en     (do_en),            //output enable
        .do_re     (data_out_i),
        .do_im     (data_out_q)
    );
	
    // 한 클락 당 실수 16개, 허수 16개를 출력하기 위함.
    // vio 포트가 256개로 한정되어 영상처럼 16개씩으로 설정.
    logic [4:0] cnt_32;
    logic cnt_f;
    always @(posedge clk, negedge rstn_sync) begin
        if(!rstn_sync) begin
            cnt_32 <= 0;
            cnt_f <= 0;
        end else if(do_en) begin
            if(cnt_f) begin
               cnt_32 <= cnt_32 + 1; 
            end
            cnt_f <= 1;
        end else begin
            cnt_f <= 0;
            cnt_32 <= 0;
        end
    end

    // ========================
    // VIO Instance
    // ========================
    vio_0 u_vio (
        .clk(clk),

        // probe_in0: do_en
        .probe_in0(do_en),

        // probe_in1 ~ probe_in32: data_out_i[0:15], data_out_q[0:15]
        .probe_in1 (data_out_i[(cnt_32<<4) + 0]),
        .probe_in2 (data_out_i[(cnt_32<<4) + 1]),
        .probe_in3 (data_out_i[(cnt_32<<4) + 2]),
        .probe_in4 (data_out_i[(cnt_32<<4) + 3]),
        .probe_in5 (data_out_i[(cnt_32<<4) + 4]),
        .probe_in6 (data_out_i[(cnt_32<<4) + 5]),
        .probe_in7 (data_out_i[(cnt_32<<4) + 6]),
        .probe_in8 (data_out_i[(cnt_32<<4) + 7]),
        .probe_in9 (data_out_i[(cnt_32<<4) + 8]),
        .probe_in10(data_out_i[(cnt_32<<4) + 9]),
        .probe_in11(data_out_i[(cnt_32<<4) + 10]),
        .probe_in12(data_out_i[(cnt_32<<4) + 11]),
        .probe_in13(data_out_i[(cnt_32<<4) + 12]),
        .probe_in14(data_out_i[(cnt_32<<4) + 13]),
        .probe_in15(data_out_i[(cnt_32<<4) + 14]),
        .probe_in16(data_out_i[(cnt_32<<4) + 15]),

        .probe_in17(data_out_q[(cnt_32<<4) + 0]),
        .probe_in18(data_out_q[(cnt_32<<4) + 1]),
        .probe_in19(data_out_q[(cnt_32<<4) + 2]),
        .probe_in20(data_out_q[(cnt_32<<4) + 3]),
        .probe_in21(data_out_q[(cnt_32<<4) + 4]),
        .probe_in22(data_out_q[(cnt_32<<4) + 5]),
        .probe_in23(data_out_q[(cnt_32<<4) + 6]),
        .probe_in24(data_out_q[(cnt_32<<4) + 7]),
        .probe_in25(data_out_q[(cnt_32<<4) + 8]),
        .probe_in26(data_out_q[(cnt_32<<4) + 9]),
        .probe_in27(data_out_q[(cnt_32<<4) + 10]),
        .probe_in28(data_out_q[(cnt_32<<4) + 11]),
        .probe_in29(data_out_q[(cnt_32<<4) + 12]),
        .probe_in30(data_out_q[(cnt_32<<4) + 13]),
        .probe_in31(data_out_q[(cnt_32<<4) + 14]),
        .probe_in32(data_out_q[(cnt_32<<4) + 15]),

        // probe_out0, probe_out1 (예: 수동 control)
        .probe_out0(rstn_vio), 
        .probe_out1()
    );
endmodule

