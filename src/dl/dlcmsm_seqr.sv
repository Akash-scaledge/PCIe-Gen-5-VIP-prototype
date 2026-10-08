////////////////////////////////////////////////////
// SEQUENCER 
////////////////////////////////////////////////////

class dlcmsm_seqr extends uvm_sequencer #(pcie_dl_seq_item);
  `uvm_component_utils(dlcmsm_seqr)
  function new(string name, uvm_component parent); 
    super.new(name, parent); 
  endfunction
endclass