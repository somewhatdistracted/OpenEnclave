`define PLAINTEXT_MODULUS 64
`define PLAINTEXT_WIDTH 6
`define DIMENSION 3
`define DIM_WIDTH 2
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH 21
`define ADDR_WIDTH 10
`define BIG_N 30
`define PARALLEL 1

module controller_tb;

    reg clk;
    reg rst_n;

    reg [1:0] opcode;
    reg config_en;
    reg [`ADDR_WIDTH-1:0] op1_base_addr;
    reg [`ADDR_WIDTH-1:0] op2_base_addr;
    reg [`ADDR_WIDTH-1:0] out_base_addr;


    reg [1:0] opcode_out;
    reg [`ADDR_WIDTH-1:0] op1_addr;
    reg [`ADDR_WIDTH-1:0] op2_addr;
    reg [`ADDR_WIDTH-1:0] out_addr;
    reg op_select;
    reg en;
    reg done;
    reg [`DIM_WIDTH:0] row;

    always #10 clk = ~clk;

    controller #(
        .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
        .DIMENSION(`DIMENSION),
        .DIM_WIDTH(`DIM_WIDTH),
        .BIG_N(`BIG_N),
        .PARALLEL(`PARALLEL)
    ) controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .opcode(opcode),
        .config_en(config_en),
        .op1_base_addr(op1_base_addr),
        .op2_base_addr(op2_base_addr),
        .out_base_addr(out_base_addr),
        .opcode_out(opcode_out),
        .op1_addr(op1_addr),
        .op2_addr(op2_addr),
        .out_addr(out_addr),
        .op_select(op_select),
        .en(en),
        .done(done),
        .row(row)
    );

    initial begin
        clk = 0;
        rst_n = 0;
        #40;
        // inputs to module:
        rst_n = 1;

        // load in add
        opcode = 2;
        config_en = 1;
        op1_base_addr = 10;
        op2_base_addr = 15;
        out_base_addr = 20;
        #20;

        // stop loading config
        config_en = 0;


        // read out contents
        for (int i = 0; i < 10; i += 1) begin
            $display("C: OP: %d, ADR1: %d, ADR2: %d, ADRO: %d, OPS: %d, EN: %d, DONE: %d, ROW: %d",opcode_out,op1_addr,op2_addr,out_addr,op_select,en,done,row);
            #20;
        end



    	//$display("Result = %d", ciphertext); assert(ciphertext == expected);

        $finish;
    end
endmodule
