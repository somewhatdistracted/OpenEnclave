`define PLAINTEXT_MODULUS 64 
`define PLAINTEXT_WIDTH 6
`define DIMENSION 3
`define DIM_WIDTH 2
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH 21 
`define BIG_N 30 
`define PARALLEL 2

module homomorphic_multiply_tb;

    reg clk;
    reg rst_n;
    reg [`CIPHERTEXT_WIDTH-1:0] op1 [`PARALLEL-1:0];
    reg [`DIM_WIDTH:0] row;
    reg ciphertext_select;
    reg en;
    wire [`CIPHERTEXT_WIDTH-1:0] result [`PARALLEL-1:0];
    reg [`CIPHERTEXT_WIDTH-1:0] expected [`PARALLEL-1:0];

    always #10 clk = ~clk;

    homomorphic_multiply #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .DIMENSION(`DIMENSION),
        .DIM_WIDTH(`DIM_WIDTH),
        .BIG_N(`BIG_N),
        .PARALLEL(`PARALLEL)
    ) homomorphic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .op1(op1),
        .row(row),
        .ciphertext_select(ciphertext_select),
        .en(en),
        .result_partial(result)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        en = 0;
        ciphertext_select = 0;
        row = 0;
        op1[0] = 0;
        op1[1] = 0;
        #20;
        rst_n = 1;
        #20;

        // reading in ciphertext 1 [ 1 1 1 1 ]
        row = 0;
        ciphertext_select = 0;
        op1[0] = 1;
        op1[1] = 1;
        en = 1;
    	#20;

        row = 2;
        op1[0] = 1;
        op1[1] = 1;
    	#20;

        // reading in ciphertext 2 [ 1 1 1 1 ]
        row = 0;
        ciphertext_select = 1;
        op1[0] = 1;
        op1[1] = 1;

        #20;
        expected[0] = 1;
        expected[1] = 2;
    	$display("Result = %d, %d", result[0], result[1]); assert(result == expected);

        row = 2;
        #20;
        expected[0] = 3;
        expected[1] = 4;
    	$display("Result = %d, %d", result[0], result[1]); assert(result == expected);

        row = 4;
        ciphertext_select = 0;
        #20;
        expected[0] = 3;
        expected[1] = 2;
    	$display("Result = %d, %d", result[0], result[1]); assert(result == expected);

        row = 6;
        #20;
        expected[0] = 1;
    	$display("Result = %d, %d", result[0], result[1]); assert(result[0] == expected[0]);

        /*
        row = 4;
        #20;
    	$display("Result = %d", result); assert(result == 3);

        row = 5;
        #20;
    	$display("Result = %d", result); assert(result == 2);

        row = 6;
        #20;
    	$display("Result = %d", result); assert(result == 1);
        #20;
        */

        #200;
        $finish;
    end

endmodule
