//------------------------------------------------------------------------------
// dl_sfc_both_support_test
//   Setup: RC and EP both have DLF Exchange Enable = 1 and Local Scaled FC
//   Supported = 1 (DLF Capabilities = 8000_0001h).
//     RC sends HdrScale = 11 (x16), DataScale = 10 (x4)
//     EP sends HdrScale = 10 (x4),  DataScale = 11 (x16)
//   Different scales per direction, so a swapped or shared scale shows up.
//   Inject: nothing.
//   Spec: Scaled FC is active on both ports. Each receiver multiplies HdrFC /
//   DataFC by the scale in the DLLP: with InitFC 32/256,
//     EP limits (from RC): Hdr 32 x16 = 512, Data 256 x4  = 1024
//     RC limits (from EP): Hdr 32 x4  = 128, Data 256 x16 = 4096
//   Every InitFC1/InitFC2/UpdateFC a port sends (also the ones the driver
//   generates itself) carries the same non-zero HdrScale/DataScale.
//------------------------------------------------------------------------------
class dl_sfc_both_support_test extends dl_sfc_base_test;
  `uvm_component_utils(dl_sfc_both_support_test)

  function new(string name = "dl_sfc_both_support_test", uvm_component parent = null);
    super.new(name, parent);
    dlf_cap        = '{32'h8000_0001, 32'h8000_0001};
    hdr_scale      = '{2'b11, 2'b10};
    data_scale     = '{2'b10, 2'b11};
    scale_injected = '{0, 0};
  endfunction
endclass
