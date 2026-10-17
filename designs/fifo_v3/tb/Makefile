# cocotb Makefile for the FIFO bench.
#
#   make                       # run the bench against the golden RTL
#   make RTL=path/to/mutated.v # run it against some other implementation
#   make TRACE=trace.csv       # also dump the per-cycle output trace
#
# RTL defaults to the golden design. MCY's test_sim.sh overrides it with the
# mutated module, which is why the bench must only depend on the module's
# ports, never its file name.

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

TB_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
RTL ?= $(TB_DIR)../rtl/fifo_v3.sv

VERILOG_SOURCES += $(RTL)
# -DSYNTHESIS disables the upstream SVA protocol assertions (Icarus can't parse them).
# The golden file has parameters; MCY's mutated.v is already elaborated at 8x8, so
# only pass -P for the golden (Icarus errors on -P for a parameter that doesn't exist).
COMPILE_ARGS += -DSYNTHESIS
ifeq ($(RTL),$(TB_DIR)../rtl/fifo_v3.sv)
COMPILE_ARGS += -P fifo_v3.DATA_WIDTH=8 -P fifo_v3.DEPTH=8
endif
TOPLEVEL = fifo_v3
COCOTB_TEST_MODULES = test_fifo_v3
export PYTHONPATH := $(TB_DIR):$(PYTHONPATH)

# Keep each run's build products out of the source tree.
SIM_BUILD ?= $(CURDIR)/sim_build
COCOTB_RESULTS_FILE ?= $(CURDIR)/results.xml

ifdef TRACE
export TRACE
endif
ifdef SEED
export SEED
endif
ifdef CYCLES
export CYCLES
endif

include $(shell cocotb-config --makefiles)/Makefile.sim
