module encrypt
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 10,
    parameter DIMENSION = 10,
    parameter DIM_WIDTH = 4,
    parameter BIG_N = 30,
    parameter PARALLEL = 1
)
(
    input clk,
    input rst_n,

    input [CIPHERTEXT_WIDTH-1:0] plaintext_and_noise,
    input [CIPHERTEXT_WIDTH-1:0] publickey_entry,
    input [DIM_WIDTH:0] row,

    // note: outputs partial over time
    output wire [CIPHERTEXT_WIDTH-1:0] ciphertext
);
    reg [CIPHERTEXT_WIDTH-1:0] psum;
    reg [DIM_WIDTH-1:0] last_row;

    always @(posedge clk) begin
        if (last_row != row) begin
            psum = 0;
        end
        if (row == 0) begin
            psum += plaintext_and_noise[PLAINTEXT_WIDTH-1:0] + plaintext_and_noise[CIPHERTEXT_WIDTH-1] ? publickey_entry : 0;
        end else begin
            psum += plaintext_and_noise[CIPHERTEXT_WIDTH-1] ? publickey_entry : 0;
        end
        last_row = row;
    end
    
    assign ciphertext = psum;
endmodule
