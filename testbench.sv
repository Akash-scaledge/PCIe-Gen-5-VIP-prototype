// // Code your testbench here
// // or browse Examples
// `include "uvm_pkg.sv"
// import uvm_pkg::*;
// typedef bit[31:0] global_que_t[$];
// `include "include.svh"
// `include "testbench_PL.sv"
// `include "testbench_DL.sv"
// `include "testbench_TL.sv"

// `include "pcie_test.sv"
// `include "pcie_top.sv"

// // Code your testbench here
// // or browse Examples
// `include "uvm_pkg.sv"
// import uvm_pkg::*;
// typedef bit[31:0] global_que_t[$];
// `include "include.svh"
// `include "testbench_PL.sv"
// `include "testbench_DL.sv"
// `include "testbench_TL.sv"
// `include "pcie_env.sv"
// `include "pcie_test.sv"
// `include "pcie_top.sv"



//======================================================
// UVM
//======================================================
`include "uvm_pkg.sv"
import uvm_pkg::*;
`include "uvm_macros.svh"

//======================================================
// Common typedefs / globals
//======================================================
typedef bit [31:0] global_que_t[$];
class dw_pkt extends uvm_object;
  `uvm_object_utils(dw_pkt)
  bit [31:0] dw[$];
  function new(string name = "dw_pkt"); super.new(name); endfunction

  static task put_q(uvm_blocking_put_port #(dw_pkt) port, input global_que_t q);
    dw_pkt p = new();
    p.dw = q;
    port.put(p);
  endtask

  static task get_q(uvm_blocking_get_port #(dw_pkt) port, output global_que_t q);
    dw_pkt p;
    port.get(p);
    q = p.dw;
  endtask
endclass

//======================================================
// Common parameters / timers
//======================================================
`include "siv_parameter.svh"
`include "timer_dl.svh"
`include "siv_timer_pl.svh"
`include "siv_timer_TL.svh"
`include "include.svh"

//======================================================
// Interfaces
//======================================================
// PL
`include "siv_ltssm_intf.sv"

// DL
`include "dl_if.sv"

// TL
`include "siv_tl_intf.sv"
`include "mem_intf.sv"

//======================================================
// CONFIGURATION OBJECTS (Unified)
//======================================================
`include "siv_ltssm_pl_cfg.sv"
`include "pcie_dl_cfg.sv"
`include "siv_tl_cfg.sv"
`include "siv_pcie_cfg.sv"        // <-- unified cfg (PL + DL + TL)

//======================================================
// PL (Physical Layer)
//======================================================
`include "siv_ltssm_seq_item.sv"
`include "siv_ltssm_pl_pkt_modify_callback.sv"
`include "siv_ltssm_fsm.sv"
`include "siv_ltssm_seq.sv"
`include "siv_ltssm_seq1.sv"
`include "siv_ltssm_sequencer.sv"
`include "siv_ltssm_driver.sv"
`include "siv_ltssm_cov.sv"
`include "siv_ltssm_agent.sv"

//======================================================
// DL (Data Link Layer)
//======================================================


`include "pcie_dl_seq_item.sv"
`include "Reg.sv"
`include "adapter.sv"
`include "dlcmsm_fsm.svi"
`include "dlcmsm_seq.sv"
`include "dlcmsm_seqr.sv"
`include "pcie_dl_pkt_modify_callback.svi" 
`include "dlcmsm_driver.sv"
`include "dlcmsm_agent.sv"

//======================================================
// TL (Transaction Layer)
//======================================================
`include "design_TL.sv"
`include "mem_common.sv"
`include "mem_tx.sv"

`include "reg_block.sv"
`include "reg2sram_adaptor.sv"

`include "siv_tl_seq_item.sv"
`include "siv_tl_seq.sv"
`include "mem_seq_lib.sv"

`include "siv_tl_seqr.sv"
`include "mem_sqr.sv"

`include "siv_tl_driver.sv"
`include "mem_drv.sv"

`include "siv_tl_mon.sv"
`include "mem_mon.sv"

`include "siv_tl_agent.sv"
`include "mem_agent.sv"
//`include "mem_env.sv"




//======================================================
// Unified PCIe Device + Environment
//======================================================
`include "siv_pcie_device_agent.sv"
`include "siv_pcie_env.sv"
`include "siv_pcie_base_test.sv"

//======================================================
// Unified Tests ONLY (NO separate PL/DL/TL tests)
//======================================================


//======================================================
// Top
//======================================================
`include "pcie_top.sv"
