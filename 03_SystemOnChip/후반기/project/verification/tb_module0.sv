`timescale 1ns / 1ps

module tb_module0;

    // Parameter
    localparam CLK_PERIOD = 2;  // 500MHz
    localparam TOTAL_SAMPLES = 512;
    localparam WIDTH = 9;
    localparam WIDTH_BF2 = 10;
    parameter int WIDTH_TEST = 21;
    // DUT Ports
    logic clk;
    logic rstn;
    logic signed [WIDTH-1:0] data_in_i;
    logic signed [WIDTH-1:0] data_in_q;
    logic signed [WIDTH_BF2-1:0] data_out_i[TOTAL_SAMPLES-1:0]; //WIDTH_BF2 data_out_i [Total]
    logic signed [WIDTH_BF2-1:0] data_out_q[TOTAL_SAMPLES-1:0];  //WIDTH_BF2 data_out_i [Total]
    logic valid_out;

    //test ports
    logic signed [WIDTH_TEST-1:0] test_out_i[0:TOTAL_SAMPLES-1]; //reverse total samples
    logic signed [WIDTH_TEST-1:0] test_out_q[0:TOTAL_SAMPLES-1];
    logic test_valid;
    // DUT Instance
    module0 #(
        .P_SIZE(16),
        .TOTAL_SIZE(TOTAL_SAMPLES),
        .WIDTH(WIDTH),
        .WIDTH_BF2(WIDTH_BF2)
    ) U1_module0 (
        .clk       (clk),
        .rstn      (rstn),
        .data_in_i (data_in_i),
        .data_in_q (data_in_q),
        .data_out_i(data_out_i),
        .data_out_q(data_out_q),
        .valid_out (valid_out),
        // test PORT
        .test_out_i(test_out_i),
        .test_out_q(test_out_q),
        .test_valid(test_valid)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Memory for input data
    reg signed [WIDTH-1:0] mem_i[0:TOTAL_SAMPLES-1];
    reg signed [WIDTH-1:0] mem_q[0:TOTAL_SAMPLES-1];

    integer fd_out, file_i, file_q;
    integer i;

    // === 파일 경로 ===
    string  file_i_path = "txt/cos_i_dat.txt";
    string  file_q_path = "txt/cos_q_dat.txt";
    string  out_file = "../../fft_output.txt";  // 프로젝트 루트에 저장



    initial begin
        // Reset
        rstn = 0;
        data_in_i = 0;
        data_in_q = 0;
        #(CLK_PERIOD * 5);
        rstn   = 1;

        // === Open input files ===
        file_i = $fopen(file_i_path, "r");
        file_q = $fopen(file_q_path, "r");

        if (file_i == 0 || file_q == 0) begin
            $display("ERROR: Cannot open input files.");
            $display("Check paths:");
            $display("%s", file_i_path);
            $display("%s", file_q_path);
            $finish;
        end

        // === Load input data ===
        for (i = 0; i < TOTAL_SAMPLES; i++) begin
            if ($fscanf(file_i, "%d\n", mem_i[i]) != 1) begin
                $display("ERROR: Reading cos_i_dat.txt failed at line %0d", i);
                $finish;
            end
            if ($fscanf(file_q, "%d\n", mem_q[i]) != 1) begin
                $display("ERROR: Reading cos_q_dat.txt failed at line %0d", i);
                $finish;
            end
        end

        $fclose(file_i);
        $fclose(file_q);
        $display("Input files loaded successfully.");

        // === Feed input samples ===
        for (i = 0; i < TOTAL_SAMPLES; i++) begin
            @(posedge clk);
            data_in_i = mem_i[i];
            data_in_q = mem_q[i];
        end

        // Wait for DUT output valid
        //wait (test_valid);
        repeat (400) @(posedge clk);
        //#1450;
        // === Save output to file ===
        fd_out = $fopen(out_file, "w");
        if (fd_out == 0) begin
            $display("ERROR: Cannot create output file.");
            $finish;
        end

        for (i = 0; i < TOTAL_SAMPLES; i++) begin
            $fwrite(fd_out, "%0d %0d\n", test_out_i[i], test_out_q[i]);
        end
        $fclose(fd_out);
        $display("Output saved to %s", out_file);

        // Display first 32 outputs
        for (i = 0; i < 32; i++) begin
            $display("OUT[%0d] = I:%0d, Q:%0d", i, data_out_i[i],
                     data_out_q[i]);
        end
        wait (test_valid);
        $finish;
    end
endmodule
