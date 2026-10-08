
//--------------------------------------------------------------
// SIV PCIe Training Sequence Item (siv_pcie_ts_item)
// PCIe Training Sequence Item (siv_ltssm_seq_item)
// Represents a single TS1/TS2 training sequence or idle ordered set
// Contains all fields required for PCIe link training and equalization
//-----------------------------------------------------------------------------
class siv_ltssm_seq_item extends uvm_sequence_item;
  `uvm_object_utils(siv_ltssm_seq_item)
  
  //-----------------------------------------------------------------
  // Sequence Control Fields
  //-----------------------------------------------------------------
  rand pcie_os_type_e ts_type;  // Selects between TS1 or TS2 generation
  
  // Specification version 
  rand bit [2:0] pcie_spec = `PCIE_SPEC_5;  
  //-----------------------------------------------------------------
  // Training Control Bits
  //-----------------------------------------------------------------
  bit hot_reset = 0;          // Initiate hot reset
  bit disable_link = 0;       // Disable link
  bit loopback = 0;           // Enable loopback
  bit disable_scrambling = 0; // Disable scrambling
  bit compliance_receive = 0; // Compliance receive mode
  bit transmit_modified_compliance_pattern_in_loopback = 0; //Loopback by the Loopback Master when 32.0 GT/s or high
  rand bit [1:0]equalization_link_behaviour_ctrl = `EQ_MODE_BYPASS;  //0-Full Equalization , 1- Equalization Bypass , 2-No Equalization 3-Modified TS1/2
  
  //-----------------------------------------------------------------
  // TS Packet Header Fields 
  //-----------------------------------------------------------------
  bit [7:0] com;                // COM symbol (K28.5 control character)
  rand bit [7:0] link_number;   // Physical link number assignment
  rand bit [7:0] lane_number;   // Lane number assignment
  rand bit [7:0] n_fts;         // Number of Fast Training Sequences
  rand bit [7:0] data_rate_id;  // Supported/suggested link speeds
  rand bit [7:0] training_control;  // Training control flags
  rand bit [7:0] ts_id[5];      // TS identifier pattern
  rand byte selected_id;        // Selected ID for negotiation

  //-----------------------------------------------------------------
  // Symbol Data Fields
  //-----------------------------------------------------------------
  rand bit [7:0] symbols[16];    // Complete TS symbol sequence 
  rand byte idle_symbols[16];    // Electrical idle ordered set

  //-----------------------------------------------------------------
  // Equalization Fields 
  //-----------------------------------------------------------------
  // Gen1/Gen2 Equalization
  rand bit [2:0] rx_preset;      // Receiver preset for 2.5/5.0 GT/s
  rand bit [3:0] tx_preset;      // Transmitter preset for all speeds
  
  // Gen3+ Equalization
  rand bit [1:0] ec;             // Equalization Control (8.0+ GT/s)
  rand bit       use_preset;     // Use preset coefficients
  rand bit       reset_eieos;    // Reset EIEOS count
  rand bit       eq_bit;         // Equalization active indicator
  
  // Equalization Coefficients
  rand bit [5:0] fs;           // Full Swing coefficient (Phase 1)
  rand bit [5:0] lf;           // Low Frequency coefficient (Phase 1)
  rand bit [5:0] c_minus1;     // Pre-cursor coefficient
  rand bit [5:0] c0;           // Main cursor coefficient
  rand bit [5:0] c_plus1;      // Post-cursor coefficient
  rand bit       reject_coeff;  // Coefficient rejection indicator

  //-----------------------------------------------------------------
  // Constraints for valid TS generation
  //-----------------------------------------------------------------
  
  constraint equalization {
    // Equalization only supported in Spec 5
    if (pcie_spec != `PCIE_SPEC_5 && (data_rate_id == `SPEED_8_GTS || `SPEED_16_GTS)) {
      equalization_link_behaviour_ctrl == `EQ_MODE_FULL;  // Full EQ for non-Spec5
    }
    // For Spec5, allow all modes
    else {
      equalization_link_behaviour_ctrl inside {`EQ_MODE_FULL,`EQ_MODE_BYPASS,`EQ_MODE_NO};
    }
//       if (data_rate_id == `SPEED_2_5_GTS || `SPEED_5_GTS)
//       {
//          equalization_link_behaviour_ctrl == `EQ_MODE_NO;
//       }
  }
   // Constraints for Training Controls
  constraint training_control_mapping {
    if(ts_type == OS_TS1 || ts_type == OS_TS2){
   soft symbols[5][7] == hot_reset;
    symbols[5][6] == disable_link;
    symbols[5][5] == loopback;
    symbols[5][4] == disable_scrambling;
    symbols[5][3] == compliance_receive;
    symbols[5][2] == transmit_modified_compliance_pattern_in_loopback;
      symbols[5][1:0] == `EQ_MODE_FULL;}
  }
      
      //Constraint for rejection coefficient
      constraint reject_coefficient{
        soft reject_coeff == 0;
        if(ts_type == OS_TS1){
          symbols[9][6] == reject_coeff;
        }


      }

  // Ensures proper TS-ID pattern in symbols 10-15
  constraint c_symbols {
    //constraint to generate TS1 OS
        if (ts_type == OS_TS1) {
            symbols[0] == COM;
            foreach (symbols[i]) { i >= 10 -> symbols[i] == TS1_ID; }
        }
    //constraint to generate TS2 OS
        if (ts_type == OS_TS2) {
            symbols[0] == COM;
            foreach (symbols[i]) { i >= 10 -> symbols[i] == TS2_ID; }
        }
    //constraint to generate EIOS OS
        if (ts_type == OS_EIOS) {
            foreach (symbols[i]) { symbols[i] == EIOS_ID; }
        }
    //constraint to generate FTS OS
        if (ts_type == OS_FTS) {
          foreach (symbols[i]) { if(i==0 && cur_data_rate < `SPEED_8_GTS) symbols[0]==COM; 
            else
            symbols[i] == FTS_ID; }
        }
    //constraint to generate SKP OS
        if (ts_type == OS_SKP) {
            foreach (symbols[i]) { symbols[i] == SKP_ID; }
        }
    //constraint to generate CONTROL SKP OS          
        if (ts_type == OS_CTRL_SKP) {
          foreach (symbols[i]) { symbols[i] == CTRL_SKP_ID; }
        }
    //constraint to generate SDS OS        
        if (ts_type == OS_SDS) {
            foreach (symbols[i]) { symbols[i] == SDS_ID; }
        }
    //constraint to generate EIE OS
       if (ts_type == OS_EIE) {
            foreach (symbols[i]) {
//              soft symbols[i] == (cur_data_rate == `SPEED_32_GTS) ? (i inside {[0:3], [8:11]} ? 8'h00 : 8'hFF) :
//                       (cur_data_rate == `SPEED_16_GTS) ? (i inside {[0:1], [4:5], [8:9], [12:13]} ? 8'h00 : 8'hFF) :
//                       (cur_data_rate == `SPEED_8_GTS) ? (i inside {0,2,4,6,8,10,12,14} ? 8'h00 : 8'hFF) :
//                              8'hFF; // Default case
              if(i%2==0)
                symbols[i]==8'h00;
              else
                symbols[i]==8'hff;
            }
              
         }
    }
   //Handles equalization settings based on data rate
  constraint eq {
    // Presets for Gen1/Gen2 (2.5/5.0 GT/s)
    if (data_rate_id inside {DATA_RATE_2_5_GT, DATA_RATE_5_0_GT}) {
      tx_preset inside {[0:11]}; // Valid transmitter presets
      rx_preset inside {[0:7]};  // Valid receiver presets
    } 
      
    // Equalization settings when active
      if (eq_bit == 1'b1 && (ts_type == OS_TS1 || ts_type == OS_TS2)) {
      // Gen1/Gen2 
      (data_rate_id inside {DATA_RATE_2_5_GT, DATA_RATE_5_0_GT}) -> {
        symbols[6][7] == 1'b1; // EQ bit set
        symbols[6][6:3] == tx_preset;
        symbols[6][2:0] == rx_preset;
      }
        
      // Gen3+ equalization (8.0 GT/s and above)
      (data_rate_id >= DATA_RATE_8_0_GT) -> {
        symbols[6][7] == use_preset;
        symbols[6][6:3] == tx_preset;
        symbols[6][2] == reset_eieos;
        symbols[6][1:0] == ec;
        symbols[7][5:0] == fs;  // Full Swing
        symbols[8][5:0] == lf;  // Low Frequency
        soft symbols[9][5:0] == 0;   // Reserved
        symbols[7][5:0] == c_minus1;  // C-1
        symbols[8][5:0] == c0;       // C0
        symbols[9][5:0] == c_plus1;  // C+1
      }
    }
    else {
      // Normal TS-ID pattern when equalization not active
      if(ts_type == OS_TS1 || ts_type == OS_TS2){
      symbols[6] == (ts_type == OS_TS1 ? TS1_ID : TS2_ID);
      symbols[7] == (ts_type == OS_TS1 ? TS1_ID : TS2_ID);
      symbols[8] == (ts_type == OS_TS1 ? TS1_ID : TS2_ID);
      symbols[9] == (ts_type == OS_TS1 ? TS1_ID : TS2_ID);
      }
    }
  }

  // Ensures idle ordered sets are all zeros              
  constraint idle_values {
    foreach(idle_symbols[i])
      idle_symbols[i] == 8'h00;
  }

      
      constraint cursors{
        soft c0 > 0;
        soft c0 inside {[11:49]};
       soft fs inside {[24:63]};

       soft (c_minus1<0?-c_minus1:c_minus1) <= (fs/4);

     soft   (c_minus1<0?-c_minus1:c_minus1) + c0 + (c_plus1<0?-c_plus1:c_plus1) == fs;

     soft   c0 - (c_minus1<0?-c_minus1:c_minus1) - (c_plus1<0?-c_plus1:c_plus1) >= lf;

      }
      
  //-----------------------------------------------------------------
  // Constructor - Initializes default values
  //-----------------------------------------------------------------
  function new(string name = "siv_pcie_ts_item");
    super.new(name);
    // Initialize header defaults
    com = COM;
    link_number = PAD;
    lane_number = PAD;
    n_fts = 255;
    
    // Enable support for all defined PCIe data rates
    data_rate_id = (DATA_RATE_2_5_GT | DATA_RATE_5_0_GT | DATA_RATE_8_0_GT | 
                   DATA_RATE_16_0_GT | DATA_RATE_32_0_GT | DATA_RATE_64_0_GT);
    training_control = 8'h00; 
    
    // Initialize TS-ID pattern
    foreach (symbols[i]) begin
      if (i >= 10 && i < 16) begin
        symbols[i] = (ts_type == OS_TS1) ? TS1_ID : TS2_ID;
      end 
    end 
  endfunction

  //-----------------------------------------------------------------
  // Post-Randomize - Updates symbol fields after randomization
  //-----------------------------------------------------------------
  function void post_randomize();
    // Update symbol header fields with current values
    
    
    if(ts_type == OS_TS1 || ts_type == OS_TS2) begin
    symbols[0] = com;
    symbols[1] = link_number;
    symbols[2] = lane_number;
    symbols[3] = n_fts;
    symbols[4] = data_rate_id;
    //symbols[5] = training_control;
    end

  endfunction
endclass
    
    
//--------------------------------------------------------------