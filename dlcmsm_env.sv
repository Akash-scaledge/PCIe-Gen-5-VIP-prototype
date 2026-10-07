class dlcmsm_env extends uvm_env;
  `uvm_component_utils(dlcmsm_env)
  
  pcie_dl_cfg cfg[];
  dlcmsm_agent device[];
  dlf_reg_adapter adapter;
  dlf_ext_cpb reg_model[];
  
  
  function new(string name, uvm_component parent); 
    super.new(name, parent); 
  endfunction
  
  function void build_phase(uvm_phase phase);
    string inst_name;
    reg_model= new[2];
    // Create arrays for 2 devices
    device = new[2];
    cfg = new[2];
    adapter=dlf_reg_adapter::type_id::create($sformatf("adapter"));
    
    foreach(device[i])begin

      reg_model[i]=dlf_ext_cpb::type_id::create($sformatf("reg_model_%0d",i));
      reg_model[i].build();
      reg_model[i].reset();
      reg_model[i].lock_model();
      reg_model[i].print();

      uvm_config_db#(dlf_ext_cpb)::set(uvm_root::get(), "*",$sformatf("reg_model_%0d",i), reg_model[i]);

    end
    
    
    
    // Configure each device with unique device_id
    foreach (device[i]) begin
      inst_name = $sformatf("device_%0d", i);////////////////////////////////(this device_0 or device_1 is used to set the vif from top module)
      
      // Create device-specific configuration
      cfg[i] = pcie_dl_cfg::type_id::create($sformatf("cfg_%0d", i), this);
      cfg[i].is_rc = (i == 0);        // Device 0 = Root Complex, Device 1 = End Point
      cfg[i].is_active = 1;
      cfg[i].name = (i == 0) ? "RC" : "EP";
      cfg[i].device_id = i;           // Critical: Set unique device_id for replay buffer separation
      cfg[i].dl_feature_exchange_enable = (i == 0) ? `RC_FEATURE_SUPPORT : `EP_FEATURE_SUPPORT;
      
      // Create the agent
      device[i] = dlcmsm_agent::type_id::create(inst_name, this);
      
      // Set device-specific configuration in config DB
      uvm_config_db#(pcie_dl_cfg)::set(this, $sformatf("%s.*", inst_name), "device_config", cfg[i]);
      
    end   
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    foreach(reg_model[i])begin
      reg_model[i].default_map.set_sequencer(.sequencer(device[i].sequencer),.adapter(adapter));
      reg_model[i].default_map.set_base_addr('h0);        
    end
  endfunction
    
endclass