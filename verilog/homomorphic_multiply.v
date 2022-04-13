
module homomorphic_multiply
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
    
    input signed [CIPHERTEXT_WIDTH-1:0] ciphertext1_entry,
    input signed [CIPHERTEXT_WIDTH-1:0] ciphertext2_entry,
    input [DIMENSION:0] one_row,
    input [DIMENSION:0] two_row,
    input one_en,
    input two_en,
    
    output wire [CIPHERTEXT_WIDTH-1:0] result_partial,
    output wire [DIMENSION:0] result_row,
    output result_en
);
  
  reg [CIPHERTEXT_WIDTH-1:0] ciphertext1 [DIMENSION:0];
  reg [CIPHERTEXT_WIDTH-1:0] interim_result [2*DIMENSION-2:0] = 0;
  reg one_ready;
  reg [DIMENSION:0] row_calc;
  reg [DIMENSION:0] out_row;
  reg out_en;

  always @(posedge clk) begin
    one_ready = 0;
    row_calc = 0;
    out_row = 0;
    out_en = 0;

    if(one_en == 1) begin
      ciphertext1[one_row] = ciphertext1_entry;
      one_ready = 1'b0;
      if(one_row == DIMENSION) begin
        one_ready = 1'b1
      end
    end

    if(two_en == 1) begin
      row_calc = two_row;
      coef_calc = ciphertext2_entry;

      assign result_partial = interim_result[row_calc];
      assign result_row = two_row;
      assign out_en = 1;
    end
  end

  genvar n;
  generate
    for (int n = 0; n <= DIMENSION; n = n+1) begin tensor_prod
      interim_result[row_calc+n] = interim_result[row_calc+n] + coef_calc * ciphertext1[n]; 
    end
  endgenerate

endmodule
