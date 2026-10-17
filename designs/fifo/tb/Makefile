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
RTL ?= $(TB_DIR)../rtl/fifo.v

VERILOG_SOURCES += $(RTL)
TOPLEVEL = fifo
COCOTB_TEST_MODULES = test_fifo
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
