//==============================================================================
// dl_tests_akash.svh  -  DL tests owned by Akash Kumar Sahu (M7)
//
//   dl_init_test            DLCMSM states, DL feature exchange, InitFC credits
//   dl_ack_test             ACK DLLPs, ACKD_SEQ, replay buffer purge
//   dl_lcrc_nak_test        bad LCRC -> NAK -> replay -> delivered once
//   dl_lcrc_seq_cover_test  LCRC must cover the sequence number
//   dl_4dw_hdr_test         4 DW header (64-bit address) TLP: sent, replayed, decoded
//   dl_rx_fc_update_test    receiver returns credits with UpdateFC, no overflow
//   dl_link_down_test       DL_Down: state reset, re-initialisation to DL_ACTIVE
//==============================================================================


`include "./dl_init_test.sv"
`include "./dl_ack_test.sv"
`include "./dl_lcrc_nak_test.sv"
`include "./dl_lcrc_seq_cover_test.sv"
`include "./dl_4dw_hdr_test.sv"
`include "./dl_rx_fc_update_test.sv"
`include "./dl_link_down_test.sv"





