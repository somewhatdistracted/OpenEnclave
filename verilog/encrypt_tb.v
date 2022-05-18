`define PLAINTEXT_MODULUS 64
`define PLAINTEXT_WIDTH 6
`define DIMENSION 1
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH 10
`define BIG_N 30

module encrypt_tb;

    reg clk;
    reg rst_n;

    reg go;
    reg [`PLAINTEXT_WIDTH-1:0] plaintext;
    reg [`CIPHERTEXT_WIDTH-1:0] publickey_row [`BIG_N-1:0];
    reg [`BIG_N-1:0] noise_select;
    reg [`DIMENSION:0] row;
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext;
    reg [`CIPHERTEXT_WIDTH-1:0] expected;

    always #10 clk = ~clk;

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
        .plaintext_and_noise(plaintext),
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

    	#20;

        row = 0;        
        plaintext = `PLAINTEXT_WIDTH'd2;
        noise_select = `BIG_N'b101010001110110011100110111001;// fill
        expected = 600;

        publickey_row[0] = `CIPHERTEXT_WIDTH'd320;
        publickey_row[1] = `CIPHERTEXT_WIDTH'd909;
        publickey_row[2] = `CIPHERTEXT_WIDTH'd721;
        publickey_row[3] = `CIPHERTEXT_WIDTH'd278;
        publickey_row[4] = `CIPHERTEXT_WIDTH'd946;
        publickey_row[5] = `CIPHERTEXT_WIDTH'd806;
        publickey_row[6] = `CIPHERTEXT_WIDTH'd193;
        publickey_row[7] = `CIPHERTEXT_WIDTH'd593;
        publickey_row[8] = `CIPHERTEXT_WIDTH'd121;
        publickey_row[9] = `CIPHERTEXT_WIDTH'd418;
        publickey_row[10] = `CIPHERTEXT_WIDTH'd739;
        publickey_row[11] = `CIPHERTEXT_WIDTH'd642;
        publickey_row[12] = `CIPHERTEXT_WIDTH'd648;
        publickey_row[13] = `CIPHERTEXT_WIDTH'd873;
        publickey_row[14] = `CIPHERTEXT_WIDTH'd279;
        publickey_row[15] = `CIPHERTEXT_WIDTH'd1023;
        publickey_row[16] = `CIPHERTEXT_WIDTH'd643;
        publickey_row[17] = `CIPHERTEXT_WIDTH'd129;
        publickey_row[18] = `CIPHERTEXT_WIDTH'd666;
        publickey_row[19] = `CIPHERTEXT_WIDTH'd962;
        publickey_row[20] = `CIPHERTEXT_WIDTH'd869;
        publickey_row[21] = `CIPHERTEXT_WIDTH'd165;
        publickey_row[22] = `CIPHERTEXT_WIDTH'd698;
        publickey_row[23] = `CIPHERTEXT_WIDTH'd821;
        publickey_row[24] = `CIPHERTEXT_WIDTH'd744;
        publickey_row[25] = `CIPHERTEXT_WIDTH'd837;
        publickey_row[26] = `CIPHERTEXT_WIDTH'd466;
        publickey_row[27] = `CIPHERTEXT_WIDTH'd394;
        publickey_row[28] = `CIPHERTEXT_WIDTH'd192;
        publickey_row[29] = `CIPHERTEXT_WIDTH'd588;

        #20
        $display("Result = %d", ciphertext); assert(ciphertext == expected);
        #20

        plaintext = `PLAINTEXT_WIDTH'd1;
        noise_select = `BIG_N'b100101000110100011011001101010;// fill
        expected = 431;

        #20
        $display("Result = %d", ciphertext); assert(ciphertext == expected);
        
        #20;

        row = 1;
        plaintext = `PLAINTEXT_WIDTH'd2;
        noise_select = `BIG_N'b101010001110110011100110111001;// fill
        expected = 882;

        publickey_row[0] = `CIPHERTEXT_WIDTH'd576;
        publickey_row[1] = `CIPHERTEXT_WIDTH'd847;
        publickey_row[2] = `CIPHERTEXT_WIDTH'd763;
        publickey_row[3] = `CIPHERTEXT_WIDTH'd626;
        publickey_row[4] = `CIPHERTEXT_WIDTH'd294;
        publickey_row[5] = `CIPHERTEXT_WIDTH'd34;
        publickey_row[6] = `CIPHERTEXT_WIDTH'd651;
        publickey_row[7] = `CIPHERTEXT_WIDTH'd187;
        publickey_row[8] = `CIPHERTEXT_WIDTH'd819;
        publickey_row[9] = `CIPHERTEXT_WIDTH'd246;
        publickey_row[10] = `CIPHERTEXT_WIDTH'd321;
        publickey_row[11] = `CIPHERTEXT_WIDTH'd854;
        publickey_row[12] = `CIPHERTEXT_WIDTH'd24;
        publickey_row[13] = `CIPHERTEXT_WIDTH'd67;
        publickey_row[14] = `CIPHERTEXT_WIDTH'd701;
        publickey_row[15] = `CIPHERTEXT_WIDTH'd117;
        publickey_row[16] = `CIPHERTEXT_WIDTH'd865;
        publickey_row[17] = `CIPHERTEXT_WIDTH'd331;
        publickey_row[18] = `CIPHERTEXT_WIDTH'd350;
        publickey_row[19] = `CIPHERTEXT_WIDTH'd150;
        publickey_row[20] = `CIPHERTEXT_WIDTH'd407;
        publickey_row[21] = `CIPHERTEXT_WIDTH'd407;
        publickey_row[22] = `CIPHERTEXT_WIDTH'd318;
        publickey_row[23] = `CIPHERTEXT_WIDTH'd135;
        publickey_row[24] = `CIPHERTEXT_WIDTH'd760;
        publickey_row[25] = `CIPHERTEXT_WIDTH'd567;
        publickey_row[26] = `CIPHERTEXT_WIDTH'd70;
        publickey_row[27] = `CIPHERTEXT_WIDTH'd430;
        publickey_row[28] = `CIPHERTEXT_WIDTH'd320;
        publickey_row[29] = `CIPHERTEXT_WIDTH'd388;

        #20
        $display("Result = %d", ciphertext); assert(ciphertext == expected);
        #20

        plaintext = `PLAINTEXT_WIDTH'd1;
        noise_select = `BIG_N'b100101000110100011011001101010;// fill
        expected = 826;

        #20
        $display("Result = %d", ciphertext); assert(ciphertext == expected);

        
        $finish;
    end
endmodule
