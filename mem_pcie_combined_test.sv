// Combined test for memory and PCIe environments

class mem_pcie_combined_test extends uvm_test;
  `uvm_component_utils(mem_pcie_combined_test)
  
  // Environments
  mem_env            memenv;
  siv_pcie_tl_env    pcieenv;

  // Sequences
  reg_seq            regseq;
  siv_pcie_tl_seq    rc_seq, ep_seq;

  // Constructor
  function new(string name = "mem_pcie_combined_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build phase: instantiate both environments
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    memenv  = mem_env::type_id::create("memenv", this);
    pcieenv = siv_pcie_tl_env::type_id::create("pcieenv", this);
  endfunction

  // end_of_elaboration: print full topology
  function void end_of_elaboration_phase(uvm_phase phase);
    uvm_top.print_topology();
  endfunction

  // Run phase: launch all three "primary" sequences in parallel
  task run_phase(uvm_phase phase);
   

    // Create all sequences
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = siv_pcie_tl_seq::type_id::create("rc_seq");
    ep_seq = siv_pcie_tl_seq::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("COMBINED_TEST", "Starting RC, EP, and MEM sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("COMBINED_TEST", "All sequences completed", UVM_MEDIUM)
  endtask
endclass

//test for write and read of the I/O packet
class io_wr_rd_test extends mem_pcie_combined_test;
  `uvm_component_utils(io_wr_rd_test)
  function new(string name = "io_wr_rd_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    reg_seq         regseq;
    io_wr_rd_seq    rc_io_seq, ep_io_seq;
    regseq = reg_seq::type_id::create("regseq");
    rc_io_seq = io_wr_rd_seq::type_id::create("rc_seq");
    ep_io_seq = io_wr_rd_seq::type_id::create("ep_seq");
  phase.raise_objection(this);
    `uvm_info("COMBINED_TEST", "Starting RC, EP, and MEM sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_io_seq.start(pcieenv.devices[0].sequencer);
//     ep_io_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("COMBINED_TEST", "All sequences completed", UVM_MEDIUM)
  endtask
endclass

//test for write and read of the memory packet
class mem_wr_rd_test extends mem_pcie_combined_test;
  `uvm_component_utils(mem_wr_rd_test)
  function new(string name = "mem_wr_rd_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    reg_seq         regseq;
    mem_wr_rd_seq    rc_mem_seq, ep_mem_seq;
    regseq = reg_seq::type_id::create("regseq");
    rc_mem_seq = mem_wr_rd_seq::type_id::create("rc_mem_seq");
    ep_mem_seq = mem_wr_rd_seq::type_id::create("ep_mem_seq");
  phase.raise_objection(this);
    `uvm_info("COMBINED_TEST", "Starting RC, EP, and MEM sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
//     rc_mem_seq.start(pcieenv.devices[0].sequencer);
    fork
    begin 
    rc_mem_seq.start(pcieenv.devices[0].sequencer);
//     ep_mem_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("COMBINED_TEST", "All sequences completed", UVM_MEDIUM)
  endtask
endclass


//test for write and read byte enable of the memory packet
class mem_wr_rd_byte_enable_test extends mem_pcie_combined_test;
  `uvm_component_utils(mem_wr_rd_byte_enable_test)
  function new(string name = "mem_wr_rd_byte_enable_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    reg_seq         regseq;
    mem_wr_rd_byte_enable_seq    rc_mem_byte_enable_seq;
    regseq = reg_seq::type_id::create("regseq");
    rc_mem_byte_enable_seq = mem_wr_rd_byte_enable_seq::type_id::create("rc_mem_byte_enable_seq");
    phase.raise_objection(this);
    `uvm_info("COMBINED_TEST", "Starting RC, EP, and MEM sequences", UVM_MEDIUM)
	  regseq.start(memenv.agent.sqr); 
      rc_mem_byte_enable_seq.start(pcieenv.devices[0].sequencer);
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("COMBINED_TEST", "All sequences completed", UVM_MEDIUM)
  endtask
endclass


//test for zero length write and read of the memory packet
class mem_wr_rd_zero_length_write_test extends mem_pcie_combined_test;
  `uvm_component_utils(mem_wr_rd_zero_length_write_test)
  function new(string name = "mem_wr_rd_zero_length_write_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    reg_seq         regseq;
    mem_wr_rd_zero_length_write_seq    rc_mem_zero_length_write_seq;
    regseq = reg_seq::type_id::create("regseq");
    rc_mem_zero_length_write_seq = mem_wr_rd_zero_length_write_seq::type_id::create("rc_mem_zero_length_write_seq");
    phase.raise_objection(this);
    `uvm_info("COMBINED_TEST", "Starting RC, EP, and MEM sequences", UVM_MEDIUM)
	  regseq.start(memenv.agent.sqr); 
      rc_mem_zero_length_write_seq.start(pcieenv.devices[0].sequencer);
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("COMBINED_TEST", "All sequences completed", UVM_MEDIUM)
  endtask
endclass


//test for write and read with invalid AT bit of the memory packet
class mem_wr_rd_invalid_at_test extends mem_pcie_combined_test;
  `uvm_component_utils(mem_wr_rd_invalid_at_test)
  function new(string name = "mem_wr_rd_invalid_tag_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    reg_seq         regseq;
    mem_wr_rd_invalid_at_seq    rc_mem_invalid_at_seq;
    regseq = reg_seq::type_id::create("regseq");
    rc_mem_invalid_at_seq = mem_wr_rd_invalid_at_seq::type_id::create("rc_mem_invalid_at_test");
    phase.raise_objection(this);
    `uvm_info("COMBINED_TEST", "Starting RC, EP, and MEM sequences", UVM_MEDIUM)
	  regseq.start(memenv.agent.sqr); 
      rc_mem_invalid_at_seq.start(pcieenv.devices[0].sequencer);
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("COMBINED_TEST", "All sequences completed", UVM_MEDIUM)
  endtask
endclass




//test for write and read of the config packet
class config_wr_rd_test extends mem_pcie_combined_test;
  `uvm_component_utils(config_wr_rd_test)
  function new(string name = "config_wr_rd_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  task run_phase(uvm_phase phase);
    reg_seq         regseq;
    config_wr_rd_seq    rc_config_seq, ep_config_seq;
    regseq = reg_seq::type_id::create("regseq");
    rc_config_seq = config_wr_rd_seq::type_id::create("rc_config_seq");
    ep_config_seq = config_wr_rd_seq::type_id::create("ep_config_seq");
    phase.raise_objection(this);
    `uvm_info("COMBINED_TEST", "Starting RC, EP, and MEM sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    rc_config_seq.start(pcieenv.devices[0].sequencer);
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("COMBINED_TEST", "All sequences completed", UVM_MEDIUM)
  endtask
endclass



//64 addresss
class mem_write_read_64 extends mem_pcie_combined_test;
  `uvm_component_utils(mem_write_read_64)
  `uvm_new_func
  mem_write_read_64_seq mem_seq; 
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");    
    mem_seq = mem_write_read_64_seq::type_id::create("mem_seq");    
    phase.raise_objection(this);    
    `uvm_info("COMBINED_TEST", "Starting RC, EP, and MEM sequences", UVM_MEDIUM)    
    regseq.start(memenv.agent.sqr);    
    mem_seq.start(pcieenv.devices[0].sequencer);    
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time    
    phase.drop_objection(this);   
    `uvm_info("COMBINED_TEST", "All sequences completed", UVM_MEDIUM)
  endtask
endclass



//32-bit Memory write read test for first byte enable rule
class  mem_wr_rd_BE_test extends mem_pcie_combined_test;
  `uvm_component_utils(mem_wr_rd_BE_test)
  seq_mem_wr_rd_first_dw_be rc_seq,ep_seq;
  function new(string name="mem_wr_rd_dw_be_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = seq_mem_wr_rd_first_dw_be::type_id::create("rc_seq");
    ep_seq = seq_mem_wr_rd_first_dw_be::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("MEM WRRD", "Starting Mem WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass
//32-bit memory write read test for zero length write
class  mem_wr_zero_length_test extends mem_pcie_combined_test;
  `uvm_component_utils(mem_wr_zero_length_test)
  seq_mem_wr_zero_length rc_seq,ep_seq;
  function new(string name="mem_wr_zero_length_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = seq_mem_wr_zero_length::type_id::create("rc_seq");
    ep_seq = seq_mem_wr_zero_length::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("MEM WRRD", "Starting Mem WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass
//32- bit memory write read test for 0 lenght read

class  mem_wr_zero_rd_length_test extends mem_pcie_combined_test;
  `uvm_component_utils(mem_wr_zero_rd_length_test)
  seq_mem_wr_zero_rd_length rc_seq,ep_seq;
  function new(string name="mem_wr_zero_rd_length_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = seq_mem_wr_zero_rd_length::type_id::create("rc_seq");
    ep_seq = seq_mem_wr_zero_rd_length::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("MEM WRRD", "Starting Mem WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass

//32- bit memory write read test for relax ordering

class  mem_wr_rd_ro_test extends mem_pcie_combined_test;
  `uvm_component_utils(mem_wr_rd_ro_test)
  seq_mem_wr_rd_ro rc_seq,ep_seq;
  function new(string name="mem_wr_rd_ro_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = seq_mem_wr_rd_ro::type_id::create("rc_seq");
    ep_seq = seq_mem_wr_rd_ro::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("MEM WRRD", "Starting Mem WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass


//IO write and read test for multiple payload 
class  io_wr_rd_new_test extends mem_pcie_combined_test;
  `uvm_component_utils(io_wr_rd_new_test)
  seq_io_wr_rd rc_seq,ep_seq;
  function new(string name="io_wr_rd_new_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = seq_io_wr_rd::type_id::create("rc_seq");
    ep_seq = seq_io_wr_rd::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("IO WRRD", "Starting IO WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 10000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("IO WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass



//td bit set with ecrc

class  mem_wr_rd_td_test extends mem_pcie_combined_test;
  `uvm_component_utils(mem_wr_rd_td_test)
  mem_wr_rd_td_seq rc_seq,ep_seq;
  function new(string name="mem_wr_rd_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = mem_wr_rd_td_seq::type_id::create("rc_seq");
    ep_seq = mem_wr_rd_td_seq::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("MEM WRRD", "Starting Mem WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 1000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass
//tc vc mapping try 1

class  mem_wr_rd_tc_vc_test extends mem_pcie_combined_test;
  `uvm_component_utils(mem_wr_rd_tc_vc_test)
  seq_mem_wr_rd_diff_vc rc_seq,ep_seq;
  function new(string name="mem_wr_rd_tc_vc_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = seq_mem_wr_rd_diff_vc::type_id::create("rc_seq");
    ep_seq = seq_mem_wr_rd_diff_vc::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("MEM WRRD", "Starting Mem WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 1000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass

//config wr rd with td bit high


class  config_wr_rd_td_test extends mem_pcie_combined_test;
  `uvm_component_utils(config_wr_rd_td_test)
  seq_config_wr_rd_td rc_seq,ep_seq;
  function new(string name="config_wr_rd_td_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = seq_config_wr_rd_td::type_id::create("rc_seq");
    ep_seq = seq_config_wr_rd_td::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("CONFIG WRRD", "Starting Config WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 1000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass




//RCB test for mem write and read

class  mem_wr_rd_rcb_test extends mem_pcie_combined_test;
  `uvm_component_utils(mem_wr_rd_rcb_test)
   mem_wr_rd_rcb_seq rc_seq,ep_seq;
  function new(string name="mem_wr_rd_rcb_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq =  mem_wr_rd_rcb_seq::type_id::create("rc_seq");
    ep_seq =  mem_wr_rd_rcb_seq::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("CONFIG WRRD", "Starting Config WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 5000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass
//Testcase for invalid format value for config packets.
class  invalid_config_packet_test extends mem_pcie_combined_test;
  `uvm_component_utils(invalid_config_packet_test)
   seq_config_wr_rd_4dw_header rc_seq,ep_seq;
  function new(string name="invalid_config_packet_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = seq_config_wr_rd_4dw_header::type_id::create("rc_seq");
    ep_seq = seq_config_wr_rd_4dw_header::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("CONFIG WRRD", "Starting Config WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 5000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass


// seq_unconditional_swap_atomicop
//Testcase for AtomicOp unconditional swap 
class atomic_op_unc_swap_test extends mem_pcie_combined_test;
  `uvm_component_utils(atomic_op_unc_swap_test)
   seq_unconditional_swap_atomicop rc_seq,ep_seq;
  function new(string name="atomic_op_unc_swap_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = seq_unconditional_swap_atomicop::type_id::create("rc_seq");
    ep_seq = seq_unconditional_swap_atomicop::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("CONFIG WRRD", "Starting Config WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 5000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass


//Testcase for AtomicOp unconditional swap for 64 bit addressing 
class atomic_op_unc_swap_64_bit_test extends mem_pcie_combined_test;
  `uvm_component_utils(atomic_op_unc_swap_64_bit_test)
  seq_unconditional_swap_atomicop_64_bits rc_seq,ep_seq;
  function new(string name="atomic_op_unc_swap_64_bit_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = seq_unconditional_swap_atomicop_64_bits::type_id::create("rc_seq");
    ep_seq = seq_unconditional_swap_atomicop_64_bits::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("CONFIG WRRD", "Starting Config WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 500); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass

//Testcase for AtomicOp Compare and swap
class atomic_op_compare_and_swap_test extends mem_pcie_combined_test;
  `uvm_component_utils(atomic_op_compare_and_swap_test)
  seq_compare_and_swap rc_seq,ep_seq;
  function new(string name="atomic_op_compare_and_swap_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = seq_compare_and_swap::type_id::create("rc_seq");
    ep_seq = seq_compare_and_swap::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("CONFIG WRRD", "Starting Config WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 5000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass


//Testcase for message without data
class msg_ptm_req_test extends mem_pcie_combined_test;
  `uvm_component_utils(msg_ptm_req_test)
  msg_ptm_req_seq rc_seq,ep_seq;
  function new(string name="msg_ptm_req_test",uvm_component parent=null);
    super.new(name,parent);
  endfunction
  task run_phase(uvm_phase phase);
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = msg_ptm_req_seq::type_id::create("rc_seq");
    ep_seq = msg_ptm_req_seq::type_id::create("ep_seq");
    phase.raise_objection(this);
    `uvm_info("CONFIG WRRD", "Starting Config WRRD sequences", UVM_MEDIUM)
	regseq.start(memenv.agent.sqr);
    fork
    begin 
    rc_seq.start(pcieenv.devices[0].sequencer);
    ep_seq.start(pcieenv.devices[1].sequencer);
    end
    join
    phase.phase_done.set_drain_time(this, 5000); // Match mem test's drain time
    phase.drop_objection(this);
   
    `uvm_info("MEM WRRD", "All sequences completed", UVM_MEDIUM)
  endtask
endclass







