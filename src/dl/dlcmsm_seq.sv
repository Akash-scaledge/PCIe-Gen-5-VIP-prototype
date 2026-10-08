////////////////////////////////////////////////////
// SEQUENCE 
////////////////////////////////////////////////////

class dlcmsm_seq extends uvm_sequence #(pcie_dl_seq_item);
  bit [11:0] current_seq; 
  static bit [1:0] tlp_sent_flags = 2'b00;
  `uvm_object_utils(dlcmsm_seq)
  dlcmsm_fsm dlcmsm;
  pcie_dl_cfg cfg;
  virtual dl_if vif;
  bit [7:0] fc1_ordered_types[3] = '{INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0};
  bit [7:0] fc2_ordered_types[3] = '{INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0};
  bit [7:0] updatefc_ordered_types[3] = '{UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0};
  static bit [11:0] shared_seq_num = 0;
  int unsigned my_hdr_limit;
  int unsigned my_data_limit;
  dlf_ext_cpb reg_model;uvm_status_e status;

  function new(string name = "dlcmsm_seq");
    super.new(name);
    dlcmsm = dlcmsm_fsm::type_id::create("dlcmsm");
  endfunction

  task pre_start();
    if (!uvm_config_db#(pcie_dl_cfg)::get(m_sequencer, "", "device_config", cfg))
      `uvm_fatal(get_type_name(), "Cannot get device_config from config DB")
      if(!uvm_config_db#(dlf_ext_cpb)::get(uvm_root::get(),"",$sformatf("reg_model_%0d",cfg.device_id), reg_model))
        `uvm_fatal(get_type_name(), "Cannot get REG_MODEL from config DB")
      endtask
  task pre_body();
    uvm_config_db#(bit)::set(null,"*","DL_SEQ_STATUS",0);
  endtask
  task post_body();
    uvm_config_db#(bit)::set(null,"*","DL_SEQ_STATUS",1);
  endtask
   task body();
    my_hdr_limit = 32;   // Start with some initial capacity
    my_data_limit = 256;
    reg_model.local_f_reg.write(status,32'h8000_0001,UVM_FRONTDOOR,.parent(this));    
    if(status!=UVM_IS_OK)
      `uvm_error(get_type_name(),"REGISTER WRITE FAIL")
//       repeat(3)
//       `uvm_do_with(req,{req.dllps_f_pkt.dllp_type == DATA_LINK_FEATURE; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;})

    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;
                         req.dllps_pkt.HdrFC == my_hdr_limit;
                         req.dllps_pkt.DataFC == my_data_limit;
                        })
    end
    wait(cfg.curr_state == FC_INIT2);
    foreach (fc2_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc2_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;
                         req.dllps_pkt.HdrFC == my_hdr_limit;
                         req.dllps_pkt.DataFC == my_data_limit;
                        })
    end
    wait(cfg.curr_state == DL_ACTIVE);
    for (int i = 0; i < `NUM_TLPS_TO_SEND; i++) begin
          foreach (updatefc_ordered_types[i]) begin
            `uvm_do_with(req, { req.dllps_pkt.dllp_type == updatefc_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;
                              req.dllps_pkt.HdrFC == my_hdr_limit;
                         req.dllps_pkt.DataFC == my_data_limit;
                              req.tlps_pkt.length inside {[1:32]};
                              })
            $display("triggered %t",$realtime);
          end
      current_seq = shared_seq_num;
      repeat(2)
      `uvm_do_with(req, { req.is_tlp == 1; req.seq_num == current_seq; })
      tlp_sent_flags[cfg.device_id] = 1;
      if (cfg.device_id == 1) begin
        wait (tlp_sent_flags == 2'b11);
        shared_seq_num++;
        tlp_sent_flags = 2'b00;
      end
      my_hdr_limit = (my_hdr_limit + 1) % 256; 
      my_data_limit = (my_data_limit + 8) % 4096;
      wait (tlp_sent_flags[cfg.device_id] == 0);
    end
  endtask

endclass
/////////////////////////////////////////
class dlcmsm_ep_seq extends dlcmsm_seq;//do not send tlps for ep
  bit [11:0] current_seq; 
  static bit [1:0] tlp_sent_flags = 2'b00;
  `uvm_object_utils(dlcmsm_ep_seq)
  dlcmsm_fsm dlcmsm;
  pcie_dl_cfg cfg;
  virtual dl_if vif;
  bit [7:0] fc1_ordered_types[3] = '{INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0};
  bit [7:0] fc2_ordered_types[3] = '{INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0};
  bit [7:0] updatefc_ordered_types[3] = '{UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0};
  static bit [11:0] shared_seq_num = 0;
  int unsigned my_hdr_limit;
  int unsigned my_data_limit;
  dlf_ext_cpb reg_model;uvm_status_e status;
 
  function new(string name = "dlcmsm_ep_seq");
    super.new(name);
    dlcmsm = dlcmsm_fsm::type_id::create("dlcmsm");
  endfunction
 
  task pre_start();
    if (!uvm_config_db#(pcie_dl_cfg)::get(m_sequencer, "", "device_config", cfg))
      `uvm_fatal(get_type_name(), "Cannot get device_config from config DB")
      if(!uvm_config_db#(dlf_ext_cpb)::get(uvm_root::get(),"",$sformatf("reg_model_%0d",cfg.device_id), reg_model))
        `uvm_fatal(get_type_name(), "Cannot get REG_MODEL from config DB")
      endtask
  task pre_body();
    uvm_config_db#(bit)::set(null,"*","DL_SEQ_STATUS",0);
  endtask
  task post_body();
   
  endtask
   task body();
    my_hdr_limit = 32;   // Start with some initial capacity
    my_data_limit = 256;
    reg_model.local_f_reg.write(status,32'h8000_0001,UVM_FRONTDOOR,.parent(this));    
    if(status!=UVM_IS_OK)
      `uvm_error(get_type_name(),"REGISTER WRITE FAIL")
      repeat(3)
      `uvm_do_with(req,{req.dllps_f_pkt.dllp_type == DATA_LINK_FEATURE; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;})
 
    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;
                         req.dllps_pkt.HdrFC == my_hdr_limit;
                         req.dllps_pkt.DataFC == my_data_limit;
                        })
    end
    wait(cfg.curr_state == FC_INIT2);
    foreach (fc2_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc2_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;
                         req.dllps_pkt.HdrFC == my_hdr_limit;
                         req.dllps_pkt.DataFC == my_data_limit;
                        })
    end
    wait(cfg.curr_state == DL_ACTIVE);
    for (int i = 0; i < `NUM_TLPS_TO_SEND; i++) begin
          foreach (updatefc_ordered_types[i]) begin
            `uvm_do_with(req, { req.dllps_pkt.dllp_type == updatefc_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;
                              req.dllps_pkt.HdrFC == my_hdr_limit;
                         req.dllps_pkt.DataFC == my_data_limit;
                              req.tlps_pkt.length inside {[1:32]};
                              })
            $display("triggered %t",$realtime);
          end
      current_seq = shared_seq_num;
//       `uvm_do_with(req, { req.is_tlp == 1; req.seq_num == current_seq; })
//       tlp_sent_flags[cfg.device_id] = 0;
//       if (cfg.device_id == 1) begin
//         wait (tlp_sent_flags == 2'b11);
//         shared_seq_num++;
//         tlp_sent_flags = 2'b00;
//       end
//       my_hdr_limit = (my_hdr_limit + 1) % 256; 
//       my_data_limit = (my_data_limit + 8) % 4096;
//       wait (tlp_sent_flags[cfg.device_id] == 0);
    end
  endtask
 
endclass
////////////////////////////////
class dlcmsm_seq_scale extends dlcmsm_seq;
  bit [11:0] current_seq; 
  static bit [1:0] tlp_sent_flags = 2'b00;
  `uvm_object_utils(dlcmsm_seq_scale)
  dlcmsm_fsm dlcmsm;
  pcie_dl_cfg cfg;
  virtual dl_if vif;
  bit [7:0] fc1_ordered_types[3] = '{INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0};
  bit [7:0] fc2_ordered_types[3] = '{INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0};
  bit [7:0] updatefc_ordered_types[3] = '{UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0};
  static bit [11:0] shared_seq_num = 0;
  int unsigned my_hdr_limit;
  int unsigned my_data_limit;
  dlf_ext_cpb reg_model;uvm_status_e status;

  function new(string name = "dlcmsm_seq");
    super.new(name);
    dlcmsm = dlcmsm_fsm::type_id::create("dlcmsm");
  endfunction

  task pre_start();
    if (!uvm_config_db#(pcie_dl_cfg)::get(m_sequencer, "", "device_config", cfg))
      `uvm_fatal(get_type_name(), "Cannot get device_config from config DB")
      if(!uvm_config_db#(dlf_ext_cpb)::get(uvm_root::get(),"",$sformatf("reg_model_%0d",cfg.device_id), reg_model))
        `uvm_fatal(get_type_name(), "Cannot get REG_MODEL from config DB")
      endtask

   task body();
    my_hdr_limit = 32;   // Start with some initial capacity
    my_data_limit = 256;
    reg_model.local_f_reg.write(status,32'h8000_0001,UVM_FRONTDOOR,.parent(this));    
    if(status!=UVM_IS_OK)
      `uvm_error(get_type_name(),"REGISTER WRITE FAIL")
      repeat(3)
      `uvm_do_with(req,{req.dllps_f_pkt.dllp_type == DATA_LINK_FEATURE; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;})

    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;
                         req.dllps_pkt.HdrFC == my_hdr_limit;
                         req.dllps_pkt.DataFC == my_data_limit;
                         req.dllps_pkt.rsvd1 == 3;
                         req.dllps_pkt.rsvd2 == 3;
                         req.scl_en==1;
                        })
    end
    wait(cfg.curr_state == FC_INIT2);
    foreach (fc2_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc2_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;
                         req.dllps_pkt.HdrFC == my_hdr_limit;
                         req.dllps_pkt.DataFC == my_data_limit;
                         req.dllps_pkt.rsvd1 == 3;
                         req.dllps_pkt.rsvd2 == 3;
                         req.scl_en==1;
                        })
    end
    wait(cfg.curr_state == DL_ACTIVE);
    for (int i = 0; i < `NUM_TLPS_TO_SEND; i++) begin
          foreach (updatefc_ordered_types[i]) begin
            `uvm_do_with(req, { req.dllps_pkt.dllp_type == updatefc_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;
                              req.dllps_pkt.HdrFC == my_hdr_limit;
                         req.dllps_pkt.DataFC == my_data_limit;
                              req.tlps_pkt.length inside {[1:32]};
                               req.dllps_pkt.rsvd1 == 3;
                         req.dllps_pkt.rsvd2 == 3;
                         req.scl_en==1;
                              })
            $display("triggered %t",$realtime);
          end
      current_seq = shared_seq_num;
      `uvm_do_with(req, { req.is_tlp == 1; req.seq_num == current_seq; })
      tlp_sent_flags[cfg.device_id] = 1;
      if (cfg.device_id == 1) begin
        wait (tlp_sent_flags == 2'b11);
        shared_seq_num++;
        tlp_sent_flags = 2'b00;
      end
      my_hdr_limit = (my_hdr_limit + 1) % 256; 
      my_data_limit = (my_data_limit + 8) % 4096;
      wait (tlp_sent_flags[cfg.device_id] == 0);
    end
  endtask

endclass
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class fc_san_01_seq extends dlcmsm_seq;
  `uvm_object_utils(fc_san_01_seq)
  function new(string name = "fc_san_01_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(), "FC_SAN_01: Starting Flow Control Initialization Sanity Test (DL_INACTIVE to DL_INIT to FC_INIT1)", UVM_LOW);

    `uvm_info(get_type_name(), "FC_SAN_01: FSM reached DL_INIT", UVM_LOW);

    // Wait for FC_INIT1
    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
    `uvm_info(get_type_name(), "FC_SAN_01: FSM reached FC_INIT1", UVM_LOW);
    `uvm_info(get_type_name(), "FC_SAN_01: COMPLETED successfully!", UVM_LOW);
  endtask

endclass
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class fc_san_02_seq extends dlcmsm_seq;
  `uvm_object_utils(fc_san_02_seq)
  function new(string name = "fc_san_02_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(), "FC_SAN_02: Starting Flow Control Initialization Sanity Test (DL_INACTIVE to DL_INIT to FC_INIT1)", UVM_LOW);

    // Wait for driver’s FSM to reach DL_INIT
    wait(cfg.curr_state == DL_INIT);
    `uvm_info(get_type_name(), "FC_SAN_02: FSM reached DL_INIT ##################################################", UVM_NONE)

    // Wait for FC_INIT1
    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
    `uvm_info(get_type_name(), "FC_SAN_02: FSM reached FC_INIT1", UVM_LOW);
    `uvm_info(get_type_name(), "FC_SAN_02: COMPLETED successfully!", UVM_LOW);
  endtask

endclass
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//The three InitFC1 DLLPs must be transmitted at least once every 34 μs. Pg. 216
class initFC1_34ms_seq extends dlcmsm_seq;
  `uvm_object_utils(initFC1_34ms_seq)
  function new(string name = "initFC1_34ms_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(), "initFC1_34ms: Starting Flow Control Initialization Sanity Test (DL_INACTIVE to DL_INIT to FC_INIT1)", UVM_LOW);

    `uvm_info(get_type_name(), "initFC1_34ms: FSM reached DL_INIT", UVM_LOW);

    // Wait for FC_INIT1
    wait(cfg.curr_state == FC_INIT1);
    repeat(3)begin
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
      
    end
    #33100; //1microsecond is 1000ns//testing 34micros 
    end
    `uvm_info(get_type_name(), "initFC1_34ms: FSM reached FC_INIT1", UVM_LOW);
    `uvm_info(get_type_name(), "initFC1_34ms: COMPLETED successfully!", UVM_LOW);
  endtask

endclass
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class block_acknak_init1_seq extends dlcmsm_seq;
  `uvm_object_utils(block_acknak_init1_seq)
//   pcie_dl_cfg cfg;

  function new(string name = "block_acknak_init1_seq");
    super.new(name);
  endfunction
  
  task pre_start();
    super.pre_start();
  endtask

  task body();
    `uvm_info(get_type_name(), "Starting Flow Control Test (Block ACK_NAK during FC_INIT1)", UVM_LOW);

    // Wait for driver’s FSM to reach DL_INIT
//     wait(cfg.curr_state == DL_INIT);
    `uvm_info(get_type_name(), "FSM reached DL_INIT", UVM_LOW);

    // Wait for FC_INIT1
    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == ACK_DLLP_TYPE; })
    end
    `uvm_info(get_type_name(), "FSM reached FC_INIT1", UVM_LOW);
    `uvm_info(get_type_name(), "COMPLETED successfully!", UVM_LOW);
  endtask

endclass
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class block_TLP_init1_seq extends dlcmsm_seq;
  `uvm_object_utils(block_TLP_init1_seq)

  function new(string name = "block_TLP_init1_seq");
    super.new(name);
  endfunction
  
  task pre_start();
    super.pre_start();
  endtask

  task body();
    `uvm_info(get_type_name(), "Starting Flow Control Test (Block ACK_NAK during FC_INIT1)", UVM_LOW);
    `uvm_info(get_type_name(), "FSM reached DL_INIT", UVM_LOW);
    // Wait for FC_INIT1
    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, {
        req.is_tlp == 1;
      })
    end
    `uvm_info(get_type_name(), "FSM reached FC_INIT1", UVM_LOW);
    `uvm_info(get_type_name(), "COMPLETED successfully!", UVM_LOW);
  endtask
endclass
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class transition_to_init2_seq extends dlcmsm_seq;
  `uvm_object_utils(transition_to_init2_seq)

  function new(string name = "transition_to_init2_seq");
    super.new(name);
  endfunction
  
  task pre_start();
    super.pre_start();
  endtask

  task body();
    `uvm_info(get_type_name(), "Starting Flow Control Test (Block ACK_NAK during FC_INIT1)", UVM_LOW);
    `uvm_info(get_type_name(), "FSM reached DL_INIT", UVM_LOW);
    // Wait for FC_INIT1
    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
    wait(cfg.curr_state == FC_INIT2);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc2_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
    foreach (updatefc_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == updatefc_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
//     foreach (fc2_ordered_types[i]) begin
//       `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc2_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
//     end
    `uvm_info(get_type_name(), "FSM reached FC_INIT1", UVM_LOW);
    `uvm_info(get_type_name(), "COMPLETED successfully!", UVM_LOW);
  endtask
endclass
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


class init2_wait_seq extends dlcmsm_seq;
  `uvm_object_utils(init2_wait_seq)

  function new(string name = "init2_wait_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(),
              "init2_wait: Verifying FI2 -> DL_ACTIVE transition trigger",
              UVM_LOW);

    wait(cfg.curr_state == FC_INIT1);
    `uvm_info(get_type_name(),
              "FSM reached FC_INIT1 -> good", UVM_LOW);

    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end

    wait(cfg.curr_state == FC_INIT2);
    `uvm_info(get_type_name(),
              "FSM reached FC_INIT2 -> waiting for FI2 trigger",
              UVM_LOW);

    // Ensure FSM does NOT auto-transition
    // give enough cycles to prove stable state
    #2000;
    if (cfg.curr_state != FC_INIT2)
      `uvm_error(get_type_name(),
                 "FSM incorrectly left FC_INIT2 BEFORE FI2 event!");

    foreach (fc2_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc2_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end

    wait(cfg.curr_state == DL_ACTIVE);
    `uvm_info(get_type_name(),
              "FSM successfully transitioned to DL_ACTIVE ONLY after FI2 -> PASS",
              UVM_LOW);
  endtask
endclass
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//sending updateFCs in initFC1 state, hence the state doesnt transition to initFC2 state
class initFC1_send_updateFC_seq extends dlcmsm_seq;
  `uvm_object_utils(initFC1_send_updateFC_seq)
  function new(string name = "initFC1_send_updateFC_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(), "initFC1_send_updateFC: Starting Flow Control Initialization Sanity Test (DL_INACTIVE to DL_INIT to FC_INIT1)", UVM_LOW);

    `uvm_info(get_type_name(), "initFC1_send_updateFC: FSM reached DL_INIT", UVM_LOW);

    // Wait for FC_INIT1
    wait(cfg.curr_state == FC_INIT1);
    foreach (updatefc_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == updatefc_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
    `uvm_info(get_type_name(), "initFC1_send_updateFC: FSM reached FC_INIT1", UVM_LOW);
//     wait(cfg.curr_state == FC_INIT2);
    #1000;
//     `uvm_info(get_type_name(), "initFC1_send_updateFC: FSM reached FC_INIT2", UVM_LOW);
    `uvm_info(get_type_name(), "initFC1_send_updateFC: COMPLETED successfully!", UVM_LOW);
  endtask

endclass

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///Dont senD cpl_initfc2, check if it transitions to DL_Active
class missing_initFC2_seq extends dlcmsm_seq;
  `uvm_object_utils(missing_initFC2_seq)
  function new(string name = "missing_initFC2_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info(get_type_name(), "missing_initFC2: Starting Flow Control Initialization Sanity Test (DL_INACTIVE to DL_INIT to FC_INIT1)", UVM_LOW);

    `uvm_info(get_type_name(), "missing_initFC2: FSM reached DL_INIT", UVM_LOW);
    // Wait for FC_INIT1
    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == updatefc_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
    `uvm_info(get_type_name(), "missing_initFC2: FSM reached FC_INIT1", UVM_LOW);
    wait(cfg.curr_state == FC_INIT2);
    foreach (fc2_ordered_types[i]) begin
      if(i==2) break;
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == updatefc_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
    wait(cfg.curr_state == DL_ACTIVE);
    `uvm_info(get_type_name(), "missing_initFC2: FSM reached DL_Active", UVM_LOW);
    `uvm_info(get_type_name(), "missing_initFC2: COMPLETED successfully!", UVM_LOW);
  endtask

endclass

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//reverse fc2, fc2, upfc

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class no_np_cplinitfc1_seq extends dlcmsm_seq;
  `uvm_object_utils(no_np_cplinitfc1_seq)

  function new(string name = "no_np_cplinitfc1_seq");
    super.new(name);
  endfunction
  
  task pre_start();
    super.pre_start();
  endtask

  task body();
    `uvm_info(get_type_name(), "Starting Flow Control Test (Block ACK_NAK during FC_INIT1)", UVM_LOW);
    `uvm_info(get_type_name(), "FSM reached DL_INIT", UVM_LOW);
    // Wait for FC_INIT1
    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == INITFC1_P_VC0; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
    wait(cfg.curr_state == FC_INIT2);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == INITFC2_P_VC0; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
    foreach (updatefc_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == updatefc_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
//     foreach (fc2_ordered_types[i]) begin
//       `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc2_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
//     end
    `uvm_info(get_type_name(), "FSM reached FC_INIT1", UVM_LOW);
    `uvm_info(get_type_name(), "COMPLETED successfully!", UVM_LOW);
  endtask
endclass

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// The "Fast Exit" Test (FC_INIT2 Logic)
class fc_init2_tlp_exit_rc_seq extends dlcmsm_seq;
  `uvm_object_utils(fc_init2_tlp_exit_rc_seq)

  function new(string name = "fc_init2_tlp_exit_rc_seq");
    super.new(name);
  endfunction
  
  task pre_start();
    super.pre_start();
  endtask

  task body();
    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
    wait(cfg.curr_state == FC_INIT2);
    foreach (fc2_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc2_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
    wait(cfg.curr_state == DL_ACTIVE);
    req = pcie_dl_seq_item::type_id::create("req");
    start_item(req);
    req.is_tlp = 1;
    req.tlps_pkt.length = 1;    req.tlps_pkt.Address = 32'h1000;
    req.payload = new[1];
    req.payload[0] = 32'hAABBCCEE;
    finish_item(req);
  endtask
endclass
class fc_init2_tlp_exit_ep_seq extends dlcmsm_seq;
  `uvm_object_utils(fc_init2_tlp_exit_ep_seq)

  function new(string name = "fc_init2_tlp_exit_ep_seq");
    super.new(name);
  endfunction
  
  task pre_start();
    super.pre_start();
  endtask

  task body();
    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
//     wait(cfg.curr_state == FC_INIT2);
//     #10;
//     foreach (fc2_ordered_types[i]) begin
//       `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc2_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
//     end
    wait(cfg.curr_state==DL_ACTIVE);
    `uvm_info(get_type_name(), "FSM reached DL_Active ######################################################################################################", UVM_LOW);
    req = pcie_dl_seq_item::type_id::create("req");
    start_item(req);
    req.is_tlp = 1;
    req.tlps_pkt.length = 1;    req.tlps_pkt.Address = 32'h1000;
    req.payload = new[1];
    req.payload[0] = 32'hEEBBCCAA;
    finish_item(req);
  endtask
endclass





// class fc_init2_tlp_exit_seq extends dlcmsm_seq;
//   `uvm_object_utils(fc_init2_tlp_exit_seq)

//   function new(string name = "fc_init2_tlp_exit_seq");
//     super.new(name);
//   endfunction
  
//   task pre_start();
//     super.pre_start();
//   endtask

//   task body();
//     `uvm_info(get_type_name(), "Starting Flow Control Test (Block ACK_NAK during FC_INIT1)", UVM_LOW);
//     `uvm_info(get_type_name(), "FSM reached DL_INIT", UVM_LOW);
//     // Wait for FC_INIT1
//     wait(cfg.curr_state == FC_INIT1);
//     foreach (fc1_ordered_types[i]) begin
//       `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
//     end
//     wait(cfg.curr_state == FC_INIT2);
//     req = pcie_dl_seq_item::type_id::create("req");
//     start_item(req);
//     req.is_tlp = 1;
//     req.tlps_pkt.length = 1;    req.tlps_pkt.Address = 32'h1000;
//     req.payload = new[1];
//     req.payload[0] = 32'hAABBCCEE;
//     finish_item(req);

//     `uvm_info(get_type_name(), "FSM reached FC_INIT1", UVM_LOW);
//     `uvm_info(get_type_name(), "COMPLETED successfully!", UVM_LOW);
//   endtask
// endclass

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class fc_init1_silent_seq extends dlcmsm_seq;
  `uvm_object_utils(fc_init1_silent_seq)

  function new(string name="fc_init1_silent_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("SEQ", "Step 1: RC entering SILENT mode during FC_INIT1...", UVM_LOW)
    wait(cfg.curr_state == FC_INIT1);
//     foreach (fc1_ordered_types[i]) begin
//       `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
//     end
    // The RC Driver relies on this sequence to provide packets.
    // By just waiting, we ensure the RC transmits nothing.
    // We wait long enough (200us) to capture multiple 34us cycles from the DUT.
    #36us;
    //send after the timeout of 34 us
    foreach (fc1_ordered_types[i]) begin
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0; })
    end
    
    `uvm_info("SEQ", "Silent period finished.", UVM_LOW)
  endtask
endclass


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

