// Define the memory environment class extending from uvm_env
class mem_env extends uvm_env;

  // Declare handles for agent, adapter, and register model
  mem_agent agent;
  reg_sram_adapter adapter;
  RegModel_SFR reg_model;

  // Register the component with the UVM factory
  `uvm_component_utils(mem_env)

  // Constructor
  function new(string name = "mem_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Build phase: create and configure sub-components
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create the agent, adapter, and register model
    agent = mem_agent::type_id::create("agent", this);
    adapter = reg_sram_adapter::type_id::create("adapter");
    reg_model = RegModel_SFR::type_id::create("reg_model");

    // Initialize the register model
    reg_model.build();        // Build the register model structure
    reg_model.reset();        // Reset all registers to default values
    reg_model.lock_model();   // Lock the model to prevent further structural changes
    reg_model.print();        // Print the register model for debug

    // Share the register model via the UVM config DB
    uvm_config_db#(RegModel_SFR)::set(uvm_root::get(), "*", "reg_model", reg_model);
  endfunction

  // Connect phase: link the register model to the sequencer and adapter
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Set the sequencer and adapter for the default register map
    reg_model.default_map.set_sequencer(.sequencer(agent.sqr), .adapter(adapter));

    // Set the base address for the register map
    reg_model.default_map.set_base_addr('h0);
  endfunction

endclass
