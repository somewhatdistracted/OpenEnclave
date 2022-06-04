module encrypt
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 32,
    parameter DIMENSION = 128,
    parameter DIM_WIDTH = 7,
    parameter BIG_N = 30,
    parameter PARALLEL = 2
)
(
    input clk,
    input rst_n,
    input en,
    input done,

    input [CIPHERTEXT_WIDTH-1:0] op1 [PARALLEL-1:0], // ops aren't named anymore since
    input [CIPHERTEXT_WIDTH-1:0] op2 [PARALLEL-1:0], // the channel gets reused for bandwidth
    input [DIM_WIDTH:0] row,

    output reg [CIPHERTEXT_WIDTH-1:0] ciphertext
);
    reg [DIMENSION:0][CIPHERTEXT_WIDTH-1:0] psum;
    wire [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] parallel1;
    wire [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] parallel2;
    reg [DIM_WIDTH-1:0] last_row;

    /*
    always @(posedge clk) begin
        $display("P: %d, %d, %d", psum[0], psum[1], psum[2]);
    end
    */

    // logic for parallel>1
    generate
        genvar ienc;
        assign parallel1[0] = op1[0][CIPHERTEXT_WIDTH-1] ? 0 : op1[0];
        assign parallel2[0] = op2[0][CIPHERTEXT_WIDTH-1] ? 0 : op2[0];
        for (ienc = 1; ienc < PARALLEL; ienc+=1) begin
            assign parallel1[ienc] = parallel1[ienc-1] + (op1[ienc][CIPHERTEXT_WIDTH-1] ? 0 : op1[ienc]);
            assign parallel2[ienc] = parallel2[ienc-1] + (op2[ienc][CIPHERTEXT_WIDTH-1] ? 0 : op2[ienc]);
        end
    endgenerate

    // main logic
    always_ff @(posedge clk) begin
        if (en && rst_n) begin
            psum[row] <= psum[row] + parallel1[PARALLEL-1] + parallel2[PARALLEL-1];
        end else begin
            last_row <= 0;
            psum <= 0;
        end

        // set output
        if (!rst_n) begin
            ciphertext <= 0;
        end else if (row != last_row) begin
            ciphertext <= psum[last_row];
        end

        last_row <= row;
    end
endmodule
