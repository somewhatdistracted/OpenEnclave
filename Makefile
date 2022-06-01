debug:
	dve -full64 -vpd dump.vcd &

unit_test: clean
	vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+pp verilog/dv/$(target)_tb.v verilog/rtl/defs.v verilog/rtl/$(target).v
	./simv

run: compile
	./simv

concat: clean
	cat verilog/rtl/defs.v verilog/rtl/top.v verilog/rtl/sram.v verilog/rtl/wishbone_ctl.v verilog/rtl/controller.v verilog/rtl/encrypt.v verilog/rtl/decrypt.v verilog/rtl/homomorphic_add.v verilog/rtl/homomorphic_multiply.v > verilog/outputs/design.v

compile: concat
	vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+pp verilog/dv/$(target).v verilog/sram/sky130_sram_1kbyte_1rw1r_32x256_8.v verilog/outputs/design.v 
	
copy_verilog: concat
	cp verilog/outputs/design.v skywater-digital-flow/OpenEnclave/design/rtl/design.v

clean:
	rm -rf simv
	rm -rf simv.daidir/ 
	rm -rf *.vcd
	rm -rf csrc
	rm -rf ucli.key
	rm -rf vc_hdrs.h
	rm -rf DVEfiles
	rm -rf verilog/outputs/design.v
