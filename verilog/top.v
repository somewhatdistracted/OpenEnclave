module top
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
);
    // WISHBONE
    
    // CONTROLLER
    
    // SRAM
    sram #(
        .WIDTH(WIDTH);
    ) sram_inst (
        .clk(clk),
    );
    
    // ADDRESS GENERATOR
    
    // I/O FIFOS
    
    // ENCRYPT
    encrypt #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .BIG_N(BIG_N)
    ) encrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .plaintext(),
        .publickey_row(),
        .noise_select(),
        .row(),
        .ciphertext(),
    );
    
    // DECRYPT
    decrypt #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .BIG_N(BIG_N)
    ) decrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
    );
    
    // ADD
    homomorphic_add #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .BIG_N(BIG_N)
    ) homomorphic_add_inst (
        .clk(clk),
        .rst_n(rst_n),
    );
    
    // MULT
    
    // MORE


endmodule
