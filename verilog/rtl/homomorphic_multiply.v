module homomorphic_multiply
#(
  parameter PLAINTEXT_MODULUS = 64,
  parameter PLAINTEXT_WIDTH = 6,
  parameter DIMENSION = 1,
  parameter DIM_WIDTH = 1,
  parameter CIPHERTEXT_MODULUS = 1024,
  parameter CIPHERTEXT_WIDTH = 10,
  parameter BIG_N = 30,
  parameter PARALLEL = 1
)
(
    input clk,
    input rst_n,
    
    input [CIPHERTEXT_WIDTH-1:0] op1 [PARALLEL-1:0],
    input [DIM_WIDTH:0] row,
    input ciphertext_select,
    input en,
    
    output wire [CIPHERTEXT_WIDTH-1:0] result_partial [PARALLEL-1:0]
);
  
    reg [CIPHERTEXT_WIDTH-1:0] ciphertext1 [DIMENSION:0];
    reg [CIPHERTEXT_WIDTH-1:0] interim_result [2*DIMENSION:0];

    /*
    initial begin
        #80;
        $display("C1: %d, %d, %d, %d",ciphertext1[0],ciphertext1[1],ciphertext1[2],ciphertext1[3]);
        $display("D: %d, %d, %d, %d, %d, %d, %d", interim_result[0],interim_result[1],interim_result[2],interim_result[3],interim_result[4],interim_result[5],interim_result[6]);
        #20;
        $display("C1: %d, %d, %d, %d",ciphertext1[0],ciphertext1[1],ciphertext1[2],ciphertext1[3]);
        $display("D: %d, %d, %d, %d, %d, %d, %d", interim_result[0],interim_result[1],interim_result[2],interim_result[3],interim_result[4],interim_result[5],interim_result[6]);
        #20;
        $display("C1: %d, %d, %d, %d",ciphertext1[0],ciphertext1[1],ciphertext1[2],ciphertext1[3]);
        $display("D: %d, %d, %d, %d, %d, %d, %d", interim_result[0],interim_result[1],interim_result[2],interim_result[3],interim_result[4],interim_result[5],interim_result[6]);
        #20;
        $display("C1: %d, %d, %d, %d",ciphertext1[0],ciphertext1[1],ciphertext1[2],ciphertext1[3]);
        $display("D: %d, %d, %d, %d, %d, %d, %d", interim_result[0],interim_result[1],interim_result[2],interim_result[3],interim_result[4],interim_result[5],interim_result[6]);
        #20;
        $display("C1: %d, %d, %d, %d",ciphertext1[0],ciphertext1[1],ciphertext1[2],ciphertext1[3]);
        $display("D: %d, %d, %d, %d, %d, %d, %d", interim_result[0],interim_result[1],interim_result[2],interim_result[3],interim_result[4],interim_result[5],interim_result[6]);
    end
    */

    generate
        genvar j;
        for (j = 0; j < PARALLEL; j+=1) begin
            assign result_partial[j] = interim_result[row+j];
            // operational logic
            always @(posedge clk) begin
                if (ciphertext_select == 0 && en) begin
                    if (row <= DIMENSION) begin
                        ciphertext1[row+j] = op1[j];
                    end else begin
                        ciphertext1[row+j-DIMENSION] = op1[j]; // need to figure out if this is still good
                    end
                end 
            end
        end

        genvar x;
        genvar y;
        for (x = 0; x < PARALLEL; x+=1) begin
            for (y = 0; y <= DIMENSION; y+=1) begin
                // operational logic
                always @(posedge clk) begin
                    if (ciphertext_select == 1 && en) begin
                        interim_result[row + x + y] = interim_result[row + x + y] + op1[x] * ciphertext1[y];
                    end
                end
            end
        end


        genvar i;
        for (i = 0; i <= DIMENSION; i+=1) begin
            // reset logic
            always @(posedge clk) begin
                if (!rst_n) begin
                    ciphertext1[i] = 0;
                    interim_result[i] = 0;
                    interim_result[i+DIMENSION] = 0;
                end
            end
        end
    endgenerate
endmodule
