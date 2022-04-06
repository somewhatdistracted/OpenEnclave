`define PLAINTEXT_MODULUS 64 
`define PLAINTEXT_WIDTH 6
`define DIMENSION 1
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH 21 
`define BIG_N 30 

module decrypt_tb;

    reg clk;
    reg rst_n;
    reg [`CIPHERTEXT_WIDTH-1:0] secret_key [`DIMENSION:0];
    reg signed [`CIPHERTEXT_WIDTH-1:0] cipher_text [`DIMENSION:0];
    reg [`PLAINTEXT_WIDTH-1:0] result;
    reg [`PLAINTEXT_WIDTH-1:0] expected;

    always #10 clk = ~clk;

    decrypt #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .DIMENSION(`DIMENSION),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .BIG_N(`BIG_N)
    ) decrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .secret_key(secret_key),
        .cipher_text(cipher_text),
        .result(result)
    );

    initial begin
        rst_n = 1;

    	secret_key[0] = `CIPHERTEXT_WIDTH'd1; // fill with value
    	secret_key[1] = `CIPHERTEXT_WIDTH'd173; // fill with value
    	cipher_text[0] = `CIPHERTEXT_WIDTH'd895; // fill
    	cipher_text[1] = `CIPHERTEXT_WIDTH'd894; // fill

    	expected = 37;
    	#20;

    	$display("Result = %d", result);
        $finish;
    end

endmodule
