//==============================================================================
// dl_tests_akash.svh  -  DL tests owned by Akash Kumar Sahu (M7)
//
//   dl_init_test            DLCMSM states, DL feature exchange, InitFC credits
//   dl_ack_test             ACK DLLPs, ACKD_SEQ, replay buffer purge
//   dl_lcrc_nak_test        bad LCRC -> NAK -> replay -> delivered once
//   dl_lcrc_seq_cover_test  LCRC must cover the sequence number
//
// Run:  bash sim/run_vcs.sh <test_name>
//==============================================================================


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
    dl_check(rc_dl.cfg.remote_feature_support == ep_dl.cfg.local_feature_support,
             "RC stored EP's feature support correctly",
             $sformatf("RC remote_feature_support=%h, EP local_feature_support=%h",
                       rc_dl.cfg.remote_feature_support, ep_dl.cfg.local_feature_support));
    dl_check(ep_dl.cfg.remote_feature_support == rc_dl.cfg.local_feature_support,
             "EP stored RC's feature support correctly",
             $sformatf("EP remote_feature_support=%h, RC local_feature_support=%h",
                       ep_dl.cfg.remote_feature_support, rc_dl.cfg.local_feature_support));

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


//------------------------------------------------------------------------------
// dl_ack_test
//   Spec: the receiver ACKs good TLPs (AckNak latency timer), the sender
//   updates ACKD_SEQ, purges ACKed TLPs from the replay buffer and stops
//   REPLAY_TIMER. With no errors, REPLAY_TIMER must never expire.
//------------------------------------------------------------------------------
class dl_ack_test extends dl_base_test;
  `uvm_component_utils(dl_ack_test)

  function new(string name = "dl_ack_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void setup_expected_errors();
    catcher.watch_text("Duplicate TLP detected");
  endfunction

  function void check_side(string tx, dl_tx_recorder tx_rec, dlcmsm_driver tx_dl,
                           string rx, dl_tx_recorder rx_rec);
    int n_tlp;
    int n_ack;
    dl_tx_record last_ack;
    n_tlp = tx_rec.count_unique_tlps();
    n_ack = rx_rec.count_dllp(ACK_DLLP_TYPE, "DL_ACTIVE");
    last_ack = rx_rec.last_dllp(ACK_DLLP_TYPE);
    dl_check(n_tlp > 0, {tx, " sent at least one TLP"}, $sformatf("TLPs=%0d", n_tlp));
    dl_check(n_ack > 0, {rx, " sent an ACK DLLP in DL_ACTIVE for ", tx, "'s TLPs"},
             $sformatf("ACK DLLPs in DL_ACTIVE=%0d", n_ack));
    if (n_ack > 0 && last_ack != null)
      dl_check(last_ack.acknak_seq == ((tx_dl.NEXT_TRANSMIT_SEQ + 4095) % 4096),
               {rx, " last ACK acknowledges ", tx, "'s last TLP"},
               $sformatf("AckNak_Seq_Num=%0d last seq sent=%0d", last_ack.acknak_seq,
                         (tx_dl.NEXT_TRANSMIT_SEQ + 4095) % 4096));
    dl_check(tx_dl.ACKD_SEQ == ((tx_dl.NEXT_TRANSMIT_SEQ + 4095) % 4096),
             {tx, " ACKD_SEQ = last sequence number sent"},
             $sformatf("ACKD_SEQ=%0d NEXT_TRANSMIT_SEQ=%0d", tx_dl.ACKD_SEQ, tx_dl.NEXT_TRANSMIT_SEQ));
    dl_check(pcie_dl_seq_item::get_replay_count_static(tx_dl.cfg.device_id) == 0,
             {tx, " replay buffer empty at end (all TLPs ACKed and purged)"},
             $sformatf("%0d DWORDs left", pcie_dl_seq_item::get_replay_count_static(tx_dl.cfg.device_id)));
    dl_check(tx_dl.REPLAY_NUM == 0, {tx, " REPLAY_NUM = 0"}, $sformatf("REPLAY_NUM=%0d", tx_dl.REPLAY_NUM));
  endfunction

  function void dl_checks();
    check_side("RC", rc_rec, rc_dl, "EP", ep_rec);
    check_side("EP", ep_rec, ep_dl, "RC", rc_rec);
    dl_check(catcher.text_hits("REPLAY_TIMER expired") == 0, "REPLAY_TIMER never expired (no errors injected)",
             $sformatf("expired %0d time(s), first at %0t", catcher.text_hits("REPLAY_TIMER expired"),
                       catcher.first_hit("REPLAY_TIMER expired")));
  endfunction
endclass


//------------------------------------------------------------------------------
// dl_lcrc_nak_test
//   Inject: RC's first TLP is sent with a bad LCRC.
//   Spec: EP drops it and sends NAK (AckNak_Seq_Num = NEXT_RCV_SEQ-1 = 4095);
//   RC replays from the replay buffer with the same sequence number and a good
//   LCRC; EP's Transaction Layer gets every RC TLP exactly once.
//------------------------------------------------------------------------------
class dl_lcrc_nak_rec extends dl_tx_recorder;
  `uvm_object_utils(dl_lcrc_nak_rec)
  bit [31:0] good_lcrc;
  function new(string name = "dl_lcrc_nak_rec");
    super.new(name);
  endfunction
  function bit inject(ref pcie_dl_seq_item item);
    if (item.dllp_pkt.size() > 0 && item.dllp_pkt[0] == `STP && n_tlp_seen == 0) begin
      good_lcrc = item.dllp_pkt[item.dllp_pkt.size()-1];
      item.dllp_pkt[item.dllp_pkt.size()-1] = good_lcrc ^ 32'hDEAD_BEEF;
      item.lcrc = good_lcrc ^ 32'hDEAD_BEEF;
      `uvm_info("DL_INJECT", $sformatf("%s: corrupting LCRC of first TLP seq=%0d (%h -> %h)",
                                       dev_name, item.dllp_pkt[1][31:20], good_lcrc, item.lcrc), UVM_NONE)
      return 1;
    end
    return 0;
  endfunction
endclass

class dl_lcrc_nak_test extends dl_base_test;
  `uvm_component_utils(dl_lcrc_nak_test)

  function new(string name = "dl_lcrc_nak_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function dl_tx_recorder make_recorder(string dev);
    dl_lcrc_nak_rec r;
    if (dev == "RC") begin
      r = dl_lcrc_nak_rec::type_id::create({dev, "_rec"});
      return r;
    end
    return super.make_recorder(dev);
  endfunction

  function void setup_expected_errors();
    catcher.expect_id("LCRC");        // EP: LCRC mismatch (correct reaction)
    catcher.expect_id("SEQ_CHECK");   // EP: next TLP out of sequence after the drop
    catcher.expect_id("REPLAY_TIMER");
  endfunction

  function void dl_checks();
    dl_lcrc_nak_rec r;
    dl_tx_record    orig;
    int             n_seq0;
    bit             replay_ok;
    void'($cast(r, rc_rec));
    dl_check(catcher.errors("LCRC") >= 1, "EP detected the bad LCRC",
             $sformatf("LCRC errors at EP=%0d", catcher.errors("LCRC")));
    dl_check(ep_rec.count_dllp(NAK_DLLP_TYPE, "DL_ACTIVE") >= 1, "EP sent a NAK DLLP",
             $sformatf("NAKs sent=%0d", ep_rec.count_dllp(NAK_DLLP_TYPE, "DL_ACTIVE")));
    if (ep_rec.last_dllp(NAK_DLLP_TYPE) != null)
      dl_check(ep_rec.last_dllp(NAK_DLLP_TYPE).acknak_seq == 12'hFFF, "NAK carries NEXT_RCV_SEQ-1 (4095)",
               $sformatf("AckNak_Seq_Num=%0d", ep_rec.last_dllp(NAK_DLLP_TYPE).acknak_seq));
    // Replay of seq 0: same DWORDs as the original, but with the good LCRC
    orig = rc_rec.first_tlp(0);
    n_seq0 = 0;
    replay_ok = 0;
    foreach (rc_rec.recs[i]) begin
      if (!rc_rec.recs[i].is_tlp || rc_rec.recs[i].seq_num != 0) continue;
      n_seq0++;
      if (n_seq0 >= 2 && orig != null && rc_rec.recs[i].dws.size() == orig.dws.size()) begin
        replay_ok = 1;
        foreach (orig.dws[k])
          if (k < orig.dws.size() - 1 && rc_rec.recs[i].dws[k] != orig.dws[k]) replay_ok = 0;
        if (rc_rec.recs[i].dws[orig.dws.size()-1] != r.good_lcrc) replay_ok = 0;
      end
    end
    dl_check(n_seq0 >= 2, "RC replayed TLP seq 0", $sformatf("seq 0 sent %0d time(s)", n_seq0));
    dl_check(replay_ok, "Replayed TLP = original TLP with the correct LCRC");
    dl_check(ep_dl.tl_queue.size() == rc_rec.count_unique_tlps(), "EP delivered every RC TLP exactly once",
             $sformatf("EP accepted=%0d, RC TLPs=%0d", ep_dl.tl_queue.size(), rc_rec.count_unique_tlps()));
  endfunction
endclass


//------------------------------------------------------------------------------
// dl_lcrc_seq_cover_test
//   Spec: the LCRC is calculated over the sequence number AND the TLP.
//   Inject: change only the sequence number of RC's first TLP on the wire
//   (0 -> 5), leave the LCRC as it is.
//   Expected: EP's LCRC check fails. If the LCRC does not cover the sequence
//   number, EP sees a valid LCRC and only an out-of-sequence TLP.
//------------------------------------------------------------------------------
class dl_seq_cover_rec extends dl_tx_recorder;
  `uvm_object_utils(dl_seq_cover_rec)
  function new(string name = "dl_seq_cover_rec");
    super.new(name);
  endfunction
  function bit inject(ref pcie_dl_seq_item item);
    if (item.dllp_pkt.size() > 1 && item.dllp_pkt[0] == `STP && n_tlp_seen == 0) begin
      item.dllp_pkt[1] = {12'd5, item.dllp_pkt[1][19:0]};
      `uvm_info("DL_INJECT", $sformatf("%s: first TLP sequence number changed 0 -> 5 on the wire, LCRC unchanged",
                                       dev_name), UVM_NONE)
      return 1;
    end
    return 0;
  endfunction
endclass

class dl_lcrc_seq_cover_test extends dl_base_test;
  `uvm_component_utils(dl_lcrc_seq_cover_test)

  function new(string name = "dl_lcrc_seq_cover_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function dl_tx_recorder make_recorder(string dev);
    dl_seq_cover_rec r;
    if (dev == "RC") begin
      r = dl_seq_cover_rec::type_id::create({dev, "_rec"});
      return r;
    end
    return super.make_recorder(dev);
  endfunction

  function void setup_expected_errors();
    catcher.expect_id("LCRC");
    catcher.expect_id("SEQ_CHECK");
    catcher.expect_id("REPLAY_TIMER");
  endfunction

  function void dl_checks();
    dl_check(catcher.errors("LCRC") >= 1, "Changed sequence number detected by EP's LCRC check",
             $sformatf("LCRC errors=%0d, out-of-sequence warnings=%0d (LCRC does not cover the sequence number if 0/>0)",
                       catcher.errors("LCRC"), catcher.warnings("SEQ_CHECK")));
  endfunction
endclass
