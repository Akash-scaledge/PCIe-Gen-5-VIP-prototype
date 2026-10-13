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

