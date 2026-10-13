//------------------------------------------------------------------------------
// dl_4dw_hdr_test
//   Stimulus: once RC's DL is in DL_ACTIVE, a Memory Write with a 64-bit
//   address (Fmt = 011b, 4 DW header, 2 DW payload) is put in RC's TL->DL
//   queue.
//   Inject: the first transmission of that TLP gets a bad LCRC, so EP Naks it
//   and RC replays it from the replay buffer.
//   Spec: the DL carries the 4 DW header unchanged; the replayed TLP is the
//   same TLP (sequence number, header, data) with the correct LCRC; EP accepts
//   it exactly once and passes it to the TL without sequence number and LCRC.
//------------------------------------------------------------------------------
class dl_4dw_lcrc_rec extends dl_tx_recorder;
  `uvm_object_utils(dl_4dw_lcrc_rec)
  static const bit [31:0] HDR0     = 32'h6000_0002;   // Fmt=011 (4 DW, data) Type=00000 (MWr) Length=2
  static const bit [31:0] LCRC_XOR = 32'h0000_00FF;
  bit done;

  function new(string name = "dl_4dw_lcrc_rec");
    super.new(name);
  endfunction

  function bit inject(ref pcie_dl_seq_item item);
    int last;
    if (!done && item.dllp_pkt.size() > 2 && item.dllp_pkt[0] == `STP && item.dllp_pkt[2] == HDR0) begin
      last = item.dllp_pkt.size() - 1;
      item.dllp_pkt[last] = item.dllp_pkt[last] ^ LCRC_XOR;
      done = 1;
      `uvm_info("DL_INJECT", $sformatf("%s: 4 DW MWr seq=%0d sent with a bad LCRC", dev_name, item.dllp_pkt[1][31:20]), UVM_NONE)
      return 1;
    end
    return 0;
  endfunction
endclass

class dl_4dw_hdr_test extends dl_base_test;
  `uvm_component_utils(dl_4dw_hdr_test)
  bit [31:0] tlp_dws[$];   // the TLP as handed from TL to DL: header + payload

  function new(string name = "dl_4dw_hdr_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function dl_tx_recorder make_recorder(string dev);
    if (dev == "RC") return dl_4dw_lcrc_rec::type_id::create({dev, "_rec"});
    return super.make_recorder(dev);
  endfunction

  function void setup_expected_errors();
    catcher.expect_id("LCRC");          // EP: the corrupted copy
    catcher.expect_id("SEQ_CHECK");     // TLPs that follow it before the replay
    catcher.expect_id("REPLAY_TIMER");
  endfunction

  task send_4dw_tlp();
    wait (rc_dl.fsm.curr_state == DL_ACTIVE);
    repeat (10) @(posedge rc_dl.vif.clk);
    tlp_dws = '{dl_4dw_lcrc_rec::HDR0,
                32'h0100_00FF,                    // Requester ID 0100h, Tag 0, Last/First BE Fh
                32'h0000_0001,                    // Address[63:32]
                32'h0000_2000,                    // Address[31:0]
                32'hCAFE_0001, 32'hCAFE_0002};    // data
    rc_dl.dl_tlp_queue.push_back(tlp_dws);
    `uvm_info("DL_TEST", $sformatf("4 DW MWr handed to RC's DL: %p", tlp_dws), UVM_NONE)
  endtask

  task run_phase(uvm_phase phase);
    fork
      send_4dw_tlp();
    join_none
    super.run_phase(phase);
  endtask

  function void dl_checks();
    dl_tx_record     sends[$];
    pcie_dl_seq_item got;
    int              n_rx;
    bit              ok;

    // every RC transmission of the 4 DW TLP; dws = {seq DW, 4 DW header, 2 DW data, LCRC}
    foreach (rc_rec.recs[i])
      if (rc_rec.recs[i].is_tlp && rc_rec.recs[i].dws.size() > 1 && rc_rec.recs[i].dws[1] == dl_4dw_lcrc_rec::HDR0)
        sends.push_back(rc_rec.recs[i]);

    dl_check(sends.size() >= 2, "RC sent the 4 DW TLP and replayed it after the Nak",
             $sformatf("transmissions=%0d", sends.size()));

    if (sends.size() >= 1) begin
      ok = (sends[0].dws.size() == 8);
      if (ok) foreach (tlp_dws[k]) if (sends[0].dws[k + 1] != tlp_dws[k]) ok = 0;
      dl_check(ok, "4 DW header and data sent unchanged (seq DW + 4 DW header + 2 DW data + LCRC)",
               $sformatf("sent=%p", sends[0].dws));
    end

    if (sends.size() >= 2) begin
      ok = (sends[1].dws.size() == sends[0].dws.size()) && (sends[1].dws.size() == 8);
      if (ok) for (int k = 0; k < 7; k++) if (sends[1].dws[k] != sends[0].dws[k]) ok = 0;
      if (ok) ok = (sends[1].dws[7] == (sends[0].dws[7] ^ dl_4dw_lcrc_rec::LCRC_XOR));
      dl_check(ok, "Replayed TLP = original (same seq, 4 DW header, data) with the correct LCRC",
               $sformatf("first=%p replay=%p", sends[0].dws, sends[1].dws));
    end

    // EP side
    n_rx = 0;
    got  = null;
    foreach (ep_dl.tl_queue[i])
      if (ep_dl.tl_queue[i].tlp_pkt.size() > 0 && ep_dl.tl_queue[i].tlp_pkt[0] == dl_4dw_lcrc_rec::HDR0) begin
        n_rx++;
        got = ep_dl.tl_queue[i];
      end
    dl_check(n_rx == 1, "EP accepted the 4 DW TLP exactly once", $sformatf("accepted=%0d", n_rx));
    if (got != null) begin
      ok = (got.tlp_pkt.size() == tlp_dws.size());
      if (ok) foreach (tlp_dws[k]) if (got.tlp_pkt[k] != tlp_dws[k]) ok = 0;
      dl_check(ok, "EP passed the TLP up without sequence number and LCRC (4 DW header + 2 DW data)",
               $sformatf("passed up=%p", got.tlp_pkt));
      dl_check(got.tlps_pkt.Address == 64'h0000_0001_0000_2000, "EP decoded the 64-bit address",
               $sformatf("Address='h%0h", got.tlps_pkt.Address));
      ok = (got.payload.size() == 2);
      if (ok) ok = (got.payload[0] == 32'hCAFE_0001 && got.payload[1] == 32'hCAFE_0002);
      dl_check(ok, "EP decoded the 2 DW payload (4th header DW is not payload)", $sformatf("payload=%p", got.payload));
    end
  endfunction
endclass
