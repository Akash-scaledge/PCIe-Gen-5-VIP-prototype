//--------------------------------------------------------------
// SIV PCIe Unified Configuration Object
// Used by both Root Complex and Endpoint
//--------------------------------------------------------------
class siv_pcie_cfg extends uvm_object;
  

  // ------------------------------------------------------------
  // Common fields
  // ------------------------------------------------------------
  bit    is_rc;
  bit    is_active;
  string inst_name;
  int    device_id;
  
  // ------------------------------------------------------------
  // Layer-specific configuration objects
  // ------------------------------------------------------------
  siv_ltssm_pl_cfg  pl_cfg;
  pcie_dl_cfg       dl_cfg;
  siv_tl_cfg        tl_cfg;
  
  
  
  `uvm_object_utils_begin(siv_pcie_cfg)
    `uvm_field_int   (is_rc,      UVM_DEFAULT)
    `uvm_field_int   (is_active,  UVM_DEFAULT)
    `uvm_field_string(inst_name,  UVM_DEFAULT)
    `uvm_field_int   (device_id,  UVM_DEFAULT)

    `uvm_field_object(pl_cfg, UVM_DEFAULT)
    `uvm_field_object(dl_cfg, UVM_DEFAULT)
    `uvm_field_object(tl_cfg, UVM_DEFAULT)
  `uvm_object_utils_end

  

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(string name = "siv_pcie_cfg");
    super.new(name);
  endfunction

  // ------------------------------------------------------------
  // Build layer configs and propagate common fields
  // ------------------------------------------------------------
  function void build();

    // Prevent accidental rebuild
    if (pl_cfg != null || dl_cfg != null || tl_cfg != null) begin
      `uvm_warning("CFG_REBUILD",
        $sformatf("%s: build() called more than once", get_name()))
      return;
    end

    // Create sub-configs
    pl_cfg = siv_ltssm_pl_cfg::type_id::create("pl_cfg");
    dl_cfg = pcie_dl_cfg      ::type_id::create("dl_cfg");
    tl_cfg = siv_tl_cfg       ::type_id::create("tl_cfg");

    // ----------------------------------------------------------
    // Propagate common fields to PL
    // ----------------------------------------------------------
    pl_cfg.is_rc     = is_rc;
    pl_cfg.is_active = is_active;
    pl_cfg.inst_name = inst_name;

    // ----------------------------------------------------------
    // Propagate common fields to DL
    // ----------------------------------------------------------
    dl_cfg.is_rc     = is_rc;
    dl_cfg.is_active = is_active;
    dl_cfg.name      = inst_name;
    dl_cfg.device_id = device_id;

    // ----------------------------------------------------------
    // Propagate common fields to TL
    // ----------------------------------------------------------
    tl_cfg.is_rc     = is_rc;
    tl_cfg.is_active = is_active;
    tl_cfg.inst_name = inst_name;
  endfunction

  

endclass
//--------------------------------------------------------------
