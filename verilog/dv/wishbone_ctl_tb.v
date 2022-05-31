`define PLAINTEXT_MODULUS  64
`define PLAINTEXT_WIDTH    6
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH   10
`define DIMENSION          10
`define BIG_N              30
`define OPCODE_ADDR        32'h30000000
`define OUTPUT_ADDR        32'h10000000
`define DATA_WIDTH         128
`define ADDR_WIDTH         10
`define DEPTH              1024
`define DIM_WIDTH          4

module top_tb;

  reg clk;
  reg rst_n;

  reg wb_clk_i;
  reg wb_rst_i;
  reg wbs_stb_i;
  reg wbs_cyc_i;
  reg wbs_we_i;

  reg [3:0] wbs_sel_i;
  reg [31:0] wbs_dat_i;
  reg [31:0] wbs_adr_i;

  reg [31:0] wishbone_output;
  wire [31:0] wishbone_data;
  wire wb_ready_i;
  reg wb_ready_o;

  wire wbs_ack_o;
  wire [31:0] wbs_dat_o;

  always #(10) clk =~clk;

    wishbone_ctl #(
        .OPCODE_ADDR(`OPCODE_ADDR)
    ) wb_inst (
        .wb_clk_i(clk),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(wbs_stb_i),
        .wbs_cyc_i(wbs_cyc_i),
        .wbs_we_i(wbs_we_i),
        .wbs_sel_i(wbs_sel_i),
        .wbs_dat_i(wbs_dat_i),
        .wbs_adr_i(wbs_adr_i),
        .output_ready(wb_ready_o),
        .wishbone_output(wishbone_output),
        .config_en(config_en),
        .input_ready(wb_ready_i),
        .wishbone_data(wishbone_data),
        .wbs_ack_o(wbs_ack_o),
        .wbs_dat_o(wbs_dat_o)        
    );

  initial begin

    clk = 0;
    rst_n = 0;

    wb_clk_i = 0;
    wb_rst_i = 0;
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    wbs_we_i = 0;

    wbs_sel_i = 0;
    wbs_dat_i = 0;
    wbs_adr_i = 0;

    wishbone_output = 0;
    wb_ready_o = 0;

    #20
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_sel_i = 4'b1111;
    wb_rst_i = 0;

    wbs_we_i = 1;

    wbs_dat_i = 32'd10;
    wishbone_output = 32'd10;
    wb_ready_o = 1;
    #20

    $display("Input = %d", wbs_dat_o);
    $display("Output = %d", wishbone_data);
    $finish;

  end

endmodule  
