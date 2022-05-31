`define PLAINTEXT_MODULUS 64 
`define PLAINTEXT_WIDTH 6
`define DIMENSION 1
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH 10 
`define BIG_N 30 

module decrypt_tb;

    reg clk;
    reg rst_n;
    reg [`CIPHERTEXT_WIDTH-1:0] secret_key [`DIMENSION:0];
    reg signed [`CIPHERTEXT_WIDTH-1:0] cipher_text [`DIMENSION:0];
    reg [`CIPHERTEXT_WIDTH-1:0] skentry;
    reg signed [`CIPHERTEXT_WIDTH-1:0] ctentry;
    reg [`DIMENSION:0] row;
    wire [`PLAINTEXT_WIDTH-1:0] result;
    reg [`PLAINTEXT_WIDTH-1:0] expected;

    always #10 clk = ~clk;

    decrypt #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .DIMENSION(`DIMENSION),
	.BIG_N(`BIG_N)
    ) decrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .secretkey_entry(skentry),
        .ciphertext_entry(ctentry),
	.row(row),
        .result(result)
    );

    initial begin
	clk = 0;
        rst_n = 0;

        #200;
        rst_n = 1;
        #200;

    	secret_key[0] = `CIPHERTEXT_WIDTH'd1; // fill with value
    	secret_key[1] = `CIPHERTEXT_WIDTH'd173; // fill with value
    	cipher_text[0] = `CIPHERTEXT_WIDTH'd895; // fill
    	cipher_text[1] = `CIPHERTEXT_WIDTH'd894; // fill

	row = 0;
	skentry = secret_key[0];
	ctentry = cipher_text[0];
	#20;

	row = 1;
	skentry = secret_key[1];
	ctentry = cipher_text[1];
	#20;

	expected = 37;
	$display("Result = %d", result); assert(result == expected);

	#200;
        rst_n = 1;
        #200;

        secret_key[0] = `CIPHERTEXT_WIDTH'd1; // fill with value
        secret_key[1] = `CIPHERTEXT_WIDTH'd157; // fill with value
        cipher_text[0] = `CIPHERTEXT_WIDTH'd600; // fill
        cipher_text[1] = `CIPHERTEXT_WIDTH'd882; // fill

        row = 0;
        skentry = secret_key[0];
        ctentry = cipher_text[0];
        #20;

        row = 1;
        skentry = secret_key[1];
        ctentry = cipher_text[1];
        #20;

        expected = 2;
        $display("Result = %d", result); assert(result == expected);

        #200;
        rst_n = 1;
        #200;

        cipher_text[0] = `CIPHERTEXT_WIDTH'd431; // fill
        cipher_text[1] = `CIPHERTEXT_WIDTH'd826; // fill

        row = 0;
        skentry = secret_key[0];
        ctentry = cipher_text[0];
        #20;

        row = 1;
        skentry = secret_key[1];
        ctentry = cipher_text[1];
        #20;

        expected = 1;
        $display("Result = %d", result); assert(result == expected);

        #200;
        rst_n = 1;
        #200;

        cipher_text[0] = `CIPHERTEXT_WIDTH'd7; // fill
        cipher_text[1] = `CIPHERTEXT_WIDTH'd684; // fill

        row = 0;
        skentry = secret_key[0];
        ctentry = cipher_text[0];
        #20;

        row = 1;
        skentry = secret_key[1];
        ctentry = cipher_text[1];
        #20;

        expected = 3;
        $display("Result = %d", result); assert(result == expected);

	$finish;
    end

endmodule
