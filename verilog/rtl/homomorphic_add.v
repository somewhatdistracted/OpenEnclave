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
    input en,
    
    input signed [CIPHERTEXT_WIDTH-1:0] ciphertext1 [PARALLEL-1:0],
    input signed [CIPHERTEXT_WIDTH-1:0] ciphertext2 [PARALLEL-1:0],
    
    output wire [CIPHERTEXT_WIDTH-1:0] result [PARALLEL-1:0]
);
    reg [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] ir;

    always_ff @(posedge clk) begin
        if (en) begin
            for (int aaa = 0; aaa < PARALLEL; aaa+=1) begin
                ir[aaa] <= ciphertext1[aaa] + ciphertext2[aaa];
            end
        end else begin
            ir <= 0;
        end
    end

    generate
        genvar iadd;
        for (iadd = 0; iadd < PARALLEL; iadd+=1) begin
            assign result[iadd] = ir[iadd];
        end
    endgenerate
  
endmodule
