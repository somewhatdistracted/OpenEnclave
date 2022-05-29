debug:
	dve -full64 -vpd dump.vcd &

run: compile
	./simv

concat: clean
	cat verilog/defs.v verilog/top.v verilog/sram.v verilog/wishbone_ctl.v verilog/controller.v verilog/encrypt.v verilog/decrypt.v verilog/homomorphic_add.v verilog/homomorphic_multiply.v > verilog/outputs/design.v

compile: concat
	vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+pp verilog/$(target).v verilog/sky130_sram_1kbyte_1rw1r_32x256_8.v verilog/outputs/design.v 
	
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
