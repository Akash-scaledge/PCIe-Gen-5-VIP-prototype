//--------------------------------------------------------------
// SIV PCIe LTSSM Parameters and Definitions
//--------------------------------------------------------------
// Contains all constants, parameters and type definitions
// for PCIe Link Training and Status State Machine (LTSSM)
// Physical Layer Constants

//defines for Data Rate
`define SPEED_2_5_GTS 5'b00001
`define SPEED_5_GTS   5'b00011
`define SPEED_8_GTS   5'b00111
`define SPEED_16_GTS  5'b01111
`define SPEED_32_GTS  5'b11111
`define SPEED_64_GTS  5'b10111

// PCIe Specification Versions
`define PCIE_SPEC_3     3'b001  // Gen3 (8 GT/s)
`define PCIE_SPEC_4     3'b010  // Gen4 (16 GT/s)
`define PCIE_SPEC_5     3'b100  // Gen5 (32 GT/s)

// Equalization Link Behavior Control
`define EQ_MODE_FULL       2'b00  // Full Equalization (Normal Operation)
`define EQ_MODE_BYPASS     2'b01  // Equalization Bypass
`define EQ_MODE_NO         2'b10  // No Equalization
`define MODIFIED_TS        2'b11  // Modified TS1/TS2 Ordered Set

`define TS_1024 16  // Number of OS for 1024-byte boundary
`define EXTENDED_SYNC_4096_FTS 10  //This is the 4096 FTS if Extended Synch Bit is set
`define FTS_255 5 // This is the normal FTS value

parameter NUM_LANES = 1;
parameter COM = 8'hBC; // K28.5 - COM symbol
parameter bit [7:0] PAD = 8'hF7;  // Default PAD value
parameter TS1_ID = 8'h4A;
parameter TS2_ID = 8'h45;
parameter bit [7:0] CTRL_SKP_ID = 8'hAA;
parameter bit [7:0] SKP_ID = 8'hAA;
parameter bit [7:0] FTS_ID = 8'h55;
parameter bit [7:0] EIOS_ID = 8'h66;
parameter bit [7:0] SDS_ID = 8'h87;
parameter bit [7:0] EIE_ID = 8'h00; // EIEOS: 4x00h
parameter bit [7:0] EIE_ID2 = 8'hff; // EIEOS: 4x11h

// Timing Parameters (in clock cycles)
parameter int LTSSM_1MS = 250;
parameter int LTSSM_2MS = 2*LTSSM_1MS;
parameter int LTSSM_12MS = 12*LTSSM_1MS;
parameter int LTSSM_24MS = 24*LTSSM_1MS;
parameter int LTSSM_32MS = 32*LTSSM_1MS;
parameter int LTSSM_48MS = 48*LTSSM_1MS;
parameter int LTSSM_800NS = 0.0008*LTSSM_1MS;
parameter int LTSSM_100MS = 0.0001*LTSSM_1MS;
parameter int IDLE_MIN = 0.2*LTSSM_1MS; // 20ns -> 0.00002ms
parameter int N_FTS_TIMEOUT = 8*LTSSM_1MS; // Not Correct Time (As of now Random Time)
parameter int L1_MIN_STAY = 0.00004*LTSSM_1MS; // 40ns -> 0.00004ms
parameter int L1_100MS = 25000000; // 100ms

// Data Rate Identifiers

// Data Rate Identifiers
parameter DATA_RATE_2_5_GT = 8'b0000_0010;
parameter DATA_RATE_5_0_GT = 8'b0000_0110;  
parameter DATA_RATE_8_0_GT = 8'b0000_1110;  
parameter DATA_RATE_16_0_GT = 8'b0001_1110;
parameter DATA_RATE_32_0_GT = 8'b0011_1110;
parameter DATA_RATE_64_0_GT = 8'b0010_1111;

// Encoding Scheme Types
typedef enum {
    ENV_8B10B,     // 8B/10B encoding
    ENC_128B130B,  // 128B/130B encoding
    ENC_1B1B       // 1B/1B encoding
} pcie_encoding_e;

// Ordered Set Types
typedef enum {
    OS_TS0 = 0,     // Training Sequence 0
    OS_TS1 = 1,     // Training Sequence 1
    OS_TS2 = 2,     // Training Sequence 2
    OS_SKP = 3,     // Skip Ordered Set
    OS_FTS = 4,     // Fast Training Sequence
    OS_EIOS = 5,    // Electrical idle ordered set
    OS_SDS = 6,     // start of data tsream
    OS_EIE = 7,     // Electrical idle exit os
    OS_CTRL_SKP = 8 // skip control
} pcie_os_type_e;

// LTSSM States (Updated with Equalization States)
typedef enum {
  DETECT_QUIET,
  DETECT_ACTIVE,
  POLLING_ACTIVE,
  POLLING_CONFIG,
  CONFIG_LINKWIDTH_START,
  CONFIG_LINKWIDTH_ACCEPT,
  CONFIG_LANENUM_WAIT,
  CONFIG_LANENUM_ACCEPT,
  CONFIG_COMPLETE,
  CONFIG_IDLE,
  L0,
  RECOVERY_RCVRLOCK,
  RECOVERY_RCFG,
  RECOVERY_EQUALIZATION_PHASE_0,  // New state
  RECOVERY_EQUALIZATION_PHASE_1,  // New state
  RECOVERY_EQUALIZATION_PHASE_2,  // New state
  RECOVERY_EQUALIZATION_PHASE_3,  // New state
  RECOVERY_SPEED,
  RECOVERY_IDLE,
  L0S_ENTRY,
  L0S_IDLE,
  L0S_FTS,
  L1_ENTRY,
  L1_IDLE,
  L2_IDLE,
  L2_TRANSMITWAKE,
  DISABLED,
  LOOPBACK_ENTRY,
  LOOPBACK_ACTIVE,
  LOOPBACK_EXIT,
  HOTRESET,DISABLE
} ltssm_state_e;

ltssm_state_e ltssm_rc_state,ltssm_ep_state;

//Global Variables
bit      directed_speed_change=1;
bit[4:0] original_data_rate;
bit[4:0] cur_data_rate = `SPEED_2_5_GTS;
bit[4:0] adv_data_rate ;
bit[4:0] max_data_rate ;
bit[4:0] com_data_rate;
bit      changed_speed_recovery;
bit      successful_speed_negotiation;
bit      speed_change=1;
//Equalization Specific Variables
bit      equalization_done_8GT_data_rate;
bit      equalization_done_16GT_data_rate;
bit      equalization_done_32GT_data_rate;
bit      start_equalization_w_preset;

// Link is really up: in L0 AND no speed change pending.
// Same condition the LTSSM FSM uses in its L0 state (siv_ltssm_fsm.sv, L0 case).
// Without the speed-change check, sequences/DL can see the 1-timestep L0 that
// happens right before the L0 -> Recovery speed change and stop/start too early.
`define SIV_LINK_UP(st) (((st) == L0) && !(com_data_rate > `SPEED_2_5_GTS && cur_data_rate != com_data_rate))

//OS SENT STATUS
bit fts_sent=0;
bit eie_sent=0;
bit link_disable=0;
bit L0_Disable=0;
bit loopback_bit = 0;
bit perform_equalization_for_loopback=0;
bit loop_back_exit = 0;
bit timeout_check=0;
parameter int C0_MIN = 11; //min is 11
parameter int C0_MAX = 49;// max upto 49

parameter int c_minus1_min = -8;
parameter int c_minus1_max = 8;

parameter int c_plus1_min = -8;
parameter int c_plus1_max = 8;



bit L0x;



typedef enum {
  PKT_TLP,
  PKT_DLLP
} pkt_layer_e;



typedef struct packed{

  bit[3:0]len;

  bit[3:0]fixed1;

  bit FP;

  bit[6:0]len1;

  bit[3:0] FCRC;

  bit[11:0] TLP_seq_num;

}STP_TOKEN; 

STP_TOKEN STP;

typedef struct packed{

  bit[3:0]fixed ;

  bit[3:0]fixed1 ;

  bit fixed2 ;

  bit[6:0]fixed3 ;

  bit[3:0]fixed4 ;

  bit[11:0]fixed5 ;

}EDS_TOKEN; 

EDS_TOKEN EDS;

typedef struct packed{

  bit[7:0]fixed ;

  bit[7:0]fixed1 ;

  bit[7:0]fixed2 ;

  bit[7:0]fixed3 ;

}EDB_TOKEN; 

EDB_TOKEN EDB;

typedef struct packed{

  bit[7:0]fixed ;

  bit[7:0]fixed1 ;

}SDP_TOKEN; 

SDP_TOKEN SDP;

typedef struct packed{

  bit[7:0]fixed ;

}IDL_TOKEN; 

IDL_TOKEN IDL;

// global_que_t  pkt_from_dl_stored[$];

