/////////////////////////////////////L2 sequence////////////////
class siv_ltssm_seq_L2 extends uvm_sequence #(siv_ltssm_seq_item);
  `uvm_object_utils(siv_ltssm_seq_L2)

  virtual siv_ltssm_intf pl_intf;
  siv_ltssm_pl_cfg pl_cfg;
  siv_ltssm_fsm state_phase;
  int fts_count_rc=0,fts_count_ep=0;
  function new(string name = "siv_ltssm_seq_L2");
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
    //pl_cfg.l0s_entry_enable=1;pl_cfg.aspm_l0s_support=1;
  endtask

  task body();
    siv_ltssm_seq_item req;

//     while ((pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_rc_state)) || (!pl_cfg.is_rc && !`SIV_LINK_UP(ltssm_ep_state))) begin
     while ((pl_cfg.is_rc ) || (!pl_cfg.is_rc)) begin

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
          
          L0: begin
            if(pl_cfg.l2_entry_enable) begin
              `uvm_do_with(req, { ts_type == OS_EIOS; })
              `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent EIOS OS IN L0"), UVM_MEDIUM)
            end
            else
              begin 
                `uvm_info("SIV_PCIE_SEQ", $sformatf("RC is in L0 active state"), UVM_MEDIUM) 
                break;
              end
            
          end
          
//           L0S_ENTRY: begin
//             `uvm_do_with(req, { ts_type == OS_EIOS; })
//             `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent EIOS OS IN L0S_ENTRY"), UVM_MEDIUM)
//           end
          
//           L0S_IDLE: begin
//           `uvm_do_with(req, { ts_type == OS_EIE; })
//             `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent EIEOS (00h,11h) OS IN L0S_IDLE"), UVM_MEDIUM)
//           end
         
//           L0S_FTS: begin
//             if(!eie_sent) begin
//               $display("cur_data_rate=%b",cur_data_rate);
//               `uvm_do_with(req, { ts_type == OS_EIE; })
//               `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent EIE OS in L0S_FTS EIE_sent=%0d",eie_sent), UVM_MEDIUM)
//             end
       
//             if (fts_sent) begin 
//               $display("%0b",cur_data_rate);
//        `uvm_do_with(req, { ts_type == (cur_data_rate inside {`SPEED_2_5_GTS, `SPEED_5_GTS} ? OS_SKP : OS_SDS); })
//               `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent #### %s OS", cur_data_rate inside {`SPEED_2_5_GTS, `SPEED_5_GTS} ? "SKP" : "SDS"), UVM_LOW) 
//              pl_cfg.l0s_entry_enable=0;    pl_cfg.aspm_l0s_support=0;
//             end
//             if ( eie_sent && !fts_sent)
//               begin
//                 `uvm_do_with(req, { ts_type == OS_FTS;})
//                 `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent FTS OS in L0S_FTS fts_sent=%0d",fts_sent), UVM_MEDIUM)
                
//               end
//           end
          
//          L1_ENTRY: begin
//             `uvm_do_with(req, { ts_type == OS_EIOS; })
//            `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent EIOS OS IN L1_ENTRY"), UVM_MEDIUM)
//           end
          
//          L1_IDLE: begin
//           `uvm_do_with(req, { ts_type == OS_EIE; })
//            `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent EIEOS (00h,11h) OS IN L1_IDLE"), UVM_MEDIUM)
//               pl_cfg.l1_entry_enable=0;    pl_cfg.aspm_l1_support=0;
//           end
            L2_IDLE: begin
            pl_cfg.l2_entry_enable=0;
               `uvm_do_with(req, { ts_type == OS_EIE; })
            //`uvm_info("SIV_PCIE_SEQ", $sformatf("RC:  in L2_IDLE "), UVM_MEDIUM)
          end
          
          L2_TRANSMITWAKE: begin
         
            `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: IN L2_TRANSMITWAKE"), UVM_MEDIUM)
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
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
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
          
           L0: begin
             if(pl_cfg.l2_entry_enable ) begin
              `uvm_do_with(req, { ts_type == OS_EIOS; })
              `uvm_info("SIV_PCIE_SEQ", $sformatf("RC: Sent EIOS OS IN L0"), UVM_MEDIUM)
            end
              else
              begin 
                `uvm_info("SIV_PCIE_SEQ", $sformatf("RC is in L0 active state"), UVM_MEDIUM) 
                break;
              end
           end
          
//           L0S_ENTRY: begin
//             `uvm_do_with(req, { ts_type == OS_EIOS; })
//             `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent EIOS OS IN L0S_ENTRY"), UVM_MEDIUM)
//           end
          
//            L0S_IDLE: begin
//           `uvm_do_with(req, { ts_type == OS_EIE; })
//              `uvm_info("SIV_PCIE_SEQ", "EP: Sent EIEOS (00h,11h) OS IN L0S_IDLE", UVM_MEDIUM)
//           end
         
//           L0S_FTS: begin
//          if(!eie_sent) begin
//            `uvm_do_with(req, { (ts_type == OS_EIE);})
//            `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent EIE OS in L0S_FTS EIE_sent=%0d",eie_sent), UVM_MEDIUM)
//             end
            
//             if (fts_sent) begin     
//        `uvm_do_with(req, { ts_type == (cur_data_rate inside {`SPEED_2_5_GTS, `SPEED_5_GTS} ? OS_SKP : OS_SDS); })
//             `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent %s OS", cur_data_rate inside {`SPEED_2_5_GTS, `SPEED_5_GTS} ? "SKP" : "SDS"), UVM_MEDIUM)
//               pl_cfg.l0s_entry_enable=0;    pl_cfg.aspm_l0s_support=0;
//         end
//             if (eie_sent && !fts_sent)
//               begin
//                 `uvm_do_with(req, { ts_type == OS_FTS;})
//                 `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent FTS OS in L0S_FTS fts_sent=%0d ",fts_sent), UVM_MEDIUM)
//               end
//           end
         
//          L1_ENTRY: begin
//             `uvm_do_with(req, { ts_type == OS_EIOS; })
//            `uvm_info("SIV_PCIE_SEQ", $sformatf("EP: Sent EIOS OS IN L1_ENTRY"), UVM_MEDIUM)
//           end
          
//          L1_IDLE: begin
//           `uvm_do_with(req, { ts_type == OS_EIE; })
//            `uvm_info("SIV_PCIE_SEQ","EP: Sent EIEOS (00h,11h) OS IN L1_IDLE", UVM_MEDIUM)
//            pl_cfg.l1_entry_enable=0;    pl_cfg.aspm_l1_support=0;
//           end 
          
           L2_IDLE: begin
         pl_cfg.l2_entry_enable=0;
           //`uvm_info("SIV_PCIE_SEQ",$sformatf("EP:  in L2_IDLE"), UVM_MEDIUM)
          end
           L2_TRANSMITWAKE: begin
          `uvm_do_with(req, { ts_type == OS_EIE; })
             `uvm_info("SIV_PCIE_SEQ","EP: Sent EIEOS (00h,ffh) OS IN L2_TRANSMITWAKE", UVM_MEDIUM)
           
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
              data_rate_id[6:0] == DATA_RATE_8_0_GT[6:0];
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
endclass
/////////////////////////////////////////TIMEOUT OF ///////////////////////////////////////////////
class siv_detect_from_polling_active_seq extends uvm_sequence #(siv_ltssm_seq_item);
  `uvm_object_utils(siv_detect_from_polling_active_seq)

  virtual siv_ltssm_intf pl_intf;
  siv_ltssm_pl_cfg pl_cfg;
  siv_ltssm_fsm state_phase; int count=0;
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
            if(timeout_check==0) begin
            `uvm_do_with(req, {
              ts_type == OS_TS2;
              link_number == PAD;
              lane_number == PAD;
            })
              `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS2 in POLLING_ACTIVE", UVM_MEDIUM) end
            if(timeout_check) begin
              `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
              `uvm_info("SIV_PCIE_SEQ", "RC: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
            end
            
           
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
////////////////////////////////////////////////////////////////
       ///////////////////////////DISABLE////////
class siv_ltssm_seq_disable extends uvm_sequence #(siv_ltssm_seq_item);
  `uvm_object_utils(siv_ltssm_seq_disable)
  
  int count ,count1  , disc1 ,disc2 ,disc3,disc4;
  
  

  virtual siv_ltssm_intf pl_intf;
  siv_ltssm_pl_cfg pl_cfg;
  siv_ltssm_fsm state_phase;
  function new(string name = "siv_ltssm_seq_disable");
    super.new(name);
    state_phase = new();
  endfunction

  task pre_body();
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
          
              
          DISABLE:begin
            disc4++;
            if(disc4==5)begin
            `uvm_do_with(req, {
              ts_type == OS_EIE;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent EIEOS in DISABLE", UVM_MEDIUM)
            end
            
          end
          
          
          
          
          
          POLLING_ACTIVE: begin
            `uvm_do_with(req, {
              ts_type == OS_TS1;
              link_number == PAD;
              lane_number == PAD;
            })
            `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in POLLING_ACTIVE", UVM_MEDIUM)
          end

          CONFIG_LINKWIDTH_START: begin
            if(link_disable)begin
              disc1++;
              if(disc1<=16)begin
                `uvm_do_with(req, {
                  ts_type == OS_TS1;
                  link_number == PAD;
                  lane_number == PAD;
                 
                })

                `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_START with DISABLE bit HIGH", UVM_MEDIUM)
              end

              if(disc1==17 || disc1==18 )begin
                `uvm_do_with(req, { ts_type == OS_EIOS; })
                `uvm_info("siv_ltssm_seq", "RC: Sent EIOS in CONFIG_LINKWIDTH_START with DISABLE bit HIGH", UVM_MEDIUM)
              end
            end

            else begin
              `uvm_do_with(req, {
                ts_type == OS_TS1;
                link_number == 0;
                lane_number == PAD;
                symbols[5][2] == loopback_bit;
              })
              `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in CONFIG_LINKWIDTH_START ", UVM_MEDIUM)
            end
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
//               symbols[7][5:0] == 6'h3F;    // FS = Max swing
//               symbols[8][5:0] == 6'h20;    // LF = Mid-range
//               symbols[9][5:0] == 6'h00;    // Post-cursor 
//               symbols[9][6]   == 0;        // No coefficient rejection
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
              
              
                    
          LOOPBACK_ENTRY : begin
            if(perform_equalization_for_loopback==0)begin
            count++;
            if(count<=2)begin
		     `uvm_do_with(req, {
		       ts_type == OS_TS1;
		       link_number == PAD;
		       lane_number == PAD;
		       symbols[5][2] == 1'b1;
               data_rate_id[6:0] == `SPEED_32_GTS;
		     })

              `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in LOOPBACK_ENTRY", UVM_MEDIUM)
            end
            if(count==3 || count==4 && perform_equalization_for_loopback==0)begin
            `uvm_do_with(req, { ts_type == OS_EIOS; })
              `uvm_info("siv_ltssm_seq", "RC: Sent EIOS in LOOPBACK_ENTRY", UVM_MEDIUM)
            end
             
           end
           else begin
             `uvm_do_with(req, {
		       ts_type == OS_TS1;
		       link_number == PAD;
		       lane_number == PAD;
		       symbols[5][2] == 1'b1;
               data_rate_id[6:0] == `SPEED_32_GTS;
		     })

             `uvm_info("siv_ltssm_seq", "RC: Sent TS1 in LOOPBACK_ENTRY", UVM_MEDIUM)
           end
            
          end
               
          LOOPBACK_ACTIVE: begin
          end

         LOOPBACK_EXIT: begin
             `uvm_do_with(req, {
               ts_type == OS_EIOS;
             })
           `uvm_info("siv_ltssm_seq", "RC: Sent EIOS in LOOPBACK_ENTRY", UVM_MEDIUM)
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
          
          DISABLE:begin
            
            disc3++;
            if(disc3== 5)begin
            `uvm_do_with(req, {
              ts_type == OS_EIE;
            })
            `uvm_info("siv_ltssm_seq", "EP: Sent EIEOS in DISABLE", UVM_MEDIUM)
            end
            
          end
          
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
            if(link_disable)begin
              disc2++;
              
              if(disc2==1 )begin
                `uvm_do_with(req, { ts_type == OS_EIOS; })
                `uvm_info("siv_ltssm_seq", "EP: Sent EIOS in CONFIG_LINKWIDTH_START with DISABLE bit HIGH", UVM_MEDIUM)
              end
            end

            else begin
              `uvm_do_with(req, {
                ts_type == OS_TS1;
                link_number == 0;
                lane_number == PAD;
                symbols[5][2] == loopback_bit;
              })
              `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in CONFIG_LINKWIDTH_START ", UVM_MEDIUM)
            end
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
//               // Standard coefficients
//               symbols[7][5:0] == 6'h02;    // C-1 (Pre)
//               symbols[8][5:0] == 6'h1F;    // C0 (Main)
//               symbols[9][5:0] == 6'h00;    // C+1 (Post)
//               symbols[9][6]   == 0;        // No rejection
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
//               // FS/LF coefficients (Phase 1 specific)
//               symbols[7][5:0] == 6'h3F;    // FS = Max swing
//               symbols[8][5:0] == 6'h20;    // LF = Mid-range
//               symbols[9][5:0] == 6'h00;    // Post-cursor 
//               symbols[9][6]   == 0;        // No coefficient rejection
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
//               // Standard coefficients
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
              

              
              
         LOOPBACK_ENTRY : begin
           if(perform_equalization_for_loopback==0)begin
            count1++;
             if(count1<=2)begin
		     `uvm_do_with(req, {
		       ts_type == OS_TS1;
		       link_number == PAD;
		       lane_number == PAD;
		       symbols[5][2] == 1'b1;
               data_rate_id[6:0] == `SPEED_32_GTS;
		     })

              `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in LOOPBACK_ENTRY", UVM_MEDIUM)
            end
             if(count1==3 || count1==4 && perform_equalization_for_loopback==0)begin
            `uvm_do_with(req, { ts_type == OS_EIOS; })
              `uvm_info("siv_ltssm_seq", "EP: Sent EIOS in LOOPBACK_ENTRY", UVM_MEDIUM)
            end
             
           end
           else begin
             `uvm_do_with(req, {
		       ts_type == OS_TS1;
		       link_number == PAD;
		       lane_number == PAD;
		       symbols[5][2] == 1'b1;
               data_rate_id[6:0] == `SPEED_32_GTS;
		     })

              `uvm_info("siv_ltssm_seq", "EP: Sent TS1 in LOOPBACK_ENTRY", UVM_MEDIUM)
           end
            
          end
         
                          
         LOOPBACK_ACTIVE: begin
//            @(posedge pl_intf.clk);
         end

         LOOPBACK_EXIT: begin
           int eios_count_rc , eios_count_ep;
              
             `uvm_do_with(req, {
               ts_type == OS_EIOS;
             })
           `uvm_info("siv_ltssm_seq", "EP: Sent EIOS in LOOPBACK_ENTRY", UVM_MEDIUM)

         end


          
        endcase
      end

      @(posedge pl_intf.clk);
    end
  endtask      
  
endclass