module encrypt
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 10,
    parameter DIMENSION = 10,
    parameter BIG_N = 30,
)
(
    input clk,
    input rst_n,

    input [PLAINTEXT_WIDTH-1:0] plaintext,
    input [CIPHERTEXT_WIDTH-1:0] publickey_row [BIG_N-1:0],
    input [BIG_N-1:0] noise_select,
    input [DIMENSION:0] row,

    // note: outputs partial over time
    output wire [CIPHERTEXT_WIDTH-1:0] ciphertext
);
    wire [CIPHERTEXT_WIDTH-1:0] psum [BIG_N-1:0];
    generate
        genvar i;
        assign psum[0] = ((row == 1)? plaintext : 0) + (noise_select[0]? publickey_row[i] : 0);
        for (i = 1; i < BIG_N; i=i+1) begin: i_loop
            psum[i] = psum[i-1] + (noise_select[i]? publickey_row[i] : 0);
        end
    endgenerate
    assign ciphertext = psum[p];
endmodule
