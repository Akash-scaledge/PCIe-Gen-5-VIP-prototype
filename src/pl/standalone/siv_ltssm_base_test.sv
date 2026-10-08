
//--------------------------------------------------------------
// SIV PCIe Base Test (siv_ltssm_base_test)
//--------------------------------------------------------------
class siv_ltssm_base_test extends uvm_test;
  `uvm_component_utils(siv_ltssm_base_test)
  
  // Test components
  siv_ltssm_env       env;
  siv_ltssm_seq    rc_seq,ep_seq;

  // Constructor
  function new(string name = "siv_ltssm_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = siv_ltssm_env::type_id::create("env", this);
  endfunction

  // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences
    rc_seq = siv_ltssm_seq::type_id::create("rc_seq");
    ep_seq = siv_ltssm_seq::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
  
  function void final_phase(uvm_phase phase);
      $display("coverage percentage of state detect quite to detect active RC = %0d",env.devices[0].coverage.cg.DETECT_quite2DETECT_active.get_coverage());
      $display("coverage percentage of state detect quite to detect active EP = %0d",env.devices[1].coverage.cg.DETECT_quite2DETECT_active.get_coverage());
    $display("coverage percentage of all = %0d",$get_coverage());
  endfunction
endclass



//--------------------------------------------------------------------------------------------------------
// SIV PCIe Config_lanenum_Accept_to_Config_Compl Test (siv_Config_lanenum_Accept_to_Config_Compl_Test)
//--------------------------------------------------------------------------------------------------------
              
class siv_Config_lanenum_Accept_to_Config_Compl_Test extends siv_ltssm_base_test;
  `uvm_component_utils(siv_Config_lanenum_Accept_to_Config_Compl_Test)

 siv_Config_lanenum_Accept_to_Config_Compl_Seq    rc_seq,ep_seq;

  // Constructor
  function new(string name = "siv_Config_lanenum_Accept_to_Config_Compl_Test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences
    rc_seq = siv_Config_lanenum_Accept_to_Config_Compl_Seq::type_id::create("rc_seq");
    ep_seq = siv_Config_lanenum_Accept_to_Config_Compl_Seq::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
  
  
endclass

//--------------------------------------------------------------------------------------------------------
// SIV PCIe Config_lanenum_Accept_to_Detect Test (siv_Config_lanenum_Accept_to_Detect_Test)
//--------------------------------------------------------------------------------------------------------

class siv_Config_lanenum_Accept_to_Detect_Test extends siv_ltssm_base_test;
  `uvm_component_utils(siv_Config_lanenum_Accept_to_Detect_Test)

  siv_Config_lanenum_Accept_to_Detect_Seq    rc_seq,ep_seq;

  // Constructor
  function new(string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences
    rc_seq = siv_Config_lanenum_Accept_to_Detect_Seq::type_id::create("rc_seq");
    ep_seq =  siv_Config_lanenum_Accept_to_Detect_Seq::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
  
  
endclass


//-------------------------------------------------------------
// SIV PCIe Equlization mode Test (siv_ltssm_eq_mode_Test)
//-------------------------------------------------------------


class siv_ltssm_eq_mode_Test extends siv_ltssm_base_test;
  `uvm_component_utils(siv_ltssm_eq_mode_Test)

  siv_ltssm_seq_eq_mode    rc_seq,ep_seq;

  // Constructor
  function new(string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences
    rc_seq = siv_ltssm_seq_eq_mode::type_id::create("rc_seq");
    ep_seq =  siv_ltssm_seq_eq_mode::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
endclass


//--------------------------------------------------------------------------------------------------------
// SIV PCIe Config_lanenum_Accept_to_Detect Test (siv_ltssm_config_lanewidth_change_test)
//--------------------------------------------------------------------------------------------------------

class siv_ltssm_config_lanewidth_change_test extends siv_ltssm_base_test;
  `uvm_component_utils(siv_ltssm_config_lanewidth_change_test)

  siv_ltssm_config_lanewidth_change    rc_seq,ep_seq;

  // Constructor
  function new(string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences
    rc_seq = siv_ltssm_config_lanewidth_change::type_id::create("rc_seq");
    ep_seq =  siv_ltssm_config_lanewidth_change::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
endclass

//--------------------------------------------------------------------------------------------------------
// SIV PCIe Speed change Test (siv_ltssm_speeed_change_32GT_Test)
//--------------------------------------------------------------------------------------------------------
class siv_ltssm_speeed_change_32GT_Test extends siv_ltssm_base_test;
  `uvm_component_utils(siv_ltssm_speeed_change_32GT_Test
)

  siv_ltssm_seq_speeed_change_32GT
    rc_seq,ep_seq;

  // Constructor
  function new(string name = "my_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences
    rc_seq = siv_ltssm_seq_speeed_change_32GT
::type_id::create("rc_seq");
    ep_seq =  siv_ltssm_seq_speeed_change_32GT
::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
endclass




//---------------------------------------------------------
// SIV PCIe COM corruption Test (siv_test_sym_0_error)
//---------------------------------------------------------
 
class siv_test_sym_0_error extends uvm_test;
  `uvm_component_utils(siv_test_sym_0_error)
  // Constructor
  function new(string name = "siv_test_sym_0_error", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  siv_ltssm_env       env;
  siv_ltssm_seq    rc_seq,ep_seq;
  modify_symbol_0_cb ei_sym_0;
  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = siv_ltssm_env::type_id::create("env", this);
    ei_sym_0 = modify_symbol_0_cb::type_id::create("ei_sym_0", this);
  endfunction
  // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    uvm_callbacks#(siv_ltssm_driver,siv_ltssm_ts_pkt_modify_callback)::add(env.devices[0].driver,ei_sym_0);
    uvm_callbacks#(siv_ltssm_driver,siv_ltssm_ts_pkt_modify_callback)::add(env.devices[1].driver,ei_sym_0);
    // Create sequences
    rc_seq = siv_ltssm_seq::type_id::create("rc_seq");
    ep_seq = siv_ltssm_seq::type_id::create("ep_seq");

    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)

    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join

    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
endclass




//--------------------------------------------------------------------------------------
// SIV PCIe TS1 and TS2  corruption Test (siv_Corrupt_ts1_to_ts2_polling_active_Test)
//--------------------------------------------------------------------------------------

class siv_Corrupt_ts1_to_ts2_polling_active_Test extends siv_ltssm_base_test;
   `uvm_component_utils(siv_Corrupt_ts1_to_ts2_polling_active_Test)

  Corrupt_ts1_to_ts2_polling_active_seq rc_seq,ep_seq;

  // Constructor
  function new(string name = "siv_Corrupt_ts1_to_ts2_polling_active_Test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences
    rc_seq = Corrupt_ts1_to_ts2_polling_active_seq::type_id::create("rc_seq");
    ep_seq =  Corrupt_ts1_to_ts2_polling_active_seq::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
endclass




//--------------------------------------------------------------------------------------
// SIV PCIe Rejection of coeficient during equalization Test (siv_reject_coeff_test)
//--------------------------------------------------------------------------------------

class siv_reject_coeff_test extends siv_ltssm_base_test;
  `uvm_component_utils(siv_reject_coeff_test)

  reject_coeff_seq   rc_seq,ep_seq;

  // Constructor
  function new(string name = "siv_reject_coeff_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences
    rc_seq = reject_coeff_seq::type_id::create("rc_seq");
    ep_seq =  reject_coeff_seq::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
  
  
endclass

//--------------------------------------------------------------------------------------
// SIV PCIe L0s state transition Test (siv_ltssm_test_L0s)
//--------------------------------------------------------------------------------------

class siv_ltssm_test_L0s extends uvm_test;
  `uvm_component_utils(siv_ltssm_test_L0s)
  
  // Test components
  siv_ltssm_env       env;
  siv_ltssm_seq_L0s    rc_seq,ep_seq;

  // Constructor
  function new(string name = "siv_ltssm_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = siv_ltssm_env::type_id::create("env", this);
  endfunction

   // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences
    rc_seq = siv_ltssm_seq_L0s::type_id::create("rc_seq");
    ep_seq = siv_ltssm_seq_L0s::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
endclass

//--------------------------------------------------------------------------------------
// SIV PCIe L1 state transition Test (siv_ltssm_test_L1)
//--------------------------------------------------------------------------------------

class siv_ltssm_test_L1 extends uvm_test;
  `uvm_component_utils(siv_ltssm_test_L1)
  
  // Test components
  siv_ltssm_env       env;
  siv_ltssm_seq_L1    rc_seq,ep_seq;

  // Constructor
  function new(string name = "siv_ltssm_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = siv_ltssm_env::type_id::create("env", this);
  endfunction

   // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences
    rc_seq = siv_ltssm_seq_L1::type_id::create("rc_seq");
    ep_seq = siv_ltssm_seq_L1::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
endclass



//--------------------------------------------------------------------------------------
// SIV PCIe L2 state transition test (siv_ltssm_test_L2)
//--------------------------------------------------------------------------------------

class siv_ltssm_test_L2 extends siv_ltssm_base_test;
  `uvm_component_utils(siv_ltssm_test_L2)

  siv_ltssm_seq_L2    rc_seq,ep_seq;

  // Constructor
  function new(string name = "siv_ltssm_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction



   // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences 
    rc_seq = siv_ltssm_seq_L2::type_id::create("rc_seq");
    ep_seq = siv_ltssm_seq_L2::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
endclass

//----------------------------------------------------------------------------------------------------
// SIV PCIe Timeout condition checking polling active  (siv_test_detect_from_polling_active)
//----------------------------------------------------------------------------------------------------

class siv_test_detect_from_polling_active extends siv_ltssm_base_test;
  `uvm_component_utils(siv_test_detect_from_polling_active)

  siv_detect_from_polling_active_seq    rc_seq,ep_seq;

  // Constructor
  function new(string name = "siv_test_detect_from_polling_active", uvm_component parent = null);
    super.new(name, parent);
  endfunction


  // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences
    rc_seq = siv_detect_from_polling_active_seq::type_id::create("rc_seq");
    ep_seq = siv_detect_from_polling_active_seq::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
endclass


//----------------------------------------------------------------------------------------------------
// SIV PCIe Disable state transition  (siv_ltssm_disable_test)
//----------------------------------------------------------------------------------------------------

class siv_ltssm_disable_test extends uvm_test;
  `uvm_component_utils(siv_ltssm_disable_test)
  
  // Test components
  siv_ltssm_env       env;
  siv_ltssm_seq_disable    rc_seq,ep_seq;

  // Constructor
  function new(string name = "siv_ltssm_disable_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = siv_ltssm_env::type_id::create("env", this);
  endfunction

  // Run Phase
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    // Create sequences
    rc_seq = siv_ltssm_seq_disable::type_id::create("rc_seq");
    ep_seq = siv_ltssm_seq_disable::type_id::create("ep_seq");
    
    `uvm_info("TEST_START", "Starting RC and EP sequences", UVM_MEDIUM)
    
    // Run sequences in parallel
    fork
      rc_seq.start(env.devices[0].sequencer);
      ep_seq.start(env.devices[1].sequencer);
    join
    
    phase.drop_objection(this);
    `uvm_info("TEST_END", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask
  
  function void final_phase(uvm_phase phase);
      $display("coverage percentage of state detect quite to detect active RC = %0d",env.devices[0].coverage.cg.DETECT_quite2DETECT_active.get_coverage());
      $display("coverage percentage of state detect quite to detect active EP = %0d",env.devices[1].coverage.cg.DETECT_quite2DETECT_active.get_coverage());
    $display("coverage percentage of all = %0d",$get_coverage());
  endfunction
endclass
