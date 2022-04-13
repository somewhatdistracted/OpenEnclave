`define PLAINTEXT_MODULUS 8
`define PLAINTEXT_WIDTH 3
`define DIMENSION 1
`define CIPHERTEXT_MODULUS 64
`define CIPHERTEXT_WIDTH 6
`define BIG_N 5 

module homomorphic_multiply_tb;

    reg clk;
    reg rst_n;
    reg signed [`CIPHERTEXT_WIDTH-1:0] ciphertext_entry;
    reg [`DIMENSION:0] row;
    reg ciphertext_select;
    reg en;
    wire [`CIPHERTEXT_WIDTH-1:0] result;
    reg signed [`CIPHERTEXT_WIDTH-1:0] expected;

    reg go;
    reg [`PLAINTEXT_WIDTH-1:0] plaintext;
    reg [`CIPHERTEXT_WIDTH-1:0] publickey_row [`BIG_N-1:0];
    reg [`BIG_N-1:0] noise_select;
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext;
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext1 [`DIMENSION:0];
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext2 [`DIMENSION:0];

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

    encrypt #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .DIMENSION(`DIMENSION),
        .BIG_N(`BIG_N)
    ) encrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .plaintext(plaintext),
        .publickey_row(publickey_row),
        .noise_select(noise_select),
        .row(row),
        .ciphertext(ciphertext)
    );

    initial begin
        row = 0;
        rst_n = 1;
        go = 0;
        plaintext = 0;
        noise_select = 0;

    	#10;

    	plaintext = `PLAINTEXT_WIDTH'd2;
    	noise_select = `BIG_N'b10111; // fill
	expected = 26;

        publickey_row[0] = `CIPHERTEXT_WIDTH'd56;
        publickey_row[1] = `CIPHERTEXT_WIDTH'd8;
        publickey_row[2] = `CIPHERTEXT_WIDTH'd24;
        publickey_row[3] = `CIPHERTEXT_WIDTH'd16;
        publickey_row[4] = `CIPHERTEXT_WIDTH'd56;

        #10
        ciphertext1[0] = ciphertext;
        $display("Result = %d", ciphertext); assert(ciphertext == expected);
        
        #10
        plaintext = `PLAINTEXT_WIDTH'd3;
        noise_select = `BIG_N'b00000; // fill
        expected = 3;

        #10
        ciphertext2[0] = ciphertext;
        $display("Result = %d", ciphertext); assert(ciphertext == expected);

        #10
        expected = 0;

        publickey_row[0] = `CIPHERTEXT_WIDTH'd1;
        publickey_row[1] = `CIPHERTEXT_WIDTH'd48;
        publickey_row[2] = `CIPHERTEXT_WIDTH'd45;
        publickey_row[3] = `CIPHERTEXT_WIDTH'd48;
        publickey_row[4] = `CIPHERTEXT_WIDTH'd54;

        #10
        ciphertext2[1] = ciphertext;
        $display("Result = %d", ciphertext); assert(ciphertext == expected);

        #10
        plaintext = `PLAINTEXT_WIDTH'd2;
        noise_select = `BIG_N'b10111; // fill
        expected = 20;

        #10
        ciphertext1[1] = ciphertext;
        $display("Result = %d", ciphertext); assert(ciphertext == expected);

        clk = 0;
        rst_n = 0;
        en = 0;
        ciphertext_select = 0;
        row = 0;
        ciphertext_entry = 0;
        #200;
        rst_n = 1;
        #200;

        // reading in ciphertext 1
        row = 0;
        ciphertext_select = 0;
        ciphertext_entry = ciphertext1[0];
        en = 1;
    	#20;

        row = 1;
        ciphertext_entry = ciphertext1[1];
    	#20;

        // reading in ciphertext 2
        row = 0;
        ciphertext_select = 1;
        ciphertext_entry = ciphertext2[0];
        #20;
    	$display("Result = %d", result); assert(result == 14);

        row = 1;
        ciphertext_entry = ciphertext2[1];
        #20;
    	$display("Result = %d", result); assert(result == 60);

        // read out rest of results
        ciphertext_select = 0;
        row = 2;
        #20;
    	$display("Result = %d", result); assert(result == 0);

        

        $finish;
    end

endmodule
