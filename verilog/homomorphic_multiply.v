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
    
    input signed [CIPHERTEXT_WIDTH-1:0] ciphertext_entry,
    input [DIMENSION:0] row,
    input ciphertext_select,
    input en,
    
    output wire [CIPHERTEXT_WIDTH-1:0] result_partial
);
  
    reg [CIPHERTEXT_WIDTH-1:0] ciphertext1 [DIMENSION:0];
    reg [CIPHERTEXT_WIDTH-1:0] interim_result [2*DIMENSION:0];

    integer i;
    always @(posedge clk) begin

        if (ciphertext_select == 0 && en) begin
            // filling first ciphertext
            if (row <= DIMENSION) begin
                ciphertext1[row] = ciphertext_entry;
            end else begin
                ciphertext1[row - DIMENSION] = ciphertext_entry;
            end
        end

        if (ciphertext_select == 1 && en) begin
            // second ciphertext
            for (i = 0; i <= DIMENSION; i=i+1) begin
                interim_result[row + i] = interim_result[row + i] + ciphertext_entry * ciphertext1[i];
            end
        end

        if (rst_n == 0) begin
            //ciphertext1 = '{default:(CIPHERTEXT_WIDTH-1)'b0};
            //interim_result = '{default:(CIPHERTEXT_WIDTH)'b0};
            for (i = 0; i <= DIMENSION; i=i+1) begin
                ciphertext1[i] = 0;
                interim_result[i] = 0;
                interim_result[i+DIMENSION] = 0;
            end
        end

    end

    assign result_partial = interim_result[row];

endmodule
