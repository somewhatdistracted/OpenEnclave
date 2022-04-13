debug: run_conv
	dve -full64 -vpd dump.vcd &

run: compile
	./simv

compile: 
	vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+pp verilog/$(target)_tb.v verilog/encrypt.v verilog/decrypt.v verilog/homomorphic_add.v
	
clean:
	rm -rf ./simv
	rm -rf simv.daidir/ 
	rm -rf *.vcd
	rm -rf csrc
	rm -rf ucli.key
	rm -rf vc_hdrs.h
	rm -rf DVEfiles
