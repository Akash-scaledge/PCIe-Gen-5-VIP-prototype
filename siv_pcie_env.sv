//--------------------------------------------------------------
// SIV PCIe Environment
// Contains RC and EP device agents
//--------------------------------------------------------------
class siv_pcie_env extends uvm_env;
  `uvm_component_utils(siv_pcie_env)

  // ------------------------------------------------------------
  // Device agents
  // ------------------------------------------------------------
  siv_pcie_device_agent rc_agent;
  siv_pcie_device_agent ep_agent;


  // ------------------------------------------------------------
  // MEMORY agent
  // ------------------------------------------------------------
  mem_agent magent;
  reg_sram_adapter madapter;
  RegModel_SFR mreg_model;
  // ------------------------------------------------------------
  // Unified configuration objects
  // ------------------------------------------------------------
  siv_pcie_cfg rc_cfg;
  siv_pcie_cfg ep_cfg;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // ------------------------------------------------------------
  // Build phase
  // ------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // ------------------------
    // Create RC configuration
    // ------------------------
    rc_cfg = siv_pcie_cfg::type_id::create("rc_cfg");
    rc_cfg.is_rc     = 1;
    rc_cfg.is_active = 1;
    rc_cfg.inst_name = "RC";
    rc_cfg.device_id = 0;
    rc_cfg.build();

    // ------------------------
    // Create EP configuration
    // ------------------------
    ep_cfg = siv_pcie_cfg::type_id::create("ep_cfg");
    ep_cfg.is_rc     = 0;
    ep_cfg.is_active = 1;
    ep_cfg.inst_name = "EP";
    ep_cfg.device_id = 1;
    ep_cfg.build();

    // ------------------------
    // Push configs down
    // ------------------------
    uvm_config_db#(siv_pcie_cfg)::set(
      this, "rc_agent*", "pcie_cfg", rc_cfg);

    uvm_config_db#(siv_pcie_cfg)::set(
      this, "ep_agent*", "pcie_cfg", ep_cfg);

    // ------------------------
    // Create device agents
    // ------------------------
    rc_agent = siv_pcie_device_agent::type_id::create("rc_agent", this);
    ep_agent = siv_pcie_device_agent::type_id::create("ep_agent", this);

    `uvm_info(get_type_name(),
      "PCIe environment built with RC and EP device agents",
      UVM_LOW)
     // Create the agent, adapter, and register model
    magent = mem_agent::type_id::create("magent", this);
    madapter = reg_sram_adapter::type_id::create("madapter");
    mreg_model = RegModel_SFR::type_id::create("mreg_model");
 
     // Initialize the register model
    mreg_model.build();        // Build the register model structure
    mreg_model.reset();        // Reset all registers to default values
    mreg_model.lock_model();   // Lock the model to prevent further structural changes
   // mreg_model.print();        // Print the register model for debug

    // Share the register model via the UVM config DB
    uvm_config_db#(RegModel_SFR)::set(uvm_root::get(), "*", "mreg_model", mreg_model);
  endfunction
 // Connect phase: link the register model to the sequencer and adapter
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Set the sequencer and adapter for the default register map
    mreg_model.default_map.set_sequencer(.sequencer(magent.sqr), .adapter(madapter));

    // Set the base address for the register map
    mreg_model.default_map.set_base_addr('h0);
  endfunction
endclass
//--------------------------------------------------------------
