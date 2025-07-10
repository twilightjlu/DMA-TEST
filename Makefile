top := tb_dma_axi_wrapper
run:
	vcs	 -R -full64 -sverilog -v2k_generate \
		-debug_all \
		-lca \
		-sverilog \
		-cm line+cond+fsm+branch+assert+tgl \
		-cm_hier top \
		-notice \
		-ntb_opts  \
		-nc \
		-timescale=1ns/1ps\
		-top ${top} \
		-f filelist.f \
 		-l sim.log \
		-assert \
		+warn=none \
		-kdb \
		-fsdb +region\
		+DUMP_FSDB 

# run: comp
# 	./simv \
# 	-gui \
# 	-l sim.log 

clean:
	rm -rf csrc/ simv.daidir/ *Report/ *.vdb/ DVEfiles/ novas* simv *.log ucli.key vc_hdrs.h *Log *fsdb* *.lib++ 
view:
	verdi  -ssf *.fsdb
cov:
	urg -dir simv.vdb
	zip -r coverage urgReport


