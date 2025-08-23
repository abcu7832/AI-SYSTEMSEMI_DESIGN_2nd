`timescale 1ns / 1ps

module RAM (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [ 2:0] func3,
    input  logic [31:0] wData,
    output logic [31:0] rData
);
    logic [31:0] mem[0:2**6-1];

    // Control Data func[2:0]

    always_ff @( posedge clk ) begin
        if (we) begin
            case (func3)
                3'b000:  mem[addr[31:2]][7:0]  <= wData[7:0];
                3'b001:  mem[addr[31:2]][15:0] <= wData[15:0];
                3'b010:  mem[addr[31:2]][31:0] <= wData[31:0];
                default: mem[addr[31:2]][31:0] <= wData[31:0];
            endcase
        end
    end

    always_comb begin
        rData = mem[addr[31:2]];
        case (func3)
            3'b000: rData = {{24{mem[addr[31:2]][7]}}, mem[addr[31:2]][7:0]};
            3'b001: rData = {{16{mem[addr[31:2]][15]}}, mem[addr[31:2]][15:0]};
            3'b010: rData = mem[addr[31:2]];
            3'b100: rData = {24'b0, mem[addr[31:2]][7:0]};
            3'b101: rData = {16'b0, mem[addr[31:2]][15:0]};
        endcase        
    end
endmodule
