// Define a class 'mem_agent' that extends from 'uvm_agent'
class mem_agent extends uvm_agent;

    // Declare handles for driver, sequencer, monitor, and coverage components
    mem_drv drv;
    mem_sqr sqr;
    mem_mon mon;
   // mem_cov cov;

    // Register the component with the UVM factory
    `uvm_component_utils(mem_agent)

    // Macro for constructor definition (assumed to be user-defined)
    `NEWCOMP;

    // Build phase: create instances of sub-components
    function void build_phase(uvm_phase phase);
        super.build_phase(phase); // Call parent class build_phase

        // Create instances of driver, sequencer, monitor, and coverage
        drv = mem_drv::type_id::create("drv", this);
        sqr = mem_sqr::type_id::create("sqr", this);
        mon = mem_mon::type_id::create("mon", this);
        //cov = mem_cov::type_id::create("cov", this);
    endfunction

    // Connect phase: connect ports between components
    function void connect_phase(uvm_phase phase);
        // Connect the driver's sequence item port to the sequencer's export
        drv.seq_item_port.connect(sqr.seq_item_export);

        // Connect the monitor's analysis port to the coverage component's analysis export
       // mon.ap_port.connect(cov.analysis_export);
    endfunction

endclass
