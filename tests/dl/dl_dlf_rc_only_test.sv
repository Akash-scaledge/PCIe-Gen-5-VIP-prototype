//------------------------------------------------------------------------------
// dl_dlf_rc_only_test
//   Setup: RC has DLF Exchange Enable = 1 and Scaled FC = 1 (DLF Capabilities
//   = 8000_0001h). EP has DLF Exchange Enable = 0 (0000_0000h).
//   Inject: nothing.
//   Spec:
//     - RC enters DL_FEATURE and sends DLF DLLPs. EP goes DL_INACTIVE ->
//       DL_INIT directly and sends InitFC1.
//     - RC leaves DL_FEATURE when it receives InitFC1 and both reach DL_ACTIVE.
//     - RC: Remote DLF Supported Valid = 0, remote features = 0 (driver cfg and
//       DLF Status register). EP never did an exchange: Remote Valid = 0.
//     - Scaled FC not active: 00 scale fields, raw credit limits.
//------------------------------------------------------------------------------
class dl_dlf_rc_only_test extends dl_sfc_base_test;
  `uvm_component_utils(dl_dlf_rc_only_test)

  function new(string name = "dl_dlf_rc_only_test", uvm_component parent = null);
    super.new(name, parent);
    dlf_cap        = '{32'h8000_0001, 32'h0000_0000};
    hdr_scale      = '{2'b00, 2'b00};
    data_scale     = '{2'b00, 2'b00};
    scale_injected = '{0, 0};
  endfunction

  function void dl_checks();
    super.dl_checks();
    dl_check(rc_rec.count_dllp(INITFC1_P_VC0) > 0 && ep_rec.count_dllp(INITFC1_P_VC0) > 0,
             "RC and EP both sent InitFC1 (RC after leaving DL_FEATURE)",
             $sformatf("InitFC1_P sent: RC=%0d EP=%0d", rc_rec.count_dllp(INITFC1_P_VC0), ep_rec.count_dllp(INITFC1_P_VC0)));
  endfunction
endclass
