//==============================================================================
// dl_tests_akash.svh  -  DL tests owned by Akash Kumar Sahu (M7)
//
//   dl_init_test            DLCMSM states, DL feature exchange, InitFC credits
//   dl_ack_test             ACK DLLPs, ACKD_SEQ, replay buffer purge
//   dl_lcrc_nak_test        bad LCRC -> NAK -> replay -> delivered once
//   dl_lcrc_seq_cover_test  LCRC must cover the sequence number
//==============================================================================


`include "./dl_init_test.sv"
`include "./dl_ack_test.sv"
`include "./dl_lcrc_nak_test.sv"
`include "./dl_lcrc_seq_cover_test.sv"





