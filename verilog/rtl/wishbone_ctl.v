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
    wire wbs_req_write = (ack_o) & wbs_req & (wbs_we_i );
    wire wbs_req_read  = (ack_o) & wbs_req & (~wbs_we_i);
    // Input Data to Sram
    always@(posedge wb_clk_i) begin
        wbs_reg_addr = wbs_adr_i;
        if (wb_rst_i)
            wbs_reg_i <= 32'd0;
        else if (wbs_req_write)
	    wbs_reg_i <= wbs_dat_i;
    end
    // Sram to Output Data
    always@(negedge wb_clk_i) begin
        if (wb_rst_i)
            wbs_reg_o <= 32'd0;
        else if (wbs_req_read)
            wbs_reg_o <= wishbone_output;
    end
// ==============================================================================
// Outputs
// ==============================================================================
assign config_en               = wbs_req & (wbs_adr_i == OPCODE_ADDR);

assign wbs_ack_o               = ack_o;
assign wbs_dat_o               = wbs_req_read ? wishbone_output : 32'd0;

assign wishbone_data           = wbs_reg_i;
assign wishbone_addr           = (wbs_reg_addr - 32'h30000004) >> 2;

assign wb_read_req             = wbs_req_read;
assign wb_write_req            = wbs_req_write;

endmodule
