`define PLAINTEXT_MODULUS 64 
`define PLAINTEXT_WIDTH 6
`define DIMENSION 1
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH 10 
`define BIG_N 30 
`define PARALLEL 2

module homomorphic_add_tb;

    reg clk;
    reg rst_n;
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext1 [`PARALLEL-1:0];
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext2 [`PARALLEL-1:0];
    wire [`CIPHERTEXT_WIDTH-1:0] result [`PARALLEL-1:0];
    reg  [`CIPHERTEXT_WIDTH-1:0] expected [`PARALLEL-1:0];

    always #10 clk = ~clk;

    homomorphic_add #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .DIMENSION(`DIMENSION),
        .BIG_N(`BIG_N),
        .PARALLEL(`PARALLEL)
    ) homomorphic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ciphertext1(ciphertext1),
        .ciphertext2(ciphertext2),
        .result(result)
    );

    initial begin
        rst_n = 1;

        ciphertext1[0] = `CIPHERTEXT_WIDTH'd102; // fill
        ciphertext1[1] = `CIPHERTEXT_WIDTH'd72; // fill
        ciphertext2[0] = `CIPHERTEXT_WIDTH'd356; // fill
        ciphertext2[1] = `CIPHERTEXT_WIDTH'd23; // fill

        expected[0] = 458;
        expected[1] = 95;
        #20;

        $display("Result = %d, %d", result[0], result[1]); assert(result == expected);

        ciphertext1[0] = `CIPHERTEXT_WIDTH'd600; // fill
        ciphertext1[1] = `CIPHERTEXT_WIDTH'd3; // fill
        ciphertext2[0] = `CIPHERTEXT_WIDTH'd431; // fill
        ciphertext2[1] = `CIPHERTEXT_WIDTH'd10; // fill

        expected[0] = 7;
        expected[1] = 13;
        #20;

        $display("Result = %d, %d", result[0], result[1]); assert(result == expected);

        ciphertext1[0] = `CIPHERTEXT_WIDTH'd882; // fill
        ciphertext2[0] = `CIPHERTEXT_WIDTH'd826; // fill

        expected[0] = 684;
        #20;

        $display("Result = %d, %d", result[0], result[1]); assert(result == expected);

        $finish;
    end

endmodule
