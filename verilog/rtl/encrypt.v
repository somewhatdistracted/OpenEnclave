module encrypt
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 32,
    parameter DIMENSION = 128,
    parameter DIM_WIDTH = 7,
    parameter BIG_N = 30,
    parameter PARALLEL = 1
)
(
    input clk,
    input rst_n,
    input en,
    input done,

    input [CIPHERTEXT_WIDTH-1:0] op1 [PARALLEL-1:0], // ops aren't named anymore since
    input [CIPHERTEXT_WIDTH-1:0] op2 [PARALLEL-1:0], // the channel gets reused for bandwidth
    input [DIM_WIDTH-1:0] row,

    output reg [CIPHERTEXT_WIDTH-1:0] ciphertext
);
    reg [CIPHERTEXT_WIDTH-1:0] psum [DIMENSION:0];
    wire [CIPHERTEXT_WIDTH-1:0] parallel1 [PARALLEL-1:0];
    wire [CIPHERTEXT_WIDTH-1:0] parallel2 [PARALLEL-1:0];
    reg [DIM_WIDTH-1:0] last_row;

    // logic for parallel>1
    generate
        genvar i;
        assign parallel1[0] = op1[0][CIPHERTEXT_WIDTH-1] ? 0 : op1[0];
        assign parallel2[0] = op2[0][CIPHERTEXT_WIDTH-1] ? 0 : op1[0];
        for (i = 1; i < PARALLEL; i+=1) begin
            assign parallel1[i] = parallel1[i-1] + op1[i][CIPHERTEXT_WIDTH-1] ? 0 : op1[i];
            assign parallel2[i] = parallel2[i-1] + op2[i][CIPHERTEXT_WIDTH-1] ? 0 : op2[i];
        end
    endgenerate

    // main logic
    always @(posedge clk) begin
        if (!done && rst_n) begin
            psum[row] = psum[row] + parallel1[PARALLEL-1] + parallel2[PARALLEL-1];
        end

        if (row != last_row) begin
            ciphertext = psum[row-1];
        end
        last_row = row;

        if (!rst_n) begin
            ciphertext = 0;
        end
    end

    // reset array logic
    generate
        genvar j;
        for (j = 0; j <= DIMENSION; j += 1) begin
            always @(posedge clk) begin
                if (done || !rst_n) begin
                    last_row = 0;
                    psum[j] = 0;
                end
            end
        end
    endgenerate

endmodule
