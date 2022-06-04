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
  
    reg [DIMENSION:0][CIPHERTEXT_WIDTH-1:0] ciphertext1;
    reg [2*DIMENSION:0][CIPHERTEXT_WIDTH-1:0] interim_result;

    wire [DIM_WIDTH:0] out_row;
    
    /*
    always @(posedge clk) begin
        $display("op1: %d, cts: %d, en: %d",op1[0],ciphertext_select,en);
        $display("C1: %d, %d, %d",ciphertext1[0],ciphertext1[1],ciphertext1[2]);
        $display("D: %d, %d, %d, %d, %d", interim_result[0],interim_result[1],interim_result[2],interim_result[3],interim_result[4]);
    end
    */
    
    assign out_row = (row == 0)? 0 : row - 1;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ciphertext1 <= 0;
            interim_result <= 0;
        end else if (ciphertext_select == 0 && en) begin
            if (row <= DIMENSION) begin
                for (int jm = 0; jm < PARALLEL; jm+=1) begin
                    ciphertext1[row+jm] <= op1[jm];
                end
            end else begin
                for (int km = 0; km < PARALLEL; km+=1) begin
                    ciphertext1[row+km-DIMENSION] <= op1[km];
                end
            end
        end else if (ciphertext_select == 1 && en) begin
            for (int xm = 0; xm < PARALLEL; xm+=1) begin
                for (int ym = 0; ym <= DIMENSION; ym+=1) begin
                    interim_result[row + xm + ym] <= interim_result[row + xm + ym] + op1[xm] * ciphertext1[ym];
                end
            end
        end
    end

    generate
        genvar mmm;
        for (mmm = 0; mmm < PARALLEL; mmm+=1) begin
            assign result_partial[mmm] = interim_result[out_row+mmm];
        end
    endgenerate

    /*
    generate
        genvar jm;
        for (jm = 0; jm < PARALLEL; jm+=1) begin
            assign result_partial[jm] = interim_result[row+jm];
            // operational logic
            always @(posedge clk) begin
                if (ciphertext_select == 0 && en) begin
                    if (row <= DIMENSION) begin
                        ciphertext1[row+jm] = op1[jm];
                    end else begin
                        ciphertext1[row+jm-DIMENSION] = op1[jm]; // need to figure out if this is still good
                    end
                end 
            end
        end

        genvar xm, ym;
        for (xm = 0; xm < PARALLEL; xm+=1) begin
            for (ym = 0; ym <= DIMENSION; ym+=1) begin
                // operational logic
                always @(posedge clk) begin
                    if (ciphertext_select == 1 && en) begin
                        interim_result[row + xm + ym] = interim_result[row + xm + ym] + op1[xm] * ciphertext1[ym];
                    end
                end
            end
        end

        genvar im;
        for (im = 0; im <= DIMENSION; im+=1) begin
            // reset logic
            always @(posedge clk) begin
                if (!rst_n) begin
                    ciphertext1[im] = 0;
                    interim_result[im] = 0;
                    interim_result[im+DIMENSION] = 0;
                end
            end
        end
    endgenerate
    */
endmodule
