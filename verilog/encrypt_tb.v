module encrypt_tb
#(
    parameter PLAINTEXT_WIDTH = 8,          // log2(p)
    parameter CIPHERTEXT_WIDTH = 10,
    parameter CIPHERTEXT_MODULUS = 1024,    // q
    parameter BIG_N = 30,                   // N
    parameter LITTLE_N = 2,                 // n
)
();

    reg clk;
    reg rst_n;

    reg go;
    reg [PLAINTEXT_WIDTH-1:0] plaintext;
    reg [CIPHERTEXT_WIDTH-1:0] publickey_row;
    reg [BIG_N-1:0] noise_select;
    reg [LITTLE_N-1:0] row;
    reg [CIPHERTEXT_WIDTH-1:0] ciphertext;

    always #10 clk = ~clk;

    encrypt #(
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .BIG_N(BIG_N),
        .LITTLE_N(LITTLE_N),
    ) encrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .go(go),
        .plaintext(plaintext),
        .publickey_row(publickey_row),
        .noise_select(noise_select),
        .row(row),
        .ciphertext(ciphertext),
    );

    initial begin
        row = 0;
        rst_n = 1;
        go = 0;
        plaintext = 0;
        publickey_row = 0;
        noise_select = 0;
    end

    #10;

    plaintext = PLAINTEXT_WIDTH'b101;
    noise_select = BIG_N'b0; // fill
    publickey_row = CIPHERTEXT_WIDTH'b0; //fill

    #10;

    $assert(ciphertext == expected[0]);

    #10;

    row += 1;
    publickey_row = CIPHERTEXT_WIDTH'b0; //fill

    #10;

    $assert(ciphertext == expected[1]);

    #10;

endmodule
