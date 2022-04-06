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
    reg [CIPHERTEXT_WIDTH-1:0] secret_key_prime;
    reg signed [CIPHERTEXT_WIDTH-1:0] cipher_text_top;
    reg signed [CIPHERTEXT_WIDTH-1:0] cipher_text_bot;
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
        .secret_key_prime(secret_key_prime),
        .cipher_text_top(cipher_text_top),
        .result(result),
    );

    initial begin
        rst_n = 1;
        secret_key_prime = 0;
        cipher_text_top = 0;
        cipher_text_bot = 0;
    end

    secret_key_prime = CIPHERTEXT_WIDTH'b0; // fill with value
    cipher_text_top = CIPHERTEXT_WIDTH'b0; // fill
    cipher_text_bot = CIPHERTEXT_WIDTH'b0;

    expected = 0;
    #10;

    $assert(result == expected);

endmodule

