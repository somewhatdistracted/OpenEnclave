`define OPCODE_ENCRYPT  2'b00
`define OPCODE_DECRYPT  2'b01
`define OPCODE_ADD      2'b10
`define OPCODE_MULT     2'b11

module controller
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 10,
    parameter DIMENSION = 10,
    parameter BIG_N = 30,
    parameter DIM_WIDTH = 4,
    parameter ADDR_WIDTH = 8
)
(
    input clk,
    input rst_n,

    input [1:0] opcode,
    input config_en,
    input [ADDR_WIDTH-1:0] op1_base_addr,
    input [ADDR_WIDTH-1:0] op2_base_addr,
    

    output reg [1:0] opcode_out,
    output reg [ADDR_WIDTH-1:0] op1_addr,
    output reg [ADDR_WIDTH-1:0] op2_addr,
    output reg op_select,
    output reg en,
    output reg done,
    output reg [DIM_WIDTH-1:0] row
);

    reg [ADDR_WIDTH-1:0] op1_base_addr_stored;
    reg [ADDR_WIDTH-1:0] op2_base_addr_stored;

    always @(posedge clk) begin

        // lowest priority: evolve state
        if (en) begin
            case (opcode_out)
                `OPCODE_ENCRYPT: begin
                    if (op1_addr <= op1_base_addr_stored + DIMENSION) begin
                        op1_addr = op1_addr + 1;
                        op2_addr = op2_addr + 1;
                        row = row + 1;
                    end else begin
                        en = 0;
                        done = 1;
                    end
                    
                end
                `OPCODE_DECRYPT: begin
                    if (op1_addr <= op1_base_addr_stored + DIMENSION) begin
                        op1_addr = op1_addr + 1;
                        op2_addr = op2_addr + 1;
                        row = row + 1;
                    end else begin
                        en = 0;
                        done = 1;
                    end
                end
                `OPCODE_ADD: begin
                    if (op1_addr <= op1_base_addr_stored + DIMENSION) begin
                        op1_addr = op1_addr + 1;
                        op2_addr = op2_addr + 1;
                    end else begin
                        en = 0;
                        done = 1;
                    end
                end
                `OPCODE_MULT: begin
                    // cycle through op1 addrs
                    // cycle through op2 addrs
                    // push rows through
                    if (op1_addr <= op1_base_addr_stored + DIMENSION) begin
                        op1_addr = op1_addr + 1;
                        row = row + 1;
                        op_select = 0;
                    end else begin
                        if (op2_addr <= op2_base_addr_stored + DIMENSION) begin
                            op2_addr = op2_addr + 1;
                            row = row + 1;
                            en = 1;
                            op_select = 1;
                        end else begin
                            en = 0;
                            done = 1;
                        end
                    end
                end
                default: begin

                end
            endcase
        end

        if (!en && !done) begin
            en = 1;
        end

        // second highest priority: configure
        if (config_en) begin
            opcode_out = opcode;
            op1_addr = op1_base_addr;
            op2_addr = op2_base_addr;
            en = 0;
            done = 0;
            row = 0;
        end

        // highest priority: reset
        if (!rst_n) begin
            opcode_out = 0;
            op1_addr = 0;
            op2_addr = 0;
            op_select = 0;
            en = 0;
            row = 0;
        end
    end

endmodule
