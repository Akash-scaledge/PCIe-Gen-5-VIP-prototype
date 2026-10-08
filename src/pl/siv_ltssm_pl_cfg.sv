
//--------------------------------------------------------------
// SIV PCIe Configuration Object (siv_ltssm_pl_cfg)
//--------------------------------------------------------------
// Used by both Root Complex and Endpoint components

class siv_ltssm_pl_cfg extends uvm_object;
  `uvm_object_utils(siv_ltssm_pl_cfg) 
  // Device Configuration
  bit         is_rc;           // 1=RC, 0=EP
  bit         is_active;       // 1=Active link 
  string      inst_name;       // Instance identifier string
  bit   [4:0] target_speed = `SPEED_32_GTS; // User Defined Speed.
  bit   [1:0] equalization_link_behaviour_ctrl = `EQ_MODE_BYPASS;
  bit         l0s_entry_enable=0; // 1 = Allow entry into L0s
  bit         aspm_l0s_support=1; // 1 = Showing support to L0s
  bit         l1_entry_enable=1;  // 1 = Allow entry into L1
  bit         aspm_l1_support=0;  // 1 = Showing support to L1 
  bit         l1_exit_enable=1;   // 1 = Allowing exit from L1
  bit         l2_entry_enable=0;  // 1 = Allow entry into L2
  bit LinkUp;					  // 1 = LinK is active
  bit beacon_directed=1;          // 1 = Directing the beacon
  bit beacon_detected =0;         // 1 = Detected the becon
  // Constructor
  function new(string name = "siv_ltssm_pl_cfg");
    super.new(name);
  endfunction
endclass

//--------------------------------------------------------------