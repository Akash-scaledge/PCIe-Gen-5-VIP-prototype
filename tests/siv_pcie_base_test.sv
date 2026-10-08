//--------------------------------------------------------------
// Base PCIe Test
//--------------------------------------------------------------
class siv_pcie_base_test extends uvm_test;
  `uvm_component_utils(siv_pcie_base_test)

  // ------------------------------------------------------------
  // Environment
  // ------------------------------------------------------------
  siv_pcie_env env;

  // ------------------------------------------------------------
  // Sequences
  // ------------------------------------------------------------
  mem_wr_rd_seq  rc_seq;
  mem_wr_rd_seq  ep_seq;
  reg_seq            regseq;

  dlcmsm_seq     rc_dl_seq;
  dlcmsm_seq     ep_dl_seq;

  siv_ltssm_seq  rc_pl_seq;
  siv_ltssm_seq  ep_pl_seq;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(string name="siv_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // ------------------------------------------------------------
  // Build phase
  // ------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = siv_pcie_env::type_id::create("env", this);

    // Create sequences
    rc_seq    = mem_wr_rd_seq ::type_id::create("rc_seq");
    ep_seq    = mem_wr_rd_seq ::type_id::create("ep_seq");

    rc_dl_seq = dlcmsm_seq    ::type_id::create("rc_dl_seq");
    ep_dl_seq = dlcmsm_seq    ::type_id::create("ep_dl_seq");

    rc_pl_seq = siv_ltssm_seq ::type_id::create("rc_pl_seq");
    ep_pl_seq = siv_ltssm_seq ::type_id::create("ep_pl_seq");
  endfunction

  // ----------------------------------------
  // Task to Run TL sequences
  // ----------------------------------------
  task run_TL(uvm_phase phase);
    // Create all sequences
    regseq = reg_seq::type_id::create("regseq");
    rc_seq = mem_wr_rd_seq::type_id::create("rc_seq");
    ep_seq = mem_wr_rd_seq::type_id::create("ep_seq");
    phase.raise_objection(this);

    regseq.start(env.magent.sqr);
    fork
      begin 
        rc_seq.start(env.rc_agent.tl_agent.sequencer);
        ep_seq.start(env.ep_agent.tl_agent.sequencer);
      end
    join

    phase.drop_objection(this);   

  endtask


  // ----------------------------------------
  // Task to Run DL sequences
  // ----------------------------------------
  task run_DL(uvm_phase phase);

    rc_dl_seq = dlcmsm_seq::type_id::create("rc_dl_seq", this);
    ep_dl_seq = dlcmsm_seq::type_id::create("ep_dl_seq", this);

    fork
      rc_dl_seq.start(env.rc_agent.dl_agent.sequencer);
      ep_dl_seq.start(env.ep_agent.dl_agent.sequencer);
    join

  endtask

  // ----------------------------------------
  // Task to Run PL sequences
  // ----------------------------------------

  task run_PL(uvm_phase phase);
    phase.raise_objection(this);
    // Create sequences
    rc_pl_seq = siv_ltssm_seq::type_id::create("rc_pl_seq");
    ep_pl_seq = siv_ltssm_seq::type_id::create("ep_pl_seq");
    `uvm_info("TEST_START_pl", "Starting RC and EP sequences", UVM_MEDIUM)
    // Run sequences in parallel
    fork
      rc_pl_seq.start(env.rc_agent.pl_agent.sequencer);
      ep_pl_seq.start(env.ep_agent.pl_agent.sequencer);
    join
    phase.drop_objection(this);
    phase.phase_done.set_drain_time(this, 500000);
    `uvm_info("TEST_END_pl", "All sequences completed", UVM_MEDIUM)
    `uvm_info("LTSSM_FINISHED", $sformatf("\n****************\nCurrent State for both RC and EP is now L0\n****************\n"), UVM_MEDIUM)
  endtask

  // Run phase: launch all three "primary" sequences in parallel

  // ----------------------------------------
  // Run ALL layer sequences
  // ----------------------------------------
  task run_phase(uvm_phase phase);
    fork
      run_TL(phase);
      run_DL(phase);
      run_PL(phase);
    join
  endtask

endclass
//--------------------------------------------------------------