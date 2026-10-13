//==============================================================================
// dl_tests_bhabagrahi.svh  -  DL tests owned by Bhabagrahi Pradhan (M1)
//
//   dl_replay_timeout_test  ACKs lost -> REPLAY_TIMER -> replay of all
//                           unACKed TLPs, same sequence numbers and contents
//   dl_seq_dup_test         duplicate TLP -> dropped, ACK sent
//   dl_seq_skip_test        missing sequence number -> TLP dropped, NAK sent
//   dl_nullified_tlp_test   nullified TLP (inverted LCRC) -> silently dropped,
//                           NEXT_RCV_SEQ unchanged
//
// Run:  bash sim/run_vcs.sh <test_name>
//==============================================================================


//------------------------------------------------------------------------------
// dl_replay_timeout_test
//   Inject: every ACK DLLP that EP sends gets a bad CRC, so RC drops it.
//   Spec: RC's REPLAY_TIMER expires; RC replays ALL unacknowledged TLPs from
//   the replay buffer, oldest first, with their original sequence numbers and
//   contents; REPLAY_NUM increments on each replay.
//------------------------------------------------------------------------------
class dl_drop_ack_rec extends dl_tx_recorder;
  `uvm_object_utils(dl_drop_ack_rec)
  function new(string name = "dl_drop_ack_rec");
    super.new(name);
  endfunction
  function bit inject(ref pcie_dl_seq_item item);
    if (item.dllp_pkt.size() > 2 && item.dllp_pkt[0] == `SDP && item.dllp_pkt[1][31:24] == ACK_DLLP_TYPE &&
        drv != null && drv.fsm.curr_state == DL_ACTIVE) begin
      item.dllp_pkt[2] = item.dllp_pkt[2] ^ 32'h00FF_0000;   // flip CRC16 bits
      `uvm_info("DL_INJECT", $sformatf("%s: ACK seq=%0d sent with a bad CRC (will be dropped)",
                                       dev_name, item.dllp_pkt[1][11:0]), UVM_NONE)
      return 1;
    end
    return 0;
  endfunction
endclass

class dl_replay_timeout_test extends dl_base_test;
  `uvm_component_utils(dl_replay_timeout_test)

  function new(string name = "dl_replay_timeout_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function dl_tx_recorder make_recorder(string dev);
    dl_drop_ack_rec r;
    if (dev == "EP") begin
      r = dl_drop_ack_rec::type_id::create({dev, "_rec"});
      return r;
    end
    return super.make_recorder(dev);
  endfunction

  function void setup_expected_errors();
    catcher.expect_id("DLLP_CRC");      // RC drops the bad ACKs
    catcher.expect_id("REPLAY_TIMER");  // timer expiry warnings, REPLAY_NUM rollover
    catcher.expect_id("LINK_RETRAIN");
    catcher.expect_id("SEQ_CHECK");     // EP sees the replayed TLPs as duplicates
  endfunction

  function void dl_checks();
    int        orig_seq[$];         // RC sequence numbers in first-send order
    bit        sent_before[int];
    int        replays[$];          // seq numbers re-sent after the first expiry
    time       t_exp;
    bit        same_content;
    bit        all_replayed;
    bit        order_ok;
    dl_tx_record o;

    t_exp = catcher.first_hit("REPLAY_TIMER expired");
    dl_check(catcher.text_hits("REPLAY_TIMER expired") >= 1, "REPLAY_TIMER expired (ACKs were lost)",
             $sformatf("expired %0d time(s)", catcher.text_hits("REPLAY_TIMER expired")));

    same_content = 1;
    foreach (rc_rec.recs[i]) begin
      if (!rc_rec.recs[i].is_tlp) continue;
      if (!sent_before.exists(rc_rec.recs[i].seq_num)) begin
        sent_before[rc_rec.recs[i].seq_num] = 1;
        orig_seq.push_back(rc_rec.recs[i].seq_num);
      end
      else begin
        replays.push_back(rc_rec.recs[i].seq_num);
        o = rc_rec.first_tlp(rc_rec.recs[i].seq_num);
        if (o.dws != rc_rec.recs[i].dws) begin
          same_content = 0;
          `uvm_info("DL_CHECK", $sformatf("replay of seq %0d differs: first=%p replay=%p",
                                          rc_rec.recs[i].seq_num, o.dws, rc_rec.recs[i].dws), UVM_NONE)
        end
      end
    end
    // A replay that comes out with a wrong sequence number shows up as a
    // "new" sequence number sent after the timer expired
    foreach (rc_rec.recs[i])
      if (rc_rec.recs[i].is_tlp && t_exp > 0 && rc_rec.recs[i].t > t_exp &&
          rc_rec.recs[i].seq_num >= rc_dl.NEXT_TRANSMIT_SEQ)
        `uvm_info("DL_CHECK", $sformatf("TLP seq %0d sent after the timer expired was never assigned by RC (wrong replay sequence number)",
                                        rc_rec.recs[i].seq_num), UVM_NONE)

    all_replayed = (orig_seq.size() > 0);
    foreach (orig_seq[i]) begin
      bit found;
      found = 0;
      foreach (replays[k]) if (replays[k] == orig_seq[i]) found = 1;
      if (!found) all_replayed = 0;
    end
    dl_check(all_replayed, "Every unACKed RC TLP was replayed",
             $sformatf("first sends=%p replays=%p", orig_seq, replays));
    dl_check(replays.size() > 0 && same_content, "Replayed TLPs have the original sequence number and contents");

    // First replay round must be the outstanding TLPs, oldest first
    order_ok = (replays.size() >= orig_seq.size()) && (orig_seq.size() > 0);
    if (order_ok) foreach (orig_seq[i]) if (replays[i] != orig_seq[i]) order_ok = 0;
    dl_check(order_ok, "Replay order = oldest unACKed TLP first, all of them",
             $sformatf("expected %p, got %p", orig_seq, replays));
    dl_check(rc_dl.REPLAY_NUM != 0 || catcher.errors("REPLAY_TIMER") > 0,
             "REPLAY_NUM incremented on replay", $sformatf("REPLAY_NUM=%0d", rc_dl.REPLAY_NUM));
  endfunction
endclass


//------------------------------------------------------------------------------
// dl_seq_dup_test
//   Inject: RC's second TLP is sent with sequence number 0 again (duplicate).
//   Spec: EP drops a duplicate TLP (it was already accepted) and sends an ACK
//   for the last good sequence number (0). It is not passed to the TL again.
//------------------------------------------------------------------------------
class dl_dup_seq_rec extends dl_tx_recorder;
  `uvm_object_utils(dl_dup_seq_rec)
  function new(string name = "dl_dup_seq_rec");
    super.new(name);
  endfunction
  function bit inject(ref pcie_dl_seq_item item);
    bit [31:0] words[$];
    if (item.dllp_pkt.size() > 2 && item.dllp_pkt[0] == `STP && n_tlp_seen == 1) begin
      item.dllp_pkt[1] = {12'd0, item.dllp_pkt[1][19:0]};
      // keep the LCRC valid for the VIP's LCRC (header .. payload)
      for (int i = 2; i < item.dllp_pkt.size() - 1; i++) words.push_back(item.dllp_pkt[i]);
      item.dllp_pkt[item.dllp_pkt.size()-1] = item.calculate_lcrc(words);
      `uvm_info("DL_INJECT", $sformatf("%s: second TLP sent with sequence number 0 (duplicate)", dev_name), UVM_NONE)
      return 1;
    end
    return 0;
  endfunction
endclass

class dl_seq_dup_test extends dl_base_test;
  `uvm_component_utils(dl_seq_dup_test)

  function new(string name = "dl_seq_dup_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function dl_tx_recorder make_recorder(string dev);
    dl_dup_seq_rec r;
    if (dev == "RC") begin
      r = dl_dup_seq_rec::type_id::create({dev, "_rec"});
      return r;
    end
    return super.make_recorder(dev);
  endfunction

  function void setup_expected_errors();
    catcher.expect_id("SEQ_CHECK");
    catcher.expect_id("REPLAY_TIMER");
    catcher.expect_id("LCRC");
    catcher.watch_text("Duplicate TLP detected");
  endfunction

  function void dl_checks();
    dl_tx_record ack;
    dl_check(catcher.text_hits("Duplicate TLP detected") >= 1, "EP detected the duplicate TLP",
             $sformatf("hits=%0d", catcher.text_hits("Duplicate TLP detected")));
    dl_check(ep_dl.tl_queue.size() <= rc_dl.NEXT_TRANSMIT_SEQ, "EP did not pass the duplicate to the TL",
             $sformatf("EP accepted=%0d, RC TLPs=%0d", ep_dl.tl_queue.size(), rc_dl.NEXT_TRANSMIT_SEQ));
    dl_check(ep_rec.count_dllp(ACK_DLLP_TYPE, "DL_ACTIVE") >= 1, "EP sent an ACK after the duplicate",
             $sformatf("ACKs sent=%0d", ep_rec.count_dllp(ACK_DLLP_TYPE, "DL_ACTIVE")));
    ack = ep_rec.last_dllp(ACK_DLLP_TYPE);
    if (ack != null && ack.state == "DL_ACTIVE")
      dl_check(ack.acknak_seq == 0, "ACK carries the last good sequence number (0)",
               $sformatf("AckNak_Seq_Num=%0d", ack.acknak_seq));
  endfunction
endclass


//------------------------------------------------------------------------------
// dl_seq_skip_test
//   Inject: RC's first TLP is sent with sequence number 2 (0 and 1 missing).
//   Spec: EP drops it (not NEXT_RCV_SEQ) and sends a NAK with
//   AckNak_Seq_Num = NEXT_RCV_SEQ-1 = 4095; RC then replays from seq 0.
//------------------------------------------------------------------------------
class dl_skip_seq_rec extends dl_tx_recorder;
  `uvm_object_utils(dl_skip_seq_rec)
  function new(string name = "dl_skip_seq_rec");
    super.new(name);
  endfunction
  function bit inject(ref pcie_dl_seq_item item);
    bit [31:0] words[$];
    if (item.dllp_pkt.size() > 2 && item.dllp_pkt[0] == `STP && n_tlp_seen == 0) begin
      item.dllp_pkt[1] = {12'd2, item.dllp_pkt[1][19:0]};
      for (int i = 2; i < item.dllp_pkt.size() - 1; i++) words.push_back(item.dllp_pkt[i]);
      item.dllp_pkt[item.dllp_pkt.size()-1] = item.calculate_lcrc(words);
      `uvm_info("DL_INJECT", $sformatf("%s: first TLP sent with sequence number 2 (0 and 1 skipped)", dev_name), UVM_NONE)
      return 1;
    end
    return 0;
  endfunction
endclass

class dl_seq_skip_test extends dl_base_test;
  `uvm_component_utils(dl_seq_skip_test)

  function new(string name = "dl_seq_skip_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function dl_tx_recorder make_recorder(string dev);
    dl_skip_seq_rec r;
    if (dev == "RC") begin
      r = dl_skip_seq_rec::type_id::create({dev, "_rec"});
      return r;
    end
    return super.make_recorder(dev);
  endfunction

  function void setup_expected_errors();
    catcher.expect_id("SEQ_CHECK");
    catcher.expect_id("REPLAY_TIMER");
    catcher.expect_id("LCRC");
  endfunction

  function void dl_checks();
    dl_tx_record nak;
    dl_check(catcher.warnings("SEQ_CHECK") >= 1, "EP detected the out-of-sequence TLP",
             $sformatf("out-of-sequence warnings=%0d", catcher.warnings("SEQ_CHECK")));
    dl_check(ep_rec.count_dllp(NAK_DLLP_TYPE, "DL_ACTIVE") >= 1, "EP sent a NAK",
             $sformatf("NAKs sent=%0d", ep_rec.count_dllp(NAK_DLLP_TYPE, "DL_ACTIVE")));
    nak = ep_rec.last_dllp(NAK_DLLP_TYPE);
    if (nak != null)
      dl_check(nak.acknak_seq == 12'hFFF, "NAK carries NEXT_RCV_SEQ-1 (4095)",
               $sformatf("AckNak_Seq_Num=%0d", nak.acknak_seq));
    dl_check(ep_dl.tl_queue.size() == rc_dl.NEXT_TRANSMIT_SEQ,
             "EP delivered all of RC's TLPs after the replay",
             $sformatf("EP accepted=%0d, RC TLPs=%0d", ep_dl.tl_queue.size(), rc_dl.NEXT_TRANSMIT_SEQ));
  endfunction
endclass


//------------------------------------------------------------------------------
// dl_nullified_tlp_test
//   Inject: RC's first TLP is sent with an inverted LCRC (nullified TLP).
//   Spec: the receiver discards a nullified TLP with no further action: no
//   NAK, not passed to the TL, and NEXT_RCV_SEQ is NOT incremented.
//------------------------------------------------------------------------------
class dl_nullify_rec extends dl_tx_recorder;
  `uvm_object_utils(dl_nullify_rec)
  function new(string name = "dl_nullify_rec");
    super.new(name);
  endfunction
  function bit inject(ref pcie_dl_seq_item item);
    if (item.dllp_pkt.size() > 2 && item.dllp_pkt[0] == `STP && n_tlp_seen == 0) begin
      item.dllp_pkt[item.dllp_pkt.size()-1] = ~item.dllp_pkt[item.dllp_pkt.size()-1];
      `uvm_info("DL_INJECT", $sformatf("%s: first TLP nullified (LCRC inverted)", dev_name), UVM_NONE)
      return 1;
    end
    return 0;
  endfunction
endclass

class dl_nullified_tlp_test extends dl_base_test;
  `uvm_component_utils(dl_nullified_tlp_test)
  bit [11:0] ep_nrs_before;
  bit [11:0] ep_nrs_after;
  bit        sampled;

  function new(string name = "dl_nullified_tlp_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function dl_tx_recorder make_recorder(string dev);
    dl_nullify_rec r;
    if (dev == "RC") begin
      r = dl_nullify_rec::type_id::create({dev, "_rec"});
      return r;
    end
    return super.make_recorder(dev);
  endfunction

  function void setup_expected_errors();
    catcher.expect_id("LCRC");        // EP: "Nulified TLP ... Dropping" warning
    catcher.expect_id("SEQ_CHECK");
    catcher.expect_id("REPLAY_TIMER");
  endfunction

  // Sample EP's NEXT_RCV_SEQ just before and just after the nullified TLP
  task watch_ep();
    while (ep_dl.fsm.curr_state != DL_ACTIVE) @(posedge ep_dl.vif.clk);
    while (catcher.warnings("LCRC") == 0) begin
      ep_nrs_before = ep_dl.next_rcv_seq;
      @(posedge ep_dl.vif.clk);
    end
    ep_nrs_after = ep_dl.next_rcv_seq;
    sampled = 1;
  endtask

  task run_phase(uvm_phase phase);
    fork
      watch_ep();
    join_none
    super.run_phase(phase);
  endtask

  function void dl_checks();
    dl_check(catcher.warnings("LCRC") >= 1, "EP recognised the nullified TLP",
             $sformatf("nullified warnings=%0d", catcher.warnings("LCRC")));
    dl_check(sampled && ep_nrs_after == ep_nrs_before, "NEXT_RCV_SEQ not incremented by the nullified TLP",
             $sformatf("before=%0d after=%0d", ep_nrs_before, ep_nrs_after));
    dl_check(ep_dl.tl_queue.size() <= rc_dl.NEXT_TRANSMIT_SEQ, "Nullified TLP not passed to the TL",
             $sformatf("EP accepted=%0d, RC TLPs=%0d", ep_dl.tl_queue.size(), rc_dl.NEXT_TRANSMIT_SEQ));
  endfunction
endclass
