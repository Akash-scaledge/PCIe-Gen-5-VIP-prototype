//------------------------------------------------------------------------------
// dl_link_down_test
//   Stimulus: after the normal traffic has been sent and acknowledged, LinkUp
//   is forced to 0 on RC and EP (dl_force_down) for down_cycles clocks, then
//   released. New DL sequences provide InitFC/UpdateFC for the second
//   initialisation.
//   Spec (DL_Down): the DLCMSM goes to DL_INACTIVE; the replay buffer and all
//   sequence numbers are reset (NEXT_TRANSMIT_SEQ = 0, ACKD_SEQ = FFFh,
//   NEXT_RCV_SEQ = 0). When LinkUp returns, the Data Link Layer initialises
//   again (feature exchange, FC_INIT1/FC_INIT2) and reaches DL_ACTIVE.
//   Needs the per-device DLCMSM fix (dl_tests_mayank) to pass.
//------------------------------------------------------------------------------
class dl_link_down_test extends dl_base_test;
  `uvm_component_utils(dl_link_down_test)
  int down_cycles    = 200;
  int reinit_timeout = 50000;

  // snapshot taken while the link is down
  dlcmsm_state_e rc_state_down, ep_state_down;
  bit [11:0]     rc_nts_down, ep_nts_down, rc_ackd_down, ep_ackd_down, rc_nrs_down, ep_nrs_down;
  int            rc_replay_down, ep_replay_down;
  bit            traffic_done;
  bit            back_active;

  function new(string name = "dl_link_down_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void setup_expected_errors();
    catcher.expect_id("REPLAY_TIMER");
    catcher.watch_text("DL_Down (LinkUp = 0)");
  endfunction

  task link_down_and_up(uvm_phase phase);
    dlcmsm_seq rc_s, ep_s;
    int n;
    phase.raise_objection(this);
    wait (rc_dl.fsm.curr_state == DL_ACTIVE && ep_dl.fsm.curr_state == DL_ACTIVE);

    // let the normal traffic (RC: MWr + MRd, EP: CplD) be sent and acknowledged
    n = 0;
    do begin
      @(posedge rc_dl.vif.clk);
      n++;
      traffic_done = rc_dl.NEXT_TRANSMIT_SEQ >= 2 && ep_dl.NEXT_TRANSMIT_SEQ >= 1 &&
                     pcie_dl_seq_item::get_replay_count_static(0) == 0 &&
                     pcie_dl_seq_item::get_replay_count_static(1) == 0;
    end while (!traffic_done && n < reinit_timeout);
    repeat (200) @(posedge rc_dl.vif.clk);

    `uvm_info("DL_TEST", "Forcing DL_Down on RC and EP (LinkUp = 0)", UVM_NONE)
    rc_dl.dl_force_down = 1;
    ep_dl.dl_force_down = 1;
    repeat (down_cycles) @(posedge rc_dl.vif.clk);

    rc_state_down  = rc_dl.fsm.curr_state;      ep_state_down  = ep_dl.fsm.curr_state;
    rc_nts_down    = rc_dl.NEXT_TRANSMIT_SEQ;   ep_nts_down    = ep_dl.NEXT_TRANSMIT_SEQ;
    rc_ackd_down   = rc_dl.ACKD_SEQ;            ep_ackd_down   = ep_dl.ACKD_SEQ;
    rc_nrs_down    = rc_dl.next_rcv_seq;        ep_nrs_down    = ep_dl.next_rcv_seq;
    rc_replay_down = pcie_dl_seq_item::get_replay_count_static(0);
    ep_replay_down = pcie_dl_seq_item::get_replay_count_static(1);

    // DL sequences for the second initialisation (they wait for FC_INIT1)
    rc_s = dlcmsm_seq::type_id::create("rc_dl_seq_reinit");
    ep_s = dlcmsm_seq::type_id::create("ep_dl_seq_reinit");
    fork
      rc_s.start(env.rc_agent.dl_agent.sequencer);
      ep_s.start(env.ep_agent.dl_agent.sequencer);
    join_none

    `uvm_info("DL_TEST", "Releasing: LinkUp = 1", UVM_NONE)
    rc_dl.dl_force_down = 0;
    ep_dl.dl_force_down = 0;

    n = 0;
    do begin
      @(posedge rc_dl.vif.clk);
      n++;
    end while (!(rc_dl.fsm.curr_state == DL_ACTIVE && ep_dl.fsm.curr_state == DL_ACTIVE) && n < reinit_timeout);
    back_active = (rc_dl.fsm.curr_state == DL_ACTIVE && ep_dl.fsm.curr_state == DL_ACTIVE);
    `uvm_info("DL_TEST", $sformatf("After LinkUp: RC %s, EP %s (%0d clocks)", rc_dl.fsm.curr_state.name(),
                                   ep_dl.fsm.curr_state.name(), n), UVM_NONE)
    repeat (500) @(posedge rc_dl.vif.clk);
    phase.drop_objection(this);
  endtask

  task run_phase(uvm_phase phase);
    fork
      link_down_and_up(phase);
    join_none
    super.run_phase(phase);
  endtask

  function void check_dev(string dev, dlcmsm_driver d, dlcmsm_state_e st, bit [11:0] nts, bit [11:0] ackd,
                          bit [11:0] nrs, int replay);
    dl_check(d.dl_down_count == 1, {dev, " handled one DL_Down"}, $sformatf("DL_Down count=%0d", d.dl_down_count));
    dl_check(st == DL_INACTIVE, {dev, " DLCMSM in DL_INACTIVE while LinkUp = 0"}, $sformatf("state=%s", st.name()));
    dl_check(nts == 0 && ackd == 12'hFFF, {dev, " NEXT_TRANSMIT_SEQ = 0 and ACKD_SEQ = FFFh after DL_Down"},
             $sformatf("NEXT_TRANSMIT_SEQ=%0d ACKD_SEQ='h%h", nts, ackd));
    dl_check(nrs == 0, {dev, " NEXT_RCV_SEQ = 0 after DL_Down"}, $sformatf("NEXT_RCV_SEQ=%0d", nrs));
    dl_check(replay == 0, {dev, " replay buffer empty after DL_Down"}, $sformatf("%0d DW left", replay));
    dl_check(d.cfg.dl_feature_sprt_valid == 1, {dev, " repeated the Data Link Feature exchange"});
  endfunction

  function void dl_checks();
    dl_check(traffic_done, "Normal traffic sent and acknowledged before the DL_Down");
    check_dev("RC", rc_dl, rc_state_down, rc_nts_down, rc_ackd_down, rc_nrs_down, rc_replay_down);
    check_dev("EP", ep_dl, ep_state_down, ep_nts_down, ep_ackd_down, ep_nrs_down, ep_replay_down);
    dl_check(back_active, "RC and EP reached DL_ACTIVE again after LinkUp",
             $sformatf("RC %s, EP %s", rc_dl.fsm.curr_state.name(), ep_dl.fsm.curr_state.name()));
  endfunction
endclass
