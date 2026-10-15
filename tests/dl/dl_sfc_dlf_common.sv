//------------------------------------------------------------------------------
// dl_sfc_dlf_common.sv  -  shared code for the Scaled Flow Control (SFC) and
//                          Data Link Feature (DLF) exchange tests
//
//   dl_sfc_seq        DL sequence: same flow as dl_knob_seq, plus a per-device
//                     DLF Capabilities value and HdrScale/DataScale in every
//                     InitFC1/InitFC2/UpdateFC it sends
//   dl_sfc_base_test  base for dl_sfc_both_support_test, dl_sfc_rc_only_test,
//                     dl_dlf_rc_only_test: knobs, state tracking and checks
//
// Spec (PCIe Base 5.0):
//   3.2.1  DLCMSM: DL_Feature is entered only with DLF Exchange Enable = 1;
//          it is left on a DLF DLLP with Feature Ack = 1, or on an InitFC1
//          (partner does not take part in the exchange)
//   3.3    DLF exchange: Remote Data Link Feature Supported (+ Valid bit) in
//          the DLF Status register
//   3.4.2  Scaled FC is active only if both ports advertise it in the DLF
//          exchange. Active: HdrScale/DataScale = 01 (x1), 10 (x4), 11 (x16)
//          in every InitFC1/InitFC2/UpdateFC, same values in all of them.
//          Not active: the fields are 00 and the receiver ignores them.
//   7.7.4  DLF Extended Capability: Capabilities (bit 31 = Exchange Enable,
//          bit 0 = Local Scaled FC Supported), Status (bit 31 = Remote Valid)
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// DL sequence with DLF capability and FC scale knobs. Knobs are static,
// index [0] = RC, [1] = EP. Defaults give the same DLLPs as dlcmsm_seq.
//------------------------------------------------------------------------------
class dl_sfc_seq extends dlcmsm_seq;
  `uvm_object_utils(dl_sfc_seq)

  static bit [31:0] dlf_cap[2]    = '{32'h8000_0001, 32'h8000_0001};  // DLF Capabilities register value
  static bit [1:0]  hdr_scale[2]  = '{2'b00, 2'b00};                  // HdrScale in every FC DLLP sent
  static bit [1:0]  data_scale[2] = '{2'b00, 2'b00};                  // DataScale in every FC DLLP sent

  function new(string name = "dl_sfc_seq");
    super.new(name);
  endfunction

  task send_fc(bit [7:0] t, bit [1:0] hs, bit [1:0] ds);
    bit sc;
    sc = (hs != 2'b00) || (ds != 2'b00);
    `uvm_do_with(req, { req.dllps_pkt.dllp_type == t; req.is_tlp == 0; req.acknak_pkt.dllp_type == 0;
                        req.scl_en == sc;
                        req.dllps_pkt.rsvd1 == hs;
                        req.dllps_pkt.rsvd2 == ds;
                        req.dllps_pkt.HdrFC == my_hdr_limit;
                        req.dllps_pkt.DataFC == my_data_limit;
                        req.tlps_pkt.length inside {[1:32]};
                      })
  endtask

  // Same flow as dl_knob_seq::body()
  task body();
    int       dev;
    bit [1:0] hs, ds;
    dev = cfg.device_id;
    hs  = hdr_scale[dev];
    ds  = data_scale[dev];
    if ((hs == 2'b00) != (ds == 2'b00))
      `uvm_fatal(get_type_name(), $sformatf("Device %0d: HdrScale=%b DataScale=%b - both must be 00 or both non-zero", dev, hs, ds))
    `uvm_info("DL_SFC_SEQ", $sformatf("Device %0d: DLF Capabilities=0x%08h (Exchange Enable=%0b, Scaled FC=%0b) HdrScale=%b DataScale=%b",
                                      dev, dlf_cap[dev], dlf_cap[dev][31], dlf_cap[dev][0], hs, ds), UVM_NONE)

    my_hdr_limit  = 32;
    my_data_limit = 256;
    reg_model.local_f_reg.write(status, dlf_cap[dev], UVM_FRONTDOOR, .parent(this));
    if (status != UVM_IS_OK)
      `uvm_error(get_type_name(), "REGISTER WRITE FAIL")

    wait(cfg.curr_state == FC_INIT1);
    foreach (fc1_ordered_types[i]) send_fc(fc1_ordered_types[i], hs, ds);
    wait(cfg.curr_state == FC_INIT2);
    foreach (fc2_ordered_types[i]) send_fc(fc2_ordered_types[i], hs, ds);
    wait(cfg.curr_state == DL_ACTIVE);
    for (int i = 0; i < `NUM_TLPS_TO_SEND; i++) begin
      foreach (updatefc_ordered_types[j]) send_fc(updatefc_ordered_types[j], hs, ds);
      // "TLP slot" items: needed by the DL driver to send TL TLPs
      current_seq = shared_seq_num;
      repeat(2)
      `uvm_do_with(req, { req.is_tlp == 1; req.seq_num == current_seq; })
      tlp_sent_flags[dev] = 1;
      if (dev == 1) begin
        wait (tlp_sent_flags == 2'b11);
        shared_seq_num++;
        tlp_sent_flags = 2'b00;
      end
      my_hdr_limit  = (my_hdr_limit + 1) % 256;
      my_data_limit = (my_data_limit + 8) % 4096;
      wait (tlp_sent_flags[dev] == 0);
    end
  endtask
endclass


//------------------------------------------------------------------------------
// Base test for the SFC / DLF tests
//   A test sets dlf_cap / hdr_scale / data_scale / scale_injected in its
//   constructor. Everything else (expected values, checks) follows from them.
//------------------------------------------------------------------------------
class dl_sfc_base_test extends dl_base_test;
  `uvm_component_utils(dl_sfc_base_test)

  // Knobs, [0] = RC, [1] = EP
  bit [31:0] dlf_cap[2]        = '{32'h8000_0001, 32'h8000_0001};
  bit [1:0]  hdr_scale[2]      = '{2'b00, 2'b00};
  bit [1:0]  data_scale[2]     = '{2'b00, 2'b00};
  bit        scale_injected[2] = '{0, 0};  // device sends non-zero scale although SFC is not active (error injection)

  // Observed during the run
  dlcmsm_state_e states[2][$];       // DLCMSM state history per device
  bit            active_seen[2];     // device reached DL_ACTIVE
  time           active_t[2];        // when
  int            active_lim[2][6];   // credit limits at that moment: PH PD NPH NPD CPLH CPLD

  function new(string name = "dl_sfc_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  //------------------------- setup -------------------------------------------
  function void setup_knobs();
    set_type_override_by_type(dlcmsm_seq::get_type(), dl_sfc_seq::get_type());
    dl_sfc_seq::dlf_cap    = dlf_cap;
    dl_sfc_seq::hdr_scale  = hdr_scale;
    dl_sfc_seq::data_scale = data_scale;
  endfunction

  //------------------------- helpers -----------------------------------------
  function dlcmsm_driver drv(int i);
    return (i == 0) ? rc_dl : ep_dl;
  endfunction

  function dl_tx_recorder rec(int i);
    return (i == 0) ? rc_rec : ep_rec;
  endfunction

  function string dn(int i);
    return (i == 0) ? "RC" : "EP";
  endfunction

  function bit dlf_on(int i);
    return dlf_cap[i][31];
  endfunction

  // Scaled FC is active only if both did the DLF exchange and both support it
  function bit sfc_active();
    return dlf_on(0) && dlf_on(1) && dlf_cap[0][0] && dlf_cap[1][0];
  endfunction

  function int scale_shift(bit [1:0] s);
    case (s)
      2'b10:   return 2;   // x4
      2'b11:   return 4;   // x16
      default: return 0;   // 00 / 01 (x1)
    endcase
  endfunction

  function bit is_fc_dllp(bit [7:0] t);
    return t inside {INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0,
                     INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0,
                     UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0};
  endfunction

  // Credit type of an FC DLLP: 0 = P, 1 = NP, 2 = Cpl
  function int fc_cls(bit [7:0] t);
    case (t[5:4])
      2'b00:   return 0;
      2'b01:   return 1;
      default: return 2;
    endcase
  endfunction

  // Last FC DLLP of credit type c sent by recorder r at or before time t
  // (init_only = 1: InitFC1/InitFC2 only)
  function dl_tx_record last_fc(dl_tx_recorder r, int c, time t, bit init_only);
    for (int k = r.recs.size() - 1; k >= 0; k--) begin
      if (r.recs[k].is_tlp || r.recs[k].t > t || !is_fc_dllp(r.recs[k].dllp_type)) continue;
      if (fc_cls(r.recs[k].dllp_type) != c) continue;
      if (init_only && r.recs[k].dllp_type[7:6] == 2'b10) continue;   // UpdateFC = 10xx_xxxx
      return r.recs[k];
    end
    return null;
  endfunction

  // Limit the receiver must hold for one field of an FC DLLP
  //   SFC active    : FC value << shift(scale field of that DLLP)
  //   SFC not active: scale field ignored, FC value as is
  function int exp_limit(dl_tx_record a, bit is_hdr);
    int        v;
    bit [1:0]  s;
    v = is_hdr ? a.hdr_fc : a.data_fc;
    s = is_hdr ? a.dws[0][23:22] : a.dws[0][13:12];
    return sfc_active() ? (v << scale_shift(s)) : v;
  endfunction

  function void get_limits(int i, output int l[6]);
    dlcmsm_driver d;
    d = drv(i);
    l = '{d.tx_ph_limit, d.tx_pd_limit, d.tx_nph_limit, d.tx_npd_limit, d.tx_cplh_limit, d.tx_cpld_limit};
  endfunction

  //------------------------- run ---------------------------------------------
  task track(int i);
    dlcmsm_driver d;
    d = drv(i);
    forever begin
      @(posedge d.vif.clk);
      if (states[i].size() == 0 || d.fsm.curr_state != states[i][states[i].size()-1])
        states[i].push_back(d.fsm.curr_state);
      if (!active_seen[i] && d.fsm.curr_state == DL_ACTIVE) begin
        active_seen[i] = 1;
        active_t[i]    = $time;
        get_limits(i, active_lim[i]);
      end
    end
  endtask

  task run_phase(uvm_phase phase);
    fork
      track(0);
      track(1);
    join_none
    super.run_phase(phase);
  endtask

  //------------------------- checks ------------------------------------------
  function void check_states(int i);
    string         s;
    bit            feat;
    dlcmsm_state_e q[$];
    s    = "";
    feat = 0;
    q    = states[i];
    foreach (q[k]) begin
      s = {s, q[k].name(), " "};
      if (q[k] == DL_FEATURE) feat = 1;
    end
    if (dlf_on(i))
      dl_check(feat, $sformatf("%s (DLF Exchange Enable=1) went through DL_FEATURE", dn(i)), {"seen: ", s});
    else
      dl_check(!feat, $sformatf("%s (DLF Exchange Enable=0) never entered DL_FEATURE", dn(i)), {"seen: ", s});
  endfunction

  function void check_dlf(int i);
    int           p;
    bit           vld;
    bit [22:0]    rmt;
    bit [31:0]    sts;
    dlcmsm_driver d;
    p   = 1 - i;
    d   = drv(i);
    vld = dlf_on(i) && dlf_on(p);
    rmt = vld ? dlf_cap[p][22:0] : 23'h0;
    sts = (i == 0) ? env.rc_agent.reg_model.remote_f_reg.get() : env.ep_agent.reg_model.remote_f_reg.get();

    dl_check(d.local_data[31:0] == dlf_cap[i], $sformatf("%s DL used the programmed DLF Capabilities", dn(i)),
             $sformatf("sampled=0x%08h programmed=0x%08h", d.local_data[31:0], dlf_cap[i]));
    dl_check(d.cfg.dl_feature_sprt_valid == vld, $sformatf("%s Remote DLF Supported Valid = %0b", dn(i), vld),
             $sformatf("cfg.dl_feature_sprt_valid=%0b", d.cfg.dl_feature_sprt_valid));
    dl_check(d.cfg.remote_feature_support == rmt, $sformatf("%s stored partner's features = 0x%06h", dn(i), rmt),
             $sformatf("cfg.remote_feature_support=0x%06h", d.cfg.remote_feature_support));
    dl_check(sts[31] == vld, $sformatf("%s DLF Status reg bit 31 (Remote Valid) = %0b", dn(i), vld),
             $sformatf("DLF Status=0x%08h", sts));
    dl_check(sts[22:0] == rmt, $sformatf("%s DLF Status reg [22:0] = partner's features 0x%06h", dn(i), rmt),
             $sformatf("DLF Status=0x%08h", sts));
    dl_check(d.scaled_fc_active() == sfc_active(), $sformatf("%s Scaled FC active = %0b", dn(i), sfc_active()),
             $sformatf("driver scaled_fc_active()=%0b", d.scaled_fc_active()));
  endfunction

  // Credit limits device i holds = what the partner last advertised (scaled if SFC active)
  function void check_credits(int i, int lim[6], time t, string when, bit init_only);
    string        nm[6] = '{"P hdr", "P data", "NP hdr", "NP data", "Cpl hdr", "Cpl data"};
    dl_tx_record  a;
    int           e;
    for (int k = 0; k < 6; k++) begin
      a = last_fc(rec(1 - i), k / 2, t, init_only);
      if (a == null) begin
        dl_check(0, $sformatf("%s %s limit %s", dn(i), nm[k], when), $sformatf("%s never sent this FC DLLP", dn(1 - i)));
        continue;
      end
      e = exp_limit(a, (k % 2) == 0);
      dl_check(lim[k] == e, $sformatf("%s %s limit %s = partner's advertisement%s", dn(i), nm[k], when,
                                      sfc_active() ? " (scaled)" : ""),
               $sformatf("stored=%0d expected=%0d (partner sent HdrFC=%0d HdrScale=%b DataFC=%0d DataScale=%b @%0t)",
                         lim[k], e, a.hdr_fc, a.dws[0][23:22], a.data_fc, a.dws[0][13:12], a.t));
    end
  endfunction

  // HdrScale/DataScale on every FC DLLP device i sent (sequence and driver generated)
  //   SFC active    : same non-zero values as in InitFC (the configured scale)
  //   SFC not active: 00 (unless this device injects a non-zero scale on purpose)
  function void check_tx_scale(int i);
    dl_tx_recorder r;
    int            n_fc, n_bad;
    bit [1:0]      hs, ds, ehs, eds;
    string         first_bad;
    r         = rec(i);
    n_fc      = 0;
    n_bad     = 0;
    first_bad = "";
    ehs = (sfc_active() || scale_injected[i]) ? hdr_scale[i]  : 2'b00;
    eds = (sfc_active() || scale_injected[i]) ? data_scale[i] : 2'b00;
    foreach (r.recs[k]) begin
      if (r.recs[k].is_tlp || !is_fc_dllp(r.recs[k].dllp_type) || r.recs[k].dws.size() == 0) continue;
      n_fc++;
      hs = r.recs[k].dws[0][23:22];
      ds = r.recs[k].dws[0][13:12];
      if (hs != ehs || ds != eds) begin
        n_bad++;
        if (first_bad == "")
          first_bad = $sformatf("first: %s HdrScale=%b DataScale=%b", r.recs[k].to_string(), hs, ds);
      end
    end
    dl_check(n_fc > 0, $sformatf("%s sent FC DLLPs", dn(i)), $sformatf("%0d FC DLLPs", n_fc));
    dl_check(n_bad == 0,
             $sformatf("%s HdrScale/DataScale = %b/%b in every InitFC/UpdateFC%s", dn(i), ehs, eds,
                       scale_injected[i] ? " (injected)" : ""),
             $sformatf("%0d of %0d FC DLLPs differ. %s", n_bad, n_fc, first_bad));
  endfunction

  function void dl_checks();
    for (int i = 0; i < 2; i++) begin
      check_states(i);
      check_dlf(i);
      if (active_seen[i]) check_credits(i, active_lim[i], active_t[i], "after FC init (InitFC)", 1);
      begin
        int l[6];
        get_limits(i, l);
        check_credits(i, l, $time, "at end of test", 0);
      end
      check_tx_scale(i);
    end
  endfunction
endclass
