// CONSTANTS and DEFINITIONS for OpenEnclave
`define OPCODE_ENCRYPT  2'b00
`define OPCODE_DECRYPT  2'b01
`define OPCODE_ADD      2'b10
`define OPCODE_MULT     2'b11

//`default_nettype none
`define MPRJ_IO_PADS 38

module user_proj_example
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 16,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 32,
    parameter DIMENSION = 2,
    parameter BIG_N = 3,
    parameter OPCODE_ADDR = 32'h30000000,
    parameter OUTPUT_ADDR = 32'h00000001,
    parameter DATA_WIDTH = 128,
    parameter ADDR_WIDTH = 9,
    parameter DEPTH = 256,
    parameter DIM_WIDTH = 8,
    parameter PARALLEL = 1,
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

    // User maskable interrupt signals
    output wire [2:0] irq,

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

    // CHIP-LEVEL STUFF
    wire clk;
    wire rst_n;

    assign clk = wb_clk_i;
    assign rst_n = (~la_oenb[1]) ? la_data_in[1] : 0;

    // WISHBONE DECLARATIONS
    wire [31:0] wishbone_output;
    wire [31:0] wishbone_data;
    wire [31:0] wishbone_addr;
    wire wb_read_req;
    wire wb_write_req;
    wire config_en;
    // CONTROLLER DECLARATIONS
    wire valid_opcode;
    wire [1:0] opcode;
    wire [ADDR_WIDTH-1:0] op1_base_addr;
    wire [ADDR_WIDTH-1:0] op2_base_addr;
    wire [ADDR_WIDTH-1:0] out_base_addr;
    wire [1:0] opcode_out;
    wire [ADDR_WIDTH-1:0] op1_addr;
    wire [ADDR_WIDTH-1:0] op2_addr;
    wire [ADDR_WIDTH-1:0] out_addr;
    wire op_select;
    reg op_select_delayed;
    wire en;
    wire done;
    wire [DIM_WIDTH:0] row;
    // SRAM DECLARATIONS
    wire in_wen;
    reg delayed_in_wen;
    wire [ADDR_WIDTH - 1 : 0] in_wadr;
    wire [DATA_WIDTH - 1 : 0] in_wdata;
    reg out_wen;
    reg [ADDR_WIDTH - 1 : 0] out_wadr_delay_stage;
    reg [ADDR_WIDTH - 1 : 0] out_wadr;
    wire [DATA_WIDTH - 1 : 0] out_wdata;
    wire op1_ren;
    wire [ADDR_WIDTH - 1 : 0] op1_radr;
    wire [DATA_WIDTH - 1 : 0] op1_rdata;
    wire op2_ren;
    wire [ADDR_WIDTH - 1 : 0] op2_radr;
    wire [DATA_WIDTH - 1 : 0] op2_rdata;
    wire out_ren;
    reg delayed_out_ren;
    wire [ADDR_WIDTH - 1 : 0] out_radr;
    wire [DATA_WIDTH - 1 : 0] out_rdata;
    // FUNCTIONAL MODULE DECLARATIONS
    wire [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] op1_structured;
    wire [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] op2_structured;
    reg [DIM_WIDTH:0] delayed_row;
    // ENCRYPT DECLARATIONS
    wire [CIPHERTEXT_WIDTH-1:0] encrypt_out;
    reg encrypt_en;
    // DECRYPT DECLARATIONS
    wire [PLAINTEXT_WIDTH-1:0] decrypt_out;
    wire decrypt_en;
    // HOMOMORPHIC ADD DECLARATIONS
    wire [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] add_out;
    wire [(PARALLEL*CIPHERTEXT_WIDTH)-1:0] add_out_flattened;
    wire add_en;
    // HOMOMORPHIC MULTIPLY DECLARACTIONS
    wire [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] muxed_ops;
    wire [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] mult_out;
    wire [(PARALLEL*CIPHERTEXT_WIDTH)-1:0] mult_out_flattened;
    wire mult_en;

    // ----- WISHBONE -----
    assign wishbone_output = out_rdata;

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

    // ----- CONTROLLER -----
    // PARSE INSTRUCTION
    assign opcode = wishbone_data[1:0];
    assign op1_base_addr = wishbone_data[(2+ADDR_WIDTH)-1:2];
    assign op2_base_addr = wishbone_data[(2+(2*ADDR_WIDTH))-1:(2+ADDR_WIDTH)];
    assign out_base_addr = wishbone_data[(2+(3*ADDR_WIDTH))-1:(2+(2*ADDR_WIDTH))];
    assign valid_opcode = wishbone_data[31];

    controller #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .DIM_WIDTH(DIM_WIDTH),
        .BIG_N(BIG_N),
        .ADDR_WIDTH(ADDR_WIDTH),
        .PARALLEL(PARALLEL)
    ) controller_inst (
        .clk(clk),
        .rst_n(rst_n),
        .opcode(opcode),
        .config_en(config_en && valid_opcode),
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

    // ----- SRAM -----
    // CONFIGURATION
    
    always @(posedge clk) begin
	   delayed_in_wen = wb_write_req & !config_en;
           delayed_out_ren <= wb_read_req;
    end

    assign in_wen = delayed_in_wen;
    assign in_wadr = wishbone_addr[ADDR_WIDTH:0];
    assign in_wdata = wishbone_data;

    //assign out_wen = en;
    //assign out_wadr = out_addr;
    assign out_wdata = (opcode_out == `OPCODE_ENCRYPT) ? encrypt_out : ((opcode_out == `OPCODE_DECRYPT) ? decrypt_out : ((opcode_out == `OPCODE_ADD) ? add_out_flattened : mult_out_flattened));

    assign op1_ren = en;
    assign op1_radr = op1_addr;

    assign op2_ren = en;
    assign op2_radr = op2_addr;

    assign out_ren = wb_read_req;
    assign out_radr = wishbone_addr[ADDR_WIDTH:0];

    // SRAM
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

    // ----- ALL FUNCTIONAL MODULES -----
    // RESTRUCTURE FOR PARALLEL
    generate
        genvar ip;
        for (ip = 0; ip<PARALLEL; ip=ip+1) begin
            assign op1_structured[ip] = op1_rdata[((ip+1)*CIPHERTEXT_WIDTH)-1:ip*CIPHERTEXT_WIDTH];
            assign op2_structured[ip] = op2_rdata[((ip+1)*CIPHERTEXT_WIDTH)-1:ip*CIPHERTEXT_WIDTH];
        end
    endgenerate

    always @(posedge clk) begin
        delayed_row <= row;
        out_wen <= en; // possible danger zone stupid thing
        out_wadr_delay_stage <= out_addr;
        out_wadr <= out_wadr_delay_stage;
        op_select_delayed <= op_select;
        encrypt_en <= (opcode_out == `OPCODE_ENCRYPT) && en;
    end

    // ----- ENCRYPT -----

    // ENCRYPT
    encrypt #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .DIM_WIDTH(DIM_WIDTH),
        .BIG_N(BIG_N),
        .PARALLEL(PARALLEL)
    ) encrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(encrypt_en),
        .done(done),
        .op1(op1_structured),
        .op2(op2_structured),
        .row(delayed_row),
        .ciphertext(encrypt_out)
    );

    // ----- DECRYPT -----
    assign decrypt_en = (opcode_out == `OPCODE_DECRYPT) && en;
    
    // DECRYPT
    decrypt #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .DIM_WIDTH(DIM_WIDTH),
        .BIG_N(BIG_N),
        .PARALLEL(PARALLEL)
    ) decrypt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .secretkey_entry(op1_structured),
        .ciphertext_entry(op2_structured),
        .row(delayed_row),
        .result(decrypt_out)
    );

    // ----- HOMOMORPHIC ADD -----
    assign add_en = (opcode_out == `OPCODE_ADD) && en;

    generate
        genvar iaf;
        for (iaf = 0; iaf<PARALLEL; iaf=iaf+1) begin
            assign add_out_flattened[((iaf+1)*CIPHERTEXT_WIDTH)-1:(iaf*CIPHERTEXT_WIDTH)] = add_out[iaf];
        end
    endgenerate
    

    // ADD
    homomorphic_add #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .BIG_N(BIG_N),
        .PARALLEL(PARALLEL)
    ) homomorphic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .ciphertext1(op1_structured),
        .ciphertext2(op2_structured),
        .result(add_out)
    );
        
    // ----- HOMOMORPHIC MULTIPLY -----
    assign mult_en = (opcode_out == `OPCODE_MULT) && en;

    generate
        genvar imf;
        for (imf = 0; imf<PARALLEL; imf=imf+1) begin
            assign mult_out_flattened[((imf+1)*CIPHERTEXT_WIDTH)-1:(imf*CIPHERTEXT_WIDTH)] = mult_out[imf];
        end
    endgenerate

    assign muxed_ops = (op_select_delayed == 0) ? op1_structured : op2_structured;

    // MULT
    homomorphic_multiply #(
        .PLAINTEXT_MODULUS(PLAINTEXT_MODULUS),
        .PLAINTEXT_WIDTH(PLAINTEXT_WIDTH),
        .CIPHERTEXT_MODULUS(CIPHERTEXT_MODULUS),
        .CIPHERTEXT_WIDTH(CIPHERTEXT_WIDTH),
        .DIMENSION(DIMENSION),
        .DIM_WIDTH(DIM_WIDTH),
        .BIG_N(BIG_N),
        .PARALLEL(PARALLEL)
    ) homomorphic_multiply_inst (
        .clk(clk),
        .rst_n(rst_n),
        .op1(muxed_ops),
        .row(delayed_row),
        .ciphertext_select(op_select_delayed),
        .en(en),
        .result_partial(mult_out)
    );

    /*
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
      $display("Func output = %d, Decrypt output: %d", out_wdata, decrypt_out);
      $display("SRAM OW ADDR = %d", out_wadr);
      $display("SRAM OR Data = %d", out_rdata);
      $display("SRAM O Adr = %d", out_radr);
      $display("Op1 Data = %d", op1_rdata);
      $display("Op2 Data = %d", op2_rdata);
      $display("Op1 Adr = %d", op1_radr);
      $display("Op2 Adr = %d", op2_radr);
      //$display("Op1 Base Adr = %d", op1_base_addr);
      //$display("Op2 Base Adr = %d", op2_base_addr);
      $display("Row = %d", row);
      //$display("Delayed Row = %d", delayed_row);
      $display("Reset = %d", rst_n);
      $display("En = %d", en);
      $display("Done = %d", done);

      $display(" ");
    end 
    */

endmodule
//`default_nettype wire
module sram
#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10,
    parameter DEPTH = 1024
)
(
    input clk,

    input in_wen,
    input [ADDR_WIDTH - 1 : 0] in_wadr,
    input [DATA_WIDTH - 1 : 0] in_wdata,

    input out_wen,
    input [ADDR_WIDTH - 1 : 0] out_wadr,
    input [DATA_WIDTH - 1 : 0] out_wdata,

    input op1_ren,
    input [ADDR_WIDTH - 1 : 0] op1_radr,
    output [DATA_WIDTH - 1 : 0] op1_rdata,

    input op2_ren,
    input [ADDR_WIDTH - 1 : 0] op2_radr,
    output [DATA_WIDTH - 1 : 0] op2_rdata,
    
    input out_ren,
    input [ADDR_WIDTH - 1 : 0] out_radr,
    output [DATA_WIDTH - 1 : 0] out_rdata
);

    genvar x, y;
    generate
        wire [DATA_WIDTH - 1 : 0] op1_rdata_w [DEPTH/256 - 1 : 0]; 
        reg  [ADDR_WIDTH - 1 : 0] op1_radr_r;
        wire [DATA_WIDTH - 1 : 0] op2_rdata_w [DEPTH/256 - 1 : 0]; 
        reg  [ADDR_WIDTH - 1 : 0] op2_radr_r;
        wire [DATA_WIDTH - 1 : 0] out_rdata_w [DEPTH/256 - 1 : 0]; 
        reg  [ADDR_WIDTH - 1 : 0] out_radr_r;

        always @ (posedge clk) begin
            op1_radr_r <= op1_radr;
            op2_radr_r <= op2_radr;
            out_radr_r <= out_radr;
        end 

        // op1
        for (x = 0; x < DATA_WIDTH/32; x = x + 1) begin: width_macro1
            for (y = 0; y < DEPTH/256; y = y + 1) begin: depth_macro1
                // note: Excerpted from EE272 Sram Wrapper:
                // note: The default behavioral model generated by OpenRAM has an arbitrary
                //       delay of 3ns. Since the SRAM data is only valid for half a cycle
                //       any delay < half a cycle will not affect the simulation result.
                //       Since we will try to push for a clock period of 5ns, we manually
                //       changed the delay number to 1ns (< 2.5ns) to prevent functional error.
                sky130_sram_1kbyte_1rw1r_32x256_8 #(
                    .VERBOSE(0)
                ) sram1 (
                    .clk0(clk),
                    .csb0(~(in_wen && (in_wadr[ADDR_WIDTH - 1 : 8] == y))),
                    .web0(~(in_wen && (in_wadr[ADDR_WIDTH - 1 : 8] == y))), // And wadr in range
                    .wmask0(4'hF),
                    .addr0(in_wadr[7:0]),
                    .din0(in_wdata[32*(x+1)-1 : 32*x]),
                    .dout0(),
                    .clk1(clk),
                    .csb1(~(op1_ren && (op1_radr[ADDR_WIDTH - 1 : 8] == y))), // And radr in range
                    .addr1(op1_radr[7:0]),
                    .dout1(op1_rdata_w[y][32*(x+1)-1 : 32*x])
                );
            end
        end

        // op2
        for (x = 0; x < DATA_WIDTH/32; x = x + 1) begin: width_macro2
            for (y = 0; y < DEPTH/256; y = y + 1) begin: depth_macro2
                // note: Excerpted from EE272 Sram Wrapper:
                // note: The default behavioral model generated by OpenRAM has an arbitrary
                //       delay of 3ns. Since the SRAM data is only valid for half a cycle
                //       any delay < half a cycle will not affect the simulation result.
                //       Since we will try to push for a clock period of 5ns, we manually
                //       changed the delay number to 1ns (< 2.5ns) to prevent functional error.
                sky130_sram_1kbyte_1rw1r_32x256_8 #(
                    .VERBOSE(0)
                ) sram2 (
                    .clk0(clk),
                    .csb0(~(in_wen && (in_wadr[ADDR_WIDTH - 1 : 8] == y))),
                    .web0(~(in_wen && (in_wadr[ADDR_WIDTH - 1 : 8] == y))), // And wadr in range
                    .wmask0(4'hF),
                    .addr0(in_wadr[7:0]),
                    .din0(in_wdata[32*(x+1)-1 : 32*x]),
                    .dout0(),
                    .clk1(clk),
                    .csb1(~(op2_ren && (op2_radr[ADDR_WIDTH - 1 : 8] == y))), // And radr in range
                    .addr1(op2_radr[7:0]),
                    .dout1(op2_rdata_w[y][32*(x+1)-1 : 32*x])
                );
            end
        end

        // out
        for (x = 0; x < DATA_WIDTH/32; x = x + 1) begin: width_macro3
            for (y = 0; y < DEPTH/256; y = y + 1) begin: depth_macro3
                // note: Excerpted from EE272 Sram Wrapper:
                // note: The default behavioral model generated by OpenRAM has an arbitrary
                //       delay of 3ns. Since the SRAM data is only valid for half a cycle
                //       any delay < half a cycle will not affect the simulation result.
                //       Since we will try to push for a clock period of 5ns, we manually
                //       changed the delay number to 1ns (< 2.5ns) to prevent functional error.
                sky130_sram_1kbyte_1rw1r_32x256_8 #(
                    .VERBOSE(0)
                ) sram3 (
                    .clk0(clk),
                    .csb0(~(out_wen && (out_wadr[ADDR_WIDTH - 1 : 8] == y))),
                    .web0(~(out_wen && (out_wadr[ADDR_WIDTH - 1 : 8] == y))), // And wadr in range
                    .wmask0(4'hF),
                    .addr0(out_wadr[7:0]),
                    .din0(out_wdata[32*(x+1)-1 : 32*x]),
                    .dout0(),
                    .clk1(clk),
                    .csb1(~(out_ren && (out_radr[ADDR_WIDTH - 1 : 8] == y))), // And radr in range
                    .addr1(out_radr[7:0]),
                    .dout1(out_rdata_w[y][32*(x+1)-1 : 32*x])
                );
            end
        end

    endgenerate

    assign op1_rdata = op1_rdata_w[op1_radr_r[ADDR_WIDTH - 1 : 8]];
    assign op2_rdata = op2_rdata_w[op2_radr_r[ADDR_WIDTH - 1 : 8]];
    assign out_rdata = out_rdata_w[out_radr_r[ADDR_WIDTH - 1 : 8]];

endmodule
module wishbone_ctl #
(
    parameter OPCODE_ADDR = 32'h30000000
)
(
    // wishbone input
    input        wb_clk_i,
    input        wb_rst_i,
    input        wbs_stb_i,
    input        wbs_cyc_i,
    input        wbs_we_i,
    input [3:0]  wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
  
    // control input
    input [31:0] wishbone_output,
 
    // controller config enable
    output        config_en,    

    //control output
    output [31:0] wishbone_data,
    output [31:0] wishbone_addr,
    output        wb_read_req,
    output        wb_write_req,

    // wishbone output
    output        wbs_ack_o,
    output [31:0] wbs_dat_o
);
  
  reg [31:0] wbs_reg_i;
  reg [31:0] wbs_reg_o;

  reg delayed_read_req;
  reg dd_read_req;

  reg [31:0] wbs_reg_addr;

// ==============================================================================
// Request, Acknowledgement
// ==============================================================================
    wire wbs_req = wbs_stb_i & wbs_cyc_i;
    reg ack_o;

    // ack
    always@(posedge wb_clk_i) begin
        if (wb_rst_i) ack_o <= 1'b0;
        else          ack_o <= wbs_req; // assume we can always process request immediately;
    end

// ==============================================================================
// Latching
// ==============================================================================
    wire wbs_req_write = (~ack_o) & wbs_req & (wbs_we_i );
    wire wbs_req_read  = (~ack_o) & wbs_req & (~wbs_we_i);
    // Input Data to Sram
    always@(posedge wb_clk_i) begin
        wbs_reg_addr = wbs_adr_i;
        if (wb_rst_i)
            wbs_reg_i <= 32'd0;
        else if (wbs_req_write)
	    wbs_reg_i <= wbs_dat_i;
    end
    // Sram to Output Data
    always@(posedge wb_clk_i) begin
	dd_read_req = delayed_read_req;
	delayed_read_req = wbs_req_read;
        if (wb_rst_i)
            wbs_reg_o <= 32'd0;
        else if (dd_read_req)
            wbs_reg_o <= wishbone_output;
    end
// ==============================================================================
// Outputs
// ==============================================================================
assign config_en               = wbs_req & (wbs_adr_i == OPCODE_ADDR);

assign wbs_ack_o               = ack_o;
assign wbs_dat_o               = wbs_reg_o;

assign wishbone_data           = wbs_dat_i;
assign wishbone_addr           = (wbs_adr_i - 32'h30000004) >> 2;

assign wb_read_req             = wbs_req_read;
assign wb_write_req            = wbs_req_write;

endmodule
module controller
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 10,
    parameter DIMENSION = 10,
    parameter BIG_N = 30,
    parameter DIM_WIDTH = 4,
    parameter ADDR_WIDTH = 10,
    parameter PARALLEL = 1
)
(
    input clk,
    input rst_n,

    input [1:0] opcode,
    input config_en,
    input [ADDR_WIDTH-1:0] op1_base_addr,
    input [ADDR_WIDTH-1:0] op2_base_addr,
    input [ADDR_WIDTH-1:0] out_base_addr,
    

    output [1:0] opcode_out,
    output [ADDR_WIDTH-1:0] op1_addr,
    output [ADDR_WIDTH-1:0] op2_addr,
    output [ADDR_WIDTH-1:0] out_addr,
    output op_select,
    output en,
    output done,
    output [DIM_WIDTH:0] row
);
    reg [ADDR_WIDTH-1:0] op1_base_addr_stored;
    reg [ADDR_WIDTH-1:0] op2_base_addr_stored;
    reg [ADDR_WIDTH-1:0] out_base_addr_stored;
    reg [DIM_WIDTH-1:0] col; // counter for encrypt


    reg [1:0] opcode_out_reg;
    reg [ADDR_WIDTH-1:0] op1_addr_reg;
    reg [ADDR_WIDTH-1:0] op2_addr_reg;
    reg [ADDR_WIDTH-1:0] out_addr_reg;
    reg op_select_reg;
    reg en_reg;
    reg done_reg;
    reg [DIM_WIDTH:0] row_reg;

    always @(posedge clk) begin

        // lowest priority: evolve state
        if (en_reg) begin
            case (opcode_out_reg)
                `OPCODE_ENCRYPT: begin
                    // if just reset col and isn't first row
                    if (row_reg > DIMENSION && col > 0) begin
                        en_reg <= 0;
                        done_reg <= 1;
                        row_reg <= 0;
                        col <= 0;
                        out_addr_reg <= out_addr_reg + 1;
                    end else if (row_reg != 0 && col == 0) begin
                        op1_addr_reg <= op1_addr_reg + 1;
                        op2_addr_reg <= op2_addr_reg + 1;
                        out_addr_reg <= out_addr_reg + 1;
                        col <= col + 2;
                    end else if (col + 1 < BIG_N) begin
                        op1_addr_reg <= op1_addr_reg + 1;
                        op2_addr_reg <= op2_addr_reg + 1;
                        col <= col + 2;
                    end else if (col + 1 >= BIG_N) begin
                        op1_addr_reg <= op1_addr_reg + 1;
                        op2_addr_reg <= op2_addr_reg + 1;
                        row_reg <= row_reg + 1;
                        col <= 0;
                    end else begin
                        en_reg <= 0;
                        done_reg <= 1;
                    end
                end
                `OPCODE_DECRYPT: begin
                    if (op1_addr_reg <= op1_base_addr_stored + DIMENSION/PARALLEL) begin
                        op1_addr_reg <= op1_addr_reg + 1;
                        op2_addr_reg <= op2_addr_reg + 1;
                        row_reg <= row_reg + 1;
                    end else begin
                        en_reg <= 0;
                        done_reg <= 1;
                    end
                end
                `OPCODE_ADD: begin
                    if (op1_addr_reg <= op1_base_addr_stored + DIMENSION/PARALLEL) begin
                        op1_addr_reg <= op1_addr_reg + 1;
                        op2_addr_reg <= op2_addr_reg + 1;
                        out_addr_reg <= out_addr_reg + 1;
                    end else begin
                        en_reg <= 0;
                        done_reg <= 1;
                    end
                end
                `OPCODE_MULT: begin
                    // cycle through op1 addrs
                    // cycle through op2 addrs
                    // push rows through
                    if (op1_addr_reg < op1_base_addr_stored + DIMENSION/PARALLEL) begin
                        op1_addr_reg <= op1_addr_reg + 1;
                        row_reg <= row_reg + 1;
                    end else if (op_select_reg != 1 && !done_reg) begin
                        row_reg <= 0;
                        op_select_reg <= 1;
                    end else if (op2_addr_reg < op2_base_addr_stored + DIMENSION/PARALLEL) begin
                        op2_addr_reg <= op2_addr_reg + 1;
                        out_addr_reg <= out_addr_reg + 1; // this covers first half of this answer
                        row_reg <= row_reg + 1;
                        op_select_reg <= 1;
                    end else if (op2_addr_reg == op2_base_addr_stored + DIMENSION/PARALLEL) begin
                        op2_addr_reg <= op2_addr_reg + 1;
                        out_addr_reg <= out_addr_reg + 1; // this covers first half of this answer
                        row_reg <= row_reg + 1;
                        op_select_reg <= 0;
                        done_reg <= 1;
                    end else if (row_reg <= 2*DIMENSION/PARALLEL) begin
                        out_addr_reg <= out_addr_reg + 1; // this covers first half of this answer
                        row_reg <= row_reg + 1;
                    end else begin
                        en_reg <= 0;
                        done_reg <= 1;
                    end
                end
            endcase
        end

        if (!en_reg && !done_reg && !config_en) begin
            en_reg <= 1;
        end

        // second highest priority: configure
        if (config_en) begin
            opcode_out_reg <= opcode;
            op1_addr_reg <= op1_base_addr;
            op2_addr_reg <= op2_base_addr;
            out_addr_reg <= out_base_addr;
            op1_base_addr_stored <= op1_base_addr;
            op2_base_addr_stored <= op2_base_addr;
            out_base_addr_stored <= out_base_addr;
            en_reg <= 0;
	    op_select_reg <= 0;
            done_reg <= 0;
            row_reg <= 0;
            col <= 0;
        end

        // highest priority: reset
        if (!rst_n) begin
            opcode_out_reg <= 0;
            op1_addr_reg <= 0;
            op2_addr_reg <= 0;
            out_addr_reg <= 0;
            op1_base_addr_stored <= 0;
            op2_base_addr_stored <= 0;
            out_base_addr_stored <= 0;
            op_select_reg <= 0;
            en_reg <= 0;
            row_reg <= 0;
            col <= 0;
        end
    end

    assign opcode_out = opcode_out_reg;
    assign op1_addr = op1_addr_reg;
    assign op2_addr = op2_addr_reg;
    assign out_addr = out_addr_reg;
    assign op_select = op_select_reg;
    assign en = en_reg;
    assign done = done_reg;
    assign row = row_reg;

endmodule
module encrypt
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 32,
    parameter DIMENSION = 128,
    parameter DIM_WIDTH = 7,
    parameter BIG_N = 30,
    parameter PARALLEL = 2
)
(
    input clk,
    input rst_n,
    input en,
    input done,

    input [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] op1, // ops aren't named anymore since
    input [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] op2, // the channel gets reused for bandwidth
    input [DIM_WIDTH:0] row,

    output reg [CIPHERTEXT_WIDTH-1:0] ciphertext
);
    reg [DIMENSION:0][CIPHERTEXT_WIDTH-1:0] psum;
    wire [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] parallel1;
    wire [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] parallel2;
    reg [DIM_WIDTH-1:0] last_row;

    /*
    always @(posedge clk) begin
        $display("P: %d, %d, %d", psum[0], psum[1], psum[2]);
    end
    */

    // logic for parallel>1
    generate
        genvar ienc;
        assign parallel1[0] = op1[0][CIPHERTEXT_WIDTH-1] ? 0 : op1[0];
        assign parallel2[0] = op2[0][CIPHERTEXT_WIDTH-1] ? 0 : op2[0];
        for (ienc = 1; ienc < PARALLEL; ienc=ienc+1) begin
            assign parallel1[ienc] = parallel1[ienc-1] + (op1[ienc][CIPHERTEXT_WIDTH-1] ? 0 : op1[ienc]);
            assign parallel2[ienc] = parallel2[ienc-1] + (op2[ienc][CIPHERTEXT_WIDTH-1] ? 0 : op2[ienc]);
        end
    endgenerate

    // main logic
    always @(posedge clk) begin
        if (en & rst_n != 0) begin
            psum[row] <= psum[row] + parallel1[PARALLEL-1] + parallel2[PARALLEL-1];
        end else begin
            last_row <= 0;
            psum <= 0;
        end

        // set output
        if (!rst_n) begin
            ciphertext <= 0;
        end else if (row != last_row) begin
            ciphertext <= psum[last_row];
        end

        last_row <= row;
    end
endmodule
module decrypt
#(
  parameter PLAINTEXT_MODULUS = 64,
  parameter PLAINTEXT_WIDTH = 6,
  parameter CIPHERTEXT_MODULUS = 1024,
  parameter CIPHERTEXT_WIDTH = 10,
  parameter DIMENSION = 10,
  parameter DIM_WIDTH = 4,
  parameter BIG_N = 30,
  parameter PARALLEL = 1
)
(
    input clk,
    input rst_n,
    input en,

    input [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] secretkey_entry,
    input [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] ciphertext_entry,
    input [DIM_WIDTH:0] row,

    output wire [PLAINTEXT_WIDTH-1:0] result
);
    wire [PARALLEL-1:0][2*CIPHERTEXT_WIDTH:0] parallel_accum;
    reg [2*CIPHERTEXT_WIDTH:0] dot_product;

    generate
        genvar idec;
        assign parallel_accum[0] = secretkey_entry[0] * ciphertext_entry[0];
        for (idec = 1; idec < PARALLEL; idec=idec+1) begin
            assign parallel_accum[idec] = parallel_accum[idec-1] + (secretkey_entry[idec] * ciphertext_entry[idec]);
        end
    endgenerate

    always @(posedge clk) begin
        //$display("Weird Verilog behavior: x if no display here");
        //$display("D: %d * %d", secretkey_entry[0], ciphertext_entry[0]);
        if (en) begin
            if(row == 0) begin
                dot_product <= parallel_accum[PARALLEL-1];
            end else begin
                dot_product <= dot_product + parallel_accum[PARALLEL-1];
            end
        end
        if(!rst_n) begin
            dot_product <= 0;
        end
    end
		    
    assign result = dot_product[PLAINTEXT_WIDTH-1:0];
  
endmodule
module homomorphic_add
#(
  parameter PLAINTEXT_MODULUS = 64,
  parameter PLAINTEXT_WIDTH = 6,
  parameter CIPHERTEXT_MODULUS = 1024,
  parameter CIPHERTEXT_WIDTH = 10,
  parameter DIMENSION = 1,
  parameter BIG_N = 30,
  parameter PARALLEL = 1
)
(
    input clk,
    input rst_n,
    input en,
    
    input signed [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] ciphertext1,
    input signed [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] ciphertext2,
    
    output wire [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] result
);
    reg [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] ir;

    always @(posedge clk) begin
        if (en) begin
            //for (int aaa = 0; aaa < PARALLEL; aaa=aaa+1) begin
	        //ir[aaa] <= ciphertext1[aaa] + ciphertext2[aaa];
		ir[0] <= ciphertext1[0] + ciphertext2[0];
            //end
        end else begin
            ir <= 0;
        end
    end

    generate
        genvar iadd;
        for (iadd = 0; iadd < PARALLEL; iadd=iadd+1) begin
            assign result[iadd] = ir[iadd];
        end
    endgenerate
  
endmodule
module homomorphic_multiply
#(
  parameter PLAINTEXT_MODULUS = 64,
  parameter PLAINTEXT_WIDTH = 6,
  parameter DIMENSION = 1,
  parameter DIM_WIDTH = 1,
  parameter CIPHERTEXT_MODULUS = 1024,
  parameter CIPHERTEXT_WIDTH = 10,
  parameter BIG_N = 30,
  parameter PARALLEL = 1
)
(
    input clk,
    input rst_n,
    
    input [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] op1,
    input [DIM_WIDTH:0] row,
    input ciphertext_select,
    input en,
    
    output wire [PARALLEL-1:0][CIPHERTEXT_WIDTH-1:0] result_partial
);
  
    reg [DIMENSION:0][CIPHERTEXT_WIDTH-1:0] ciphertext1;
    reg [2*DIMENSION:0][CIPHERTEXT_WIDTH-1:0] interim_result;

    wire [DIM_WIDTH:0] out_row;
    
    /*
    always @(posedge clk) begin
        $display("op1: %d, cts: %d, en: %d",op1[0],ciphertext_select,en);
        $display("C1: %d, %d, %d",ciphertext1[0],ciphertext1[1],ciphertext1[2]);
        $display("D: %d, %d, %d, %d, %d", interim_result[0],interim_result[1],interim_result[2],interim_result[3],interim_result[4]);
    end
    */
    
    assign out_row = (row == 0)? 0 : row - 1;

    always @(posedge clk) begin
        if (!rst_n) begin
            ciphertext1 <= 0;
            interim_result <= 0;
        end else if (ciphertext_select == 0 && en) begin
            if (row <= DIMENSION) begin
                //for (int jm = 0; jm < PARALLEL; jm=jm+1) begin
		    //ciphertext1[row+jm] <= op1[jm];
		    ciphertext1[row] <= op1[0];
                //end
            end else begin
                //for (int km = 0; km < PARALLEL; km=km+1) begin
		    //ciphertext1[row+km-DIMENSION] <= op1[km];
		    ciphertext1[row-DIMENSION] <= op1[0];
                //end
            end
        end //else if (ciphertext_select == 1 && en) begin
            //for (int xm = 0; xm < PARALLEL; xm=xm+1) begin
            //    for (int ym = 0; ym <= DIMENSION; ym=ym+1) begin
            //        interim_result[row + xm + ym] <= interim_result[row + xm + ym] + op1[xm] * ciphertext1[ym];
            //    end
            //end
        //end
    end

    generate
        genvar ym;
        for (ym = 0; ym <= DIMENSION; ym=ym+1) begin
            always @(posedge clk) begin
		    if (ciphertext_select == 1 && en) begin
			    interim_result[row + ym] <= interim_result[row + ym] + op1[0] * ciphertext1[ym];
		    end
	    end
        end
    endgenerate

    generate
        genvar mmm;
        for (mmm = 0; mmm < PARALLEL; mmm=mmm+1) begin
            assign result_partial[mmm] = interim_result[out_row+mmm];
        end
    endgenerate

    /*
    generate
        genvar jm;
        for (jm = 0; jm < PARALLEL; jm+=1) begin
            assign result_partial[jm] = interim_result[row+jm];
            // operational logic
            always @(posedge clk) begin
                if (ciphertext_select == 0 && en) begin
                    if (row <= DIMENSION) begin
                        ciphertext1[row+jm] = op1[jm];
                    end else begin
                        ciphertext1[row+jm-DIMENSION] = op1[jm]; // need to figure out if this is still good
                    end
                end 
            end
        end

        genvar xm, ym;
        for (xm = 0; xm < PARALLEL; xm+=1) begin
            for (ym = 0; ym <= DIMENSION; ym+=1) begin
                // operational logic
                always @(posedge clk) begin
                    if (ciphertext_select == 1 && en) begin
                        interim_result[row + xm + ym] = interim_result[row + xm + ym] + op1[xm] * ciphertext1[ym];
                    end
                end
            end
        end

        genvar im;
        for (im = 0; im <= DIMENSION; im+=1) begin
            // reset logic
            always @(posedge clk) begin
                if (!rst_n) begin
                    ciphertext1[im] = 0;
                    interim_result[im] = 0;
                    interim_result[im+DIMENSION] = 0;
                end
            end
        end
    endgenerate
    */
endmodule
