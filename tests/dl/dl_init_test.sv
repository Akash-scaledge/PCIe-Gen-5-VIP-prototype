//------------------------------------------------------------------------------
// dl_init_test
//   Spec: DLCMSM goes DL_Inactive -> DL_Feature -> DL_Init (FC_INIT1, FC_INIT2)
//   -> DL_Active. Each side stores the partner's DL feature support and the
//   credit limits the partner advertised in InitFC.
//------------------------------------------------------------------------------
class dl_init_test extends dl_base_test;
  `uvm_component_utils(dl_init_test)
  dlcmsm_state_e rc_states[$];

  function new(string name = "dl_init_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Record every DLCMSM state change seen through the RC driver
  task track_rc_states();
    forever begin
      @(posedge rc_dl.vif.clk);
      if (rc_states.size() == 0 || rc_dl.fsm.curr_state != rc_states[rc_states.size()-1])
        rc_states.push_back(rc_dl.fsm.curr_state);
    end
  endtask

  task run_phase(uvm_phase phase);
    fork
      track_rc_states();
    join_none
    super.run_phase(phase);
  endtask

  // Credit limit the driver stored must equal what the partner advertised
  function void check_limit(string what, int stored, dl_tx_record adv, bit is_hdr);
    if (adv == null) begin
      dl_check(0, what, "partner never sent this FC DLLP");
      return;
    end
    dl_check(stored == (is_hdr ? adv.hdr_fc : adv.data_fc), what,
             $sformatf("stored=%0d advertised=%0d", stored, is_hdr ? adv.hdr_fc : adv.data_fc));
  endfunction

  function void dl_checks();
    dlcmsm_state_e exp[$];
    string got;
    bit    same;
    exp = '{DL_INACTIVE, DL_FEATURE, DL_INIT, FC_INIT1, FC_INIT2, DL_ACTIVE};
    got = "";
    foreach (rc_states[i]) got = {got, rc_states[i].name(), " "};
    same = (rc_states.size() == exp.size());
    if (same) foreach (exp[i]) if (rc_states[i] != exp[i]) same = 0;
    dl_check(same, "DLCMSM state order DL_INACTIVE>DL_FEATURE>DL_INIT>FC_INIT1>FC_INIT2>DL_ACTIVE",
             {"seen: ", got});

    // DL feature exchange (spec: Data Link Feature Status register)
    dl_check(rc_dl.cfg.dl_feature_sprt_valid == 1, "RC received EP's Data Link Feature DLLP");
    dl_check(ep_dl.cfg.dl_feature_sprt_valid == 1, "EP received RC's Data Link Feature DLLP");

    // Credit limits stored = last value the partner advertised (Init or Update)
    check_limit("RC P header limit = EP advertised",  rc_dl.tx_ph_limit,   last_fc(ep_rec, 0), 1);
    check_limit("RC P data limit = EP advertised",    rc_dl.tx_pd_limit,   last_fc(ep_rec, 0), 0);
    check_limit("RC NP header limit = EP advertised", rc_dl.tx_nph_limit,  last_fc(ep_rec, 1), 1);
    check_limit("RC CPL header limit = EP advertised",rc_dl.tx_cplh_limit, last_fc(ep_rec, 2), 1);
    check_limit("EP P header limit = RC advertised",  ep_dl.tx_ph_limit,   last_fc(rc_rec, 0), 1);
    check_limit("EP NP header limit = RC advertised", ep_dl.tx_nph_limit,  last_fc(rc_rec, 1), 1);
    check_limit("EP CPL header limit = RC advertised",ep_dl.tx_cplh_limit, last_fc(rc_rec, 2), 1);
  endfunction

  // Last FC DLLP (InitFC1/InitFC2/UpdateFC) of a credit type: 0=P 1=NP 2=CPL
  function dl_tx_record last_fc(dl_tx_recorder r, int typ);
    for (int i = r.recs.size() - 1; i >= 0; i--) begin
      if (r.recs[i].is_tlp) continue;
      case (typ)
        0: if (r.recs[i].dllp_type inside {INITFC1_P_VC0, INITFC2_P_VC0, UPDATEFC_P_VC0}) return r.recs[i];
        1: if (r.recs[i].dllp_type inside {INITFC1_NP_VC0, INITFC2_NP_VC0, UPDATEFC_NP_VC0}) return r.recs[i];
        default: if (r.recs[i].dllp_type inside {INITFC1_CPL_VC0, INITFC2_CPL_VC0, UPDATEFC_CPL_VC0}) return r.recs[i];
      endcase
    end
    return null;
  endfunction
endclass

