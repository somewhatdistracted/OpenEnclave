module decrypt
#(
  parameter PLAINTEXT_MODULUS = 64,
  parameter PLAINTEXT_WIDTH = 6,
  parameter CIPHERTEXT_MODULUS = 1024,
  parameter CIPHERTEXT_WIDTH = 10,
  parameter DIMENSION = 10,
  parameter DIM_WIDTH = 4,
  parameter BIG_N = 30,
  parameter PARALLEL = 1
)
(
    input clk,
    input rst_n,
    input en,

    input [CIPHERTEXT_WIDTH-1:0] secretkey_entry [PARALLEL-1:0],
    input [CIPHERTEXT_WIDTH-1:0] ciphertext_entry [PARALLEL-1:0],
    input [DIM_WIDTH:0] row,

    output wire [PLAINTEXT_WIDTH-1:0] result
);
    reg [2*CIPHERTEXT_WIDTH:0] parallel_accum [PARALLEL-1:0];
    reg [2*CIPHERTEXT_WIDTH:0] dot_product;

    generate
        genvar idec;
        assign parallel_accum[0] = secretkey_entry[0] * ciphertext_entry[0];
        for (idec = 1; idec < PARALLEL; idec+=1) begin
            assign parallel_accum[idec] = parallel_accum[idec-1] + (secretkey_entry[idec] * ciphertext_entry[idec]);
        end
    endgenerate

    always_ff @(posedge clk) begin
        //$display("Weird Verilog behavior: x if no display here");
        //$display("D: %d * %d", secretkey_entry[0], ciphertext_entry[0]);
        if (en) begin
            if(row == 0) begin
                dot_product <= parallel_accum[PARALLEL-1];
            end else begin
                dot_product <= dot_product + parallel_accum[PARALLEL-1];
            end
        end
        if(!rst_n) begin
            dot_product <= 0;
        end
    end
		    
    assign result = dot_product[PLAINTEXT_WIDTH-1:0];
  
endmodule
