`define PLAINTEXT_MODULUS  64
`define PLAINTEXT_WIDTH    16
`define CIPHERTEXT_MODULUS 1024
`define CIPHERTEXT_WIDTH   32
`define DIMENSION          2
`define BIG_N              3
`define OPCODE_ADDR        32'h30000000
`define OUTPUT_ADDR        32'h10000000
`define DATA_WIDTH         128
`define ADDR_WIDTH         9
`define DEPTH              256
`define DIM_WIDTH          8

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

  reg [3:0] tests_successful;

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
    tests_successful = 4'b1111;
    // initialize and reset
    la_data_in = 0;
    la_oenb = 0;
    la_oenb[1] = 1;

    wb_clk_i = 0;
    wb_rst_i = 0;
    wbs_stb_i = 0;
    wbs_we_i = 0;

    wbs_sel_i = 0;
    wbs_dat_i = 0;
    wbs_adr_i = 0;

    #20
    // clear reset
    la_oenb[1] = 0;

    // ----- LOAD TWO CIPHERTEXTS (3-VECTORS) PLUS SOME REDUNDANT VALUES -----
    #50
    // Load in [10 15 20] and [20 25 30]
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_sel_i = 4'b1111;
    wb_rst_i = 0;
    wbs_we_i = 1;

    wbs_adr_i = 0;
    wbs_dat_i = 32'd10;

    #60
    wbs_adr_i = 100;
    wbs_dat_i = 32'd20;

    #40 
    wbs_adr_i = 1;
    wbs_dat_i = 32'd11;

    #40
    wbs_adr_i = 101;
    wbs_dat_i = 32'd21;

    #40
    wbs_adr_i = 2;
    wbs_dat_i = 32'd12;

    #40
    wbs_adr_i = 102;
    wbs_dat_i = 32'd22;

    #40
    wbs_adr_i = 3;
    wbs_dat_i = 32'd13;

    #40
    wbs_adr_i = 103;
    wbs_dat_i = 32'd23;

    #40
    wbs_adr_i = 4;
    wbs_dat_i = 32'd14;

    #40
    wbs_adr_i = 104;
    wbs_dat_i = 32'd24;

    #40
    wbs_adr_i = 5;
    wbs_dat_i = 32'd15;

    #40
    wbs_adr_i = 105;
    wbs_dat_i = 32'd25;

    // ----- TEST 1: ADD -----
    $display("\n\n\n ----- TEST 1 ----- \n\n\n");
    // Send Instruction
    #40
    wbs_adr_i = `OPCODE_ADDR;

    wbs_dat_i = 0;
    wbs_dat_i[1:0] = 2'b10;
    wbs_dat_i[(2+`ADDR_WIDTH)-1:2] = 0;
    wbs_dat_i[(2+(2*`ADDR_WIDTH))-1:(2+`ADDR_WIDTH)] = 100;    
    wbs_dat_i[(2+(3*`ADDR_WIDTH))-1:(2+(2*`ADDR_WIDTH))] = 50;
    wbs_dat_i[31] = 1'b1;

    #100
    wbs_we_i = 0;
    wbs_stb_i = 0;
    wbs_cyc_i = 0;

    // Wait for calculation to finish
    #200
    /*
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
    */

    #20
    // Read out
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 50;  
 
    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 30); if (wbs_dat_o != 30) tests_successful[0] = 0;    

    #20
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 51;

    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 32); if (wbs_dat_o != 32) tests_successful[0] = 0;  

    #20
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 52;

    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 34); if (wbs_dat_o != 34) tests_successful[0] = 0;

    // ----- TEST 2: DECRYPT -----
    $display("\n\n\n ----- TEST 2 ----- \n\n\n");
    // Send Instruction
    #40
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_sel_i = 4'b1111;
    wb_rst_i = 0;
    wbs_we_i = 1;

    wbs_adr_i = `OPCODE_ADDR;

    wbs_dat_i = 0;
    wbs_dat_i[1:0] = 2'b01;
    wbs_dat_i[(2+`ADDR_WIDTH)-1:2] = 0;
    wbs_dat_i[(2+(2*`ADDR_WIDTH))-1:(2+`ADDR_WIDTH)] = 100;    
    wbs_dat_i[(2+(3*`ADDR_WIDTH))-1:(2+(2*`ADDR_WIDTH))] = 30;
    wbs_dat_i[31] = 1'b1;

    #100
    wbs_we_i = 0;
    wbs_stb_i = 0;
    wbs_cyc_i = 0;

    // Wait for calculation to finish
    #200

    #20
    // Read out
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 30;  
 
    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 695); if (wbs_dat_o != 695) tests_successful[1] = 0;   
    

    // ----- TEST 3: MULTIPLY -----
    $display("\n\n\n ----- TEST 3 ----- \n\n\n");
    // Send Instruction
    #40
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_sel_i = 4'b1111;
    wb_rst_i = 0;
    wbs_we_i = 1;

    wbs_adr_i = `OPCODE_ADDR;

    wbs_dat_i = 0;
    wbs_dat_i[1:0] = 2'b11;
    wbs_dat_i[(2+`ADDR_WIDTH)-1:2] = 0;
    wbs_dat_i[(2+(2*`ADDR_WIDTH))-1:(2+`ADDR_WIDTH)] = 100;    
    wbs_dat_i[(2+(3*`ADDR_WIDTH))-1:(2+(2*`ADDR_WIDTH))] = 40;
    wbs_dat_i[31] = 1'b1;

    #100
    wbs_we_i = 0;
    wbs_stb_i = 0;
    wbs_cyc_i = 0;

    // Wait for calculation to finish
    #200

    #20
    // Read out
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 40;  
 
    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 200); if (wbs_dat_o != 200) tests_successful[2] = 0;   

    #20
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 41;  
 
    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 430); if (wbs_dat_o != 430) tests_successful[2] = 0;   

    #20
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 42;  
 
    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 691); if (wbs_dat_o != 691) tests_successful[2] = 0;   

    #20
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 43;  
 
    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 494); if (wbs_dat_o != 494) tests_successful[2] = 0;   

    #20
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 44;  
 
    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 264); if (wbs_dat_o != 264) tests_successful[2] = 0;   


    // ----- TEST 4: ENCRYPT -----
    $display("\n\n\n ----- TEST 4 ----- \n\n\n");
    // Send Instruction
    #40
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_sel_i = 4'b1111;
    wb_rst_i = 0;
    wbs_we_i = 1;

    wbs_adr_i = `OPCODE_ADDR;

    wbs_dat_i = 0;
    wbs_dat_i[1:0] = 2'b00;
    wbs_dat_i[(2+`ADDR_WIDTH)-1:2] = 0;
    wbs_dat_i[(2+(2*`ADDR_WIDTH))-1:(2+`ADDR_WIDTH)] = 100;    
    wbs_dat_i[(2+(3*`ADDR_WIDTH))-1:(2+(2*`ADDR_WIDTH))] = 70;
    wbs_dat_i[31] = 1'b1;

    #100
    wbs_we_i = 0;
    wbs_stb_i = 0;
    wbs_cyc_i = 0;

    // Wait for calculation to finish
    #200

    #20
    // Read out
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 70;
 
    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 62); if (wbs_dat_o != 62) tests_successful[3] = 0;    

    #20
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 71;

    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 70); if (wbs_dat_o != 70) tests_successful[3] = 0;  

    #20
    wbs_stb_i = 1;
    wbs_cyc_i = 1;
    wbs_adr_i = 72;

    #40
    wbs_stb_i = 0;
    wbs_cyc_i = 0;
    $display("Wishbone Out = %d", wbs_dat_o);
    assert(wbs_dat_o == 78); if (wbs_dat_o != 78) tests_successful[3] = 0;

    #20

    // TEST LOGIC
    $display("\n\n\n ----- TEST RECAP ----- \n\n\n");
    if (tests_successful[0]) begin
        $display("Add Test Passed");
    end
    if (tests_successful[1]) begin
        $display("Decrypt Test Passed");
    end
    if (tests_successful[2]) begin
        $display("Multiply Test Passed");
    end
    if (tests_successful[3]) begin
        $display("Encrypt Test Passed");
    end

    $display("\n\n\nTest done!\n\n\n");
    $finish;
  
  end

  initial begin    
    $dumpfile("dump.vcd");
    $dumpvars(0, top_tb);
  end

endmodule  
