// SIV PCIe Agent (siv_ltssm_agent)
//--------------------------------------------------------------
class siv_ltssm_agent extends uvm_agent;
  `uvm_component_utils(siv_ltssm_agent)

  // Agent components
  siv_ltssm_driver    driver;
  siv_ltssm_sequencer sequencer;
  siv_ltssm_pl_cfg      pl_cfg;
    siv_pcie_pl_coverage  coverage;
  // Agent type 
  bit is_rc;

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create sub-components
    driver = siv_ltssm_driver::type_id::create("driver", this);
    sequencer = siv_ltssm_sequencer::type_id::create("sequencer", this);
    coverage=siv_pcie_pl_coverage::type_id::create("coverage",this);
    
    // Get configuration
    if(uvm_config_db#(siv_ltssm_pl_cfg)::get(this, "", "pl_cfg", pl_cfg)) begin
      `uvm_info("CFG", 
               $sformatf("Received config - Type: %s, Name: %s",
               pl_cfg.is_rc ? "Root Complex" : "Endpoint",
               pl_cfg.inst_name), 
               UVM_MEDIUM)
      
      // Pass config to driver
      uvm_config_db#(siv_ltssm_pl_cfg)::set(this, "*", "pl_cfg", pl_cfg);
    end
    else begin
      `uvm_fatal("CFG_ERR", "Failed to get device configuration")
    end
  endfunction

  // Connect Phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

//--------------------------------------------------------------