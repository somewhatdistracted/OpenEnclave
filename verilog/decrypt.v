module decrypt
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

    input [CIPHERTEXT_WIDTH-1:0] secretkey_entry,
    input [CIPHERTEXT_WIDTH-1:0] ciphertext_entry,
    input [DIMENSION:0] row,

    output wire [PLAINTEXT_WIDTH-1:0] result
);

    reg signed [2*CIPHERTEXT_WIDTH:0] dot_product;

    always @(posedge clk) begin
        dot_product = dot_product + secretkey_entry * ciphertext_entry; 
        if(row == 0) begin
            dot_product <= secretkey_entry * ciphertext_entry;
        end
        if(!rst_n) begin
            dot_product = 0;
        end  
    end
		    
    assign result = dot_product[PLAINTEXT_WIDTH-1:0];
  
endmodule
