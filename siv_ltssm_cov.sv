//--------------------------------------------------------------
// SIV PCIe Verification Coverage (siv_pcie_pl_coverage)
//--------------------------------------------------------------
class siv_pcie_pl_coverage extends uvm_subscriber#(siv_ltssm_seq_item);
  `uvm_component_utils(siv_pcie_pl_coverage)
// ltssm_state_e ltssm_rc_state;
  siv_ltssm_seq_item tx;
    virtual siv_ltssm_intf    pl_intf;
  siv_ltssm_pl_cfg           pl_cfg=new();
 
  covergroup cg;
    DETECT_quite2DETECT_active: coverpoint ltssm_rc_state
    {
     bins dq_da = (DETECT_QUIET => DETECT_ACTIVE);  
    }
 
    DETECT_active2POLLING_active: coverpoint ltssm_rc_state
    {
     bins da_pa = (DETECT_ACTIVE => POLLING_ACTIVE);  
    }
    POLLING_active2POLLING_config: coverpoint ltssm_rc_state
    {
      bins pa_pc = (POLLING_ACTIVE => POLLING_CONFIG);  
    }
//     //timeout
//     POLLING_active2DETECT_QUIET: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (POLLING_ACTIVE => DETECT_QUIET);  
//     }
    POLLING_config2CONFIGURATION_linkwidthstart: coverpoint ltssm_rc_state
    {
      bins pa_pc = (POLLING_CONFIG => CONFIG_LINKWIDTH_START);  
    }
//     //timeout
//     POLLING_config2DETECT_QUIET: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (POLLING_CONFIG => DETECT_QUIET);  
//     }
    CONFIGURATION_linkwidthstart2CONFIGURATION_linkwidthaccept: coverpoint ltssm_rc_state
    {
      bins pa_pc = (CONFIG_LINKWIDTH_START => CONFIG_LINKWIDTH_ACCEPT);  
    }
//     //timeout
//     CONFIGURATION_linkwidthstart2DETECT_QIET: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (CONFIG_LINKWIDTH_START => DETECT_QUIET);  
//     }
    CONFIGURATION_linkwidthaccept2CONFIGURATION_lanenumwait: coverpoint ltssm_rc_state
    {
      bins pa_pc = (CONFIG_LINKWIDTH_ACCEPT => CONFIG_LANENUM_WAIT);  
    }
//     //timeout
//     CONFIGURATION_linkwidthaccept2DETECT_QUIET: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (CONFIG_LINKWIDTH_ACCEPT => DETECT_QUIET);  
//     }
    CONFIGURATION_lanenumwait2CONFIGURATION_lanenumaccept: coverpoint ltssm_rc_state
    {
      bins pa_pc = (CONFIG_LANENUM_WAIT => CONFIG_LANENUM_ACCEPT);  
    }
//     //timeout
//     CONFIGURATION_lanenumwait2DETECT_QUITE: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (CONFIG_LANENUM_WAIT => DETECT_QUIET);  
//     }
    CONFIGURATION_lanenumaccept2CONFIGURATION_complete: coverpoint ltssm_rc_state
    {
      bins pa_pc = (CONFIG_LANENUM_ACCEPT => CONFIG_COMPLETE);  
    }
//     //timeout
//     CONFIGURATION_lanenumaccept2DETECT_QUITE: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (CONFIG_LANENUM_ACCEPT => DETECT_QUIET);  
//     }
 
    CONFIGURATION_complete2CONFIGURATION_idle: coverpoint ltssm_rc_state
    {
      bins pa_pc = (CONFIG_COMPLETE => CONFIG_IDLE);  
    }
//     //timeout
//     CONFIGURATION_complete2DETECT_QUITE: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (CONFIG_COMPLETE => DETECT_QUIET);  
//     }
 
    CONFIGURATION_idle2L0: coverpoint ltssm_rc_state
    {
      bins pa_pc = (CONFIG_IDLE => L0);  
    }
//     //timeout
//     CONFIGURATION_idle2DETECT_QUITE: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (CONFIG_IDLE => DETECT_QUIET);  
//     }
    //L0 to Recovery_rcvrlock, L0 to L0s_entry, L0 to L1_entry, L0 to L2_idle 
    L02RECOVERY_RCVRLOCK: coverpoint ltssm_rc_state
    {
      bins pa_pc = (L0 => RECOVERY_RCVRLOCK);  
    }
//     L02L0s_ENTRY: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (L0 => L0S_ENTRY);  
//     }
//     L02L1_ENTRY: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (L0 => L1_ENTRY);  
//     }
//     L02L2_IDLE: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (L0 => L2_IDLE);  
//     }
//     RECOVERY_RCVRLOCK2RECOVERY_RCFG: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_RCVRLOCK => RECOVERY_RCFG);  
//     }
//     RECOVERY_RCVRLOCK2RECOVERY_SPEED: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_RCVRLOCK => RECOVERY_SPEED);  
//     }
//     //timeout
//     RECOVERY_RCVRLOCK2DETECT_QUIET: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_RCVRLOCK => DETECT_QUIET);  
//     }
//     RECOVERY_RCVRLOCK2RECOVERY_EQUALIZATION_PHASE_1: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_RCVRLOCK => RECOVERY_EQUALIZATION_PHASE_1);  
//     }
//     RECOVERY_EQUALIZATION_PHASE_12RECOVERY_EQUALIZATION_PHASE_2: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_EQUALIZATION_PHASE_1 => RECOVERY_EQUALIZATION_PHASE_2);  
//     }
//     RECOVERY_RCVRLOCK2CONFIG_LINKWIDTH_START: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_RCVRLOCK => CONFIG_LINKWIDTH_START);  
//     }
//     //timeout
//     RECOVERY_EQUALIZATION_PHASE_12RECOVERY_SPEED: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_EQUALIZATION_PHASE_1 => RECOVERY_SPEED);  
//     }
//     RECOVERY_EQUALIZATION_PHASE_22RECOVERY_EQUALIZATION_PHASE_3: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_EQUALIZATION_PHASE_2 => RECOVERY_EQUALIZATION_PHASE_3);  
//     }
//     //coefficients rejected
//     RECOVERY_EQUALIZATION_PHASE_22RECOVERY_EQUALIZATION_PHASE_2: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_EQUALIZATION_PHASE_2 => RECOVERY_EQUALIZATION_PHASE_2);  
//     }
//     //timeout
//     RECOVERY_EQUALIZATION_PHASE_22RECOVERY_SPEED: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_EQUALIZATION_PHASE_2 => RECOVERY_SPEED);  
//     }
//     RECOVERY_EQUALIZATION_PHASE_32RECOVERY_RCVRLOCK: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_EQUALIZATION_PHASE_3 => RECOVERY_RCVRLOCK);  
//     }
//     //timeout
//     RECOVERY_EQUALIZATION_PHASE_32RECOVERY_SPEED: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_EQUALIZATION_PHASE_3 => RECOVERY_SPEED);  
//     }
//     RECOVERY_RCFG2RECOVERY_IDLE: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_RCFG => RECOVERY_IDLE);  
//     }
//     RECOVERY_RCFG2RECOVERY_SPEED: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_RCFG => RECOVERY_SPEED);  
//     }
//     //timeout
//     RECOVERY_RCFG2DETECT_QUITE: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_RCFG => DETECT_QUIET);  
//     }
//     RECOVERY_SPEED2RECOVERY_RCVRLOCK: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_SPEED => RECOVERY_RCVRLOCK);  
//     }
//     RECOVERY_IDLE2L0: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_IDLE => L0);  
//     }
//     RECOVERY_IDLE2HOTRESET: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_IDLE => HOTRESET);  
//     }
//     RECOVERY_IDLE2DETECT_QUITE: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (RECOVERY_IDLE => DETECT_QUIET);  
//     }
//     L0S_ENTRY2L0S_IDLE: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (L0S_ENTRY => L0S_IDLE);  
//     }
//     L0S_IDLE2L0S_FTS: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (L0S_IDLE => L0S_FTS);  
//     }
//     L0S_IDLE2L0: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (L0S_FTS => L0);  
//     }
//     L0S_FTS2RECOVERY_RCVRLOCK: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (L0S_FTS => RECOVERY_RCVRLOCK);  
//     }
//     L1_ENTRY2L1_IDLE: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (L1_ENTRY => L1_IDLE);  
//     }
//     L1_IDLE2RECOVERY_RCVRLOCK: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (L1_IDLE => RECOVERY_RCVRLOCK);  
//     }
//     L2_IDLE2DTECT_QUITE: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (L2_IDLE => DETECT_QUIET);  
//     }
//     HOTRESET2DTECT_QUITE: coverpoint ltssm_rc_state
//     {
//       bins pa_pc = (HOTRESET => DETECT_QUIET);  
//     }

  endgroup
  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction  
    // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
   if(!uvm_config_db#(siv_ltssm_pl_cfg)::get(this, "", "pl_cfg", pl_cfg))
      `uvm_fatal("CFG_ERR", "Failed to get device configuration")
 
      if(uvm_config_db#(virtual siv_ltssm_intf)::get(this, "", pl_cfg.inst_name=="RC"? "rc_vif":"ep_vif", pl_intf)) 
        $display("%s - DRIVER.BUILD - interface recieved: %p",pl_cfg.inst_name,pl_intf);
    else 
      `uvm_fatal("VIF_ERR", "Failed to get virtual interface")
  endfunction
  task run_phase(uvm_phase phase);
    forever begin
    @(posedge pl_intf.clk);
          cg.sample();
    end
  endtask
 
  function void write(siv_ltssm_seq_item t);
    cg.sample();
  endfunction
endclass  