// ============================================================
// SIV PCIe Link Training Interface (siv_ltssm_intf)
// ============================================================

interface siv_ltssm_intf(input logic clk, input logic rst);
  
  logic [7:0] tx_data;     // Transmit data (8-bit symbols)
                           // Carries TS1/TS2 training sequences or idle data
  logic [7:0] rx_data;     // Receive data (8-bit symbols)
                           // In real implementation would come from link partner
  logic [4:0] current_state; // Current LTSSM state
  logic  tx_elec_idle;      // Transmitter electrical Idle
  logic  rx_elec_idle;     // Receiver electrical Idle
endinterface

//--------------------------------------------------------------