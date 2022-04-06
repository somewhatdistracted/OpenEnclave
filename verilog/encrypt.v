module encrypt
#(
    parameter PLAINTEXT_WIDTH = 8,          // log2(p)
    parameter CIPHERTEXT_WIDTH = 10,
    parameter CIPHERTEXT_MODULUS = 1024,    // q
    parameter BIG_N = 30,                   // N
    parameter LITTLE_N = 2,                 // n
)
(
    input clk,
    input rst_n,

    input go,
    input [PLAINTEXT_WIDTH-1:0] plaintext,
    input [CIPHERTEXT_WIDTH-1:0] publickey_row [BIG_N-1:0],
    input [BIG_N-1:0] noise_select,
    input [LITTLE_N-1:0] row,

    // note: outputs partial over time
    output wire [CIPHER_TEXT_WIDTH-1:0] ciphertext,
);
    wire [CIPHERTEXT_WIDTH-1:0] psum [2*BIG_N-1:0];
    generate
        genvar p = 0;
        for (int n = BIG_N; n > 1; n >> 1) begin
            for (int i = 0; i < n; i+=1) begin
                if (n == BIG_N) begin
                    psum[i] = (noise_select[i]? publickey_row[i] : BIG_N'b0) + (noise_select[i+1]? publickey_row[i+1] : BIG_N'b0);
                else begin
                    psum[p+i] = psum[p-(2*n)+i] + psum[p-(2*n)+i+1];
                end
            end
            p = p + n;
        end
        assign ciphertext = psum[p];
    endgenerate

endmodule
