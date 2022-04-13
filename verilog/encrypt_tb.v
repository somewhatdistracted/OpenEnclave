`define PLAINTEXT_MODULUS 64
`define PLAINTEXT_WIDTH 6
`define DIMENSION 1
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH 21
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

    	plaintext = `PLAINTEXT_WIDTH'b101;
    	noise_select = `BIG_N'b100110001101010110000011000010; // fill
	expected = 752224;

        publickey_row[0] = `CIPHERTEXT_WIDTH'd124312;
        publickey_row[1] = `CIPHERTEXT_WIDTH'd58876;
        publickey_row[2] = `CIPHERTEXT_WIDTH'd59532;
        publickey_row[3] = `CIPHERTEXT_WIDTH'd3836;
        publickey_row[4] = `CIPHERTEXT_WIDTH'd94956;
        publickey_row[5] = `CIPHERTEXT_WIDTH'd161376;
        publickey_row[6] = `CIPHERTEXT_WIDTH'd20564;
        publickey_row[7] = `CIPHERTEXT_WIDTH'd92888;
        publickey_row[8] = `CIPHERTEXT_WIDTH'd126280;
        publickey_row[9] = `CIPHERTEXT_WIDTH'd72980;
        publickey_row[10] = `CIPHERTEXT_WIDTH'd101908;
        publickey_row[11] = `CIPHERTEXT_WIDTH'd656;
        publickey_row[12] = `CIPHERTEXT_WIDTH'd127920;
        publickey_row[13] = `CIPHERTEXT_WIDTH'd76980;
        publickey_row[14] = `CIPHERTEXT_WIDTH'd75340;
        publickey_row[15] = `CIPHERTEXT_WIDTH'd105124;
        publickey_row[16] = `CIPHERTEXT_WIDTH'd141104;
        publickey_row[17] = `CIPHERTEXT_WIDTH'd23352;
        publickey_row[18] = `CIPHERTEXT_WIDTH'd3772;
        publickey_row[19] = `CIPHERTEXT_WIDTH'd41656;
        publickey_row[20] = `CIPHERTEXT_WIDTH'd28700;
        publickey_row[21] = `CIPHERTEXT_WIDTH'd123820;
        publickey_row[22] = `CIPHERTEXT_WIDTH'd44344;
        publickey_row[23] = `CIPHERTEXT_WIDTH'd7052;
        publickey_row[24] = `CIPHERTEXT_WIDTH'd148976;
        publickey_row[25] = `CIPHERTEXT_WIDTH'd57300;
        publickey_row[26] = `CIPHERTEXT_WIDTH'd17448;
        publickey_row[27] = `CIPHERTEXT_WIDTH'd118900;
        publickey_row[28] = `CIPHERTEXT_WIDTH'd64352;
        publickey_row[29] = `CIPHERTEXT_WIDTH'd55432;

    	#10;

    	$display("Result = %d", ciphertext); assert(ciphertext == expected);

        $finish;
    end
endmodule
