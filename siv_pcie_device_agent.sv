//--------------------------------------------------------------
// PCIe Device Agent (RC or EP)
// Encapsulates TL + DL + PL agents with internal FIFOs
//--------------------------------------------------------------
class siv_pcie_device_agent extends uvm_agent;
  `uvm_component_utils(siv_pcie_device_agent)

  // ------------------------------------------------------------
  // Unified PCIe configuration
  // ------------------------------------------------------------
  siv_pcie_cfg pcie_cfg;

  // ------------------------------------------------------------
  // Layer agents
  // ------------------------------------------------------------
  siv_pcie_tl_agent  tl_agent;
  dlcmsm_agent       dl_agent;
  siv_ltssm_agent    pl_agent;

  // ------------------------------------------------------------
  // DL Register Model (REQUIRED)
  // ------------------------------------------------------------
  dlf_ext_cpb        reg_model;
  dlf_reg_adapter   reg_adapter;

  // ------------------------------------------------------------
  // Internal FIFOs between layers
  // ------------------------------------------------------------
  uvm_tlm_fifo #(global_que_t) tl_2_dl_fifo;
  uvm_tlm_fifo #(global_que_t) dl_2_tl_fifo;
  uvm_tlm_fifo #(global_que_t) dl_2_pl_fifo;
  uvm_tlm_fifo #(global_que_t) pl_2_dl_fifo;

  // ------------------------------------------------------------
  // Constructor
  // ------------------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // ------------------------------------------------------------
  // Build phase
  // ------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // ----------------------------------------------------------
    // Get unified PCIe configuration
    // ----------------------------------------------------------
    if (!uvm_config_db#(siv_pcie_cfg)::get(this, "", "pcie_cfg", pcie_cfg)) begin
      `uvm_fatal("CFG",
        $sformatf("%s: siv_pcie_cfg not found in config DB",
                  get_full_name()))
    end

    `uvm_info(get_type_name(),
      $sformatf("Building %s device agent (device_id=%0d)",
                pcie_cfg.is_rc ? "RC" : "EP",
                pcie_cfg.device_id),
      UVM_LOW)

    // ----------------------------------------------------------
    // Push layer-specific configs BEFORE creating sub-agents
    // ----------------------------------------------------------
    uvm_config_db#(siv_tl_cfg)::set(
      this, "tl_agent*", "device_cfg", pcie_cfg.tl_cfg);

    uvm_config_db#(pcie_dl_cfg)::set(
      this, "dl_agent*", "device_config", pcie_cfg.dl_cfg);

    uvm_config_db#(siv_ltssm_pl_cfg)::set(
      this, "pl_agent*", "pl_cfg", pcie_cfg.pl_cfg);

    // ----------------------------------------------------------
    // Create DL register model (FIXES UVM_FATAL)
    // ----------------------------------------------------------
    reg_model = dlf_ext_cpb::type_id::create(
      $sformatf("reg_model_dev%0d", pcie_cfg.device_id), this);

    reg_model.build();
    reg_model.reset();
    reg_model.lock_model();

    reg_adapter = dlf_reg_adapter::type_id::create("reg_adapter");

    // Provide reg model to DL
    uvm_config_db#(dlf_ext_cpb)::set(
      null, "*", $sformatf("reg_model_%0d", pcie_cfg.device_id), reg_model);

    // ----------------------------------------------------------
    // Create layer agents
    // ----------------------------------------------------------
    tl_agent = siv_pcie_tl_agent::type_id::create("tl_agent", this);
    dl_agent = dlcmsm_agent     ::type_id::create("dl_agent", this);
    pl_agent = siv_ltssm_agent  ::type_id::create("pl_agent", this);

    // ----------------------------------------------------------
    // Create internal FIFOs
    // ----------------------------------------------------------
    tl_2_dl_fifo = new("tl_2_dl_fifo", this);
    dl_2_tl_fifo = new("dl_2_tl_fifo", this);
    dl_2_pl_fifo = new("dl_2_pl_fifo", this);
    pl_2_dl_fifo = new("pl_2_dl_fifo", this);
  endfunction

  // ------------------------------------------------------------
  // Connect phase
  // ------------------------------------------------------------
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // ----------------------------------------------------------
    // Bind reg model map to DL sequencer
    // ----------------------------------------------------------
    reg_model.default_map.set_sequencer(.sequencer(dl_agent.sequencer), .adapter(reg_adapter));
    reg_model.default_map.set_base_addr('h0);     
    // ------------------------
    // TL <-> DL connections
    // ------------------------
    tl_agent.driver.tl_driver_dl_put_port
      .connect(tl_2_dl_fifo.put_export);

    tl_agent.driver.tl_driver_dl_get_port
      .connect(dl_2_tl_fifo.get_export);

    dl_agent.driver.dl_driver_put_tl_port
      .connect(dl_2_tl_fifo.put_export);

    dl_agent.driver.dl_driver_get_tl_port
      .connect(tl_2_dl_fifo.get_export);

    // ------------------------
    // DL <-> PL connections
    // ------------------------
    dl_agent.driver.dl_sending_pl_port
      .connect(dl_2_pl_fifo.put_export);

    dl_agent.driver.dl_rcv_pl_port
      .connect(pl_2_dl_fifo.get_export);

    pl_agent.driver.pl_sending_dl_port
      .connect(pl_2_dl_fifo.put_export);

    pl_agent.driver.pl_rcv_dl_port
      .connect(dl_2_pl_fifo.get_export);
  endfunction

endclass
