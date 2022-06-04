module controller
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 10,
    parameter DIMENSION = 10,
    parameter BIG_N = 30,
    parameter DIM_WIDTH = 4,
    parameter ADDR_WIDTH = 10,
    parameter PARALLEL = 1
)
(
    input clk,
    input rst_n,

    input [1:0] opcode,
    input config_en,
    input [ADDR_WIDTH-1:0] op1_base_addr,
    input [ADDR_WIDTH-1:0] op2_base_addr,
    input [ADDR_WIDTH-1:0] out_base_addr,
    

    output reg [1:0] opcode_out,
    output reg [ADDR_WIDTH-1:0] op1_addr,
    output reg [ADDR_WIDTH-1:0] op2_addr,
    output reg [ADDR_WIDTH-1:0] out_addr,
    output reg op_select,
    output reg en,
    output reg done,
    output reg [DIM_WIDTH:0] row
);
    reg [ADDR_WIDTH-1:0] op1_base_addr_stored;
    reg [ADDR_WIDTH-1:0] op2_base_addr_stored;
    reg [ADDR_WIDTH-1:0] out_base_addr_stored;
    reg [DIM_WIDTH-1:0] col; // counter for encrypt

    always_ff @(posedge clk) begin

        // lowest priority: evolve state
        if (en) begin
            case (opcode_out)
                `OPCODE_ENCRYPT: begin
                    // if just reset col and isn't first row
                    if (row > DIMENSION && col > 0) begin
                        en <= 0;
                        done <= 1;
                        row <= 0;
                        col <= 0;
                        out_addr <= out_addr + 1;
                    end else if (row != 0 && col == 0) begin
                        op1_addr <= op1_addr + 1;
                        op2_addr <= op2_addr + 1;
                        out_addr <= out_addr + 1;
                        col <= col + 2;
                    end else if (col + 1 < BIG_N) begin
                        op1_addr <= op1_addr + 1;
                        op2_addr <= op2_addr + 1;
                        col <= col + 2;
                    end else if (col + 1 >= BIG_N) begin
                        op1_addr <= op1_addr + 1;
                        op2_addr <= op2_addr + 1;
                        row <= row + 1;
                        col <= 0;
                    end else begin
                        en <= 0;
                        done <= 1;
                    end
                end
                `OPCODE_DECRYPT: begin
                    if (op1_addr <= op1_base_addr_stored + DIMENSION/PARALLEL) begin
                        op1_addr <= op1_addr + 1;
                        op2_addr <= op2_addr + 1;
                        row <= row + 1;
                    end else begin
                        en <= 0;
                        done <= 1;
                    end
                end
                `OPCODE_ADD: begin
                    if (op1_addr <= op1_base_addr_stored + DIMENSION/PARALLEL) begin
                        op1_addr <= op1_addr + 1;
                        op2_addr <= op2_addr + 1;
                        out_addr <= out_addr + 1;
                    end else begin
                        en <= 0;
                        done <= 1;
                    end
                end
                `OPCODE_MULT: begin
                    // cycle through op1 addrs
                    // cycle through op2 addrs
                    // push rows through
                    if (op1_addr < op1_base_addr_stored + DIMENSION/PARALLEL) begin
                        op1_addr <= op1_addr + 1;
                        row <= row + 1;
                    end else if (op_select != 1 && !done) begin
                        row <= 0;
                        op_select <= 1;
                    end else if (op2_addr < op2_base_addr_stored + DIMENSION/PARALLEL) begin
                        op2_addr <= op2_addr + 1;
                        out_addr <= out_addr + 1; // this covers first half of this answer
                        row <= row + 1;
                        op_select <= 1;
                    end else if (op2_addr == op2_base_addr_stored + DIMENSION/PARALLEL) begin
                        op2_addr <= op2_addr + 1;
                        out_addr <= out_addr + 1; // this covers first half of this answer
                        row <= row + 1;
                        op_select <= 0;
                        done <= 1;
                    end else if (row <= 2*DIMENSION/PARALLEL) begin
                        out_addr <= out_addr + 1; // this covers first half of this answer
                        row <= row + 1;
                    end else begin
                        en <= 0;
                        done <= 1;
                    end
                end
            endcase
        end

        if (!en && !done && !config_en) begin
            en <= 1;
        end

        // second highest priority: configure
        if (config_en) begin
            opcode_out <= opcode;
            op1_addr <= op1_base_addr;
            op2_addr <= op2_base_addr;
            out_addr <= out_base_addr;
            op1_base_addr_stored <= op1_base_addr;
            op2_base_addr_stored <= op2_base_addr;
            out_base_addr_stored <= out_base_addr;
            en <= 0;
            done <= 0;
            row <= 0;
            col <= 0;
        end

        // highest priority: reset
        if (!rst_n) begin
            opcode_out <= 0;
            op1_addr <= 0;
            op2_addr <= 0;
            out_addr <= 0;
            op1_base_addr_stored <= 0;
            op2_base_addr_stored <= 0;
            out_base_addr_stored <= 0;
            op_select <= 0;
            en <= 0;
            row <= 0;
            col <= 0;
        end
    end

endmodule
