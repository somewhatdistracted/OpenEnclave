module decrypt
#(
  parameter PLAINTEXT_MODULUS = 64,
  parameter PLAINTEXT_WIDTH = 6,
  parameter DIMENSION = 1,
  parameter CIPHERTEXT_MODULUS = 1024,
  parameter CIPHERTEXT_WIDTH = 10,
  parameter BIG_N = 30,
  
)
(
    input clk,
    input rst_n,
    
    input [CIPHERTEXT_WIDTH-1:0] secret_key_prime,
	input signed [CIPHERTEXT_WIDTH-1:0] cipher_text_top,
	input signed [CIPHERTEXT_WIDTH-1:0] cipher_text_bot,
    
    output reg [PLAINTEXT_WIDTH-1:0] result,
);

  wire signed [2*CIPHERTEXT_WIDTH:0] dot_product;
  assign dot_product = cipher_text_top + secret_key_prime * cipher_text_bot;
  assign result = dot_product[PLAINTEXT_WIDTH-1:0];
  
endmodule
