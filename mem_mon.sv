// Define a memory monitor class extending from uvm_monitor
class mem_mon extends uvm_monitor;

    // Register the component with the UVM factory
    `uvm_component_utils(mem_mon)

    // Use macro to define constructor
    `NEWCOMP;

    // Declare a transaction handle
    mem_tx tx;

    // Declare an analysis port to send observed transactions
    uvm_analysis_port #(mem_tx) ap_port;

    // Declare a virtual interface handle
    virtual mem_intf vif;

    // Build phase: retrieve virtual interface and create analysis port
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get the virtual interface from the resource database
      uvm_config_db#(virtual mem_intf)::get(this,"","vif",vif);

        // Create the analysis port
        ap_port = new("ap_port", this);
    endfunction

    // Run phase: continuously monitor the interface for valid transactions
    task run_phase(uvm_phase phase);
        forever begin
            // Wait for a clocking event on the monitor clocking block
            @(vif.mon_cb);

            // Check if a valid transaction is occurring
            if (vif.mon_cb.enable_i == 1 && vif.mon_cb.ready_o == 1) begin
                // Create a new transaction object
                tx = new("tx");

                // Capture signal values into the transaction
                tx.addr_i = vif.mon_cb.addr_i;
                tx.write_i = vif.mon_cb.write_i;
                tx.data = vif.mon_cb.write_i ? vif.mon_cb.wdata_i : vif.mon_cb.rdata_o;

                // Send the transaction through the analysis port
                ap_port.write(tx);
            end
        end
    endtask

endclass
