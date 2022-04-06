module decrypt_tb
#(
  parameter PLAINTEXT_MODULUS = 64, 
  parameter PLAINTEXT_WIDTH = 6,
  parameter DIMENSION = 1,
  parameter CIPHERTEXT_MODULUS = 1024,
  parameter CIPHERTEXT_WIDTH = 10, 
  parameter BIG_N = 30, 
  
)
();

    reg clk;
    reg rst_n;
    reg [CIPHERTEXT_WIDTH-1:0] secret_key [DIMENSION:0];
    reg signed [CIPHERTEXT_WIDTH-1:0] cipher_text [DIMENSION:0];
    reg [PLAINTEXT_WIDTH-1:0] result;
    reg [PLAINTEXT_WIDTH-1:0] expected;

    always #10 clk = ~clk;

    decrypt #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .BIG_N(BIG_N),
    ) decrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .secret_key(secret_key),
        .cipher_text(cipher_text),
        .result(result),
    );

    initial begin
        rst_n = 1;
        secret_key_prime = [0, 0];
        cipher_text_top = [0, 0];
    end

    secret_key[0] = CIPHERTEXT_WIDTH'b0; // fill with value
    secret_key[1] = CIPHERTEXT_WIDTH'b0; // fill with value
    cipher_text[0] = CIPHERTEXT_WIDTH'b0; // fill
    cipher_text[1] = CIPHERTEXT_WIDTH'b0; // fill

    expected = 0;
    #10;

    $assert(result == expected);

endmodule

