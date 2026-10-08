#!/usr/bin/env bash
# Usage (from repo root): bash sim/run_vcs.sh [TESTNAME]
# Needs UVM_HOME pointing at a UVM 1.2 install (testbench.sv includes uvm_pkg.sv itself).
set -e
TEST=${1:-siv_pcie_base_test}
: "${UVM_HOME:?Set UVM_HOME to your UVM 1.2 install}"
mkdir -p sim/out
vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb \
    +incdir+$UVM_HOME/src $UVM_HOME/src/dpi/uvm_dpi.cc -CFLAGS -DVCS \
    -f sim/vip.f -o sim/out/simv -l sim/out/compile.log
./sim/out/simv +UVM_TESTNAME=$TEST +UVM_VERBOSITY=UVM_MEDIUM \
    +UVM_TIMEOUT=2000000000,NO -l sim/out/run.log
