TOPLEVEL_LANG ?= verilog
SIM ?= icarus

# DUT
VERILOG_SOURCES = $(PWD)/rtl/static_branch_predict.sv
TOPLEVEL = static_branch_predict
MODULE = test_static_branch_predict

# Make harness directory visible to cocotb
export PYTHONPATH := $(PWD)/harness:$(PYTHONPATH)

# Override IVERILOG command to use Docker wrapper
IVERILOG ?= $(PWD)/iverilog-docker.sh

include $(shell cocotb-config --makefiles)/Makefile.sim

