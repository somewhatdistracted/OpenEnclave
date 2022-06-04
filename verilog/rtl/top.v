//`default_nettype none
`define MPRJ_IO_PADS 38

module top
#(
    parameter PLAINTEXT_MODULUS = 64,
    parameter PLAINTEXT_WIDTH = 6,
    parameter CIPHERTEXT_MODULUS = 1024,
    parameter CIPHERTEXT_WIDTH = 32,
    parameter DIMENSION = 10,
    parameter BIG_N = 30,
    parameter OPCODE_ADDR = 32'h30000000,
    parameter OUTPUT_ADDR = 32'h00000001,
    parameter DATA_WIDTH = 128,
    parameter ADDR_WIDTH = 9,
    parameter DEPTH = 256,
    parameter DIM_WIDTH = 4,
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

    // CHIP-LEVEL STUFF
    wire clk;
    wire rst_n;

    assign clk = (la_oenb[0] & la_data_in[0]) ? user_clock2 : wb_clk_i;
    assign rst_n = la_oenb[1] ? la_data_in[1] : 1;

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
    reg [1:0] opcode_out;
    reg [ADDR_WIDTH-1:0] op1_addr;
    reg [ADDR_WIDTH-1:0] op2_addr;
    reg [ADDR_WIDTH-1:0] out_addr;
    reg op_select;
    reg op_select_delayed;
    reg en;
    reg done;
    reg [DIM_WIDTH:0] row;
    // SRAM DECLARATIONS
    wire in_wen;
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
    wire [ADDR_WIDTH - 1 : 0] out_radr;
    wire [DATA_WIDTH - 1 : 0] out_rdata;
    // FUNCTIONAL MODULE DECLARATIONS
    wire [CIPHERTEXT_WIDTH-1:0] op1_structured [PARALLEL-1:0];
    wire [CIPHERTEXT_WIDTH-1:0] op2_structured [PARALLEL-1:0];
    reg [DIM_WIDTH:0] delayed_row;
    // ENCRYPT DECLARATIONS
    wire [CIPHERTEXT_WIDTH-1:0] encrypt_out;
    reg encrypt_en;
    // DECRYPT DECLARATIONS
    wire [PLAINTEXT_WIDTH-1:0] decrypt_out;
    wire decrypt_en;
    // HOMOMORPHIC ADD DECLARATIONS
    wire [CIPHERTEXT_WIDTH-1:0] add_out [PARALLEL-1:0];
    wire [(PARALLEL*CIPHERTEXT_WIDTH)-1:0] add_out_flattened;
    wire add_en;
    // HOMOMORPHIC MULTIPLY DECLARACTIONS
    wire [CIPHERTEXT_WIDTH-1:0] muxed_ops [PARALLEL-1:0];
    wire [CIPHERTEXT_WIDTH-1:0] mult_out [PARALLEL-1:0];
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
    assign in_wen = wb_write_req & !config_en;
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
        for (ip = 0; ip<PARALLEL; ip+=1) begin
            assign op1_structured[ip] = op1_rdata[((ip+1)*CIPHERTEXT_WIDTH)-1:ip*CIPHERTEXT_WIDTH];
            assign op2_structured[ip] = op2_rdata[((ip+1)*CIPHERTEXT_WIDTH)-1:ip*CIPHERTEXT_WIDTH];
        end
    endgenerate

    always_ff @(posedge clk) begin
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
        for (iaf = 0; iaf<PARALLEL; iaf+=1) begin
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
        for (imf = 0; imf<PARALLEL; imf+=1) begin
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
