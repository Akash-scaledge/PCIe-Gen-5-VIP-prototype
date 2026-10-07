//--------------------------------------------------------------
// SIV PCIe Sequencer (siv_ltssm_sequencer)
//--------------------------------------------------------------
class siv_ltssm_sequencer extends uvm_sequencer #(siv_ltssm_seq_item);
  `uvm_component_utils(siv_ltssm_sequencer)
  // Constructor
  function new(string name = "siv_ltssm_sequencer", 
               uvm_component parent = null);
    super.new(name, parent);
    `uvm_info("SEQ_INIT", $sformatf("Initialized PCIe sequencer: %s", name), UVM_MEDIUM)
  endfunction
endclass