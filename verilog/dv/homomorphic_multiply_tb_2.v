`define PLAINTEXT_MODULUS 64 
`define PLAINTEXT_WIDTH 6
`define DIMENSION 1
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH 10 
`define BIG_N 30 

module homomorphic_multiply_tb;

    reg clk;
    reg rst_n;
    reg signed [`CIPHERTEXT_WIDTH-1:0] ciphertext_entry;
    reg [`DIMENSION:0] row;
    reg ciphertext_select;
    reg en;
    wire [`CIPHERTEXT_WIDTH-1:0] result;
    reg signed [`CIPHERTEXT_WIDTH-1:0] expected;

    always #10 clk = ~clk;

    homomorphic_multiply #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .DIMENSION(`DIMENSION),
        .BIG_N(`BIG_N)
    ) homomorphic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ciphertext_entry(ciphertext_entry),
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
        ciphertext_entry = 0;
        #200;
        rst_n = 1;
        #200;

        // reading in ciphertext 1 [ 11 948 ]
        row = 0;
        ciphertext_select = 0;
        ciphertext_entry = 11;
        en = 1;
    	#20;

        row = 1;
        ciphertext_entry = 948;
    	#20;

        // reading in ciphertext 2 [ 805 374 ]
        row = 0;
        ciphertext_select = 1;
        ciphertext_entry = 805;
        #20;
    	$display("Result = %d", result); assert(result == 663);

        row = 1;
        ciphertext_entry = 374;
        #20;
    	$display("Result = %d", result); assert(result == 278);

        // read out rest of results
        ciphertext_select = 0;
        row = 2;
        #20;
    	$display("Result = %d", result); assert(result == 248);

        

        $finish;
    end

endmodule
