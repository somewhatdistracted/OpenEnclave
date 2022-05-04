`define DEPTH 1024
`define DATA_WIDTH 128
`define ADDR_WIDTH 10

module sram_tb;
  
  reg clk;
  reg wen;
  reg ren;
  reg [`ADDR_WIDTH-1:0] wadr;
  reg [`DATA_WIDTH-1:0] wdata;
  reg [`ADDR_WIDTH-1:0] radr;
  wire [`DATA_WIDTH-1:0] rdata;

  always #(10) clk =~clk;
 
  sram #(
    .DATA_WIDTH(`DATA_WIDTH),
    .ADDR_WIDTH(`ADDR_WIDTH),
    .DEPTH(`DEPTH)
  ) sram_inst (
    .clk(clk),
    .wen(wen),
    .wdata(wdata),
    .ren(ren),
    .radr(radr),
    .rdata(rdata)
  );

  initial begin
    clk = 0;
    wen = 0;
    ren = 0;

    wadr = 0;
    wdata = 0;
    #20

    wdata = `DATA_WIDTH'd137;
    wadr = `ADDR_WIDTH'd97;
    wen = 1;
    #20

    wen = 0;
    #20

    radr = `ADDR_WIDTH'd97;
    ren = 1;
    #20

    $display("Result = %d", rdata);
    assert(rdata == 137);   
    ren = 0;   
    #20

    wdata = `DATA_WIDTH'd84;
    wadr = `ADDR_WIDTH'd83;
    wen = 1;
    #20

    wen = 0;
    #20

    radr = `ADDR_WIDTH'd83;
    ren = 1;
    #20
    
    $display("Result = %d", rdata);
    assert(rdata == 84);    
    
    #20

    wdata = `DATA_WIDTH'd39;
    wadr = `ADDR_WIDTH'd4;
    wen = 1;
    #20

    wen = 0;
    $display("Result = %d", rdata);
    assert(rdata == 84);
    #20

    radr = `ADDR_WIDTH'd4;
    ren = 1;
    #20
    
    ren = 0;
    $display("Result = %d", rdata);
    assert(rdata == 39);    
    
    $finish;
  end
endmodule 
