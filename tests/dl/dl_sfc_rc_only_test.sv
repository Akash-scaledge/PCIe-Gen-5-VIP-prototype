//------------------------------------------------------------------------------
// dl_sfc_rc_only_test
//   Setup: both ports have DLF Exchange Enable = 1. RC supports Scaled FC
//   (DLF Capabilities = 8000_0001h), EP does not (8000_0000h).
//   Inject: RC still sends HdrScale = 11 / DataScale = 11 in its InitFC and
//   UpdateFC DLLPs (an RC that ignores the negotiation).
//   +DL_SFC_RC_INJECT=0 makes RC send 00 instead (fully legal stimulus).
//   Spec: the DLF exchange completes (both Remote Valid = 1; RC sees EP's
//   Scaled FC bit = 0, EP sees RC's = 1), but Scaled FC is NOT active.
//   EP must ignore RC's scale fields; both store the raw advertised credits.
//   EP sends 00 in every FC DLLP.
//------------------------------------------------------------------------------
class dl_sfc_rc_only_test extends dl_sfc_base_test;
  `uvm_component_utils(dl_sfc_rc_only_test)

  function new(string name = "dl_sfc_rc_only_test", uvm_component parent = null);
    int inject;
    super.new(name, parent);
    inject = 1;
    void'($value$plusargs("DL_SFC_RC_INJECT=%d", inject));
    dlf_cap        = '{32'h8000_0001, 32'h8000_0000};
    hdr_scale      = '{(inject != 0) ? 2'b11 : 2'b00, 2'b00};
    data_scale     = '{(inject != 0) ? 2'b11 : 2'b00, 2'b00};
    scale_injected = '{inject != 0, 1'b0};
  endfunction
endclass
