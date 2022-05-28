`define DEPTH 1024
`define DATA_WIDTH 128
`define ADDR_WIDTH 10

module sram_tb;
  
  reg clk;

  reg in_wen;
  reg [`ADDR_WIDTH - 1 : 0] in_wadr;
  reg [`DATA_WIDTH - 1 : 0] in_wdata;

  reg out_wen;
  reg [`ADDR_WIDTH - 1 : 0] out_wadr;
  reg [`DATA_WIDTH - 1 : 0] out_wdata;
    
  reg op1_ren;
  reg [`ADDR_WIDTH - 1 : 0] op1_radr;
  wire [`DATA_WIDTH - 1 : 0] op1_rdata;

  reg op2_ren;
  reg [`ADDR_WIDTH - 1 : 0] op2_radr;
  wire [`DATA_WIDTH - 1 : 0] op2_rdata;
    
  reg out_ren;
  reg [`ADDR_WIDTH - 1 : 0] out_radr;
  wire [`DATA_WIDTH - 1 : 0] out_rdata;

  reg [`DATA_WIDTH - 1 : 0] op1_result;
  reg [`DATA_WIDTH - 1 : 0] op2_result;
  reg [`DATA_WIDTH - 1 : 0] out_result;

  always #(10) clk =~clk;
 
  sram #(
      .DATA_WIDTH(`DATA_WIDTH),
      .ADDR_WIDTH(`ADDR_WIDTH),
      .DEPTH(`DEPTH)
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

  initial begin
    clk = 0;

    in_wen = 0;
    out_wen = 0;

    op1_ren = 0;
    op2_ren = 0;
    out_ren = 0;

    in_wadr = 0;
    in_wdata = 0;

    out_wadr = 100;
    out_wdata = 0;

    op1_radr = 0;
    op2_radr = 0;
    out_radr = 100;

    #20

    in_wdata = `DATA_WIDTH'd137;
    in_wadr = `ADDR_WIDTH'd0;
    in_wen = 1;

    out_wdata = `DATA_WIDTH'd42;
    out_wen = 1;
    
    #20

    in_wen = 0;
    out_wen = 0;

    op1_radr = `ADDR_WIDTH'd0;
    op1_ren = 1;

    out_ren = 1;

    #30

    op1_result = op1_rdata;
    out_result = out_rdata;
 
    $display("In Result = %d", op1_result);
    assert(op1_result == 137);

    $display("Out Result = %d", out_result);
    assert(out_result == 42); 
   
    #20

    op1_ren = 0;
    out_ren = 0;

    #20

    in_wdata = `DATA_WIDTH'd27;
    in_wadr = `ADDR_WIDTH'd0;
    in_wen = 1;

    out_wdata = `DATA_WIDTH'd100;
    out_wen = 1;

    #20

    in_wen = 0;
    out_wen = 0;

    op2_radr = `ADDR_WIDTH'd0;
    op2_ren = 1;

    out_ren = 1;

    #20

    op2_result = op2_rdata;
    out_result = out_rdata;

    $display("In Result = %d", op2_result);
    assert(op2_result == 27);

    $display("Out Result = %d", out_result);
    assert(out_result == 100);

    #20
    
    $finish;
  end
endmodule 
