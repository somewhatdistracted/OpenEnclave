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
    
    input [CIPHERTEXT_WIDTH-1:0] secret_key [DIMENSION:0],
    input [CIPHERTEXT_WIDTH-1:0] cipher_text [DIMENSION:0],
    
    output wire [PLAINTEXT_WIDTH-1:0] result,
);

  wire signed [2*CIPHERTEXT_WIDTH:0] dot_product [DIMENSION:0];
  
  genvar n;
  generate
    assign dot_product[0] = secret_key[0] * cipher_text[0]
	    for (int n = 1; n <= DIMENSION; n = n+1) begin dot_prod
      assign dot_product[n] = dot_product[n] + secret_key[n] * cipher_text[n]
    end
  endgenerate
		    
  assign result = dot_product[DIMENSION][PLAINTEXT_WIDTH-1:0];
  
endmodule
