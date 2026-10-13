//------------------------------------------------------------------------------
// dl_rx_fc_update_test
//   Setup: EP returns credits (cfg.rx_fc_auto_update = 1): every TLP it
//   passes to its TL frees the credits, which are advertised again with an
//   UpdateFC. RC's TL sends 40 memory writes; EP's DL sequence advertises
//   only 32/33 Posted header credits.
//   Spec: the receiver keeps CREDITS_ALLOCATED / CREDITS_RECEIVED per type,
//   never overflows, and returns freed credits with UpdateFC. Without credit
//   return RC stops after 33 MWr; with it all 40 get through.
//------------------------------------------------------------------------------
class dl_rx_fc_update_test extends dl_base_test;
  `uvm_component_utils(dl_rx_fc_update_test)
  int num_mwr = 40;

  function new(string name = "dl_rx_fc_update_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void setup_knobs();
    set_type_override_by_type(mem_wr_rd_seq::get_type(), dl_multi_mwr_seq::get_type());
    dl_multi_mwr_seq::num_mwr = num_mwr;
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    ep_dl.cfg.rx_fc_auto_update   = 1;
    ep_dl.cfg.rx_fc_update_cycles = 50;
  endfunction

  function void setup_expected_errors();
    catcher.watch_text("Receiver overflow");
    catcher.watch_text("returning Posted credits");
  endfunction

  function void dl_checks();
    bit seen[int];
    int posted;
    int init_hdr;
    int max_upd_hdr;
    posted = 0;
    foreach (rc_rec.recs[i]) begin
      if (!rc_rec.recs[i].is_tlp || rc_rec.recs[i].dws.size() < 2) continue;
      if (seen.exists(rc_rec.recs[i].seq_num)) continue;
      seen[rc_rec.recs[i].seq_num] = 1;
      if (rc_rec.recs[i].dws[1][30] == 1'b1 && rc_rec.recs[i].dws[1][28:24] == 5'b00000) posted++;
    end
    init_hdr    = -1;
    max_upd_hdr = -1;
    foreach (ep_rec.recs[i]) begin
      if (ep_rec.recs[i].is_tlp) continue;
      if (ep_rec.recs[i].dllp_type == INITFC1_P_VC0 && init_hdr < 0) init_hdr = ep_rec.recs[i].hdr_fc;
      if (ep_rec.recs[i].dllp_type == UPDATEFC_P_VC0 && int'(ep_rec.recs[i].hdr_fc) > max_upd_hdr) max_upd_hdr = ep_rec.recs[i].hdr_fc;
    end

    dl_check(catcher.text_hits("returning Posted credits") >= 1, "EP returned freed Posted credits with UpdateFC",
             $sformatf("UpdateFC sent by EP's driver=%0d", catcher.text_hits("returning Posted credits")));
    dl_check(max_upd_hdr > init_hdr + 1, "EP advertised more Posted header credits than its initial InitFC",
             $sformatf("InitFC1_P HdrFC=%0d, highest UpdateFC_P HdrFC=%0d", init_hdr, max_upd_hdr));
    dl_check(posted == num_mwr, "RC sent all MWr (credits came back)", $sformatf("posted TLPs sent=%0d of %0d", posted, num_mwr));
    dl_check(ep_dl.tl_queue.size() == num_mwr, "EP accepted all MWr", $sformatf("accepted=%0d", ep_dl.tl_queue.size()));
    dl_check(catcher.text_hits("Receiver overflow") == 0, "No receiver overflow at EP",
             $sformatf("overflow errors=%0d", catcher.text_hits("Receiver overflow")));
  endfunction
endclass
