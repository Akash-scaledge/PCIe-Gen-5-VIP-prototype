// Define a memory driver class extending from uvm_driver with mem_tx as the transaction type
class mem_drv extends uvm_driver #(mem_tx);

    // Register the component with the UVM factory
    `uvm_component_utils(mem_drv)

    // Use the macro to define the constructor
    `NEWCOMP;

    // Declare a virtual interface handle
    virtual mem_intf vif;

    // Build phase: retrieve the virtual interface from the UVM resource database
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
      uvm_config_db#(virtual mem_intf)::get(this,"","vif",vif);
    endfunction

    // Run phase: continuously fetch and drive transactions
    task run_phase(uvm_phase phase);
   
      wait(dlcmsm_rc_state==DL_ACTIVE);
 
      $display("#################MEM DRIVER##########################");
        forever begin
            // Get the next transaction from the sequencer
            seq_item_port.get_next_item(req);

            // Drive the transaction onto the interface
            drive_tx(req);
          //req.print();
            // Indicate that the transaction is done
            seq_item_port.item_done();
        end
    endtask

    // Task to drive a single transaction onto the DUT interface
    task drive_tx(mem_tx tx);
        // Wait for the interface clocking block
        @(vif.bfm_cb);

        // Drive address and control signals
        vif.bfm_cb.addr_i <= tx.addr_i;
        vif.bfm_cb.write_i <= tx.write_i;
        vif.bfm_cb.enable_i <= 1;

        // Wait for the DUT to be ready
        wait(vif.bfm_cb.ready_o <= 1);

        // Drive write data if it's a write operation
        if (tx.write_i == 1)
            vif.bfm_cb.wdata_i <= tx.data;
        else
            vif.bfm_cb.wdata_i <= 0;
      
        // Capture read data if it's a read operation
        if (tx.write_i == 0) begin
           @(vif.bfm_cb);
            tx.data = vif.bfm_cb.rdata_o;
        end

        // Deassert control signals after the transaction
        @(vif.bfm_cb);
        vif.bfm_cb.enable_i <= 0;
        vif.bfm_cb.addr_i <= 0;
        vif.bfm_cb.write_i <= 0;
    endtask

endclass
