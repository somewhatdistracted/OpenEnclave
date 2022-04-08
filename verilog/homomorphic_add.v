module homomorphic_add
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
    
    input signed [CIPHERTEXT_WIDTH-1:0] ciphertext1 [DIMENSION:0],
    input signed [CIPHERTEXT_WIDTH-1:0] ciphertext2 [DIMENSION:0],
    
    output wire [CIPHERTEXT_WIDTH-1:0] result [DIMENSION:0],
);

  assign result = ciphertext1 + ciphertext2;
  
endmodule
