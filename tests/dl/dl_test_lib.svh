//==============================================================================
// dl_test_lib.svh  -  shared infrastructure for Data Link Layer tests
//
//   dl_tx_record      one packet a DL driver put on the DL -> PL interface
//   dl_tx_recorder    callback on dlcmsm_driver: records every packet sent and
//                     lets a test inject an error (override inject())
//   dl_err_catcher    report catcher: turns EXPECTED errors/warnings into
//                     counted infos, and counts messages containing a text
//   dl_knob_seq       DL sequence with knobs (FC values, PM DLLPs) - same flow
//                     as dlcmsm_seq on main otherwise
//   dl_multi_mwr_seq  TL sequence: RC sends N memory writes
//   dl_base_test      base class for all DL tests: hooks, checks, summary
//
// How a DL test works
//   1. The test extends dl_base_test.
//   2. Optional: override make_recorder() to inject errors, setup_knobs() to
//      change sequences, setup_expected_errors() to list error IDs that are
//      the CORRECT reaction to the injected error.
//   3. Override dl_checks() and call dl_check(condition, "name", "detail")
//      for every rule the spec requires.
//   4. At the end the log shows a "DL TEST SUMMARY" block with PASS/FAIL for
//      every check. A failing check is a UVM_ERROR with ID DL_CHECK.
//==============================================================================

//------------------------------------------------------------------------------
// One packet seen on the DL -> PL interface
//------------------------------------------------------------------------------
class dl_tx_record extends uvm_object;
  `uvm_object_utils(dl_tx_record)
  time        t;
  bit         is_tlp;
  bit [11:0]  seq_num;     // TLP : sequence number on the wire
  bit [7:0]   dllp_type;   // DLLP: type byte on the wire
  bit [11:0]  acknak_seq;  // ACK/NAK: AckNak_Seq_Num
  bit [7:0]   hdr_fc;      // FC DLLP: HdrFC
  bit [11:0]  data_fc;     // FC DLLP: DataFC
  bit [31:0]  dws[$];      // packet DWORDs after the start marker
                           //   TLP : [0]=seq DW, [1..3]=header, payload, [$]=LCRC
                           //   DLLP: [0]=DLLP DW, [1]={CRC16,16'h0}
  bit         injected;    // the test injected an error into this packet
  string      state;       // DLCMSM state of the sender when it was sent

  function new(string name = "dl_tx_record");
    super.new(name);
  endfunction

  function string to_string();
    if (is_tlp)
      return $sformatf("@%0t TLP seq=%0d hdr0=%h state=%s%s", t, seq_num,
                       (dws.size() > 1) ? dws[1] : 32'h0, state, injected ? " [INJECTED]" : "");
    return $sformatf("@%0t DLLP type=%h hdr_fc=%0d data_fc=%0d acknak_seq=%0d state=%s%s", t, dllp_type,
                     hdr_fc, data_fc, acknak_seq, state, injected ? " [INJECTED]" : "");
  endfunction
endclass


//------------------------------------------------------------------------------
// Recorder callback (one per DL driver)
//------------------------------------------------------------------------------
class dl_tx_recorder extends pcie_dl_pkt_modify_callback;
  `uvm_object_utils(dl_tx_recorder)
  dlcmsm_driver drv;          // driver this recorder is attached to
  string        dev_name;     // "RC" / "EP"
  dl_tx_record  recs[$];      // everything this driver sent, in order
  int           n_tlp_seen;   // TLPs seen so far (first sends and replays)

  function new(string name = "dl_tx_recorder");
    super.new(name);
  endfunction

  // Override in a test to inject an error into "item".
  // Return 1 if the packet was changed. n_tlp_seen = TLPs seen before this one.
  virtual function bit inject(ref pcie_dl_seq_item item);
    return 0;
  endfunction

  // Called by dlcmsm_driver just before a packet is driven
  virtual function void modify_item(ref pcie_dl_seq_item item);
    dl_tx_record r;
    bit          inj;
    bit          tlp;
    tlp = (item.dllp_pkt.size() > 0) && (item.dllp_pkt[0] == `STP);
    inj = inject(item);
    r = dl_tx_record::type_id::create("r");
    r.t        = $time;
    r.injected = inj;
    r.state    = (drv != null) ? drv.fsm.curr_state.name() : "";
    for (int i = 1; i < item.dllp_pkt.size(); i++) r.dws.push_back(item.dllp_pkt[i]);
    r.is_tlp = tlp;
    if (tlp) begin
      if (r.dws.size() > 0) r.seq_num = r.dws[0][31:20];
      n_tlp_seen++;
    end
    else if (r.dws.size() > 0) begin
      r.dllp_type  = r.dws[0][31:24];
      r.acknak_seq = r.dws[0][11:0];
      r.hdr_fc     = r.dws[0][21:14];
      r.data_fc    = r.dws[0][11:0];
    end
    recs.push_back(r);
    `uvm_info("DL_TX_REC", $sformatf("%s sent %s", dev_name, r.to_string()), UVM_HIGH)
  endfunction

  //--------------------------- query helpers ----------------------------------
  // Number of DLLPs of a type sent (in_state = "" means any state)
  function int count_dllp(bit [7:0] typ, string in_state = "");
    int n = 0;
    foreach (recs[i])
      if (!recs[i].is_tlp && recs[i].dllp_type == typ && (in_state == "" || recs[i].state == in_state)) n++;
    return n;
  endfunction

  // Last DLLP of a type sent; returns null if none
  function dl_tx_record last_dllp(bit [7:0] typ);
    for (int i = recs.size() - 1; i >= 0; i--)
      if (!recs[i].is_tlp && recs[i].dllp_type == typ) return recs[i];
    return null;
  endfunction

  // Number of TLP transmissions (first sends + replays)
  function int count_tlp_sends();
    int n = 0;
    foreach (recs[i]) if (recs[i].is_tlp) n++;
    return n;
  endfunction

  // Number of different sequence numbers sent (= TLPs, without replays)
  function int count_unique_tlps();
    bit seen[int];
    foreach (recs[i]) if (recs[i].is_tlp) seen[recs[i].seq_num] = 1;
    return seen.num();
  endfunction

  // First transmission of a sequence number; returns null if never sent
  function dl_tx_record first_tlp(bit [11:0] seq);
    foreach (recs[i]) if (recs[i].is_tlp && recs[i].seq_num == seq) return recs[i];
    return null;
  endfunction

  // Latest HdrFC this device advertised for a credit type before time t
  // (InitFC1/InitFC2/UpdateFC of that type). Returns -1 if none yet.
  function int advertised_hdr_fc(bit [7:0] init1, bit [7:0] init2, bit [7:0] upd, time t);
    int v = -1;
    foreach (recs[i])
      if (!recs[i].is_tlp && recs[i].t <= t && recs[i].dllp_type inside {init1, init2, upd}) v = recs[i].hdr_fc;
    return v;
  endfunction

  function void print_all();
    string s;
    s = $sformatf("\n---- packets sent by %s DL (%0d) ----\n", dev_name, recs.size());
    foreach (recs[i]) s = {s, "  ", recs[i].to_string(), "\n"};
    `uvm_info("DL_TX_REC", s, UVM_LOW)
  endfunction
endclass


//------------------------------------------------------------------------------
// Report catcher for EXPECTED errors
//------------------------------------------------------------------------------
class dl_err_catcher extends uvm_report_catcher;
  `uvm_object_utils(dl_err_catcher)
  string expected_ids[$];        // IDs whose ERROR/WARNING is the expected reaction
  int    n_err[string];          // demoted UVM_ERRORs per ID
  int    n_warn[string];         // demoted UVM_WARNINGs per ID
  string watched_text[$];        // texts to count in any message
  int    n_text[string];
  time   first_text_t[string];

  function new(string name = "dl_err_catcher");
    super.new(name);
  endfunction

  function void expect_id(string id);
    expected_ids.push_back(id);
  endfunction

  function void watch_text(string txt);
    watched_text.push_back(txt);
  endfunction

  function int errors(string id);
    return n_err.exists(id) ? n_err[id] : 0;
  endfunction

  function int warnings(string id);
    return n_warn.exists(id) ? n_warn[id] : 0;
  endfunction

  function int text_hits(string txt);
    return n_text.exists(txt) ? n_text[txt] : 0;
  endfunction

  function time first_hit(string txt);
    return first_text_t.exists(txt) ? first_text_t[txt] : 0;
  endfunction

  static function bit has_text(string s, string sub);
    int n;
    int m;
    n = s.len();
    m = sub.len();
    if (m == 0) return 1;
    for (int i = 0; i + m <= n; i++)
      if (s.substr(i, i + m - 1) == sub) return 1;
    return 0;
  endfunction

  function string summary();
    string s;
    s = "";
    foreach (n_err[id])  s = {s, $sformatf("%s:%0d error(s) ", id, n_err[id])};
    foreach (n_warn[id]) s = {s, $sformatf("%s:%0d warning(s) ", id, n_warn[id])};
    if (s == "") s = "none";
    return s;
  endfunction

  virtual function action_e catch();
    string msg;
    msg = get_message();
    foreach (watched_text[i]) begin
      if (has_text(msg, watched_text[i])) begin
        if (!n_text.exists(watched_text[i])) begin
          n_text[watched_text[i]] = 0;
          first_text_t[watched_text[i]] = $time;
        end
        n_text[watched_text[i]]++;
      end
    end
    if (get_severity() == UVM_ERROR || get_severity() == UVM_WARNING) begin
      foreach (expected_ids[i]) begin
        if (get_id() == expected_ids[i]) begin
          if (get_severity() == UVM_ERROR) begin
            if (!n_err.exists(get_id())) n_err[get_id()] = 0;
            n_err[get_id()]++;
          end
          else begin
            if (!n_warn.exists(get_id())) n_warn[get_id()] = 0;
            n_warn[get_id()]++;
          end
          set_severity(UVM_INFO);
          set_action(UVM_DISPLAY);
          set_message({"[EXPECTED] ", msg});
          return THROW;
        end
      end
    end
    return THROW;
  endfunction
endclass


//------------------------------------------------------------------------------
// DL sequence with knobs. With all knobs at default it does exactly what
// dlcmsm_seq on main does. Knobs are static, index [0] = RC, [1] = EP.
//------------------------------------------------------------------------------
class dl_knob_seq extends dlcmsm_seq;
  `uvm_object_utils(dl_knob_seq)

  static int fc_p_hdr[2]        = '{-1, -1};  // HdrFC for Posted InitFC1/InitFC2/UpdateFC (-1 = default)
  static int updatefc_hdr[2]    = '{-1, -1};  // HdrFC for all UpdateFC DLLPs (-1 = default)
  static bit pm_in_fc_init1[2]  = '{0, 0};    // send PM_Enter_L1 while in FC_INIT1 (not allowed)
  static bit pm_in_dl_active[2] = '{0, 0};    // send PM_Enter_L1 once in DL_ACTIVE (allowed)

  function new(string name = "dl_knob_seq");
    super.new(name);
  endfunction

  function int hdr_for(bit [7:0] t, int dflt);
    int dev;
    dev = cfg.device_id;
    if (t inside {INITFC1_P_VC0, INITFC2_P_VC0, UPDATEFC_P_VC0} && fc_p_hdr[dev] >= 0) return fc_p_hdr[dev];
    if (t inside {UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0} && updatefc_hdr[dev] >= 0) return updatefc_hdr[dev];
    return dflt;
  endfunction

  task send_pm_enter_l1();
    `uvm_do_with(req, { req.is_tlp == 0; req.is_pm == 1; req.pm_pkt.dllp_type == PM_Enter_L1;
                        req.acknak_pkt.dllp_type == 0; })
    `uvm_info("DL_KNOB_SEQ", $sformatf("Device %0d: PM_Enter_L1 DLLP handed to driver in state %s",
                                       cfg.device_id, cfg.curr_state.name()), UVM_LOW)
  endtask

  // Same flow as dlcmsm_seq::body() on main, plus the knobs
  task body();
    int h;
    my_hdr_limit = 32;   // Start with some initial capacity
    my_data_limit = 256;
    reg_model.local_f_reg.write(status,32'h8000_0001,UVM_FRONTDOOR,.parent(this));
    if(status!=UVM_IS_OK)
      `uvm_error(get_type_name(),"REGISTER WRITE FAIL")

    wait(cfg.curr_state == FC_INIT1);
    if (pm_in_fc_init1[cfg.device_id]) send_pm_enter_l1();
    foreach (fc1_ordered_types[i]) begin
      h = hdr_for(fc1_ordered_types[i], my_hdr_limit);
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc1_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;
                         req.dllps_pkt.HdrFC == h;
                         req.dllps_pkt.DataFC == my_data_limit;
                        })
    end
    wait(cfg.curr_state == FC_INIT2);
    foreach (fc2_ordered_types[i]) begin
      h = hdr_for(fc2_ordered_types[i], my_hdr_limit);
      `uvm_do_with(req, { req.dllps_pkt.dllp_type == fc2_ordered_types[i]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;
                         req.dllps_pkt.HdrFC == h;
                         req.dllps_pkt.DataFC == my_data_limit;
                        })
    end
    wait(cfg.curr_state == DL_ACTIVE);
    if (pm_in_dl_active[cfg.device_id]) send_pm_enter_l1();
    for (int i = 0; i < `NUM_TLPS_TO_SEND; i++) begin
      foreach (updatefc_ordered_types[j]) begin
        h = hdr_for(updatefc_ordered_types[j], my_hdr_limit);
        `uvm_do_with(req, { req.dllps_pkt.dllp_type == updatefc_ordered_types[j]; req.is_tlp == 0;req.acknak_pkt.dllp_type == 0;
                           req.dllps_pkt.HdrFC == h;
                           req.dllps_pkt.DataFC == my_data_limit;
                           req.tlps_pkt.length inside {[1:32]};
                          })
      end
      // "TLP slot" items: needed by the DL driver on main to send TL TLPs
      current_seq = shared_seq_num;
      repeat(2)
      `uvm_do_with(req, { req.is_tlp == 1; req.seq_num == current_seq; })
      tlp_sent_flags[cfg.device_id] = 1;
      if (cfg.device_id == 1) begin
        wait (tlp_sent_flags == 2'b11);
        shared_seq_num++;
        tlp_sent_flags = 2'b00;
      end
      my_hdr_limit = (my_hdr_limit + 1) % 256;
      my_data_limit = (my_data_limit + 8) % 4096;
      wait (tlp_sent_flags[cfg.device_id] == 0);
    end
  endtask
endclass


//------------------------------------------------------------------------------
// TL sequence: RC sends num_mwr memory writes (EP sends nothing)
//------------------------------------------------------------------------------
class dl_multi_mwr_seq extends mem_wr_rd_seq;
  `uvm_object_utils(dl_multi_mwr_seq)
  static int num_mwr = 3;

  function new(string name = "dl_multi_mwr_seq");
    super.new(name);
  endfunction

  task body();
    bit [31:0] addr;
    if (device_cfg.is_rc) begin
      for (int i = 0; i < num_mwr; i++) begin
        addr = 32'h1000 + (i * 16);
        `uvm_do_with(req, {req.pkt_type == 2;             //memory write
                           req.header_mem.typef == 0;
                           req.header_mem.fmt == 2;
                           req.header_mem.td == 0;
                           req.header_mem.tc == 0;
                           req.header_mem.address1 == addr;
                           req.header_mem.len == 3;
                           req.payload_m.size() == req.header_mem.len;})
      end
    end
  endtask
endclass


//------------------------------------------------------------------------------
// Base class for all DL tests
//------------------------------------------------------------------------------
class dl_base_test extends siv_pcie_base_test;
  `uvm_component_utils(dl_base_test)

  dl_tx_recorder rc_rec, ep_rec;      // packets sent by RC DL / EP DL
  dl_err_catcher catcher;
  dlcmsm_driver  rc_dl, ep_dl;        // DL drivers (state, counters, limits)
  bit            expect_link_active = 1;  // common check: both reach DL_ACTIVE
  int            n_checks, n_fail;
  string         check_log[$];

  function new(string name = "dl_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //------------------------- hooks for tests ---------------------------------
  // Return a recorder subclass to inject errors (default: record only)
  virtual function dl_tx_recorder make_recorder(string dev);
    return dl_tx_recorder::type_id::create({dev, "_rec"});
  endfunction
  // Factory overrides / sequence knobs (called before the env is built)
  virtual function void setup_knobs();
  endfunction
  // catcher.expect_id("ID") for errors that are the CORRECT reaction
  virtual function void setup_expected_errors();
  endfunction
  // Test-specific checks (call dl_check)
  virtual function void dl_checks();
  endfunction

  //------------------------- phases ------------------------------------------
  function void build_phase(uvm_phase phase);
    // reset sequence knobs (static) and apply the test's own
    dl_knob_seq::fc_p_hdr        = '{-1, -1};
    dl_knob_seq::updatefc_hdr    = '{-1, -1};
    dl_knob_seq::pm_in_fc_init1  = '{0, 0};
    dl_knob_seq::pm_in_dl_active = '{0, 0};
    setup_knobs();
    super.build_phase(phase);
    catcher = dl_err_catcher::type_id::create("catcher");
    uvm_report_cb::add(null, catcher);
    catcher.watch_text("REPLAY_TIMER expired");
    setup_expected_errors();
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    rc_dl = env.rc_agent.dl_agent.driver;
    ep_dl = env.ep_agent.dl_agent.driver;
    rc_rec = make_recorder("RC");
    rc_rec.dev_name = "RC";
    rc_rec.drv = rc_dl;
    ep_rec = make_recorder("EP");
    ep_rec.dev_name = "EP";
    ep_rec.drv = ep_dl;
    uvm_callbacks#(dlcmsm_driver, pcie_dl_pkt_modify_callback)::add(rc_dl, rc_rec);
    uvm_callbacks#(dlcmsm_driver, pcie_dl_pkt_modify_callback)::add(ep_dl, ep_rec);
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    rc_rec.print_all();
    ep_rec.print_all();
    common_checks();
    dl_checks();
  endfunction

  function void report_phase(uvm_phase phase);
    string s;
    super.report_phase(phase);
    s = $sformatf("\n==================== DL TEST SUMMARY: %s ====================\n", get_type_name());
    foreach (check_log[i]) s = {s, "  ", check_log[i], "\n"};
    s = {s, "  Expected errors caught: ", catcher.summary(), "\n"};
    s = {s, $sformatf("  RESULT: %s  (%0d of %0d checks failed)\n",
                      (n_fail == 0) ? "PASS" : "FAIL", n_fail, n_checks)};
    s = {s, "============================================================================"};
    `uvm_info("DL_TEST_SUMMARY", s, UVM_NONE)
  endfunction

  //------------------------- check helpers -----------------------------------
  function void dl_check(bit ok, string name, string detail = "");
    n_checks++;
    if (ok) begin
      check_log.push_back($sformatf("PASS  %s", name));
      `uvm_info("DL_CHECK", $sformatf("PASS  %s  %s", name, detail), UVM_NONE)
    end
    else begin
      n_fail++;
      check_log.push_back($sformatf("FAIL  %s  -- %s", name, detail));
      `uvm_error("DL_CHECK", $sformatf("FAIL  %s  -- %s", name, detail))
    end
  endfunction

  // Checks every DL test does
  virtual function void common_checks();
    if (expect_link_active) begin
      dl_check(rc_dl.fsm.curr_state == DL_ACTIVE, "RC DLCMSM reached DL_ACTIVE",
               $sformatf("state=%s", rc_dl.fsm.curr_state.name()));
      dl_check(ep_dl.fsm.curr_state == DL_ACTIVE, "EP DLCMSM reached DL_ACTIVE",
               $sformatf("state=%s", ep_dl.fsm.curr_state.name()));
    end
    // Receiver rule: NEXT_RCV_SEQ only advances when a TLP is accepted
    dl_check(rc_dl.next_rcv_seq == (rc_dl.tl_queue.size() % 4096),
             "RC NEXT_RCV_SEQ equals number of TLPs accepted",
             $sformatf("NEXT_RCV_SEQ=%0d accepted=%0d", rc_dl.next_rcv_seq, rc_dl.tl_queue.size()));
    dl_check(ep_dl.next_rcv_seq == (ep_dl.tl_queue.size() % 4096),
             "EP NEXT_RCV_SEQ equals number of TLPs accepted",
             $sformatf("NEXT_RCV_SEQ=%0d accepted=%0d", ep_dl.next_rcv_seq, ep_dl.tl_queue.size()));
  endfunction
endclass
