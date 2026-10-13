//==============================================================================
// dl_tests_mayank.svh  -  DL tests owned by Kumar Mayank Kashyap (M2)
//
//   dl_dllp_crc_test         DLLP with bad CRC16 is dropped (credits unchanged)
//   dl_fc_gating_test        no TLP sent without enough flow-control credits
//   dl_state_filter_test     PM DLLP not sent in FC_INIT1, accepted in DL_ACTIVE
//   dl_fsm_per_device_test   RC and EP each have their own DLCMSM
//
// Run:  bash sim/run_vcs.sh <test_name>
//==============================================================================


//------------------------------------------------------------------------------
// dl_dllp_crc_test
//   Setup: RC advertises HdrFC=40 in all its UpdateFC DLLPs (InitFC = 32).
//   Inject: RC's UpdateFC_P DLLPs get a bad CRC16; UpdateFC_NP stays good.
//   Spec: a DLLP with a bad CRC is discarded, so EP keeps P limit = 32 while
//   its NP limit becomes 40 (shows UpdateFC itself works).
//------------------------------------------------------------------------------
class dl_bad_updfc_rec extends dl_tx_recorder;
  `uvm_object_utils(dl_bad_updfc_rec)
  function new(string name = "dl_bad_updfc_rec");
    super.new(name);
  endfunction
  function bit inject(ref pcie_dl_seq_item item);
    if (item.dllp_pkt.size() > 2 && item.dllp_pkt[0] == `SDP && item.dllp_pkt[1][31:24] == UPDATEFC_P_VC0) begin
      item.dllp_pkt[2] = item.dllp_pkt[2] ^ 32'h0F0F_0000;   // flip CRC16 bits
      `uvm_info("DL_INJECT", $sformatf("%s: UpdateFC_P (HdrFC=%0d) sent with a bad CRC",
                                       dev_name, item.dllp_pkt[1][21:14]), UVM_NONE)
      return 1;
    end
    return 0;
  endfunction
endclass

class dl_dllp_crc_test extends dl_base_test;
  `uvm_component_utils(dl_dllp_crc_test)

  function new(string name = "dl_dllp_crc_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void setup_knobs();
    set_type_override_by_type(dlcmsm_seq::get_type(), dl_knob_seq::get_type());
    dl_knob_seq::updatefc_hdr[0] = 40;   // RC UpdateFC HdrFC = 40
  endfunction

  function dl_tx_recorder make_recorder(string dev);
    dl_bad_updfc_rec r;
    if (dev == "RC") begin
      r = dl_bad_updfc_rec::type_id::create({dev, "_rec"});
      return r;
    end
    return super.make_recorder(dev);
  endfunction

  function void setup_expected_errors();
    catcher.expect_id("DLLP_CRC");
    catcher.expect_id("REPLAY_TIMER");
  endfunction

  function void dl_checks();
    int n_bad;
    n_bad = 0;
    foreach (rc_rec.recs[i]) if (rc_rec.recs[i].injected) n_bad++;
    dl_check(n_bad >= 1, "RC sent at least one UpdateFC_P with a bad CRC", $sformatf("bad DLLPs=%0d", n_bad));
    dl_check(catcher.errors("DLLP_CRC") >= 1, "EP detected the bad DLLP CRC",
             $sformatf("DLLP_CRC errors at EP=%0d", catcher.errors("DLLP_CRC")));
    dl_check(ep_dl.tx_ph_limit == 32, "EP ignored the bad UpdateFC_P (P header limit still 32)",
             $sformatf("tx_ph_limit=%0d", ep_dl.tx_ph_limit));
    dl_check(ep_dl.tx_nph_limit == 40, "EP applied the good UpdateFC_NP (NP header limit 40)",
             $sformatf("tx_nph_limit=%0d", ep_dl.tx_nph_limit));
  endfunction
endclass


//------------------------------------------------------------------------------
// dl_fc_gating_test
//   Setup: EP advertises only 1 Posted header credit (InitFC and UpdateFC);
//   RC's TL sends 3 memory writes (Posted).
//   Spec (flow-control gating): a TLP may only be sent if
//   CREDITS_CONSUMED + cost <= CREDIT_LIMIT, so RC may send only 1 MWr.
//------------------------------------------------------------------------------
class dl_fc_gating_test extends dl_base_test;
  `uvm_component_utils(dl_fc_gating_test)

  function new(string name = "dl_fc_gating_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void setup_knobs();
    set_type_override_by_type(dlcmsm_seq::get_type(), dl_knob_seq::get_type());
    set_type_override_by_type(mem_wr_rd_seq::get_type(), dl_multi_mwr_seq::get_type());
    dl_knob_seq::fc_p_hdr[1]   = 1;      // EP: 1 Posted header credit
    dl_multi_mwr_seq::num_mwr  = 3;
  endfunction

  function void setup_expected_errors();
    catcher.expect_id("REPLAY_TIMER");
  endfunction

  function void dl_checks();
    int  posted_sent;
    int  limit;
    bit  ok;
    bit  seen[int];
    string viol;
    ok = 1;
    posted_sent = 0;
    viol = "";
    foreach (rc_rec.recs[i]) begin
      if (!rc_rec.recs[i].is_tlp || rc_rec.recs[i].dws.size() < 2) continue;
      if (seen.exists(rc_rec.recs[i].seq_num)) continue;          // replay: no new credits
      seen[rc_rec.recs[i].seq_num] = 1;
      // Posted = MWr (Fmt[1]=1, Type=00000) or Msg (Type=10xxx)
      if ((rc_rec.recs[i].dws[1][30] == 1'b1 && rc_rec.recs[i].dws[1][28:24] == 5'b00000) ||
          rc_rec.recs[i].dws[1][28:27] == 2'b10) begin
        posted_sent++;
        limit = ep_rec.advertised_hdr_fc(INITFC1_P_VC0, INITFC2_P_VC0, UPDATEFC_P_VC0, rc_rec.recs[i].t);
        if (limit > 0 && posted_sent > limit) begin
          ok = 0;
          viol = {viol, $sformatf("[@%0t seq %0d: %0d posted headers used, EP limit %0d] ",
                                  rc_rec.recs[i].t, rc_rec.recs[i].seq_num, posted_sent, limit)};
        end
      end
    end
    dl_check(ep_rec.advertised_hdr_fc(INITFC1_P_VC0, INITFC2_P_VC0, UPDATEFC_P_VC0, $time) == 1,
             "EP advertised 1 Posted header credit (setup)");
    dl_check(posted_sent >= 1, "RC sent at least one MWr", $sformatf("posted TLPs=%0d", posted_sent));
    dl_check(ok, "RC never sent a Posted TLP without a Posted header credit",
             (viol == "") ? $sformatf("posted TLPs sent=%0d", posted_sent) : viol);
  endfunction
endclass


//------------------------------------------------------------------------------
// dl_state_filter_test
//   Setup: RC's DL sequence offers a PM_Enter_L1 DLLP in FC_INIT1 (only
//   InitFC1 DLLPs are allowed there) and another one in DL_ACTIVE.
//   Expected: the one in FC_INIT1 is blocked by RC's DL driver; the one in
//   DL_ACTIVE is sent and EP receives it.
//------------------------------------------------------------------------------
class dl_state_filter_test extends dl_base_test;
  `uvm_component_utils(dl_state_filter_test)

  function new(string name = "dl_state_filter_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void setup_knobs();
    set_type_override_by_type(dlcmsm_seq::get_type(), dl_knob_seq::get_type());
    dl_knob_seq::pm_in_fc_init1[0]  = 1;
    dl_knob_seq::pm_in_dl_active[0] = 1;
  endfunction

  function void setup_expected_errors();
    catcher.expect_id("dlcmsm_driver");   // "Blocked ... DLLP" warnings (correct reaction)
    catcher.expect_id("REPLAY_TIMER");
    catcher.watch_text("RX PM_Enter_L1 DLLP");
  endfunction

  function void dl_checks();
    int n_bad;
    int n_good;
    n_bad = 0;
    n_good = 0;
    foreach (rc_rec.recs[i]) begin
      if (rc_rec.recs[i].is_tlp) continue;
      if (rc_rec.recs[i].dllp_type inside {PM_Enter_L1, PM_Enter_L23, PM_Active_State_Request_L1, PM_Request_Ack}) begin
        if (rc_rec.recs[i].state == "DL_ACTIVE") n_good++;
        else begin
          n_bad++;
          `uvm_info("DL_CHECK", $sformatf("PM DLLP sent in %s: %s", rc_rec.recs[i].state, rc_rec.recs[i].to_string()), UVM_NONE)
        end
      end
    end
    dl_check(n_bad == 0, "RC did not send a PM DLLP outside DL_ACTIVE", $sformatf("PM DLLPs outside DL_ACTIVE=%0d", n_bad));
    dl_check(n_good >= 1, "RC sent the PM DLLP in DL_ACTIVE", $sformatf("PM DLLPs in DL_ACTIVE=%0d", n_good));
    dl_check(catcher.text_hits("RX PM_Enter_L1 DLLP") >= 1, "EP received the PM_Enter_L1 DLLP",
             $sformatf("hits=%0d", catcher.text_hits("RX PM_Enter_L1 DLLP")));
  endfunction
endclass


//------------------------------------------------------------------------------
// dl_fsm_per_device_test
//   Inject: every InitFC1 and InitFC2 DLLP that EP sends gets a bad CRC, so
//   RC never receives EP's credits. (In FC_INIT1 the receiver may record
//   credits from InitFC1 OR InitFC2, so both are corrupted.)
//   Spec: RC must stay in FC_INIT1 (it never got credits for P, NP and CPL),
//   must not send InitFC2, and must not reach DL_ACTIVE. Each device has its
//   own DLCMSM, so EP progressing must not move RC.
//------------------------------------------------------------------------------
class dl_bad_initfc1_rec extends dl_tx_recorder;
  `uvm_object_utils(dl_bad_initfc1_rec)
  function new(string name = "dl_bad_initfc1_rec");
    super.new(name);
  endfunction
  function bit inject(ref pcie_dl_seq_item item);
    if (item.dllp_pkt.size() > 2 && item.dllp_pkt[0] == `SDP &&
        item.dllp_pkt[1][31:24] inside {INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0,
                                        INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0}) begin
      item.dllp_pkt[2] = item.dllp_pkt[2] ^ 32'h00F0_0000;   // flip CRC16 bits
      `uvm_info("DL_INJECT", $sformatf("%s: InitFC DLLP type %h sent with a bad CRC", dev_name, item.dllp_pkt[1][31:24]), UVM_NONE)
      return 1;
    end
    return 0;
  endfunction
endclass

class dl_fsm_per_device_test extends dl_base_test;
  `uvm_component_utils(dl_fsm_per_device_test)

  function new(string name = "dl_fsm_per_device_test", uvm_component parent = null);
    super.new(name, parent);
    expect_link_active = 0;   // the link must NOT come up in this test
  endfunction

  function dl_tx_recorder make_recorder(string dev);
    dl_bad_initfc1_rec r;
    if (dev == "EP") begin
      r = dl_bad_initfc1_rec::type_id::create({dev, "_rec"});
      return r;
    end
    return super.make_recorder(dev);
  endfunction

  function void setup_expected_errors();
    catcher.expect_id("DLLP_CRC");
    catcher.expect_id("REPLAY_TIMER");
  endfunction

  function void dl_checks();
    int n_init2;
    n_init2 = rc_rec.count_dllp(INITFC2_P_VC0) + rc_rec.count_dllp(INITFC2_NP_VC0) + rc_rec.count_dllp(INITFC2_CPL_VC0);
    dl_check(catcher.errors("DLLP_CRC") >= 1, "RC detected EP's bad InitFC DLLPs",
             $sformatf("DLLP_CRC errors=%0d", catcher.errors("DLLP_CRC")));
    dl_check(rc_dl.tx_ph_limit == 0, "RC has no Posted credits from EP (all InitFC dropped)",
             $sformatf("tx_ph_limit=%0d", rc_dl.tx_ph_limit));
    dl_check(n_init2 == 0, "RC never sent InitFC2 (it never completed FC_INIT1)",
             $sformatf("InitFC2 DLLPs sent by RC=%0d", n_init2));
    dl_check(rc_dl.fsm.curr_state != DL_ACTIVE, "RC did not reach DL_ACTIVE",
             $sformatf("RC state=%s (EP state=%s)", rc_dl.fsm.curr_state.name(), ep_dl.fsm.curr_state.name()));
  endfunction
endclass
