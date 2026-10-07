//--------------------------------------------------------------
// SIV PCIe Verification Environment (siv_ltssm_env)
//--------------------------------------------------------------
class siv_ltssm_env extends uvm_env;
  `uvm_component_utils(siv_ltssm_env)

  // Environment components
  siv_ltssm_agent devices[2];  // Index 0: RC, Index 1: EP
  siv_ltssm_pl_cfg  pl_cfg[2];

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create and configure both agents
    foreach(devices[i]) begin
      string inst_name = (i == 0) ? "rc_pl_agent" : "ep_pl_agent";
      
      // Create configuration
      pl_cfg[i] = siv_ltssm_pl_cfg::type_id::create($sformatf("cfg_%0d", i), this);
      pl_cfg[i].is_rc = (i == 0);
      pl_cfg[i].is_active = 1;
      pl_cfg[i].inst_name = (i == 0) ? "RC" : "EP";
      
      // Set configuration
      uvm_config_db#(siv_ltssm_pl_cfg)::set(this, inst_name, "pl_cfg", pl_cfg[i]);
      
      // Create agent
      devices[i] = siv_ltssm_agent::type_id::create(inst_name, this);
    end
  endfunction

  // End of Elaboration Phase
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
endclass

//--------------------------------------------------------------