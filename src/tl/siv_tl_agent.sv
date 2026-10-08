//--------------------------------------------------------------
// SIV PCIe Agent (siv_pcie_agent)
//--------------------------------------------------------------
class siv_pcie_tl_agent extends uvm_agent ;
  `uvm_component_utils(siv_pcie_tl_agent)

  // Agent components
  siv_pcie_tl_driver    driver;
  siv_pcie_tl_sequencer sequencer;
  siv_tl_cfg      device_cfg;
  siv_tl_mon mon;
  // Agent type 
  bit is_rc;
  //uvm_event pktc_done;
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build Phase
    function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create sub-components
    driver = siv_pcie_tl_driver::type_id::create("driver", this);
    sequencer = siv_pcie_tl_sequencer::type_id::create("sequencer", this);
    mon=siv_tl_mon::type_id::create("mon",this);  
   // pktc_done = new("pktc_done");
   // uvm_config_db#(uvm_event)::set(this, "driver", "pktc_done", pktc_done);

    
    // Get configuration
      if(uvm_config_db#(siv_tl_cfg)::get(this, "", "device_cfg", device_cfg)) begin
      `uvm_info("CFG_LOAD", 
               $sformatf("Received config - Type: %s, Name: %s",
               device_cfg.is_rc ? "Root Complex" : "Endpoint",
               device_cfg.inst_name), 
               UVM_MEDIUM)
      
      // Pass config to driver
        uvm_config_db#(siv_tl_cfg)::set(this, "*", "device_cfg", device_cfg);
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