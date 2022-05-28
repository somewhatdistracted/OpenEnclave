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

  wire wbs_ack_o;
  wire [31:0] wbs_dat_o;

  always #(10) clk =~clk;

  top #(
    .PLAINTEXT_MODULUS(`PLAINTEXT_MODULUS),
    .PLAINTEXT_WIDTH(`PLAINTEXT_WIDTH),
    .CIPHERTEXT_MODULUS(`CIPHERTEXT_MODULUS),
    .CIPHERTEXT_WIDTH(`CIPHERTEXT_WIDTH),
    .DIMENSION(`DIMENSION),
    .BIG_N(`BIG_N),
    .OPCODE_ADDR(`OPCODE_ADDR),
    .OUTPUT_ADDR(`OUTPUT_ADDR),
    .DATA_WIDTH(`DATA_WIDTH),
    .ADDR_WIDTH(`ADDR_WIDTH),
    .DEPTH(`DEPTH),
    .DIM_WIDTH(`DIM_WIDTH)
  ) top_inst (
    .clk(clk),
    .rst_n(rst_n),
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
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

    #20

    #20

    $finish;

  end

endmodule  
