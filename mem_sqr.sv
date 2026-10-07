// Define a memory sequencer class extending from uvm_sequencer with mem_tx as the transaction type
class mem_sqr extends uvm_sequencer#(mem_tx);

    // Register the component with the UVM factory
    `uvm_component_utils(mem_sqr)

    // Use macro to define constructor
    `NEWCOMP;

    // Build phase: currently no additional setup needed
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

endclass
