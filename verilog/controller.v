`DEFINE OPCODE_ENCRYPT  2'b00
`DEFINE OPCODE_DECRYPT  2'b01
`DEFINE OPCODE_ADD      2'b10
`DEFINE OPCODE_MULT     2'b11

module controller
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 10,
    parameter DIMENSION = 10,
    parameter BIG_N = 30
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
    output reg [DIM_WIDTH-1:0] row
);

    always @(posedge clk) begin

        // lowest priority: evolve state
        case (opcode_out)
            OPCODE_ENCRYPT: begin
                
            end
            OPCODE_DECRYPT: begin

            end
            OPCODE_ADD: begin

            end
            OPCODE_MULT: begin

            end
            default: begin

            end
        endcase

        // second highest priority: configure
        if (config_en == 1) begin
            opcode_out = opcode;
            op1_addr = op1_base_addr;
            op2_addr = op2_base_addr;
            en = 0;
            row = 0;
        end

        // highest priority: reset
        if (rst_n == 0) begin
            opcode_out = 0;
            op1_addr = 0;
            op2_addr = 0;
            op_select = 0;
            en = 0;
            row = 0;
        end
    end

endmodule
