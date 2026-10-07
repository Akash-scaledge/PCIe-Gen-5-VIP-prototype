// Define a register sequence class extending from uvm_sequence with mem_tx as the transaction type
class reg_seq extends uvm_sequence#(mem_tx);

  // Declare transaction handles and register model
  mem_tx tx, txQ[$];            // Transaction and transaction queue
  mem_tx req;                   // Request transaction
  RegModel_SFR reg_model;       // Handle to the register model
  uvm_status_e status;          // Status of register operations
  uvm_reg_data_t read_data;     // Variable to store read data

  // Register the sequence with the UVM factory
  `uvm_object_utils(reg_seq)

  // Constructor
  function new (string name = "reg_seq");
    super.new(name);
  endfunction

  // Body task: main sequence logic
  task body();
   int mps;
    // Print debug message
    `uvm_info(get_type_name(), "Reg seq: Inside Body", UVM_LOW);

    // Retrieve the register model from the config DB
    if (!uvm_config_db#(RegModel_SFR)::get(uvm_root::get(), "", "mreg_model", reg_model))
      `uvm_fatal(get_type_name(), "reg_model is not set at top level");
       reg_model.mod_reg.cfg_reg.reset();
    reg_model.mod_reg.cfg_reg.write(status,'h8086,UVM_FRONTDOOR, .parent(this));
     reg_model.mod_reg.dfg_reg.reset();
    reg_model.mod_reg.dfg_reg.write(status,'h10D3,UVM_FRONTDOOR, .parent(this));
    
    //reg_model.mod_pcie_cap_reg.dev_ctrl_reg.reset();
    reg_model.mod_pcie_cap_reg.dev_ctrl_reg.max_payload_size.set('b101);
    reg_model.mod_pcie_cap_reg.dev_ctrl_reg.write(status,reg_model.mod_pcie_cap_reg.dev_ctrl_reg.get(), .parent(this));
      reg_model.mod_pcie_cap_reg.dev_ctrl_reg.read(status, read_data);

    reg_model.vc_reg_block.port_vc_cap_1.reset();
    reg_model.vc_reg_block.port_vc_cap_1.write(status,'h0007,UVM_FRONTDOOR, .parent(this));
    
    reg_model.vc_reg_block.vc_resource_0_cap.reset();
    reg_model.vc_reg_block.vc_resource_0_cap.write(status,'h0001,UVM_FRONTDOOR, .parent(this));
    reg_model.vc_reg_block.vc_resource_0_ctrl.reset();
    reg_model.vc_reg_block.vc_resource_0_ctrl.write(status,32'h80000001,UVM_FRONTDOOR, .parent(this));
    
    reg_model.vc_reg_block.vc_resource_1_cap.reset();
    reg_model.vc_reg_block.vc_resource_1_cap.write(status,'h0001,UVM_FRONTDOOR, .parent(this));
    
    reg_model.vc_reg_block.vc_resource_2_cap.reset();
    reg_model.vc_reg_block.vc_resource_2_cap.write(status,'h0001,UVM_FRONTDOOR, .parent(this));
    
    reg_model.vc_reg_block.vc_resource_3_cap.reset();
    reg_model.vc_reg_block.vc_resource_3_cap.write(status,'h0001,UVM_FRONTDOOR, .parent(this));
    
    reg_model.vc_reg_block.vc_resource_4_cap.reset();
    reg_model.vc_reg_block.vc_resource_4_cap.write(status,'h0001,UVM_FRONTDOOR, .parent(this));
    
    reg_model.vc_reg_block.vc_resource_5_cap.reset();
    reg_model.vc_reg_block.vc_resource_5_cap.write(status,'h0001,UVM_FRONTDOOR, .parent(this));
    
    reg_model.vc_reg_block.vc_resource_6_cap.reset();
    reg_model.vc_reg_block.vc_resource_6_cap.write(status,'h0001,UVM_FRONTDOOR, .parent(this));
    
    reg_model.vc_reg_block.vc_resource_7_cap.reset();
    reg_model.vc_reg_block.vc_resource_7_cap.write(status,'h0001,UVM_FRONTDOOR, .parent(this));
    //reg_model.mod_pcie_cap_reg.link_ctrl_reg.reset();
    // Set a field value in cfg_reg
//     reg_model.mod_reg.cfg_reg.vendor_id_fields.set(16'haabb);

    // Write the entire cfg_reg
//     reg_model.mod_reg.cfg_reg.write(status, reg_model.mod_reg.cfg_reg.get(), .parent(this));

    // Read back the cfg_reg
//     reg_model.mod_reg.cfg_reg.read(status, read_data);

    // Write a value to dfg_reg
//     reg_model.mod_reg.dfg_reg.write(status, 16'haabb);

    // Enable memory space in cmd_reg
//     reg_model.mod_reg.cmd_reg.memory_space_enable.set(1);

    // Write the updated cmd_reg
//     reg_model.mod_reg.cmd_reg.write(status, reg_model.mod_reg.cmd_reg.get(), .parent(this));

    
/*    // Enable memory space in cmd_reg
    //reg_model.mod_reg.bar0.base_addr.set(20'habacd);
    reg_model.mod_reg.bar0.write(status,32'haaaabbbb);

    // Write the updated cmd_reg
//     reg_model.mod_reg.bar0.write(status, reg_model.mod_reg.bar0.get(), .parent(this));
    
     // Read back the cfg_reg
//     #5;
    reg_model.mod_reg.bar0.read(status, read_data);*/
    // Write a value to bar0
//reg_model.mod_reg.bar0.write(status, 32'haaaabbbb, .parent(this));

// Optionally predict the value in RAL model
// reg_model.mod_reg.bar0.predict(32'haaaabbbb);  // software-side sync

// OR mirror it from DUT (with or without checking)
// reg_model.mod_reg.bar0.mirror(status, UVM_CHECK);  // sync + validate

// Read back to verify (optional)
//reg_model.mod_reg.bar0.read(status, read_data);
//`uvm_info(get_type_name(), $sformatf("BAR0 read value: 0x%0h", read_data), UVM_LOW);
    
  endtask

endclass
