module decrypt
#(
  parameter PLAINTEXT_MODULUS = 64,
  parameter PLAINTEXT_WIDTH = 6,
  parameter CIPHERTEXT_MODULUS = 1024,
  parameter CIPHERTEXT_WIDTH = 10,
  parameter DIMENSION = 10,
  parameter BIG_N = 30,
  parameter PARALLEL = 1
)
(
    input clk,
    input rst_n,
    input en,

    input [CIPHERTEXT_WIDTH-1:0] secretkey_entry [PARALLEL-1:0],
    input [CIPHERTEXT_WIDTH-1:0] ciphertext_entry [PARALLEL-1:0],
    input [DIMENSION:0] row,

    output wire [PLAINTEXT_WIDTH-1:0] result
);
    reg [2*CIPHERTEXT_WIDTH:0] parallel_accum [PARALLEL-1:0];
    reg [2*CIPHERTEXT_WIDTH:0] dot_product;

    generate
        genvar i;
        assign parallel_accum[0] = secretkey_entry[0] * ciphertext_entry[0];
        for (i = 1; i < PARALLEL; i+=1) begin
            assign parallel_accum[i] = parallel_accum[i-1] + (secretkey_entry[i] * ciphertext_entry[i]);
        end
    endgenerate

    always @(posedge clk) begin
        if (en) begin
            dot_product = dot_product + parallel_accum[PARALLEL-1];
            if(row == 0) begin
                dot_product = parallel_accum[PARALLEL-1];
            end
        end
        if(!rst_n) begin
            dot_product = 0;
        end
    end
		    
    assign result = dot_product[PLAINTEXT_WIDTH-1:0];
  
endmodule
