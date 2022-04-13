`define PLAINTEXT_MODULUS 64 
`define PLAINTEXT_WIDTH 6
`define DIMENSION 1
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH 21 
`define BIG_N 30 

module homomorphic_add_tb;

    reg clk;
    reg rst_n;
    reg signed [`CIPHERTEXT_WIDTH-1:0] ciphertext1;
    reg signed [`CIPHERTEXT_WIDTH-1:0] ciphertext2;
    wire signed [`CIPHERTEXT_WIDTH-1:0] result;
    reg signed [`CIPHERTEXT_WIDTH-1:0] expected;

    always #10 clk = ~clk;

    homomorphic_add #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .DIMENSION(`DIMENSION),
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

    	ciphertext1 = `CIPHERTEXT_WIDTH'd102; // fill
    	ciphertext2 = `CIPHERTEXT_WIDTH'd356; // fill

    	expected = 458;
    	#20;

    	$display("Result = %d", result); assert(result == expected);
        $finish;
    end

endmodule
