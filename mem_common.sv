// Macro to define a constructor for UVM components
`define NEWCOMP\
    function new(string name, uvm_component parent);\
        super.new(name, parent);\
    endfunction

// Macro to define a constructor for UVM objects
`define NEWOBJ\
    function new(string name="");\
        super.new(name);\
    endfunction

`define pkt_len(PAYLOAD, HS, LENGTH, TD)\
if(PAYLOAD)\
  begin\
    pkt_len= LENGTH + TD + 3 + HS;\
  end\
else\
  begin\
    pkt_len= TD + 3 + HS;\
  end\

parameter WIDTH = 32;       // Data bus width
parameter DEPTH = 1024;     // Memory depth (number of locations)
parameter ADDR_SIZE = $clog2(DEPTH); // Address size calculated using clog2

// TC-VC Mapping data structures
typedef struct packed {
    bit         vc_enable;
    bit [3:0]   rsvdp_3;
    bit [2:0]   vc_id;
    bit [3:0]   rsvdp_2;
    bit [2:0]   port_arb_select;
    bit         load_pat;
    bit [7:0]   rsvdp_1;
    bit [7:0]   tc_vc_map;
} vc_res_ctrl_reg_t;

// VC Memory transaction tracking
    typedef struct {
        bit [2:0]  vc_id;
        bit [2:0]  tc;
        bit [31:0] address;
        bit [9:0]  length;
        string     operation;
        time       timestamp;
    } vc_memory_transaction_t;

    typedef struct {
        bit [2:0]  vc_id;
        bit [2:0]  tc;
        bit [31:0] address;
        bit [9:0]  length;
        string     operation;
        time       timestamp;
    } vc_io_transaction_t;
    
    // TC-VC mapping variables
    vc_res_ctrl_reg_t vc_res_ctrl_reg[];
    bit [2:0] tc_to_vc_map[8];              // TC0-TC7 -> VC ID mapping
    bit [7:0] active_vcs;                   // Bitmask of active VCs
    bit [2:0] current_vc;                   // Current VC being processed
    bit tc_vc_initialized;                  // Flag to track initialization
    vc_memory_transaction_t vc_memory_log[$]; // Transaction log
    vc_io_transaction_t vc_io_log[$];
// Array to store VC resource control registers
// vc_res_ctrl_reg_t vc_res_ctrl_reg[];

// // TC to VC mapping table (TC0-TC7 -> VC ID)
// bit [2:0] tc_to_vc_map[8];

// // VC arbitration and status tracking
// bit [7:0] active_vcs;           // Bitmask of active VCs
// bit [2:0] current_vc;           // Current VC being processed


/*//VC1_RESOURCE_CTRL_REG
typedef struct{
  logic        vc_enable=0;        // [31]
  logic[30:27] rsvdp_3=0;          // [30:27] Reserved
  logic[26:24] vc_id=3'b001;       // [26:24] VC ID
  logic[23:20] rsvdp_2=0;          // [23:20] Reserved
  logic[19:17] port_arb_select=0;  // [19:17] Port Arbitration Select
  logic        load_pat=0;         // [16]     Load Port Arbitration Table
  logic[15:8]  rsvdp_1=0;          // [15:8]   Reserved
  logic[7:0]   tc_vc_map=8'h0000_0010;    // [7:0]    TC/VC Map
} vc1_resource_ctrl_reg_t;
static vc1_resource_ctrl_reg_t vc1_res_ctrl_reg;

//VC2_RESOURCE_CTRL_REG
typedef struct{
  logic        vc_enable=0;        // [31]
  logic[30:27] rsvdp_3=0;          // [30:27] Reserved
  logic[26:24] vc_id=3'b010;       // [26:24] VC ID
  logic[23:20] rsvdp_2=0;          // [23:20] Reserved
  logic[19:17] port_arb_select=0;  // [19:17] Port Arbitration Select
  logic        load_pat=0;         // [16]     Load Port Arbitration Table
  logic[15:8]  rsvdp_1=0;          // [15:8]   Reserved
  logic[7:0]   tc_vc_map=8'b0000_0000;    // [7:0]    TC/VC Map
} vc2_resource_ctrl_reg_t;
static vc2_resource_ctrl_reg_t vc2_res_ctrl_reg;

//VC3_RESOURCE_CTRL_REG
typedef struct{
  logic        vc_enable=0;        // [31]
  logic[30:27] rsvdp_3=0;          // [30:27] Reserved
  logic[26:24] vc_id=3'b011;       // [26:24] VC ID
  logic[23:20] rsvdp_2=0;          // [23:20] Reserved
  logic[19:17] port_arb_select=0;  // [19:17] Port Arbitration Select
  logic        load_pat=0;         // [16]     Load Port Arbitration Table
  logic[15:8]  rsvdp_1=0;          // [15:8]   Reserved
  logic[7:0]   tc_vc_map=8'b0000_1000;    // [7:0]    TC/VC Map
} vc3_resource_ctrl_reg_t;
static vc3_resource_ctrl_reg_t vc3_res_ctrl_reg;

//VC4_RESOURCE_CTRL_REG
typedef struct{
  logic        vc_enable=0;        // [31]
  logic[30:27] rsvdp_3=0;          // [30:27] Reserved
  logic[26:24] vc_id=3'b100;       // [26:24] VC ID
  logic[23:20] rsvdp_2=0;          // [23:20] Reserved
  logic[19:17] port_arb_select=0;  // [19:17] Port Arbitration Select
  logic        load_pat=0;         // [16]     Load Port Arbitration Table
  logic[15:8]  rsvdp_1=0;          // [15:8]   Reserved
  logic[7:0]   tc_vc_map=8'b0001_0000;    // [7:0]    TC/VC Map
} vc4_resource_ctrl_reg_t;
static vc4_resource_ctrl_reg_t vc4_res_ctrl_reg;

//VC5_RESOURCE_CTRL_REG
typedef struct{
  logic        vc_enable=1;        // [31]
  logic[30:27] rsvdp_3=0;          // [30:27] Reserved
  logic[26:24] vc_id=3'b101;       // [26:24] VC ID
  logic[23:20] rsvdp_2=0;          // [23:20] Reserved
  logic[19:17] port_arb_select=0;  // [19:17] Port Arbitration Select
  logic        load_pat=0;         // [16]     Load Port Arbitration Table
  logic[15:8]  rsvdp_1=0;          // [15:8]   Reserved
  logic[7:0]   tc_vc_map=8'b0010_0000;    // [7:0]    TC/VC Map
} vc5_resource_ctrl_reg_t;
static vc5_resource_ctrl_reg_t vc5_res_ctrl_reg;

//VC6_RESOURCE_CTRL_REG
typedef struct{
  logic        vc_enable=0;        // [31]
  logic[30:27] rsvdp_3=0;          // [30:27] Reserved
  logic[26:24] vc_id=3'b110;       // [26:24] VC ID
  logic[23:20] rsvdp_2=0;          // [23:20] Reserved
  logic[19:17] port_arb_select=0;  // [19:17] Port Arbitration Select
  logic        load_pat=0;         // [16]     Load Port Arbitration Table
  logic[15:8]  rsvdp_1=0;          // [15:8]   Reserved
  logic[7:0]   tc_vc_map=8'b0100_0000;    // [7:0]    TC/VC Map
} vc6_resource_ctrl_reg_t;
static vc6_resource_ctrl_reg_t vc6_res_ctrl_reg;

//VC7_RESOURCE_CTRL_REG
typedef struct{
  logic        vc_enable=1;        // [31]
  logic[30:27] rsvdp_3=0;          // [30:27] Reserved
  logic[26:24] vc_id=3'b111;       // [26:24] VC ID
  logic[23:20] rsvdp_2=0;          // [23:20] Reserved
  logic[19:17] port_arb_select=0;  // [19:17] Port Arbitration Select
  logic        load_pat=0;         // [16]     Load Port Arbitration Table
  logic[15:8]  rsvdp_1=0;          // [15:8]   Reserved
  logic[7:0]   tc_vc_map=8'h1000_0000;    // [7:0]    TC/VC Map
} vc7_resource_ctrl_reg_t;
static vc7_resource_ctrl_reg_t vc7_res_ctrl_reg;*/
/*typedef struct {
  //DWORD 0
  logic[15:0] vendor_id=16'h5678;
  logic[15:0] device_id=16'h1212;
  //DWORD 1
  logic[15:0] command=16'h2222;
  logic[15:0] status=16'h0;
  //DWORD 2
  logic[7:0] revision_id=8'h44;
  logic[23:0] class_code=24'h33_3333;
  //DWORD 3
  logic[7:0]  cache_line_size=8'h88;
  logic[7:0]  latancy_timer=8'h77;
  logic[7:0]  header_type=8'h66;
  logic[7:0]  BIST=8'h55;
  //DWORD 4-9
  logic[31:0] BAR_0=32'hffff_ffff;
  logic[31:0] BAR_1=32'hffff_ffff;
  logic[31:0] BAR_2=32'hffff_ffff;
  logic[31:0] BAR_3=32'hffff_ffff;
  logic[31:0] BAR_4=32'hffff_ffff;
  logic[31:0] BAR_5=32'hffff_ffff;
  //DWORD 10
  logic[31:0] cardbus_cis_pointer=32'h9999_9999;
  //DWORD 11
  logic[15:0] subsystem_vendor_id=16'hbbbb;
  logic[15:0] subsystem_id=16'haaaa;
  //DWORD 12
  logic[31:0] expansion_rom_base_address=32'hcccc_cccc;
  //DWORD 13
  logic[7:0]  capabilites_pointer=8'hdd;
  logic[23:0] reserved1=24'h0;
  //DWORD 14
  logic[31:0] reserved2=32'h0;
  //DWORD 15
  logic[7:0]  interrupt_line=8'hdd;
  logic[7:0]  interrupt_pin=8'hcc;
  logic[7:0]  min_grant=8'hbb;
  logic[7:0]  max_latency=8'haa;
} pcie_config_header_t;
static pcie_config_header_t cfg0_hdr; */
