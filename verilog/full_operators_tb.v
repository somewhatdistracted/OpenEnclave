`define PLAINTEXT_MODULUS 8
`define PLAINTEXT_WIDTH 3
`define DIMENSION 1
`define CIPHERTEXT_MODULUS 64
`define CIPHERTEXT_WIDTH 6
`define BIG_N 5 

module homomorphic_multiply_tb;

    reg clk;
    reg rst_n;
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext_entry;
    reg [`DIMENSION:0] row;
    reg [`DIMENSION+1:0] row_n;
    reg ciphertext_select;
    reg en;
    wire [`PLAINTEXT_WIDTH-1:0] result_decrypt;
    wire [`CIPHERTEXT_WIDTH-1:0] result_partial;
    wire [`CIPHERTEXT_WIDTH-1:0] result_add;
    reg [`CIPHERTEXT_WIDTH-1:0] expected;

    reg go;
    reg [`PLAINTEXT_WIDTH-1:0] plaintext;
    reg [`CIPHERTEXT_WIDTH-1:0] publickey_row [`BIG_N-1:0];
    reg [`BIG_N-1:0] noise_select;
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext;
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext1 [`DIMENSION:0];
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext2 [`DIMENSION:0];
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext3 [`DIMENSION:0];
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext1_add;
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext2_add;
    reg [`CIPHERTEXT_WIDTH-1:0] cipher_text [`DIMENSION+1:0];
    reg [`CIPHERTEXT_WIDTH-1:0] secret_key [`DIMENSION+1:0];
    reg [`CIPHERTEXT_WIDTH-1:0] skentry;
    reg [`CIPHERTEXT_WIDTH-1:0] ctentry;

    always #10 clk = ~clk;

    homomorphic_multiply #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .DIMENSION(`DIMENSION),
        .BIG_N(`BIG_N)
    ) homomorphic_mul_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ciphertext_entry(ciphertext_entry),
        .row(row),
        .ciphertext_select(ciphertext_select),
        .en(en),
        .result_partial(result_partial)
    );

    homomorphic_add #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .DIMENSION(`DIMENSION),
        .BIG_N(`BIG_N)
    ) homomorphic_add_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ciphertext1(ciphertext1_add),
        .ciphertext2(ciphertext2_add),
        .result(result_add)
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

    decrypt #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .DIMENSION(`DIMENSION + 1),
	.BIG_N(`BIG_N)
    ) decrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .secretkey_entry(skentry),
        .ciphertext_entry(ctentry),
	.row(row_n),
        .result(result_decrypt)
    );

    initial begin
        // Encryption
        row = 0;
        rst_n = 1;
        go = 0;
        plaintext = 0;
        noise_select = 0;

        //Get get row 1 of ciphertext 1
    	#20;
	row = 0;
    	plaintext = `PLAINTEXT_WIDTH'd2;
    	noise_select = `BIG_N'b10111; //noise select is reverse from gold
	expected = 26;

        //read in public key row 1
        publickey_row[0] = `CIPHERTEXT_WIDTH'd36;
        publickey_row[1] = `CIPHERTEXT_WIDTH'd20;
        publickey_row[2] = `CIPHERTEXT_WIDTH'd60;
        publickey_row[3] = `CIPHERTEXT_WIDTH'd12;
        publickey_row[4] = `CIPHERTEXT_WIDTH'd36;

        #20
        ciphertext1[0] = ciphertext;
        $display("Result = %d", ciphertext); assert(ciphertext == expected);
        
        //Get row 1 of ciphertext 2
        #20
        plaintext = `PLAINTEXT_WIDTH'd1;
        noise_select = `BIG_N'b11010; // fill
        expected = 5;

        #20
        ciphertext2[0] = ciphertext;
        $display("Result = %d", ciphertext); assert(ciphertext == expected);

        //Get row 2 of ciphertext 2
        #20
        row = 1;
        expected = 49;

        //read in public key 2
        publickey_row[0] = `CIPHERTEXT_WIDTH'd61;
        publickey_row[1] = `CIPHERTEXT_WIDTH'd25;
        publickey_row[2] = `CIPHERTEXT_WIDTH'd1;
        publickey_row[3] = `CIPHERTEXT_WIDTH'd11;
        publickey_row[4] = `CIPHERTEXT_WIDTH'd13;

        #20
        ciphertext2[1] = ciphertext;
        $display("Result = %d", ciphertext); assert(ciphertext == expected);

        //Get row 2 of ciphertext 1
        #20
        plaintext = `PLAINTEXT_WIDTH'd2;
        noise_select = `BIG_N'b10111; // fill
        expected = 36;

        #20
        ciphertext1[1] = ciphertext;
        $display("Result = %d", ciphertext); assert(ciphertext == expected);
        
        #20
        //Addition
        rst_n = 1;

        //load first row
    	ciphertext1_add = ciphertext1[0]; // fill
    	ciphertext2_add = ciphertext2[0]; // fill

    	expected = 31;
    	#20;
        ciphertext3[0] = result_add;
    	$display("Result = %d", result_add); assert(result_add == expected);
        #20
        
        //load second row
        ciphertext1_add = ciphertext1[1]; // fill
        ciphertext2_add = ciphertext2[1]; // fill

        expected = 21;
        #20;
        ciphertext3[1] = result_add;
        $display("Result = %d", result_add); assert(result_add == expected);
        #20        

        // Multiplication
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
        ciphertext_entry = ciphertext3[0];
        
        #20;
        cipher_text[0] = result_partial;
    	$display("Result = %d", result_partial); assert(result_partial == 38);       

        row = 1;
        ciphertext_entry = ciphertext3[1];
        
        #20;
        cipher_text[1] = result_partial;
    	$display("Result = %d", result_partial); assert(result_partial == 62);

        // read out rest of results
        ciphertext_select = 0;
        row = 2;
        
        #20;
        cipher_text[2] = result_partial;
    	$display("Result = %d", result_partial); assert(result_partial == 52);

        //Decryption
        clk = 0;
        rst_n = 0;
 
        #200
        rst_n = 1;
        #200

        //secret key for multiplication [1, s1, s1^2]
    	secret_key[0] = `CIPHERTEXT_WIDTH'd1;
    	secret_key[1] = `CIPHERTEXT_WIDTH'd20;
        secret_key[2] = `CIPHERTEXT_WIDTH'd400;

        #20  

        //insert row 0 info
	row_n = 0;
	skentry = secret_key[0];
	ctentry = cipher_text[0];
	#20;
        
        //insert row 1 info
	row_n = 1;
	skentry = secret_key[1];
	ctentry = cipher_text[1];
	#20;
        
        //insert row 2 info
        row_n = 2;
        skentry = secret_key[2];
        ctentry = cipher_text[2];
        #20;        

        //get final info
	expected = 6;
	$display("Result = %d", result_decrypt); assert(result_decrypt == expected);
	#20;
	$finish;

    end

endmodule
