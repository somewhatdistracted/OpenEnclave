`define PLAINTEXT_MODULUS 64 
`define PLAINTEXT_WIDTH 6
`define DIMENSION 1
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH 21 
`define BIG_N 30 

module homomorphic_add_tb;

    reg clk;
    reg rst_n;
    reg signed [`CIPHERTEXT_WIDTH-1:0] ciphertext1 [`DIMENSION:0];
    reg signed [`CIPHERTEXT_WIDTH-1:0] ciphertext2 [`DIMENSION:0];
    reg signed [`CIPHERTEXT_WIDTH-1:0] result [`DIMENSION:0];
    reg signed [`CIPHERTEXT_WIDTH-1:0] expected [`DIMENSION:0];

    always #10 clk = ~clk;

    homomorphic_add #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .DIMENSION(`DIMENSION),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .BIG_N(`BIG_N)
    ) homomorphic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ciphertext1(ciphertext1),
        .ciphertext2(ciphertext2),
        .result(result)
    );

    initial begin
        rst_n = 1;

    	ciphertext[0] = `CIPHERTEXT_WIDTH'd895; // fill
    	ciphertext[1] = `CIPHERTEXT_WIDTH'd894; // fill

    	ciphertext[0] = `CIPHERTEXT_WIDTH'd895; // fill
    	ciphertext[1] = `CIPHERTEXT_WIDTH'd894; // fill

    	expected = 37;
    	#20;

    	$display("Result = %d", result);
        $assert(expected == result);


        $finish;
    end

endmodule
