`define PCIE_DLLP_TYPE_INITFC1_P_VC0 		8'b01000000   //40
`define PCIE_DLLP_TYPE_INITFC1_NP_VC0 		8'b01010000  //50
`define PCIE_DLLP_TYPE_INITFC1_CPL_VC0 		8'b01100000 //60
`define PCIE_DLLP_TYPE_INITFC2_P_VC0 		8'b11000000   //C0
`define PCIE_DLLP_TYPE_INITFC2_NP_VC0 		8'b11010000  //D0
`define PCIE_DLLP_TYPE_INITFC2_CPL_VC0 		8'b11100000 //E0
`define PCIE_DLLP_TYPE_UPDATEFC_P_VC0 		8'b10000000  //80
`define PCIE_DLLP_TYPE_UPDATEFC_NP_VC0 		8'b10010000 //90
`define PCIE_DLLP_TYPE_UPDATEFC_CPL_VC0 	8'b10100000//A0
`define PCIE_DLLP_TYPE_ACK_DLLP_TYPE 		8'b00000000
`define PCIE_DLLP_TYPE_NAK_DLLP_TYPE 		8'b00010000
`define PCIE_DLLP_TYPE_DATA_LINK_FEATURE 	8'b00000010 
`define PCIE_DLLP_TYPE_NOP 					8'b00110001 ///NOP
`define PCIE_DLLP_TYPE_PM_Enter_L1			8'b00100000
`define PCIE_DLLP_TYPE_PM_Enter_L23			8'b00100001
`define PCIE_DLLP_TYPE_PM_Active_State_Request_L1			8'b00100011
`define PCIE_DLLP_TYPE_PM_Request_Ack		8'b00100100 
`define NUM_TLPS_TO_SEND 2

`define RC_FEATURE_SUPPORT 1'b1
`define EP_FEATURE_SUPPORT 1'b1
`define STP 32'hDEADBEEF
`define SDP 32'hDEADBEEA

typedef enum bit [7:0] {INITFC1_P_VC0    = `PCIE_DLLP_TYPE_INITFC1_P_VC0,
                        INITFC1_NP_VC0   = `PCIE_DLLP_TYPE_INITFC1_NP_VC0,
                        INITFC1_CPL_VC0  = `PCIE_DLLP_TYPE_INITFC1_CPL_VC0,
                        INITFC2_P_VC0    = `PCIE_DLLP_TYPE_INITFC2_P_VC0,
                        INITFC2_NP_VC0   = `PCIE_DLLP_TYPE_INITFC2_NP_VC0,
                        INITFC2_CPL_VC0  = `PCIE_DLLP_TYPE_INITFC2_CPL_VC0,
                        UPDATEFC_P_VC0   = `PCIE_DLLP_TYPE_UPDATEFC_P_VC0,
                        UPDATEFC_NP_VC0  = `PCIE_DLLP_TYPE_UPDATEFC_NP_VC0,
                        UPDATEFC_CPL_VC0 = `PCIE_DLLP_TYPE_UPDATEFC_CPL_VC0,
                        ACK_DLLP_TYPE = `PCIE_DLLP_TYPE_ACK_DLLP_TYPE,
                        NAK_DLLP_TYPE = `PCIE_DLLP_TYPE_NAK_DLLP_TYPE,
                        DATA_LINK_FEATURE = `PCIE_DLLP_TYPE_DATA_LINK_FEATURE,
                        NOP= `PCIE_DLLP_TYPE_NOP,
                        PM_Enter_L1= `PCIE_DLLP_TYPE_PM_Enter_L1,
                        PM_Enter_L23= `PCIE_DLLP_TYPE_PM_Enter_L23,
                        PM_Active_State_Request_L1= `PCIE_DLLP_TYPE_PM_Active_State_Request_L1,
                        PM_Request_Ack= `PCIE_DLLP_TYPE_PM_Request_Ack
                       }dllp_type_e;

typedef enum {
  DL_INACTIVE,
  DL_FEATURE, //
  DL_INIT, 
  FC_INIT1,
  FC_INIT2,
  DL_ACTIVE
} dlcmsm_state_e;

typedef struct packed{
  dllp_type_e dllp_type; // 8 bits
  logic [1:0] rsvd1;  	// 2 bits
  logic [7:0] HdrFC;     // 8 bits
  logic [1:0] rsvd2;  	// 2 bits
  logic [11:0] DataFC;   // 12 bits
  logic [15:0] crc16;               // 16-bit CRC
} header_dllp_structure; // Total 32 + 16 = 48

typedef struct packed{
  dllp_type_e dllp_type; // 8 bits
  logic [1:0] HdrScl;  	// 2 bits
  logic [7:0] HdrFC;     // 8 bits
  logic [1:0] DataScl;  	// 2 bits
  logic [11:0] DataFC;   // 12 bits
  logic [15:0] crc16;               // 16-bit CRC
} header_dllp_sfc_structure;


typedef struct packed {
  dllp_type_e dllp_type;   // 8 bits
  logic [11:0] rsvd;       // 12 bits 
  logic [11:0] seq_num;    // 12 bits      
  logic [15:0] crc16;      // 16 bits
} dllp_acknak; // Total: 48 bits (6 bytes) 

typedef struct packed{
  logic [2:0]  Fmt;
  logic [4:0]  Type;
  logic        rsvd1;
  logic [2:0]  TC;   
  logic        rsvd2;
  logic        attr1;
  logic        rsvd3;
  logic        TH;
  logic        TD;
  logic        EP;
  logic [1:0]  attr2;
  logic [1:0]  AT;
  logic [9:0]  length;
  logic [63:0] Address;
  logic [31:0] sdw;
} header_tlp_structure;

typedef struct packed{
  dllp_type_e dllp_type;
  logic feature_ack;
  logic [22:0] feature_sprt;
  logic [15:0] crc16;
} dllp_feature_structure;

///////////Adding the structure for powermanagement///////////////////////
typedef struct packed {
  dllp_type_e dllp_type;   // 8 bits
  logic [23:0] rsvd;       // 24 bits     
  logic [15:0] crc16;      // 16 bits
} dllp_pm; // Total: 48 bits (6 bytes) 

// parameter int LTSSM_1MS = 50;
// parameter int LTSSM_2MS = 2*LTSSM_1MS;
// parameter int LTSSM_12MS = 12*LTSSM_1MS;
dlcmsm_state_e dlcmsm_rc_state,dlcmsm_ep_state;


