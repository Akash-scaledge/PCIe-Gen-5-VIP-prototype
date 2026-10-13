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

