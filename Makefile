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
	
manualv: clean
	vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+pp verilog/dv/$(target).v verilog/sram/sky130_sram_1kbyte_1rw1r_32x256_8.v verilog/openlane_rtl/user_project_wrapper.v verilog/openlane_rtl/user_proj_example.v

copy_verilog: concat
	cp verilog/outputs/design.v skywater-digital-flow/OpenEnclave/design/rtl/design.v
	cp verilog/dv/top_tb.v skywater-digital-flow/OpenEnclave/design/testbench/top_tb.sv

copy_mverilog: clean
	cp verilog/openlane_rtl/user_proj_example.v skywater-digital-flow/OpenEnclave/design/rtl/user_proj_example.v
	cp verilog/dv/user_project_wrapper_tb.v skywater-digital-flow/OpenEnclave/design/testbench/user_project_wrapper_tb.sv
	cp verilog/dv/user_project_wrapper.v skywater-digital-flow/OpenEnclave/design/testbench/user_project_wrapper.sv

clean:
	rm -rf simv
	rm -rf simv.daidir/ 
	rm -rf *.vcd
	rm -rf csrc
	rm -rf ucli.key
	rm -rf vc_hdrs.h
	rm -rf DVEfiles
	rm -rf verilog/outputs/design.v
