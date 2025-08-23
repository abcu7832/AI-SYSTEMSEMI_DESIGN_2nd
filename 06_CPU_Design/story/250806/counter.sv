module counter (
    input  logic                    clk,
    input  logic                    reset,
    input  logic                    tick,
    input  logic                    mode,
    input  logic [             1:0] fsm,
    output logic [$clog2(10_000):0] count
);

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
        end else begin
            if ((mode == 0) && (fsm == 1)) begin  // up counter
                if (tick) begin
                    if (count == 10_000 - 1) begin
                        count <= 0;
                    end else begin
                        count <= count + 1;
                    end
                end
            end else if ((mode == 1) && (fsm == 1)) begin  // down counter
                if (tick) begin
                    if (count == 0) begin
                        count <= 9999;
                    end else begin
                        count <= count - 1;
                    end
                end
            end else if (fsm == 2) begin
                count <= 0;
            end
        end
    end
endmodule
