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
