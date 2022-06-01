`define PLAINTEXT_MODULUS 64
`define PLAINTEXT_WIDTH 6
`define DIMENSION 3
`define DIM_WIDTH 2
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH 32
`define BIG_N 2
`define PARALLEL 2

module encrypt_tb;

    reg clk;
    reg rst_n;

    reg en;
    reg done;
    reg [`CIPHERTEXT_WIDTH-1:0] chan1 [`PARALLEL-1:0];
    reg [`CIPHERTEXT_WIDTH-1:0] chan2 [`PARALLEL-1:0];
    reg [`DIM_WIDTH-1:0] row;
    reg [`CIPHERTEXT_WIDTH-1:0] ciphertext;
    reg [`CIPHERTEXT_WIDTH-1:0] expected;

    always #10 clk = ~clk;

    encrypt #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .DIMENSION(`DIMENSION),
        .DIM_WIDTH(`DIM_WIDTH),
        .BIG_N(`BIG_N),
        .PARALLEL(`PARALLEL)
    ) encrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .done(done),
        .en(en),
        .op1(chan1),
        .op2(chan2),
        .row(row),
        .ciphertext(ciphertext)
    );

    initial begin
        clk = 0;
        row = 0;
        rst_n = 0;
        en = 0;
        done = 0;
        chan1[0] = 0;
        chan1[1] = 0;
        chan2[0] = 0;
        chan2[1] = 0;

    	#20;
        rst_n = 1;

        #20;

        row = 0;
        en = 1;
        chan1[0] = 25;
        chan1[1] = 5;
        chan2[0] = 13; 
        chan2[1] = 5; //sum 48

        #20;
        chan1[0] = 2;
        chan1[1] = 0;
        chan2[0] = 5; 
        chan2[1] = 0; //sum 55

        #20;
        expected = 55;
        row = 1;
        chan1[0] = 12;
        chan1[1] = 2;
        chan2[0] = 5; 
        chan2[1] = 3; //sum 22

        #20;
        $display("Result = %d", ciphertext); assert(ciphertext == expected);
        expected = 22;
        row = 2;

        #20;
        $display("Result = %d", ciphertext); assert(ciphertext == expected);
        

        #200;
        $finish;
    end
endmodule
