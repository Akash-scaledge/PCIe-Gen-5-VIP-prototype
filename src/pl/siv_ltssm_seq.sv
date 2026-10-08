//--------------------------------------------------------------
// SIV PCIe Root Complex Training Sequence (siv_ltssm_rc_seq)
//--------------------------------------------------------------
// Generates training sequences (TS1/TS2) for Root Complex LTSSM states
// - Polling.Active state (TS1 sequences)
// - Polling.Config state (TS2 sequences)
// - Configuration states (TS1/TS2 with lane/link numbers)
// - Configuration.Idle state (IDLE sequences)
class siv_ltssm_seq extends uvm_sequence #(siv_ltssm_seq_item);
  `uvm_object_utils(siv_ltssm_seq)

  virtual siv_ltssm_intf pl_intf;
  siv_ltssm_pl_cfg pl_cfg;
  siv_ltssm_fsm state_phase;
  function new(string name = "siv_ltssm_seq");
    super.new(name);
    state_phase = new();
  endfunction

  task pre_body();
//     if (!uvm_config_db#(virtual siv_ltssm_intf)::get(null, "", "vif", pl_intf)) begin
//       `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
//     end
    //     TODO: get both rc_vif and ep_vif
    if (!uvm_config_db#(virtual siv_ltssm_intf)::get(null, "", "rc_vif", pl_intf)) begin
      `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
    end
      
    // Get pl_cfg from driver
    if (!uvm_config_db#(siv_ltssm_pl_cfg)::get(null, get_full_name(), "pl_cfg", pl_cfg)) begin
      `uvm_fatal("CFG_ERR", "Failed to get device configuration from driver")
    end
    pl_cfg.l0s_entry_enable=1;pl_cfg.aspm_l0s_support=1;
    uvm_config_db#(bit)::set(null,"*","PL_SEQ_STATUS",0);
  endtask

  task body();
    siv_ltssm_seq_item req;

    while ((pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_rc_state)) || (!pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_ep_state))) begin

      if (pl_cfg.is_rc) begin
        case (ltssm_rc_state)
          POLLING_ACTIVE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_START: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_START ", UVM_MEDIUM)
          end
          
          CONFIG_LINKWIDTH_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_ACCEPT", UVM_MEDIUM)
          end
          
          POLLING_CONFIG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS2 in POLLING_CONFIG", UVM_MEDIUM)
          end

          CONFIG_LANENUM_WAIT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LANENUM_WAIT", UVM_MEDIUM)
          end
          
          CONFIG_LANENUM_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_32_0_GT;
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in CONFIG_LANENUM_ACCEPT", UVM_MEDIUM)
          end
          
          CONFIG_COMPLETE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_32_0_GT;
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS2 in CONFIG_COMPLETE", UVM_MEDIUM)
          end

          CONFIG_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent IDLE in CONFIG_IDLE", UVM_MEDIUM)
          end
          
          //L0: begin
            //if(pl_cfg.)
            
          //end
          
          L0S_ENTRY: begin
            `uvm_do_with(req, { ts_type == OS_EIOS; })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent EIOS OS IN L0S_ENTRY"), UVM_MEDIUM)
          end
          
          L0S_IDLE: begin
          `uvm_do_with(req, { ts_type == OS_EIE; })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent EIEOS (00h,11h) OS IN L0S_IDLE"), UVM_MEDIUM)
          end
         
          L0S_FTS: begin
       
            
       `uvm_do_with(req, { ts_type == (cur_data_rate inside {`SPEED_2_5_GTS, `SPEED_5_GTS} ? OS_SKP : OS_SDS); })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent %s OS", cur_data_rate inside {`SPEED_2_5_GTS, `SPEED_5_GTS} ? "SKP" : "SDS"), UVM_MEDIUM) 
           
                `uvm_do_with(req, { ts_type == OS_FTS;})
                 `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent FTS OS in L0S_FTS "), UVM_MEDIUM)
                
              
          end
          
         L1_ENTRY: begin
            `uvm_do_with(req, { ts_type == OS_EIOS; })
           `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent EIOS OS IN L1_ENTRY"), UVM_MEDIUM)
          end
          
         L1_IDLE: begin
          `uvm_do_with(req, { ts_type == OS_EIE; })
           `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent EIEOS (00h,11h) OS IN L1_IDLE"), UVM_MEDIUM)
          end
          
          // For RC in RECOVERY_RCVRLOCK
          RECOVERY_RCVRLOCK: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change; // Speed change bit
              
              // Equalization settings
              if (start_equalization_w_preset) {
                symbols[6][7] == 1'b1;      // Use preset bit
                symbols[6][6:3] == 4'b0010; //  preset value
                symbols[6][2] == 1'b0;      // Reset EIEOS
                symbols[6][1:0] == 2'b00;   // EC = 00b
              }
              else if (cur_data_rate >= `SPEED_8_GTS) {
                symbols[6][7] == 1'b0;      // Use coefficients
                symbols[6][6:3] == 4'b0000; //  coefficients
                symbols[6][2] == 1'b0;      // Reset EIEOS
              }
            })
                `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent TS1 in RECOVERY_RCVRLOCK (directed_speed_change=%b, speed_change=%b)",              directed_speed_change, speed_change), UVM_MEDIUM)
          end         
          
          // For RC in RECOVERY_RCFG
          RECOVERY_RCFG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change; // Speed change bit
          
              // Equalization settings
              if (start_equalization_w_preset) {
                symbols[6][7] == 1'b1;      // Request Equalization bit
                symbols[6][6:3] == 4'b0010; // Preset value
                symbols[6][2] == 1'b0;      // Reset EIEOS
                symbols[6][1:0] == 2'b00;   // EC for RCFG
              }
              else {
                symbols[6][7] == 1'b0;      // No equalization request
              }
            })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent TS2 in RECOVERY_RCFG (speed_change=%b)", 
                     directed_speed_change), UVM_MEDIUM)
          end
              
          // Updated Equalization States for RC
          RECOVERY_EQUALIZATION_PHASE_1: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0010; // Transmitter preset = 2
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // FS/LF coefficients (Phase 1 specific)
              symbols[7][5:0] == 6'h3F;    // FS = Max swing
              symbols[8][5:0] == 6'h20;    // LF = Mid-range
              symbols[9][5:0] == 6'h00;    // Post-cursor 
              symbols[9][6]   == 0;        // No coefficient rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_1", UVM_MEDIUM)            
          end
         
          RECOVERY_EQUALIZATION_PHASE_2: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0011; // Transmitter preset = 3
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
//               symbols[7][5:0] == 6'h08;    // C-1 (Pre)
//               symbols[8][5:0] == 6'h30;    // C0 (Main)
//               symbols[9][5:0] == 6'h00;    // C+1 (Post)
//               symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_2", UVM_MEDIUM)
          end

          RECOVERY_EQUALIZATION_PHASE_3: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0011; // Transmitter preset = 3
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
//               symbols[7][5:0] == 6'h07;    // C-1 (Pre)
//               symbols[8][5:0] == 6'h4F;    // C0 (Main)
//               symbols[9][5:0] == 6'h00;    // C+1 (Post)
//               symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_3", UVM_MEDIUM)
          end
          
          RECOVERY_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent IDLE in RECOVERY_IDLE", UVM_MEDIUM)
          end
        endcase
      end
      //--------------------------------------------------------------
      // SIV PCIe Endpoint Training Sequence (siv_ltssm_ep_seq)
      //--------------------------------------------------------------
      // Generates training sequences (TS1/TS2) for Endpoint LTSSM states
      // - Synchronized with PCIe clock domain
      // - Generates TS1/TS2 sequences according to LTSSM state
      // - Handles all configuration states (link width, lane number)

      else begin
        case (ltssm_ep_state)
          POLLING_ACTIVE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
          end

          POLLING_CONFIG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS2 in POLLING_CONFIG", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_START: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_START", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_ACCEPT", UVM_MEDIUM)
          end

          CONFIG_LANENUM_WAIT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LANENUM_WAIT", UVM_MEDIUM)
          end
          
          CONFIG_LANENUM_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_32_0_GT[6:0];
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in CONFIG_LANENUM_ACCEPT", UVM_MEDIUM)
          end
          
          CONFIG_COMPLETE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_32_0_GT[6:0];
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS2 in CONFIG_COMPLETE", UVM_MEDIUM)
          end

          CONFIG_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent IDLE in CONFIG_IDLE", UVM_MEDIUM)
          end
          
          
          L0S_ENTRY: begin
            `uvm_do_with(req, { ts_type == OS_EIOS; })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent EIOS OS IN L0S_ENTRY"), UVM_MEDIUM)
          end
          
           L0S_IDLE: begin
          `uvm_do_with(req, { ts_type == OS_EIE; })
             `uvm_info("SIV_PCIE_SEQ", "EP: Sent EIEOS (00h,11h) OS IN L0S_IDLE", UVM_MEDIUM)
          end
         
          L0S_FTS: begin
//        `uvm_do_with(req, { ts_type == OS_FTS;})
//             `uvm_info("SIV_PCIE_SEQ", "EP: Sent FTS OS in L0S_FTS ", UVM_MEDIUM)
         
             
       `uvm_do_with(req, { ts_type == (cur_data_rate inside {`SPEED_2_5_GTS, `SPEED_5_GTS} ? OS_SKP : OS_SDS); })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent %s OS", cur_data_rate inside {`SPEED_2_5_GTS, `SPEED_5_GTS} ? "SKP" : "SDS"), UVM_MEDIUM)
        
                `uvm_do_with(req, { ts_type == OS_FTS;})
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent FTS OS in L0S_FTS ", UVM_MEDIUM)
              
          end
         
         L1_ENTRY: begin
            `uvm_do_with(req, { ts_type == OS_EIOS; })
           `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent EIOS OS IN L1_ENTRY"), UVM_MEDIUM)
          end
          
         L1_IDLE: begin
          `uvm_do_with(req, { ts_type == OS_EIE; })
           `uvm_info("SIV_PCIE_SEQ","EP: Sent EIEOS (00h,11h) OS IN L1_IDLE", UVM_MEDIUM)
          end
          
          // For EP in RECOVERY_RCVRLOCK 
          RECOVERY_RCVRLOCK: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
          
              // EP specific
              if (!equalization_done_8GT_data_rate) {
                symbols[6][7] == 1'b1;      // Request Equalization
                symbols[6][6:3] == 4'b0011; // Preset
                symbols[6][2] == 1'b0;      // Reset EIEOS 
              }
              else {
                symbols[6][7] == 1'b0;      // Use coefficients
                symbols[6][6:3] == 4'b0000; // coefficients
                symbols[6][2] == 1'b0;      // Reset EIEOS
                }
            })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent TS1 in RECOVERY_RCVRLOCK (directed_speed_change=%b, speed_change=%b)",              directed_speed_change, speed_change), UVM_MEDIUM)
          end
          
          // For EP in RECOVERY_RCFG 
          RECOVERY_RCFG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
          
              // EP specific equalization settings
              if (!equalization_done_8GT_data_rate && com_data_rate == `SPEED_8_GTS) {
                symbols[6][7] == 1'b1;      // Request Equalization
                symbols[6][6:3] == 4'b0011; // Example preset
                symbols[6][2] == 1'b0;      // Reset EIEOS 
                symbols[6][1:0] == 2'b00;   // EC
              }
            })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent TS2 in RECOVERY_RCFG (speed_change=%b)", 
                     directed_speed_change), UVM_MEDIUM)
          end
          
          // Updated Equalization States for RC
          RECOVERY_EQUALIZATION_PHASE_0: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0010; // Transmitter preset = 2
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
              symbols[7][5:0] == 6'h02;    // C-1 (Pre)
              symbols[8][5:0] == 6'h1F;    // C0 (Main)
              symbols[9][5:0] == 6'h00;    // C+1 (Post)
              symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_0", UVM_MEDIUM)            
          end
              
          // Updated Equalization States for RC
          RECOVERY_EQUALIZATION_PHASE_1: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0010; // Transmitter preset = 2
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // FS/LF coefficients (Phase 1 specific)
              symbols[7][5:0] == 6'h3F;    // FS = Max swing
              symbols[8][5:0] == 6'h20;    // LF = Mid-range
              symbols[9][5:0] == 6'h00;    // Post-cursor 
              symbols[9][6]   == 0;        // No coefficient rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_1", UVM_MEDIUM)            
          end
         
          RECOVERY_EQUALIZATION_PHASE_2: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0011; // Transmitter preset = 3
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
//               symbols[7][5:0] == 6'h08;    // C-1 (Pre)
//               symbols[8][5:0] == 6'h7F;    // C0 (Main)
//               symbols[9][5:0] == 6'h00;    // C+1 (Post)
//               symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_2", UVM_MEDIUM)
          end

          RECOVERY_EQUALIZATION_PHASE_3: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0011; // Transmitter preset = 3
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
//               symbols[7][5:0] == 6'h07;    // C-1 (Pre)
//               symbols[8][5:0] == 6'h4F;    // C0 (Main)
//               symbols[9][5:0] == 6'h00;    // C+1 (Post)
//               symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_3", UVM_MEDIUM)
          end
          
          RECOVERY_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent IDLE in RECOVERY_IDLE", UVM_MEDIUM)
          end
        endcase
      end

      @(posedge pl_intf.clk);
    end
  endtask
              task post_body();
                repeat(1)@(posedge pl_intf.clk);
                uvm_config_db#(bit)::set(null,"*","PL_SEQ_STATUS",1);
              endtask
endclass
              
////////////////////////////////////////////////////
class siv_Config_lanenum_Accept_to_Config_Compl_Seq extends siv_ltssm_seq;
  `uvm_object_utils(siv_Config_lanenum_Accept_to_Config_Compl_Seq)

                virtual siv_ltssm_intf pl_intf;
                siv_ltssm_pl_cfg pl_cfg;
                siv_ltssm_fsm state_phase;
                function new(string name = "siv_Config_lanenum_Accept_to_Config_Compl_Seq");
                  super.new(name);
                  state_phase = new();
                endfunction

                task pre_body();
//                   if (!uvm_config_db#(virtual siv_ltssm_intf)::get(null, "", "vif", pl_intf)) begin
//                     `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
//                   end
    //     TODO: get both rc_vif and ep_vif
    if (!uvm_config_db#(virtual siv_ltssm_intf)::get(null, "", "rc_vif", pl_intf)) begin
      `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
    end
                  // Get pl_cfg from driver
                  if (!uvm_config_db#(siv_ltssm_pl_cfg)::get(null, get_full_name(), "pl_cfg", pl_cfg)) begin
                    `uvm_fatal("CFG_ERR", "Failed to get device configuration from driver")
                  end
                endtask

                task body();
                  siv_ltssm_seq_item req;

                  while ((pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_rc_state)) || (!pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_ep_state))) begin

                    if (pl_cfg.is_rc) begin
                      case (ltssm_rc_state)

                        POLLING_ACTIVE: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == PAD;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
                        end

                        POLLING_CONFIG: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS2;
                            link_number == PAD;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "RC: Sent TS2 in POLLING_CONFIG", UVM_MEDIUM)
                        end

                        CONFIG_LINKWIDTH_START: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == 0;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_START ", UVM_MEDIUM)
                        end

                        CONFIG_LINKWIDTH_ACCEPT: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == 0;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_ACCEPT", UVM_MEDIUM)
                        end

                        CONFIG_LANENUM_WAIT: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == 0;
                            lane_number == 0;
                          })
                          `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LANENUM_WAIT", UVM_MEDIUM)
                        end

                        CONFIG_LANENUM_ACCEPT: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == 0;
                            lane_number == 0;
                            data_rate_id == DATA_RATE_8_0_GT;
                          })
                          `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in CONFIG_LANENUM_ACCEPT", UVM_MEDIUM)
                        end
                        CONFIG_COMPLETE: begin
//                             `uvm_do_with(req, {
//               ts_type == OS_TS2;
//               link_number == 0;
//               lane_number == 0;
//               data_rate_id == DATA_RATE_8_0_GT;
//             })
//             `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS2 in CONFIG_COMPLETE", UVM_MEDIUM)
                        end

                      endcase
                    end
                    //--------------------------------------------------------------
                    // SIV PCIe Endpoint Training Sequence (siv_ltssm_ep_seq)
                    //--------------------------------------------------------------
                    // Generates training sequences (TS1/TS2) for Endpoint LTSSM states
                    // - Synchronized with PCIe clock domain
                    // - Generates TS1/TS2 sequences according to LTSSM state
                    // - Handles all configuration states (link width, lane number)

                    else begin
                      case (ltssm_ep_state)
                        POLLING_ACTIVE: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == PAD;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
                        end

                        POLLING_CONFIG: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS2;
                            link_number == PAD;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "EP: Sent TS2 in POLLING_CONFIG", UVM_MEDIUM)
                        end

                        CONFIG_LINKWIDTH_START: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == PAD;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_START", UVM_MEDIUM)
                        end

                        CONFIG_LINKWIDTH_ACCEPT: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == 0;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_ACCEPT", UVM_MEDIUM)
                        end

                        CONFIG_LANENUM_WAIT: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == 0;
                            lane_number == 0;
                          })
                          `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LANENUM_WAIT", UVM_MEDIUM)
                        end

                        CONFIG_LANENUM_ACCEPT: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == 0;
                            lane_number == 0;
                            data_rate_id == DATA_RATE_8_0_GT[6:0];
                          })
                          `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in CONFIG_LANENUM_ACCEPT", UVM_MEDIUM)
                        end
                        CONFIG_COMPLETE: begin

                        end
                      endcase
                    end

                    @(posedge pl_intf.clk);
                  end
                endtask
              endclass              


              //--------------------------------------------------------------

              
class siv_Config_lanenum_Accept_to_Detect_Seq extends siv_ltssm_seq;
  `uvm_object_utils(siv_Config_lanenum_Accept_to_Detect_Seq)

                virtual siv_ltssm_intf pl_intf;
                siv_ltssm_pl_cfg pl_cfg;
                siv_ltssm_fsm state_phase;
                function new(string name = "siv_ltssm_seq");
                  super.new(name);
                  state_phase = new();
                endfunction

                task pre_body();
//                   if (!uvm_config_db#(virtual siv_ltssm_intf)::get(null, "", "vif", pl_intf)) begin
//                     `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
//                   end
                      //     TODO: get both rc_vif and ep_vif
    if (!uvm_config_db#(virtual siv_ltssm_intf)::get(null, "", "rc_vif", pl_intf)) begin
      `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
    end

                  // Get pl_cfg from driver
                  if (!uvm_config_db#(siv_ltssm_pl_cfg)::get(null, get_full_name(), "pl_cfg", pl_cfg)) begin
                    `uvm_fatal("CFG_ERR", "Failed to get device configuration from driver")
                  end
                endtask

                task body();
                  siv_ltssm_seq_item req;

                  while ((pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_rc_state)) || (!pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_ep_state))) begin

                    if (pl_cfg.is_rc) begin
                      case (ltssm_rc_state)

                        POLLING_ACTIVE: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == PAD;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
                        end

                        POLLING_CONFIG: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS2;
                            link_number == PAD;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "RC: Sent TS2 in POLLING_CONFIG", UVM_MEDIUM)
                        end

                        CONFIG_LINKWIDTH_START: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == 0;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_START ", UVM_MEDIUM)
                        end

                        CONFIG_LINKWIDTH_ACCEPT: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == 0;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_ACCEPT", UVM_MEDIUM)
                        end

                        CONFIG_LANENUM_WAIT: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == 0;
                            lane_number == 0;
                          })
                          `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LANENUM_WAIT", UVM_MEDIUM)
                        end

//                         CONFIG_LANENUM_ACCEPT: begin
//                           `uvm_info("SIV_PCIE_SEQ", "RC: NOT Sending TS1 in CONFIG_LANENUM_ACCEPT Waiting for timeout", UVM_MEDIUM)
//                         end

                      endcase
                    end
                    //--------------------------------------------------------------
                    // SIV PCIe Endpoint Training Sequence (siv_ltssm_ep_seq)
                    //--------------------------------------------------------------
                    // Generates training sequences (TS1/TS2) for Endpoint LTSSM states
                    // - Synchronized with PCIe clock domain
                    // - Generates TS1/TS2 sequences according to LTSSM state
                    // - Handles all configuration states (link width, lane number)

                    else begin
                      case (ltssm_ep_state)
                        POLLING_ACTIVE: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == PAD;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
                        end

                        POLLING_CONFIG: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS2;
                            link_number == PAD;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "EP: Sent TS2 in POLLING_CONFIG", UVM_MEDIUM)
                        end

                        CONFIG_LINKWIDTH_START: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == PAD;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_START", UVM_MEDIUM)
                        end

                        CONFIG_LINKWIDTH_ACCEPT: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == 0;
                            lane_number == PAD;
                          })
                          `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_ACCEPT", UVM_MEDIUM)
                        end

                        CONFIG_LANENUM_WAIT: begin
                          `uvm_do_with(req, {
                            ts_type == OS_TS1;
                            link_number == 0;
                            lane_number == 0;
                          })
                          `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LANENUM_WAIT", UVM_MEDIUM)
                        end

//                         CONFIG_LANENUM_ACCEPT: begin
//                           `uvm_info("SIV_PCIE_SEQ", "EP: NOT Sending TS1 in CONFIG_LANENUM_ACCEPT Waiting for timeout", UVM_MEDIUM)
//                         end

                      endcase
                    end

                    @(posedge pl_intf.clk);
                  end
                endtask
              endclass   
              
class siv_ltssm_seq_eq_mode extends siv_ltssm_seq;
  `uvm_object_utils(siv_ltssm_seq_eq_mode)

  virtual siv_ltssm_intf pl_intf;
  siv_ltssm_pl_cfg pl_cfg;
  siv_ltssm_fsm state_phase;
  function new(string name = "siv_ltssm_seq");
    super.new(name);
    state_phase = new();
  endfunction

  task pre_body();
//     if (!uvm_config_db#(virtual siv_ltssm_intf)::get(null, "", "vif", pl_intf)) begin
//       `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
//     end
    
          //     TODO: get both rc_vif and ep_vif
    if (!uvm_config_db#(virtual siv_ltssm_intf)::get(null, "", "rc_vif", pl_intf)) begin
      `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
    end
    
    // Get pl_cfg from driver
    if (!uvm_config_db#(siv_ltssm_pl_cfg)::get(null, get_full_name(), "pl_cfg", pl_cfg)) begin
      `uvm_fatal("CFG_ERR", "Failed to get device configuration from driver")
    end
  endtask

  task body();
    siv_ltssm_seq_item req;

    while ((pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_rc_state)) || (!pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_ep_state))) begin

      if (pl_cfg.is_rc) begin
        case (ltssm_rc_state)
          POLLING_ACTIVE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_START: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_START ", UVM_MEDIUM)
          end
          
          CONFIG_LINKWIDTH_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_ACCEPT", UVM_MEDIUM)
          end
          
          POLLING_CONFIG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS2 in POLLING_CONFIG", UVM_MEDIUM)
          end

          CONFIG_LANENUM_WAIT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LANENUM_WAIT", UVM_MEDIUM)
          end
          
          CONFIG_LANENUM_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_32_0_GT;
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in CONFIG_LANENUM_ACCEPT", UVM_MEDIUM)
          end
          
          CONFIG_COMPLETE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_32_0_GT;
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS2 in CONFIG_COMPLETE", UVM_MEDIUM)
          end

          CONFIG_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent IDLE in CONFIG_IDLE", UVM_MEDIUM)
          end
          
          // For RC in RECOVERY_RCVRLOCK
          RECOVERY_RCVRLOCK: begin
            `uvm_do_with(req, {
               req.equalization_link_behaviour_ctrl == pl_cfg.equalization_link_behaviour_ctrl;
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change; // Speed change bit
              
              // Equalization settings
              if(cur_data_rate < `SPEED_8_GTS)
              {              
                symbols[6] == TS1_ID;
                symbols[7] == TS1_ID;
                symbols[8] == TS1_ID;
                symbols[9] == TS1_ID;
              }
                
                else if (`SPEED_32_GTS > cur_data_rate >= `SPEED_8_GTS) 
              {
                if (start_equalization_w_preset)
                {
                  symbols[6][7] == 1'b1;      // Use preset bit
                  symbols[6][6:3] == 4'b0010; //  preset value
                  symbols[6][2] == 1'b0;      // Reset EIEOS
                  symbols[6][1:0] == 2'b00;   // EC = 00b
                }
                else
                {

                  symbols[6][7] == 1'b0;      // Use coefficients
                  symbols[6][6:3] == 4'b0000; //  coefficients
                  symbols[6][2] == 1'b0;      // Reset EIEOS 
                }
                  
              }
                  
              else if (cur_data_rate == `SPEED_32_GTS) 
              {    
               if (equalization_link_behaviour_ctrl == `EQ_MODE_FULL) 
               {
                 if (start_equalization_w_preset)
                {
                  symbols[6][7] == 1'b1;      // Use preset bit
                  symbols[6][6:3] == 4'b0010; //  preset value
                  symbols[6][2] == 1'b0;      // Reset EIEOS
                  symbols[6][1:0] == 2'b00;   // EC = 00b
                }
                else
                {

                  symbols[6][7] == 1'b0;      // Use coefficients
                  symbols[6][6:3] == 4'b0000; //  coefficients
                  symbols[6][2] == 1'b0;      // Reset EIEOS 
                }
               }
                  
              else if(equalization_link_behaviour_ctrl == `EQ_MODE_BYPASS)
              {
                  symbols[6][7] == 1'b0;           // do not use preset
                  symbols[6][6:3] == 4'b0000;      // no tx preset
                  symbols[6][2] == 1'b0;           // reset EIEOS
                  symbols[6][1:0] == `EQ_MODE_BYPASS; // EC field marks bypass
                // keep symbols[7..9] as TS-ID pattern (no coefficients)
                  symbols[7] == TS1_ID;
                  symbols[8] == TS1_ID;
                  symbols[9] == TS1_ID;

              }
              
              else 
              {
                 symbols[6] == TS1_ID;
                 symbols[7] == TS1_ID;
                 symbols[8] == TS1_ID;
                 symbols[9] == TS1_ID;    
              }
                
             }
              
            })
                `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent TS1 in RECOVERY_RCVRLOCK (directed_speed_change=%b, speed_change=%b)",              directed_speed_change, speed_change), UVM_MEDIUM)
          end         
          
          // For RC in RECOVERY_RCFG
          RECOVERY_RCFG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change; // Speed change bit
          
                
              // Equalization settings
              if(cur_data_rate < `SPEED_8_GTS)
              {              
                symbols[6] == TS1_ID;
                symbols[7] == TS1_ID;
                symbols[8] == TS1_ID;
                symbols[9] == TS1_ID;
              }
                
              else if (`SPEED_32_GTS > cur_data_rate >= `SPEED_8_GTS) 
              {
                if (start_equalization_w_preset)
                {
                  symbols[6][7] == 1'b1;      // Use preset bit
                  symbols[6][6:3] == 4'b0010; //  preset value
                  symbols[6][2] == 1'b0;      // Reset EIEOS
                  symbols[6][1:0] == 2'b00;   // EC = 00b
                }
                else
                {

                  symbols[6][7] == 1'b0;      // Use coefficients
                  symbols[6][6:3] == 4'b0000; //  coefficients
                  symbols[6][2] == 1'b0;      // Reset EIEOS 
                }
                  
              }
                  
              else if (cur_data_rate == `SPEED_32_GTS) 
              {    
               if (equalization_link_behaviour_ctrl == `EQ_MODE_FULL) 
               {
                 if (start_equalization_w_preset)
                {
                  symbols[6][7] == 1'b1;      // Use preset bit
                  symbols[6][6:3] == 4'b0010; //  preset value
                  symbols[6][2] == 1'b0;      // Reset EIEOS
                  symbols[6][1:0] == 2'b00;   // EC = 00b
                }
                else
                {

                  symbols[6][7] == 1'b0;      // Use coefficients
                  symbols[6][6:3] == 4'b0000; //  coefficients
                  symbols[6][2] == 1'b0;      // Reset EIEOS 
                }
               }
                  
              else if(equalization_link_behaviour_ctrl == `EQ_MODE_BYPASS)
              {
                  symbols[6][7] == 1'b0;           // do not use preset
                  symbols[6][6:3] == 4'b0000;      // no tx preset
                  symbols[6][2] == 1'b0;           // reset EIEOS
                  symbols[6][1:0] == `EQ_MODE_BYPASS; // EC field marks bypass
                // keep symbols[7..9] as TS-ID pattern (no coefficients)
                  symbols[7] == TS2_ID;
                  symbols[8] == TS2_ID;
                  symbols[9] == TS2_ID;

              }
              
              else 
              {
                 symbols[6] == TS2_ID;
                 symbols[7] == TS2_ID;
                 symbols[8] == TS2_ID;
                 symbols[9] == TS2_ID;    
              }
                
             }
            })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent TS2 in RECOVERY_RCFG (speed_change=%b)", 
                     directed_speed_change), UVM_MEDIUM)
          end
              
          // Updated Equalization States for RC
                RECOVERY_EQUALIZATION_PHASE_1: begin
                  `uvm_do_with(req, {
                    ts_type == OS_TS1;
                    link_number == 0;
                    lane_number == 0;
                    data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
                    data_rate_id[7] == directed_speed_change;

                    if (equalization_link_behaviour_ctrl == `EQ_MODE_FULL)                     {
                      symbols[6][7] == 1'b1;    // Use preset bit
                      symbols[6][6:3] == 4'b0010; // Transmitter preset = 2
                      symbols[6][2] == 1'b0;  // Reset EIEOS
                      symbols[7][5:0] == 6'h3F;    // FS= Max swing
                      symbols[8][5:0] ==  6'h20;    // LF= Mid-range
                      symbols[9][5:0] == 6'h00; // Post-cursor 
                      symbols[9][6]   == 0; // No coefficient rejection
                    }
              else if (equalization_link_behaviour_ctrl == `EQ_MODE_BYPASS)                  {
                      symbols[6][7] == 1'b0;
                      symbols[6][6:3] == 4'b0000;
                      symbols[6][2] == 1'b0;
                      symbols[6][1:0] == `EQ_MODE_BYPASS;
                      symbols[7] == TS1_ID;
                      symbols[8] == TS1_ID;
                      symbols[9] == TS1_ID;
                 }
               else 
                   {
                      symbols[6] == TS1_ID;
                      symbols[7] == TS1_ID;
                      symbols[8] == TS1_ID;
                      symbols[9] == TS1_ID;
                   }
                  })
                  `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_1", UVM_MEDIUM)
                end

                 RECOVERY_EQUALIZATION_PHASE_2: begin
                   `uvm_do_with(req, {
                     ts_type == OS_TS1;
                     link_number == 0;
                     lane_number == 0;
                     data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
                     data_rate_id[7] == directed_speed_change;

                     if (equalization_link_behaviour_ctrl == `EQ_MODE_FULL)                      {
                       symbols[6][7] == 1'b1; // Use preset bit
                       symbols[6][6:3] == 4'b0011;// Transmitter preset = 3
                       symbols[6][2] == 1'b0;  // Reset EIEOS
                       symbols[7][5:0] == 6'h08;  // C-1(Pre)
                       symbols[8][5:0] == 6'h30;  // C0(Main)
                       symbols[9][5:0] == 6'h00;  // C+1(Post)
                       symbols[9][6]   == 0;   // No rejection
                     }
                       else if (equalization_link_behaviour_ctrl == `EQ_MODE_BYPASS) {
                       symbols[6][7] == 1'b0;
                       symbols[6][6:3] == 4'b0000;
                       symbols[6][2] == 1'b0;
                       symbols[6][1:0] == `EQ_MODE_BYPASS;
                       symbols[7] == TS1_ID;
                       symbols[8] == TS1_ID;
                       symbols[9] == TS1_ID;
                       }
                    else 
                       {
                       symbols[6] == TS1_ID;
                       symbols[7] == TS1_ID;
                       symbols[8] == TS1_ID;
                       symbols[9] == TS1_ID;
                       }
                   })
                   `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_2", UVM_MEDIUM)
                 end

    // -----------------------------------------------------------------
                    // RECOVERY_EQUALIZATION_PHASE_3 (RC)
    // -----------------------------------------------------------------
                    RECOVERY_EQUALIZATION_PHASE_3: begin
                      `uvm_do_with(req, {
                        ts_type == OS_TS1;
                        link_number == 0;
                        lane_number == 0;
                        data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
                        data_rate_id[7] == directed_speed_change;

                     if (equalization_link_behaviour_ctrl == `EQ_MODE_FULL)          {
                          symbols[6][7] == 1'b1;
                          symbols[6][6:3] == 4'b0011;
                          symbols[6][2] == 1'b0;
                          symbols[7][5:0] == 6'h07;    // C-1
                          symbols[8][5:0] == 6'h4F;    // C0
                          symbols[9][5:0] == 6'h00;    // C+1
                          symbols[9][6]   == 0;
                        }
               else if (equalization_link_behaviour_ctrl == `EQ_MODE_BYPASS) {
                          symbols[6][7] == 1'b0;
                          symbols[6][6:3] == 4'b0000;
                          symbols[6][2] == 1'b0;
                          symbols[6][1:0] == `EQ_MODE_BYPASS;
                          symbols[7] == TS1_ID;
                          symbols[8] == TS1_ID;
                          symbols[9] == TS1_ID;
                          }
                       else 
                          {
                          symbols[6] == TS1_ID;
                          symbols[7] == TS1_ID;
                          symbols[8] == TS1_ID;
                          symbols[9] == TS1_ID;
                          }
                      })
                      `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_3", UVM_MEDIUM)
                    end
        
          RECOVERY_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent IDLE in RECOVERY_IDLE", UVM_MEDIUM)
          end
        endcase
      end
      //--------------------------------------------------------------
      // SIV PCIe Endpoint Training Sequence (siv_ltssm_ep_seq)
      //--------------------------------------------------------------
      // Generates training sequences (TS1/TS2) for Endpoint LTSSM states
      // - Synchronized with PCIe clock domain
      // - Generates TS1/TS2 sequences according to LTSSM state
      // - Handles all configuration states (link width, lane number)

      else begin
        case (ltssm_ep_state)
          POLLING_ACTIVE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
          end

          POLLING_CONFIG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS2 in POLLING_CONFIG", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_START: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_START", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_ACCEPT", UVM_MEDIUM)
          end

          CONFIG_LANENUM_WAIT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LANENUM_WAIT", UVM_MEDIUM)
          end
          
          CONFIG_LANENUM_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_32_0_GT[6:0];
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in CONFIG_LANENUM_ACCEPT", UVM_MEDIUM)
          end
          
          CONFIG_COMPLETE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_32_0_GT[6:0];
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS2 in CONFIG_COMPLETE", UVM_MEDIUM)
          end

          CONFIG_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent IDLE in CONFIG_IDLE", UVM_MEDIUM)
          end
          
          // For EP in RECOVERY_RCVRLOCK 
          RECOVERY_RCVRLOCK: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              req.equalization_link_behaviour_ctrl == pl_cfg.equalization_link_behaviour_ctrl;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
          
              // EP specific
              if (!equalization_done_32GT_data_rate) {
                symbols[6][7] == 1'b1;      // Request Equalization
                symbols[6][6:3] == 4'b0011; // Preset
                symbols[6][2] == 1'b0;      // Reset EIEOS 
              }
              else {
                symbols[6][7] == 1'b0;      // Use coefficients
                symbols[6][6:3] == 4'b0000; // coefficients
                symbols[6][2] == 1'b0;      // Reset EIEOS
                }
            })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent TS1 in RECOVERY_RCVRLOCK (directed_speed_change=%b, speed_change=%b)",              directed_speed_change, speed_change), UVM_MEDIUM)
          end
          
          // For EP in RECOVERY_RCFG 
          RECOVERY_RCFG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
          
              // EP specific equalization settings
              if (!equalization_done_32GT_data_rate && com_data_rate == `SPEED_32_GTS) {
                symbols[6][7] == 1'b1;      // Request Equalization
                symbols[6][6:3] == 4'b0011; // Example preset
                symbols[6][2] == 1'b0;      // Reset EIEOS 
                symbols[6][1:0] == 2'b00;   // EC
              }
            })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent TS2 in RECOVERY_RCFG (speed_change=%b)", 
                     directed_speed_change), UVM_MEDIUM)
          end
          
          // Updated Equalization States for EP
                RECOVERY_EQUALIZATION_PHASE_0: begin
                  `uvm_do_with(req, {
                    ts_type == OS_TS1;
                    link_number == 0;
                    lane_number == 0;
                    data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
                    data_rate_id[7] == directed_speed_change;

                    if (equalization_link_behaviour_ctrl == `EQ_MODE_FULL) {
                      symbols[6][7] == 1'b1;
                      symbols[6][6:3] == 4'b0010;
                      symbols[6][2] == 1'b0;
                      symbols[7][5:0] == 6'h02;    // C-1
                      symbols[8][5:0] == 6'h1F;    // C0
                      symbols[9][5:0] == 6'h00;    // C+1
                      symbols[9][6]   == 0;
                    }
                      else if (equalization_link_behaviour_ctrl == `EQ_MODE_BYPASS) {
                      symbols[6][7] == 1'b0;
                      symbols[6][6:3] == 4'b0000;
                      symbols[6][2] == 1'b0;
                      symbols[6][1:0] == `EQ_MODE_BYPASS;
                      symbols[7] == TS1_ID;
                      symbols[8] == TS1_ID;
                      symbols[9] == TS1_ID;
                      }
                    else 
                    {
                      symbols[6] == TS1_ID;
                      symbols[7] == TS1_ID;
                      symbols[8] == TS1_ID;
                      symbols[9] == TS1_ID;
                    }
                  })
                  `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_0", UVM_MEDIUM)
                end

              
          // Updated Equalization States for EP
         RECOVERY_EQUALIZATION_PHASE_1: begin
                  `uvm_do_with(req, {
                    ts_type == OS_TS1;
                    link_number == 0;
                    lane_number == 0;
                    data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
                    data_rate_id[7] == directed_speed_change;

                    if (equalization_link_behaviour_ctrl == `EQ_MODE_FULL)                     {
                      symbols[6][7] == 1'b1;    // Use preset bit
                      symbols[6][6:3] == 4'b0010; // Transmitter preset = 2
                      symbols[6][2] == 1'b0;  // Reset EIEOS
                      symbols[7][5:0] == 6'h3F;    // FS= Max swing
                      symbols[8][5:0] ==  6'h20;    // LF= Mid-range
                      symbols[9][5:0] == 6'h00; // Post-cursor 
                      symbols[9][6]   == 0; // No coefficient rejection
                    }
              else if (equalization_link_behaviour_ctrl == `EQ_MODE_BYPASS)                  {
                      symbols[6][7] == 1'b0;
                      symbols[6][6:3] == 4'b0000;
                      symbols[6][2] == 1'b0;
                      symbols[6][1:0] == `EQ_MODE_BYPASS;
                      symbols[7] == TS1_ID;
                      symbols[8] == TS1_ID;
                      symbols[9] == TS1_ID;
                 }
               else 
                   {
                      symbols[6] == TS1_ID;
                      symbols[7] == TS1_ID;
                      symbols[8] == TS1_ID;
                      symbols[9] == TS1_ID;
                   }
                  })
                 `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_1", UVM_MEDIUM)
                end
         
          RECOVERY_EQUALIZATION_PHASE_2: begin
                   `uvm_do_with(req, {
                     ts_type == OS_TS1;
                     link_number == 0;
                     lane_number == 0;
                     data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
                     data_rate_id[7] == directed_speed_change;

                     if (equalization_link_behaviour_ctrl == `EQ_MODE_FULL)                      {
                       symbols[6][7] == 1'b1; // Use preset bit
                       symbols[6][6:3] == 4'b0011;// Transmitter preset = 3
                       symbols[6][2] == 1'b0;  // Reset EIEOS
                       symbols[7][5:0] == 6'h08;  // C-1(Pre)
                       symbols[8][5:0] == 6'h7F;  // C0(Main)
                       symbols[9][5:0] == 6'h00;  // C+1(Post)
                       symbols[9][6]   == 0;   // No rejection
                     }
                       else if (equalization_link_behaviour_ctrl == `EQ_MODE_BYPASS) {
                       symbols[6][7] == 1'b0;
                       symbols[6][6:3] == 4'b0000;
                       symbols[6][2] == 1'b0;
                       symbols[6][1:0] == `EQ_MODE_BYPASS;
                       symbols[7] == TS1_ID;
                       symbols[8] == TS1_ID;
                       symbols[9] == TS1_ID;
                       }
                    else 
                       {
                       symbols[6] == TS1_ID;
                       symbols[7] == TS1_ID;
                       symbols[8] == TS1_ID;
                       symbols[9] == TS1_ID;
                       }
                   })
                      `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_2", UVM_MEDIUM)
                 end

    // -----------------------------------------------------------------
                      // RECOVERY_EQUALIZATION_PHASE_3 (EP)
    // -----------------------------------------------------------------
                    RECOVERY_EQUALIZATION_PHASE_3: begin
                      `uvm_do_with(req, {
                        ts_type == OS_TS1;
                        link_number == 0;
                        lane_number == 0;
                        data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
                        data_rate_id[7] == directed_speed_change;

                     if (equalization_link_behaviour_ctrl == `EQ_MODE_FULL)          {
                          symbols[6][7] == 1'b1;
                          symbols[6][6:3] == 4'b0011;
                          symbols[6][2] == 1'b0;
                          symbols[7][5:0] == 6'h07;    // C-1
                          symbols[8][5:0] == 6'h4F;    // C0
                          symbols[9][5:0] == 6'h00;    // C+1
                          symbols[9][6]   == 0;
                        }
               else if (equalization_link_behaviour_ctrl == `EQ_MODE_BYPASS) {
                          symbols[6][7] == 1'b0;
                          symbols[6][6:3] == 4'b0000;
                          symbols[6][2] == 1'b0;
                          symbols[6][1:0] == `EQ_MODE_BYPASS;
                          symbols[7] == TS1_ID;
                          symbols[8] == TS1_ID;
                          symbols[9] == TS1_ID;
                          }
                       else 
                          {
                          symbols[6] == TS1_ID;
                          symbols[7] == TS1_ID;
                          symbols[8] == TS1_ID;
                          symbols[9] == TS1_ID;
                          }
                      })
                         `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_3", UVM_MEDIUM)
                    end
        
          
          RECOVERY_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent IDLE in RECOVERY_IDLE", UVM_MEDIUM)
          end
        endcase
      end

      @(posedge pl_intf.clk);
    end
  endtask
endclass              
              
              
              
              
              


              //--------------------------------------------------------------
///pratik 
                        
 class siv_ltssm_config_lanewidth_change extends siv_ltssm_seq;
  `uvm_object_utils(siv_ltssm_config_lanewidth_change)

  virtual siv_ltssm_intf pl_intf;
  siv_ltssm_pl_cfg pl_cfg;
  siv_ltssm_fsm state_phase;
  function new(string name = "siv_ltssm_seq");
    super.new(name);
    state_phase = new();
  endfunction

  task pre_body();
//     if (!uvm_config_db#(virtual siv_ltssm_intf)::get(null, "", "vif", pl_intf)) begin
//       `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
//     end
    
        //     TODO: get both rc_vif and ep_vif
    if (!uvm_config_db#(virtual siv_ltssm_intf)::get(null, "", "rc_vif", pl_intf)) begin
      `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
    end
      
    // Get pl_cfg from driver
    if (!uvm_config_db#(siv_ltssm_pl_cfg)::get(null, get_full_name(), "pl_cfg", pl_cfg)) begin
      `uvm_fatal("CFG_ERR", "Failed to get device configuration from driver")
    end
  endtask

  task body();
    siv_ltssm_seq_item req;

    while ((pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_rc_state)) || (!pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_ep_state))) begin

      if (pl_cfg.is_rc) begin
        case (ltssm_rc_state)
          POLLING_ACTIVE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_START: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_START ", UVM_MEDIUM)
          end
          
          CONFIG_LINKWIDTH_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_ACCEPT", UVM_MEDIUM)
          end
          
          POLLING_CONFIG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS2 in POLLING_CONFIG", UVM_MEDIUM)
          end

          CONFIG_LANENUM_WAIT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LANENUM_WAIT", UVM_MEDIUM)
          end
          
          CONFIG_LANENUM_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 1;
              data_rate_id == DATA_RATE_8_0_GT;
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in CONFIG_LANENUM_ACCEPT", UVM_MEDIUM)
          end
          
          CONFIG_COMPLETE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_8_0_GT;
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS2 in CONFIG_COMPLETE", UVM_MEDIUM)
          end

          CONFIG_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent IDLE in CONFIG_IDLE", UVM_MEDIUM)
          end
          
          // For RC in RECOVERY_RCVRLOCK
          RECOVERY_RCVRLOCK: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
              data_rate_id[7] == directed_speed_change; // Speed change bit
              
              // Equalization settings
              if (start_equalization_w_preset) {
                symbols[6][7] == 1'b1;      // Use preset bit
                symbols[6][6:3] == 4'b0010; //  preset value
                symbols[6][2] == 1'b0;      // Reset EIEOS
                symbols[6][1:0] == 2'b00;   // EC = 00b
              }
              else if (cur_data_rate >= `SPEED_8_GTS) {
                symbols[6][7] == 1'b0;      // Use coefficients
                symbols[6][6:3] == 4'b0000; //  coefficients
                symbols[6][2] == 1'b0;      // Reset EIEOS
              }
            })
                `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent TS1 in RECOVERY_RCVRLOCK (directed_speed_change=%b, speed_change=%b)",              directed_speed_change, speed_change), UVM_MEDIUM)
          end         
          
          // For RC in RECOVERY_RCFG
          RECOVERY_RCFG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
              data_rate_id[7] == directed_speed_change; // Speed change bit
          
              // Equalization settings
              if (start_equalization_w_preset) {
                symbols[6][7] == 1'b1;      // Request Equalization bit
                symbols[6][6:3] == 4'b0010; // Preset value
                symbols[6][2] == 1'b0;      // Reset EIEOS
                symbols[6][1:0] == 2'b00;   // EC for RCFG
              }
              else {
                symbols[6][7] == 1'b0;      // No equalization request
              }
            })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent TS2 in RECOVERY_RCFG (speed_change=%b)", 
                     directed_speed_change), UVM_MEDIUM)
          end
              
          // Updated Equalization States for RC
          RECOVERY_EQUALIZATION_PHASE_1: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0010; // Transmitter preset = 2
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // FS/LF coefficients (Phase 1 specific)
              symbols[7][5:0] == 6'h3F;    // FS = Max swing
              symbols[8][5:0] == 6'h20;    // LF = Mid-range
              symbols[9][5:0] == 6'h00;    // Post-cursor 
              symbols[9][6]   == 0;        // No coefficient rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_1", UVM_MEDIUM)            
          end
         
          RECOVERY_EQUALIZATION_PHASE_2: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0011; // Transmitter preset = 3
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
              symbols[7][5:0] == 6'h08;    // C-1 (Pre)
              symbols[8][5:0] == 6'h30;    // C0 (Main)
              symbols[9][5:0] == 6'h00;    // C+1 (Post)
              symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_2", UVM_MEDIUM)
          end

          RECOVERY_EQUALIZATION_PHASE_3: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0011; // Transmitter preset = 3
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
              symbols[7][5:0] == 6'h07;    // C-1 (Pre)
              symbols[8][5:0] == 6'h4F;    // C0 (Main)
              symbols[9][5:0] == 6'h00;    // C+1 (Post)
              symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_3", UVM_MEDIUM)
          end
          
          RECOVERY_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent IDLE in RECOVERY_IDLE", UVM_MEDIUM)
          end
        endcase
      end
      //--------------------------------------------------------------
      // SIV PCIe Endpoint Training Sequence (siv_ltssm_ep_seq)
      //--------------------------------------------------------------
      // Generates training sequences (TS1/TS2) for Endpoint LTSSM states
      // - Synchronized with PCIe clock domain
      // - Generates TS1/TS2 sequences according to LTSSM state
      // - Handles all configuration states (link width, lane number)

      else begin
        case (ltssm_ep_state)
          POLLING_ACTIVE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
          end

          POLLING_CONFIG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS2 in POLLING_CONFIG", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_START: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_START", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_ACCEPT", UVM_MEDIUM)
          end

          CONFIG_LANENUM_WAIT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LANENUM_WAIT", UVM_MEDIUM)
          end
          
          CONFIG_LANENUM_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_8_0_GT[6:0];
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in CONFIG_LANENUM_ACCEPT", UVM_MEDIUM)
          end
          
          CONFIG_COMPLETE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_8_0_GT[6:0];
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS2 in CONFIG_COMPLETE", UVM_MEDIUM)
          end

          CONFIG_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent IDLE in CONFIG_IDLE", UVM_MEDIUM)
          end
          
          // For EP in RECOVERY_RCVRLOCK 
          RECOVERY_RCVRLOCK: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
          
              // EP specific
              if (!equalization_done_8GT_data_rate) {
                symbols[6][7] == 1'b1;      // Request Equalization
                symbols[6][6:3] == 4'b0011; // Preset
                symbols[6][2] == 1'b0;      // Reset EIEOS 
              }
              else {
                symbols[6][7] == 1'b0;      // Use coefficients
                symbols[6][6:3] == 4'b0000; // coefficients
                symbols[6][2] == 1'b0;      // Reset EIEOS
                }
            })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent TS1 in RECOVERY_RCVRLOCK (directed_speed_change=%b, speed_change=%b)",              directed_speed_change, speed_change), UVM_MEDIUM)
          end
          
          // For EP in RECOVERY_RCFG 
          RECOVERY_RCFG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
          
              // EP specific equalization settings
              if (!equalization_done_8GT_data_rate && com_data_rate == `SPEED_8_GTS) {
                symbols[6][7] == 1'b1;      // Request Equalization
                symbols[6][6:3] == 4'b0011; // Example preset
                symbols[6][2] == 1'b0;      // Reset EIEOS 
                symbols[6][1:0] == 2'b00;   // EC
              }
            })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent TS2 in RECOVERY_RCFG (speed_change=%b)", 
                     directed_speed_change), UVM_MEDIUM)
          end
          
          // Updated Equalization States for RC
          RECOVERY_EQUALIZATION_PHASE_0: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0010; // Transmitter preset = 2
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
              symbols[7][5:0] == 6'h02;    // C-1 (Pre)
              symbols[8][5:0] == 6'h1F;    // C0 (Main)
              symbols[9][5:0] == 6'h00;    // C+1 (Post)
              symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_0", UVM_MEDIUM)            
          end
              
          // Updated Equalization States for RC
          RECOVERY_EQUALIZATION_PHASE_1: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0010; // Transmitter preset = 2
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // FS/LF coefficients (Phase 1 specific)
              symbols[7][5:0] == 6'h3F;    // FS = Max swing
              symbols[8][5:0] == 6'h20;    // LF = Mid-range
              symbols[9][5:0] == 6'h00;    // Post-cursor 
              symbols[9][6]   == 0;        // No coefficient rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_1", UVM_MEDIUM)            
          end
         
          RECOVERY_EQUALIZATION_PHASE_2: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0011; // Transmitter preset = 3
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
              symbols[7][5:0] == 6'h08;    // C-1 (Pre)
              symbols[8][5:0] == 6'h7F;    // C0 (Main)
              symbols[9][5:0] == 6'h00;    // C+1 (Post)
              symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_2", UVM_MEDIUM)
          end

          RECOVERY_EQUALIZATION_PHASE_3: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0011; // Transmitter preset = 3
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
              symbols[7][5:0] == 6'h07;    // C-1 (Pre)
              symbols[8][5:0] == 6'h4F;    // C0 (Main)
              symbols[9][5:0] == 6'h00;    // C+1 (Post)
              symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_3", UVM_MEDIUM)
          end
          
          RECOVERY_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent IDLE in RECOVERY_IDLE", UVM_MEDIUM)
          end
        endcase
      end

      @(posedge pl_intf.clk);
    end
  endtask
endclass
              
              
              
class siv_ltssm_seq_speeed_change_32GT extends siv_ltssm_seq;
  `uvm_object_utils(siv_ltssm_seq_speeed_change_32GT)

  virtual siv_ltssm_intf pl_intf;
  siv_ltssm_pl_cfg pl_cfg;
  siv_ltssm_fsm state_phase;
  function new(string name = "siv_ltssm_seq");
    super.new(name);
    state_phase = new();
  endfunction

  task pre_body();
//     if (!uvm_config_db#(virtual siv_ltssm_intf)::get(null, "", "vif", pl_intf)) begin
//       `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
//     end
    
        //     TODO: get both rc_vif and ep_vif
    if (!uvm_config_db#(virtual siv_ltssm_intf)::get(null, "", "rc_vif", pl_intf)) begin
      `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
    end
      
    // Get pl_cfg from driver
    if (!uvm_config_db#(siv_ltssm_pl_cfg)::get(null, get_full_name(), "pl_cfg", pl_cfg)) begin
      `uvm_fatal("CFG_ERR", "Failed to get device configuration from driver")
    end
  endtask

  task body();
    siv_ltssm_seq_item req;

    while ((pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_rc_state)) || (!pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_ep_state))) begin

      if (pl_cfg.is_rc) begin
        case (ltssm_rc_state)
          POLLING_ACTIVE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_START: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_START ", UVM_MEDIUM)
          end
          
          CONFIG_LINKWIDTH_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_ACCEPT", UVM_MEDIUM)
          end
          
          POLLING_CONFIG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS2 in POLLING_CONFIG", UVM_MEDIUM)
          end

          CONFIG_LANENUM_WAIT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LANENUM_WAIT", UVM_MEDIUM)
          end
          
          CONFIG_LANENUM_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_32_0_GT;
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in CONFIG_LANENUM_ACCEPT", UVM_MEDIUM)
          end
          
          CONFIG_COMPLETE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_32_0_GT;
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS2 in CONFIG_COMPLETE", UVM_MEDIUM)
          end

          CONFIG_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent IDLE in CONFIG_IDLE", UVM_MEDIUM)
          end
          
          // For RC in RECOVERY_RCVRLOCK
          RECOVERY_RCVRLOCK: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change; // Speed change bit
              
              // Equalization settings
              if (start_equalization_w_preset) {
                symbols[6][7] == 1'b1;      // Use preset bit
                symbols[6][6:3] == 4'b0010; //  preset value
                symbols[6][2] == 1'b0;      // Reset EIEOS
                symbols[6][1:0] == 2'b00;   // EC = 00b
              }
                else if (cur_data_rate >= `SPEED_8_GTS) {
                symbols[6][7] == 1'b0;      // Use coefficients
                symbols[6][6:3] == 4'b0000; //  coefficients
                symbols[6][2] == 1'b0;      // Reset EIEOS
              }
            })
                `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent TS1 in RECOVERY_RCVRLOCK (directed_speed_change=%b, speed_change=%b)",              directed_speed_change, speed_change), UVM_MEDIUM)
          end         
          
          // For RC in RECOVERY_RCFG
          RECOVERY_RCFG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change; // Speed change bit
          
              // Equalization settings
              if (start_equalization_w_preset) {
                symbols[6][7] == 1'b1;      // Request Equalization bit
                symbols[6][6:3] == 4'b0010; // Preset value
                symbols[6][2] == 1'b0;      // Reset EIEOS
                symbols[6][1:0] == 2'b00;   // EC for RCFG
              }
              else {
                symbols[6][7] == 1'b0;      // No equalization request
              }
            })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent TS2 in RECOVERY_RCFG (speed_change=%b)", 
                     directed_speed_change), UVM_MEDIUM)
          end
              
          // Updated Equalization States for RC
          RECOVERY_EQUALIZATION_PHASE_1: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0010; // Transmitter preset = 2
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // FS/LF coefficients (Phase 1 specific)
              symbols[7][5:0] == 6'h3F;    // FS = Max swing
              symbols[8][5:0] == 6'h20;    // LF = Mid-range
              symbols[9][5:0] == 6'h00;    // Post-cursor 
              symbols[9][6]   == 0;        // No coefficient rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_1", UVM_MEDIUM)            
          end
         
          RECOVERY_EQUALIZATION_PHASE_2: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0011; // Transmitter preset = 3
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
              symbols[7][5:0] == 6'h08;    // C-1 (Pre)
              symbols[8][5:0] == 6'h30;    // C0 (Main)
              symbols[9][5:0] == 6'h00;    // C+1 (Post)
              symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_2", UVM_MEDIUM)
          end

          RECOVERY_EQUALIZATION_PHASE_3: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0011; // Transmitter preset = 3
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
              symbols[7][5:0] == 6'h07;    // C-1 (Pre)
              symbols[8][5:0] == 6'h4F;    // C0 (Main)
              symbols[9][5:0] == 6'h00;    // C+1 (Post)
              symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_3", UVM_MEDIUM)
          end
          
          RECOVERY_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "RC: Sent IDLE in RECOVERY_IDLE", UVM_MEDIUM)
          end
        endcase
      end
      //--------------------------------------------------------------
      // SIV PCIe Endpoint Training Sequence (siv_ltssm_ep_seq)
      //--------------------------------------------------------------
      // Generates training sequences (TS1/TS2) for Endpoint LTSSM states
      // - Synchronized with PCIe clock domain
      // - Generates TS1/TS2 sequences according to LTSSM state
      // - Handles all configuration states (link width, lane number)

      else begin
        case (ltssm_ep_state)
          POLLING_ACTIVE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
          end

          POLLING_CONFIG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS2 in POLLING_CONFIG", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_START: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_START", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_ACCEPT", UVM_MEDIUM)
          end

          CONFIG_LANENUM_WAIT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LANENUM_WAIT", UVM_MEDIUM)
          end
          
          CONFIG_LANENUM_ACCEPT: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_32_0_GT[6:0];
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in CONFIG_LANENUM_ACCEPT", UVM_MEDIUM)
          end
          
          CONFIG_COMPLETE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id == DATA_RATE_32_0_GT[6:0];
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS2 in CONFIG_COMPLETE", UVM_MEDIUM)
          end

          CONFIG_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent IDLE in CONFIG_IDLE", UVM_MEDIUM)
          end
          
          // For EP in RECOVERY_RCVRLOCK 
          RECOVERY_RCVRLOCK: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
          
              // EP specific
              if (!equalization_done_32GT_data_rate) {
                symbols[6][7] == 1'b1;      // Request Equalization
                symbols[6][6:3] == 4'b0011; // Preset
                symbols[6][2] == 1'b0;      // Reset EIEOS 
              }
              else {
                symbols[6][7] == 1'b0;      // Use coefficients
                symbols[6][6:3] == 4'b0000; // coefficients
                symbols[6][2] == 1'b0;      // Reset EIEOS
                }
            })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent TS1 in RECOVERY_RCVRLOCK (directed_speed_change=%b, speed_change=%b)",              directed_speed_change, speed_change), UVM_MEDIUM)
          end
          
          // For EP in RECOVERY_RCFG 
          RECOVERY_RCFG: begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
          
              // EP specific equalization settings
              if (!equalization_done_32GT_data_rate && com_data_rate == `SPEED_32_GTS) {
                symbols[6][7] == 1'b1;      // Request Equalization
                symbols[6][6:3] == 4'b0011; // Example preset
                symbols[6][2] == 1'b0;      // Reset EIEOS 
                symbols[6][1:0] == 2'b00;   // EC
              }
            })
            `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent TS2 in RECOVERY_RCFG (speed_change=%b)", 
                     directed_speed_change), UVM_MEDIUM)
          end
          
          // Updated Equalization States for RC
          RECOVERY_EQUALIZATION_PHASE_0: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0010; // Transmitter preset = 2
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
              symbols[7][5:0] == 6'h02;    // C-1 (Pre)
              symbols[8][5:0] == 6'h1F;    // C0 (Main)
              symbols[9][5:0] == 6'h00;    // C+1 (Post)
              symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_0", UVM_MEDIUM)            
          end
              
          // Updated Equalization States for RC
          RECOVERY_EQUALIZATION_PHASE_1: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0010; // Transmitter preset = 2
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // FS/LF coefficients (Phase 1 specific)
              symbols[7][5:0] == 6'h3F;    // FS = Max swing
              symbols[8][5:0] == 6'h20;    // LF = Mid-range
              symbols[9][5:0] == 6'h00;    // Post-cursor 
              symbols[9][6]   == 0;        // No coefficient rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_1", UVM_MEDIUM)            
          end
         
          RECOVERY_EQUALIZATION_PHASE_2: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0011; // Transmitter preset = 3
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
              symbols[7][5:0] == 6'h08;    // C-1 (Pre)
              symbols[8][5:0] == 6'h7F;    // C0 (Main)
              symbols[9][5:0] == 6'h00;    // C+1 (Post)
              symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_2", UVM_MEDIUM)
          end

          RECOVERY_EQUALIZATION_PHASE_3: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == 0;
              lane_number == 0;
              data_rate_id[6:0] == DATA_RATE_32_0_GT[6:0];
              data_rate_id[7] == directed_speed_change;
              symbols[6][7] == 1'b1;      // Use preset bit
              symbols[6][6:3] == 4'b0011; // Transmitter preset = 3
              symbols[6][2] == 1'b0;      // Reset EIEOS
              // Standard coefficients
              symbols[7][5:0] == 6'h07;    // C-1 (Pre)
              symbols[8][5:0] == 6'h4F;    // C0 (Main)
              symbols[9][5:0] == 6'h00;    // C+1 (Post)
              symbols[9][6]   == 0;        // No rejection
            })
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent TS1 in RECOVERY_EQUALIZATION_PHASE_3", UVM_MEDIUM)
          end
          
          RECOVERY_IDLE: begin
            `uvm_do(req)
            `uvm_info("SIV_PCIE_SEQ", "EP: Sent IDLE in RECOVERY_IDLE", UVM_MEDIUM)
          end
        endcase
      end

      @(posedge pl_intf.clk);
    end
  endtask
endclass

