//`default_nettype none
`define MPRJ_IO_PADS 38

module top
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 10,
    parameter DIMENSION = 10,
    parameter BIG_N = 30,
    parameter OPCODE_ADDR = 32'h30000000,
    parameter OUTPUT_ADDR = 32'h00000001,
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 10,
    parameter DEPTH = 512,
    parameter DIM_WIDTH = 4,
    parameter USE_POWER_PINS = 0, 
    parameter ENABLE_FULL_IO = 0  
)
(
  `ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
  `endif

    // Logic Analyzer
    // [0] -> gpio (1) / wishbone (0) select
    // [1] -> rst_n
    input  wire [127:0] la_data_in,
    output wire [127:0] la_data_out,
    input  wire [127:0] la_oenb,

    // IOs
    input  wire [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout wire [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input wire user_clock2,

    // User maskable interrupt signals
    output wire [2:0] user_irq,

    //Wishbone
    input wire       wb_clk_i,
    input wire       wb_rst_i,
    input wire       wbs_stb_i,
    input wire       wbs_cyc_i,
    input wire       wbs_we_i,
    input wire [3:0]  wbs_sel_i,
    input wire [31:0] wbs_dat_i,
    input wire [31:0] wbs_adr_i,
    output wire        wbs_ack_o,
    output wire [31:0] wbs_dat_o
);  
    wire clk;
    wire rst_n;

    assign clk = (la_oenb[0] & la_data_in[0]) ? user_clock2 : wb_clk_i;
    assign rst_n = la_oenb[1] ? la_data_in[1] : 1;

    wire [31:0] wishbone_output;
    wire [31:0] wishbone_data;
    wire [31:0] wishbone_addr;
    wire wb_read_req;
    wire wb_write_req;
   
    wire [1:0] opcode;
    wire config_en;
    wire [ADDR_WIDTH-1:0] op1_base_addr;
    wire [ADDR_WIDTH-1:0] op2_base_addr;
    wire [ADDR_WIDTH-1:0] out_base_addr;
    reg [1:0] opcode_out;
    reg [ADDR_WIDTH-1:0] op1_addr;
    reg [ADDR_WIDTH-1:0] op2_addr;
    reg [ADDR_WIDTH-1:0] out_addr;
    reg op_select;
    reg en;
    reg done;
    reg [DIM_WIDTH-1:0] row;

    wire in_wen;
    wire [ADDR_WIDTH - 1 : 0] in_wadr;
    wire [DATA_WIDTH - 1 : 0] in_wdata;

    wire out_wen;
    wire [ADDR_WIDTH - 1 : 0] out_wadr;
    wire [DATA_WIDTH - 1 : 0] out_wdata;
    
    wire op1_ren;
    wire [ADDR_WIDTH - 1 : 0] op1_radr;
    wire [DATA_WIDTH - 1 : 0] op1_rdata;

    wire op2_ren;
    wire [ADDR_WIDTH - 1 : 0] op2_radr;
    wire [DATA_WIDTH - 1 : 0] op2_rdata;
    
    wire out_ren;
    wire [ADDR_WIDTH - 1 : 0] out_radr;
    wire [DATA_WIDTH - 1 : 0] out_rdata;

    wire [CIPHERTEXT_WIDTH-1:0] plaintext_and_noise;
    wire [CIPHERTEXT_WIDTH-1:0] publickey_entry;
    wire [BIG_N-1:0] noise_select;
    wire [DIM_WIDTH-1:0] encrypt_row;
    wire [CIPHERTEXT_WIDTH-1:0] ciphertext_result;

    wire [CIPHERTEXT_WIDTH-1:0] secretkey_entry;
    wire [CIPHERTEXT_WIDTH-1:0] ct_entry;
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

    assign wishbone_output = out_rdata;

    //Debug Prints
    always@(posedge clk) begin
      $display("Chip Output = %d", wbs_dat_o);
      $display("Wishbone In = %d", wbs_dat_i);
      $display("Wishbone Data = %d", wishbone_data);
      $display("Wishbone ADR = %d", wbs_adr_i);
      $display("Config = %d", config_en);
      $display("OPCODE = %d", opcode_out);
      $display("SRAM Write Data = %d", in_wdata);
      $display("SRAM Write Adr = %d", in_wadr);
      $display("SRAM OW Data = %d", out_wdata);
      $display("SRAM OW ADDR = %d", out_wadr);
      $display("SRAM OR Data = %d", out_rdata);
      $display("SRAM O Adr = %d", out_radr);
      $display("Op Data 1 = %d", op1_rdata);
      $display("Op Data 2 = %d", op2_rdata);
      $display("Op Adr 1 = %d", op1_radr);
      $display("Op Adr 2 = %d", op2_radr);
      $display("Op Base Adr 1 = %d", op1_base_addr);
      $display("Op Base Adr 2 = %d", op2_base_addr);
      $display("Row = %d", row);

      $display("Reset = %d", rst_n);
      $display("En = %d", en);
      $display("Done = %d", done);

      $display(" ");
    end

    // WISHBONE
    wishbone_ctl #(
        .OPCODE_ADDR(OPCODE_ADDR)
    ) wb_inst (
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .wishbone_output(wishbone_output),
        .config_en(config_en),
        .wishbone_data(wishbone_data),
        .wishbone_addr(wishbone_addr),
        .wb_read_req(wb_read_req),
        .wb_write_req(wb_write_req),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o)        
    );

    //Controller
    assign opcode = wishbone_data[1:0];
    assign op1_base_addr = wishbone_data[(2+ADDR_WIDTH)-1:2];
    assign op2_base_addr = wishbone_data[(2+(2*ADDR_WIDTH))-1:(2+ADDR_WIDTH)];
    assign out_base_addr = wishbone_data[(2+(3*ADDR_WIDTH))-1:(2+(2*ADDR_WIDTH))];

    controller #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .BIG_N(BIG_N),
        .ADDR_WIDTH(ADDR_WIDTH)
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

    //SRAM
    assign in_wen = wb_write_req & !config_en;
    assign in_wadr = wishbone_addr[ADDR_WIDTH:0];
    assign in_wdata = wishbone_data;

    assign out_wen = en;
    assign out_wadr = out_addr;
    assign out_wdata = (opcode_out == `OPCODE_ENCRYPT) ? ciphertext_result : ((opcode_out == `OPCODE_DECRYPT) ? decrypt_result : ((opcode_out == `OPCODE_ADD) ? add_result : mult_result));

    assign op1_ren = en;
    assign op1_radr = op1_addr;

    assign op2_ren = en;
    assign op2_radr = op2_addr;

    assign out_ren = wb_read_req;
    assign out_radr = wishbone_addr[ADDR_WIDTH:0];

    sram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DEPTH(DEPTH)
    ) sram_inst (
        .clk(clk),
        .in_wen(in_wen),
        .in_wadr(in_wadr),
        .in_wdata(in_wdata),
        .out_wen(out_wen),
        .out_wadr(out_wadr),
        .out_wdata(out_wdata),
        .op1_ren(op1_ren),
        .op1_radr(op1_radr),
        .op1_rdata(op1_rdata),
        .op2_ren(op2_ren),
        .op2_radr(op2_radr),
        .op2_rdata(op2_rdata),
        .out_ren(out_ren),
        .out_radr(out_radr),
        .out_rdata(out_rdata)
    );

    assign encrypt_row = row;

    assign plaintext_and_noise = op1_rdata;
    assign publickey_entry = op2_rdata;
    assign noise_select = 42;
    
    // ENCRYPT
    encrypt #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .DIM_WIDTH(DIM_WIDTH),
        .BIG_N(BIG_N)
    ) encrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .plaintext_and_noise(plaintext_and_noise),
        .publickey_entry(publickey_entry),
        .row(encrypt_row),
        .ciphertext(ciphertext_result)
    );

    assign decrypt_row = row;

    assign ct_entry = op1_rdata;
    assign secretkey_entry = op2_rdata;
    
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
        .secretkey_entry(secretkey_entry),
        .ciphertext_entry(ct_entry),
        .row(decrypt_row),
        .result(decrypt_result)
    );

    assign ciphertext1 = op1_rdata;
    assign ciphertext2 = op2_rdata;

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
        
    assign mult_row = row;
    assign mult_en = en & (opcode_out == `OPCODE_MULT);
    assign ciphertext_select = op_select;

    assign ciphertext_entry = op1_rdata;     

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

endmodule
//`default_nettype wire
