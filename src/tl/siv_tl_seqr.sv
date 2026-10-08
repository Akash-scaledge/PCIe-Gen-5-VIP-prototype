//--------------------------------------------------------------
// SIV PCIe Sequencer (siv_pcie_tl_sequencer)
//--------------------------------------------------------------
class siv_pcie_tl_sequencer extends uvm_sequencer #(siv_pcie_tl_sequence_items);
  `uvm_component_utils(siv_pcie_tl_sequencer)
  // Constructor
  function new(string name = "siv_pcie_tl_sequencer", 
               uvm_component parent = null);
    super.new(name, parent);
    `uvm_info("SEQ_INIT", $sformatf("Initialized PCIe sequencer: %s", name), UVM_MEDIUM)
    endfunction
endclass