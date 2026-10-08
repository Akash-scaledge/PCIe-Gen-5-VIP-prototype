//--------------------------------------------------------------
// SIV PCIe Verification Environment (siv_pcie_tl_env)
//--------------------------------------------------------------
class siv_pcie_tl_env extends uvm_env;
  `uvm_component_utils(siv_pcie_tl_env)

  // Environment components
  siv_pcie_tl_agent devices[2];  // Index 0: RC, Index 1: EP
  siv_tl_cfg  device_cfgs[2];
 // event pktc_done;
  

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create and configure both agents
    foreach(devices[i]) begin
      string inst_name = (i == 0) ? "rc_agent" : "ep_agent";
      
      // Create configuration
      device_cfgs[i] = siv_tl_cfg::type_id::create($sformatf("cfg_%0d", i), this);
      device_cfgs[i].is_rc = (i == 0);
      device_cfgs[i].is_active = 1;
      device_cfgs[i].inst_name = (i == 0) ? "RC" : "EP";
      
      // Set configuration
      uvm_config_db#(siv_tl_cfg)::set(this, inst_name, "device_cfg", device_cfgs[i]);
     
      // Create agent
      devices[i] = siv_pcie_tl_agent::type_id::create(inst_name, this);
    end
  endfunction

  // End of Elaboration Phase
  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
endclass