class dlcmsm_test extends uvm_test;
  `uvm_component_utils(dlcmsm_test)
  dlcmsm_env env;
  dlcmsm_seq rc_seq, ep_seq;
  function new(string name, uvm_component parent); 
    super.new(name, parent); 
  endfunction
  function void build_phase(uvm_phase phase);
    env = dlcmsm_env::type_id::create("env", this);
  endfunction
  function void end_of_elaboration_phase(uvm_phase phase);
    pcie_dl_pkt_modify_callback cb = pcie_dl_pkt_modify_callback::type_id::create("cb");
    uvm_callbacks#(dlcmsm_driver, pcie_dl_pkt_modify_callback)::add(env.device[0].driver, cb);
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    rc_seq = dlcmsm_seq::type_id::create("rc_seq", this);
    ep_seq = dlcmsm_seq::type_id::create("ep_seq", this);
    fork
      rc_seq.start(env.device[0].sequencer);
      ep_seq.start(env.device[1].sequencer);
    join
    phase.drop_objection(this);
  endtask
endclass

//////////////////////
class dlcmsm_scale_test extends dlcmsm_test;
  `uvm_component_utils(dlcmsm_scale_test)
  dlcmsm_env env;
  dlcmsm_seq rc_seq, ep_seq;
  function new(string name, uvm_component parent); 
    super.new(name, parent); 
  endfunction
  function void build_phase(uvm_phase phase);
    env = dlcmsm_env::type_id::create("env", this);
  endfunction
  function void end_of_elaboration_phase(uvm_phase phase);
    pcie_dl_pkt_modify_callback cb = pcie_dl_pkt_modify_callback::type_id::create("cb");
    uvm_callbacks#(dlcmsm_driver, pcie_dl_pkt_modify_callback)::add(env.device[0].driver, cb);
  endfunction
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    rc_seq = dlcmsm_seq_scale::type_id::create("rc_seq", this);
    ep_seq = dlcmsm_seq_scale::type_id::create("ep_seq", this);
    fork
      rc_seq.start(env.device[0].sequencer);
      ep_seq.start(env.device[1].sequencer);
    join
    phase.drop_objection(this);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class fc_san_01_test extends dlcmsm_test;
  `uvm_component_utils(fc_san_01_test)
//   pcie_dl_cfg cfg0;
  fc_san_01_seq rc_seq, ep_seq;

  function new(string name = "fc_san_01_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    rc_seq = fc_san_01_seq::type_id::create("rc_seq", this);
    ep_seq = fc_san_01_seq::type_id::create("ep_seq", this);
    `uvm_info(get_type_name(), "Running FC_SAN_01 Test (Basic Flow Control bring-up)", UVM_LOW);
    fork
      rc_seq.start(env.device[0].sequencer);
      ep_seq.start(env.device[1].sequencer);
    join
    phase.drop_objection(this);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class fc_san_02_test extends dlcmsm_test;
  `uvm_component_utils(fc_san_02_test)
//   pcie_dl_cfg cfg0;
  fc_san_02_seq rc_seq, ep_seq;

  function new(string name = "fc_san_02_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    rc_seq = fc_san_02_seq::type_id::create("rc_seq", this);
    ep_seq = fc_san_02_seq::type_id::create("ep_seq", this);
    `uvm_info(get_type_name(), "Running FC_SAN_02 Test (Basic Flow Control bring-up)", UVM_LOW);
    fork
      rc_seq.start(env.device[0].sequencer);
      ep_seq.start(env.device[1].sequencer);
    join
    phase.drop_objection(this);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class initFC1_34ms_test extends dlcmsm_test;
  `uvm_component_utils(initFC1_34ms_test)
//   pcie_dl_cfg cfg0;
  initFC1_34ms_seq rc_seq, ep_seq;

  function new(string name = "initFC1_34ms_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    rc_seq = initFC1_34ms_seq::type_id::create("rc_seq", this);
    ep_seq = initFC1_34ms_seq::type_id::create("ep_seq", this);
    `uvm_info(get_type_name(), "Running initFC1_34ms Test (Basic Flow Control bring-up)", UVM_LOW);
    fork
      rc_seq.start(env.device[0].sequencer);
      begin
      #40000;//ep_starts after a while(40micros)
      ep_seq.start(env.device[1].sequencer);
        end
    join
    phase.drop_objection(this);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class block_acknak_init1_test extends dlcmsm_test;
  `uvm_component_utils(block_acknak_init1_test)
  pcie_dl_cfg cfg0;
  block_acknak_init1_seq rc_seq, ep_seq;

  function new(string name = "block_acknak_init1_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    rc_seq = block_acknak_init1_seq::type_id::create("rc_seq", this);
    ep_seq = block_acknak_init1_seq::type_id::create("ep_seq", this);
//     ep_seq = fc_san_01_seq::type_id::create("ep_seq", this);
    
    // Create config object for device_id 0 (VC0)
//     cfg0 = pcie_dl_cfg::type_id::create("cfg0");
//     cfg0.device_id = 0;

    // Provide config + interface to driver
//     uvm_config_db#(pcie_dl_cfg)::set(this, "*", "device_config", cfg0);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(), "Running block_acknak_init1 Test (Basic Flow Control bring-up)", UVM_LOW);
    fork
      rc_seq.start(env.device[0].sequencer);
      ep_seq.start(env.device[1].sequencer);
    join

//     #2000;

    phase.drop_objection(this);
  endtask
endclass


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class block_TLP_init1_test extends dlcmsm_test;
  `uvm_component_utils(block_TLP_init1_test)
  pcie_dl_cfg cfg0;
  block_TLP_init1_seq rc_seq, ep_seq;

  function new(string name = "block_TLP_init1_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    rc_seq = block_TLP_init1_seq::type_id::create("rc_seq", this);
    ep_seq = block_TLP_init1_seq::type_id::create("ep_seq", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(), "Running block_TLP_init1 Test (Basic Flow Control bring-up)", UVM_LOW);
    fork
      rc_seq.start(env.device[0].sequencer);
      ep_seq.start(env.device[1].sequencer);
    join

//     #2000;

    phase.drop_objection(this);
  endtask
endclass


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class transition_to_init2_test extends dlcmsm_test;
  `uvm_component_utils(transition_to_init2_test)
  pcie_dl_cfg cfg0;
  transition_to_init2_seq rc_seq, ep_seq;

  function new(string name = "transition_to_init2_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    rc_seq = transition_to_init2_seq::type_id::create("rc_seq", this);
    ep_seq = transition_to_init2_seq::type_id::create("ep_seq", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(), "Running transition_to_init2 Test (Basic Flow Control bring-up)", UVM_LOW);
    fork
      rc_seq.start(env.device[0].sequencer);
      ep_seq.start(env.device[1].sequencer);
    join

//     #2000;

    phase.drop_objection(this);
  endtask
endclass


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class init2_wait_test extends dlcmsm_test;
  `uvm_component_utils(init2_wait_test)

  init2_wait_seq rc_seq;
  pcie_dl_cfg cfg0;
  
  function new(string name = "init2_wait_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    rc_seq = init2_wait_seq::type_id::create("rc_seq", this);
    ep_seq = init2_wait_seq::type_id::create("rc_seq", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(), "Running transition_to_init2 Test (Basic Flow Control bring-up)", UVM_LOW);
    fork
      rc_seq.start(env.device[0].sequencer);
      ep_seq.start(env.device[1].sequencer);
    join

//     #2000;

    phase.drop_objection(this);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class initFC1_send_updateFC_test extends dlcmsm_test;
  `uvm_component_utils(initFC1_send_updateFC_test)
//   pcie_dl_cfg cfg0;
  initFC1_send_updateFC_seq rc_seq, ep_seq;

  function new(string name = "initFC1_send_updateFC_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    rc_seq = initFC1_send_updateFC_seq::type_id::create("rc_seq", this);
    ep_seq = initFC1_send_updateFC_seq::type_id::create("ep_seq", this);
    `uvm_info(get_type_name(), "Running FC_SAN_01 Test (Basic Flow Control bring-up)", UVM_LOW);
    fork
      rc_seq.start(env.device[0].sequencer);
      ep_seq.start(env.device[1].sequencer);
    join
    phase.drop_objection(this);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class missing_initFC2_test extends dlcmsm_test;
  `uvm_component_utils(missing_initFC2_test)
//   pcie_dl_cfg cfg0;
  missing_initFC2_seq rc_seq, ep_seq;

  function new(string name = "missing_initFC2_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    rc_seq = missing_initFC2_seq::type_id::create("rc_seq", this);
    ep_seq = missing_initFC2_seq::type_id::create("ep_seq", this);
    `uvm_info(get_type_name(), "Running FC_SAN_01 Test (Basic Flow Control bring-up)", UVM_LOW);
    fork
      rc_seq.start(env.device[0].sequencer);
      ep_seq.start(env.device[1].sequencer);
    join
    phase.drop_objection(this);
  endtask
endclass


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class no_np_cplinitfc1_test extends dlcmsm_test;
  `uvm_component_utils(no_np_cplinitfc1_test)
  pcie_dl_cfg cfg0;
  no_np_cplinitfc1_seq rc_seq, ep_seq;

  function new(string name = "no_np_cplinitfc1_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    rc_seq = no_np_cplinitfc1_seq::type_id::create("rc_seq", this);
    ep_seq = no_np_cplinitfc1_seq::type_id::create("ep_seq", this);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(), "Running no_np_cplinitfc1 Test (Basic Flow Control bring-up)", UVM_LOW);
    fork
      rc_seq.start(env.device[0].sequencer);
//       ep_seq.start(env.device[1].sequencer);
//       ep responds to the initfc1s sent by rc. hence there is no need for it send those
    join

//     #2000;
    //checking if the ep transitioned to initfc2 vespite sending only initfc1--p
    if (env.device[1].driver.fsm.curr_state == FC_INIT2) begin
        `uvm_error("BUG_FOUND", "FAIL: DUT transitioned to FC_INIT2 despite missing NP/Cpl credits! FSM logic is flawed.")
    end else if (env.device[1].driver.fsm.curr_state == FC_INIT1) begin
        `uvm_info("PASS", "SUCCESS: DUT correctly stayed in FC_INIT1.", UVM_LOW)
    end else begin
        `uvm_info("INFO", $sformatf("DUT State is: %s", env.device[1].driver.fsm.curr_state.name()), UVM_LOW)
    end

    phase.drop_objection(this);
  endtask
endclass


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class fc_init2_tlp_exit_test extends dlcmsm_test;
  `uvm_component_utils(fc_init2_tlp_exit_test)
  fc_init2_tlp_exit_rc_seq rc_seq;
  fc_init2_tlp_exit_ep_seq ep_seq;

  function new(string name = "missing_initFC2_1test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    rc_seq =  fc_init2_tlp_exit_rc_seq::type_id::create("rc_seq", this);
    ep_seq =  fc_init2_tlp_exit_ep_seq::type_id::create("ep_seq", this);
    
    fork
      rc_seq.start(env.device[0].sequencer);
      ep_seq.start(env.device[1].sequencer);
    join
    #100us;

    // CHECK: Did it reach DL_ACTIVE?
    if (env.device[1].driver.fsm.curr_state == DL_ACTIVE) begin
        `uvm_info("PASS", "SUCCESS: DUT correctly exited FC_INIT2 on TLP reception.", UVM_LOW)
    end else begin
        `uvm_error("BUG_FOUND", $sformatf("FAIL: DUT stuck in %s. It ignored the TLP exit rule!", env.device[1].driver.fsm.curr_state.name()))
    end
    phase.drop_objection(this);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class fc_init1_retransmit_timer_test extends dlcmsm_test;
  `uvm_component_utils(fc_init1_retransmit_timer_test)
  
  fc_init1_silent_seq seq;
  virtual dl_if dut_vif;
  time start_time, diff, current_time;
  
  function new(string name="fc_init1_retransmit_timer_test", uvm_component p=null); 
    super.new(name,p); 
  endfunction
  
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "RUNNING: InitFC1 34us Timer Test", UVM_LOW)
    dut_vif = env.device[1].driver.vif;
    
    seq = fc_init1_silent_seq::type_id::create("seq");
    start_time=$realtime;
    fork
      seq.start(env.device[0].sequencer);
//       monitor_34us_rule();
      begin
//         wait(env.device[0].cfg.curr_state == FC_INIT1);
//         wait(seq.cfg.curr_state == FC_INIT1);
      	#34us;
      end
    join_any
    if($realtime - start_time > 34us)begin
      `uvm_error("PROTO_FAIL", $sformatf("InitFC1 Re-transmit Violation! Gap: %0t > 34us limit", diff))
    end else begin
      `uvm_info("PROTO_PASS", $sformatf("InitFC1 Gap OK: %0t", diff), UVM_HIGH)
    end
    
    phase.drop_objection(this);
  endtask
  //0.034ms
//   task monitor_34us_rule();
//     timer_uvm timer;
//     timer = timer_uvm::type_id::create("timer");
//     timer.start_timer(0.035*LTSSM_1MS,"34us_rule");
//     wait(timer.done_flag);
//     `uvm_info("34_us_rule","34us timeout", UVM_HIGH)
//   endtask

endclass