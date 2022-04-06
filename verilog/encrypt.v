module encrypt
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter DIMENSION = 1,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 10,
    parameter BIG_N = 30
)
(
    input clk,
    input rst_n,

    input go,
    input [PLAINTEXT_WIDTH-1:0] plaintext,
    input [CIPHERTEXT_WIDTH-1:0] publickey_row [BIG_N-1:0],
    input [BIG_N-1:0] noise_select,
    input [DIMENSION:0] row,

    // note: outputs partial over time
    output wire [CIPHER_TEXT_WIDTH-1:0] ciphertext
);
    wire [CIPHERTEXT_WIDTH-1:0] psum [2*BIG_N-1:0];
    genvar n, i;
    generate
        int p = 0;
        for (n = BIG_N; n > 1; n >> 1) begin: small_n_loop
            for (i = 0; i < n; i=i+1) begin: i_loop
                if (n == BIG_N) begin
                    assign psum[i] = (noise_select[i]? publickey_row[i] : BIG_N'b0) + (noise_select[i+1]? publickey_row[i+1] : BIG_N'b0);
                else begin
                    assign psum[p+i] = psum[p-(2*n)+i] + psum[p-(2*n)+i+1];
                end
            end
            p = p + n;
        end
    endgenerate
    assign ciphertext = psum[p];
endmodule
