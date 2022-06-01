module homomorphic_add
#(
  parameter PLAINTEXT_MODULUS = 64,
  parameter PLAINTEXT_WIDTH = 6,
  parameter CIPHERTEXT_MODULUS = 1024,
  parameter CIPHERTEXT_WIDTH = 10,
  parameter DIMENSION = 1,
  parameter BIG_N = 30,
  parameter PARALLEL = 1
)
(
    input clk,
    input rst_n,
    
    input signed [CIPHERTEXT_WIDTH-1:0] ciphertext1 [PARALLEL-1:0],
    input signed [CIPHERTEXT_WIDTH-1:0] ciphertext2 [PARALLEL-1:0],
    
    output wire [CIPHERTEXT_WIDTH-1:0] result [PARALLEL-1:0]
);
    generate
        genvar i;
        for (i = 0; i < PARALLEL; i+=1) begin
            assign result[i] = ciphertext1[i] + ciphertext2[i];
        end
    endgenerate
  
endmodule
