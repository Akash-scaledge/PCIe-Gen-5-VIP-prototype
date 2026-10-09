////////////////////////////////////////////////////
// Config (no change)
////////////////////////////////////////////////////
class pcie_dl_cfg extends uvm_object;
  
  bit dl_feature_exchange_enable = 1; 	//bit 31 of dl feature capability register(pg798)
  bit [22:0] local_feature_support;   	//bit 22:0 of dl feature capability register(pg798) //for future use
  bit dl_feature_sprt_valid;			//bit 31 of dl feature status register(pg798)
  bit [22:0] remote_feature_support; 	//bit 22:0 of dl feature status register(pg799)     //for future use
  bit feature_exchange_done = 0;
  
  bit scaled_flow_control_enable = 1;
  bit scaled_flow_control_spprt = 1;
  bit [1:0] local_hdr_scale = 2'b01;  // Example: 4x scaling
  bit [1:0] local_data_scale = 2'b01; // Example: 16x scaling 
  bit [1:0] remote_hdr_scale;         // Captured from partner
  bit [1:0] remote_data_scale;        // Captured from partner
  
  bit is_rc;
  bit is_active;
  string name;
  dlcmsm_state_e curr_state;
  dlcmsm_state_e last_state;
  int device_id = 0; // Add device identifier for replay buffer separation

  // PM L1 entry (see dlcmsm_driver::pm_l1_manager)
  bit pm_l1_accept          = 1;   // responder accepts a PM L1 request (sends PM_Request_Ack)
  bit pm_l1_use_pci_pm      = 0;   // requester: 0 = ASPM (PM_Active_State_Request_L1), 1 = PCI-PM (PM_Enter_L1)
  int pm_dllp_resend_cycles = 32;  // PM request / PM_Request_Ack DLLP repeated every N clocks
  
  `uvm_object_utils_begin(pcie_dl_cfg)
    `uvm_field_int(is_rc, UVM_ALL_ON)
    `uvm_field_int(is_active, UVM_ALL_ON)
    `uvm_field_string(name, UVM_ALL_ON)
    `uvm_field_enum(dlcmsm_state_e, curr_state, UVM_ALL_ON)
    `uvm_field_enum(dlcmsm_state_e, last_state, UVM_ALL_ON)
    `uvm_field_int(device_id, UVM_ALL_ON) // Register device_id field
  	`uvm_field_int(scaled_flow_control_enable, UVM_ALL_ON)
    `uvm_field_int(local_hdr_scale, UVM_ALL_ON)
    `uvm_field_int(local_data_scale, UVM_ALL_ON)
  	`uvm_field_int(remote_data_scale, UVM_ALL_ON)
  	`uvm_field_int(remote_data_scale, UVM_ALL_ON)
  	`uvm_field_int(feature_exchange_done, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "pcie_dl_cfg"); 
    super.new(name);
    device_id = 0; // Default device ID
    
  endfunction
endclass
