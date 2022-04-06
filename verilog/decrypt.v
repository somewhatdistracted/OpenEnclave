module decrypt
#(
  parameter DIMENSION = 1,
  parameter MODULUS = 1024,
  parameter N = 30,
  parameter PLAINTEXT = 64,
  parameter P = 6,
  
)
(
    input clk,
    input rst_n,
    
    input [N - 1 : 0] secret_key_prime,
	input signed [N - 1 : 0] cipher_text_top,
	input signed [N - 1 : 0] cipher_text_bot,
    
    output reg [P - 1 : 0] result,
);

  wire signed [N : 0] dot_product;
  assign dot_product = cipher_text_top + secret_key_prime * cipher_text_bot;
  assign result = dot_product[P - 1 : 0];
  
endmodule