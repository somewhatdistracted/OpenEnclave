module top
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 10,
    parameter DIMENSION = 10,
    parameter BIG_N = 30,
    parameter WISHBONE_BASE_ADDR = 32'h30000000,
    parameter DATA_WIDTH = 128,
    parameter ADDR_WIDTH = 10,
    parameter DEPTH = 1024,
    
)
(
    input clk,
    input rst_n,

    input        wb_clk_i,
    input        wb_rst_i,
    input        wbs_stb_i,
    input        wbs_cyc_i,
    input        wbs_we_i,
    input [3:0]  wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,

    output        wbs_ack_o,
    output [31:0] wbs_dat_o
);  

    wire [31:0] wishbone_output;
    wire [31:0] wishbone_data;
    wire wb_ready_i;
    wire wb_ready_o;
   
    wire [1:0] opcode;
    wire config_en;
    wire [ADDR_WIDTH-1:0] op1_base_addr;
    wire [ADDR_WIDTH-1:0] op2_base_addr;
    reg [1:0] opcode_out;
    reg [ADDR_WIDTH-1:0] op1_addr;
    reg [ADDR_WIDTH-1:0] op2_addr;
    reg op_select;
    reg en;
    reg done;
    reg [DIM_WIDTH-1:0] row;

    wire wen;
    wire [ADDR_WIDTH - 1 : 0] wadr;
    wire [DATA_WIDTH - 1 : 0] wdata;
    wire ren;
    wire [ADDR_WIDTH - 1 : 0] radr;
    wire [DATA_WIDTH - 1 : 0] rdata;

    wire [PLAINTEXT_WIDTH-1:0] plaintext,
    wire [CIPHERTEXT_WIDTH-1:0] publickey_row [BIG_N-1:0],
    wire [BIG_N-1:0] noise_select,
    wire [DIMENSION:0] encrypt_row,
    wire [CIPHERTEXT_WIDTH-1:0] ciphertext

    wire [CIPHERTEXT_WIDTH-1:0] secretkey_entry;
    wire [CIPHERTEXT_WIDTH-1:0] ciphertext_entry;
    wire [DIMENSION:0] decrypt_row;
    wire [PLAINTEXT_WIDTH-1:0] decrypt_result;

    wire [CIPHERTEXT_WIDTH-1:0] ciphertext1;
    wire [CIPHERTEXT_WIDTH-1:0] ciphertext2;
    wire [CIPHERTEXT_WIDTH-1:0] add_result;

    wire [CIPHERTEXT_WIDTH-1:0] ciphertext_entry;
    wire [DIMENSION:0] mult_row;
    wire ciphertext_select;
    wire mult_en;
    wire [CIPHERTEXT_WIDTH-1:0] mult_result;

    // WISHBONE
    wishbone_ctl #(
        .WISHBONE_BASE_ADDR(WISHBONE_BASE_ADDR)
    ) wb_inst (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .output_ready(wb_ready_i),
        .wishbone_output(wishbone_output),
        .input_ready(wb_ready_i),
        .wishbone_data(wishbone_data),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o)        
    );
    
    // CONTROLLER
    controller #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .BIG_N(BIG_N)
    ) controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .opcode(opcode),
        .config_en(config_en),
        .op1_base_addr(op1_base_addr),
        .op2_base_addr(op2_base_addr),
        .opcode_out(opcode_out),
        .op1_addr(op1_addr),
        .op2_addr(op2_addr),
        .op_select(op_select),
        .en(en),
        .done(done),
        .row(row)
    );


    // SRAM
    sram #(
        .DATA_WIDTH(DATA_WIDTH);
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) sram_inst (
        .clk(clk),
        .wen(wen),
        .wdata(wdata),
        .ren(ren),
        .radr(radr),
        .rdata(rdata)
    );
    
    // ADDRESS GENERATOR
    
    // I/O FIFOS
    
    // ENCRYPT
    encrypt #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .BIG_N(BIG_N)
    ) encrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .plaintext(plaintext),
        .publickey_row(publickey_row),
        .noise_select(noise_select),
        .row(encrypt_row),
        .ciphertext(ciphertext)
    );    
    
    // DECRYPT
    decrypt #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .BIG_N(BIG_N)
    ) decrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .secretkey_entry(sk_entry),
        .ciphertext_entry(ct_entry),
        .row(decrypt_row),
        .result(decrypt_result)
    );
    
    // ADD
    homomorphic_add #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .BIG_N(BIG_N)
    ) homomorphic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ciphertext1(ciphertext1),
        .ciphertext2(ciphertext2),
        .result(add_result)
    );
    
    
    // MULT
    homomorphic_multiply #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .BIG_N(BIG_N)
    ) homomorphic_multiply_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ciphertext_entry(ciphertext_entry),
        .row(mult_row),
        .ciphertext_select(ciphertext_select),
        .en(mult_en),
        .result_partial(mult_result)
    );


    // MORE


endmodule
