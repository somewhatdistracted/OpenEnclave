`define PLAINTEXT_MODULUS  64
`define PLAINTEXT_WIDTH    6
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH   10
`define DIMENSION          2
`define BIG_N              30
`define OPCODE_ADDR        32'h30000000
`define OUTPUT_ADDR        32'h10000000
`define DATA_WIDTH         128
`define ADDR_WIDTH         10
`define DEPTH              1024
`define DIM_WIDTH          4

//`default_nettype none
`define MPRJ_IO_PADS 38


module top_tb;

  reg [127:0] la_data_in;
  wire [127:0] la_data_out;
  reg [127:0] la_oenb;

  reg [`MPRJ_IO_PADS-1:0] io_in;
  wire [`MPRJ_IO_PADS-1:0] io_out;
  wire [`MPRJ_IO_PADS-1:0] io_oeb;

  wire [`MPRJ_IO_PADS-10:0] analog_io;
 
  reg user_clock2;

  wire [2:0] user_irq;

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

  always #(10) wb_clk_i = ~wb_clk_i;

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
    .la_data_in(la_data_in),
    .la_data_out(la_data_out),
    .la_oenb(la_oenb),
    .io_in(io_in),
    .io_out(io_out),
    .io_oeb(io_oeb),
    .analog_io(analog_io),
    .user_clock2(user_clock2),
    .user_irq(user_irq),
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

    la_data_in = 0;
    la_oenb = 0;

    wb_clk_i = 0;
    wb_rst_i = 0;
    wbs_stb_i = 0;
    wbs_we_i = 0;

    wbs_sel_i = 0;
    wbs_dat_i = 0;
    wbs_adr_i = 0;

    #30
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_sel_i = 4'b1111;
    wb_rst_i = 0;

    wbs_we_i = 1;
    
    wbs_adr_i = 0;
    wbs_dat_i = 32'd10;

    #100
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_sel_i = 4'b1111;
    wb_rst_i = 0;

    wbs_we_i = 1;

    wbs_adr_i = 100;
    wbs_dat_i = 32'd20;

    #100 
    
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_sel_i = 4'b1111;
    wb_rst_i = 0;

    wbs_we_i = 1;

    wbs_adr_i = 1;
    wbs_dat_i = 32'd15;

    #100
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_sel_i = 4'b1111;
    wb_rst_i = 0;

    wbs_we_i = 1;

    wbs_adr_i = 101;
    wbs_dat_i = 32'd25;

    #100

    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_sel_i = 4'b1111;
    wb_rst_i = 0;

    wbs_we_i = 1;

    wbs_adr_i = 2;
    wbs_dat_i = 32'd20;

    #100
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_sel_i = 4'b1111;
    wb_rst_i = 0;

    wbs_we_i = 1;

    wbs_adr_i = 102;
    wbs_dat_i = 32'd30;

    #100

    wbs_we_i = 1;
    wbs_stb_i = 1;
    wbs_cyc_i = 1;

    wbs_adr_i = `OPCODE_ADDR;

    wbs_dat_i = 0;
    wbs_dat_i[1:0] = 2'b10;
    wbs_dat_i[(2+`ADDR_WIDTH)-1:2] = 0;
    wbs_dat_i[(2+(2*`ADDR_WIDTH))-1:(2+`ADDR_WIDTH)] = 100;    
    wbs_dat_i[(2+(3*`ADDR_WIDTH))-1:(2+(2*`ADDR_WIDTH))] = 50;

    #100

    wbs_we_i = 0;
    wbs_stb_i = 0;
    wbs_cyc_i = 0;

    $display("Result = %d", wbs_dat_o);
    #20
    $display("Result = %d", wbs_dat_o);
    #20
    $display("Result = %d", wbs_dat_o);
    #20
    $display("Result = %d", wbs_dat_o);
    #20
    $display("Result = %d", wbs_dat_o);
    #20
    $display("Result = %d", wbs_dat_o);
    #20

    #20
    //read out
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 50;  
 
    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 30);    

    #20
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 51;

    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 40);    

    #20
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 52;

    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 50);

    #20


    $finish;
  
  end

  initial begin
    $vcdplusfile("dump.vcd");
    $vcdplusmemon();
    $vcdpluson(0, top_tb);
    #2000;
    $finish(2);
  end

endmodule  
