// ============================================================
// SIV PCIe Link Training Interface (siv_pl_if)
// ============================================================
interface siv_tl_if(input logic clk, input logic rst);
  bit [31:0] tx_data;
  bit [31:0] rx_data;
endinterface