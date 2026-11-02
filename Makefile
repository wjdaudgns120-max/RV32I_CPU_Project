#vcs Makefile

RTL_DIR		= ./rtl
PKG_DIR		= ./rtl/pkg
TB_DIR		= ./tb
BUILD_DIR	= ./build
INC_DIR		= +incdir+$(RTL_DIR)
SIMV_DIR	= ./build/simv
#SIMV_OPTS	:= -cm line+cond+fsm+tgl+branch+assert -cm_dir coverage.vdb -cm_name sim1
#SIMV_OPTS	+= +UVM_VERBOSITY=UVM_HIGH
VCS_OPT     = -full64 -sverilog -debug_access+all -kdb -lca \
              -timescale=1ns/1ps -o $(SIMV_DIR) \ 
			  #-ntb_opts uvm-1.2 \
              $(INC_DIR) \
              -o $(SIMV_DIR)

all: run simv

SRC_DIR		= $(RTL_DIR)/pkg/rv32i_pkg.sv $(RTL_DIR) $(TB_DIR)

generate_f:
	cat pkg.f > files.f
	find $(RTL_DIR) $(TB_DIR) -path $(PKG_DIR) -prune -o -name "*.sv" -print >> files.f


run:	generate_f
	mkdir -p	$(BUILD_DIR)
	vcs			$(VCS_OPT) -f files.f
simv:
	$(SIMV_DIR) $(SIMV_OPTS)

verdi:
	verdi -dbdir $(BUILD_DIR)/simv.daidir -ssf wave.fsdb &

clean:
	rm -rf inter.* *.fsdb $(BUILD_DIR) csrc novas* ucli.key.verdiLog files.f *.fsdb inter.fsdb .inter.fsdb.tbsim sys*


.PHONY:	all vcs simv verdi clean
