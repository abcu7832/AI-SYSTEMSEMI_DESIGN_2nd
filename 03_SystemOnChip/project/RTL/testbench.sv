`timescale 1ns / 1ps

module testbench();

    logic               clk;
    logic               rstn;
    logic               din_valid;
    logic signed [ 8:0] din_i    [ 0:15];
    logic signed [ 8:0] din_q    [ 0:15];
    logic               do_en;
    logic signed [12:0] do_re    [0:511];
    logic signed [12:0] do_im    [0:511];

    fft_top dut (.*);

    // === 파일 경로 ===
    string file_i_path = "cos_i_dat.txt";
    string file_q_path = "cos_q_dat.txt";
    string out_file = "fft_output.txt";  // 프로젝트 루트에 저장
    // Memory for input data
    logic signed [8:0] mem_i[0:511];
    logic signed [8:0] mem_q[0:511];
    integer fd_out, file_i, file_q;
    integer i, j;

    initial begin
        clk = 1;
        din_valid=0;
        rstn=0;
    end

    always #5 clk = ~clk;

    initial begin
        #10;
        rstn=1;    
        din_valid=1;
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
        for (i = 0; i < 512; i++) begin
            if ($fscanf(file_i, "%d %d\n", mem_i[i]) != 1) begin
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

        // === Save output to file ===
        fd_out = $fopen(out_file, "w");
        if (fd_out == 0) begin
            $display("ERROR: Cannot create output file.");
            $finish;
        end

        // === Feed input samples ===
        for (i = 0; i < 32; i++) begin
            for (j = 0; j < 16; j++) begin
                din_i[j] = mem_i[j+i*16];
                din_q[j] = mem_q[j+i*16];
            end                 
            #10;
        end
        
        wait (do_en);

        
        for (j = 0; j < 512; j++) begin
            $fwrite(fd_out, "%0d %0d\n", do_re[j], do_im[j]);
        end

        #20;

        $fclose(fd_out);
        
        $display("Output saved to %s", out_file);

        $finish;
    end
endmodule
