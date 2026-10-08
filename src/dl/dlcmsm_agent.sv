class dlcmsm_agent extends uvm_agent;
  `uvm_component_utils(dlcmsm_agent)
  bit is_rc;
  dlcmsm_driver driver;
  dlcmsm_seqr sequencer;
  pcie_dl_cfg cfg;
  function new(string name, uvm_component parent);
    super.new(name, parent); 
  endfunction
  
  function void build_phase(uvm_phase phase);
    driver = dlcmsm_driver::type_id::create("driver", this);
    sequencer = dlcmsm_seqr::type_id::create("sequencer", this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass