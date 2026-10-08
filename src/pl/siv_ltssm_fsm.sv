//--------------------------------------------------------------
// SIV PCIe LTSSM Finite State Machine (siv_ltssm_fsm)
//--------------------------------------------------------------

class siv_ltssm_fsm;
  
 // State Tracking Variables
  ltssm_state_e current_state, previous_state;
  
  // Fast Training Sequence (FTS) counters
  int fts_tran_cnt = 0; // Number of FTS ordered sets transmitted
  int fts_rcvd_cnt = 0; // Number of FTS ordered sets received
  
  // TS1/TS2 Training Sequence counters
  int ts1_rcvd_cnt = 0;  // Number of TS1 ordered sets received
  int ts2_rcvd_cnt = 0;  // Number of TS2 ordered sets received
  int ts1_tran_cnt = 0;  // Number of TS1 ordered sets transmitted
  int ts2_tran_cnt = 0;  // Number of TS2 ordered sets transmitted
  
  // Idle symbol counters
  int idle_rcvd_cnt = 0; // Number of IDLE ordered sets received
  int idle_tran_cnt = 0; // Number of IDLE ordered sets transmitted
  
  // Electrical Idle Ordered Set counter
  int eios_tran_cnt = 0; // Number of EIOS ordered sets transmitted (enter electrical idle)
  int eie_tran_cnt = 0;  // Number of EIEOS ordered sets transmitted (exit electrical idle)
  int eios_rcvd_cnt = 0; // Number of EIOS ordered sets received
  int eie_rcvd_cnt = 0;  // Number of EIEOS ordered sets received
 
  // SKP (Skip) Ordered Set counters
  int skp_tran_cnt = 0; // Number of SKP ordered sets transmitted
  int skp_rcvd_cnt = 0; // Number of SKP ordered sets received
 
  // SDS (Start of data stream) counters
  int sds_tran_cnt = 0; // Number of SDS ordered sets transmitted
  int sds_rcvd_cnt = 0; // Number of SDS ordered sets received
  // Control Flags
  bit timer_active;				// Indicates whether the state timer is running
  bit hotreset_ltssm;           // To check whether transition to hotreset will occur or not
  // Configuration and Timer
  siv_ltssm_pl_cfg     pl_cfg;
  siv_uvm_timer_pl     state_timer;
  bit no_eq_done;

  virtual siv_ltssm_intf pl_intf;
  // Initialization Method
//==============================================================
// initialize() : Sets initial state + resets counters
//==============================================================
  function void initialize(
    siv_uvm_timer_pl timer, 
    virtual siv_ltssm_intf vif, 
    siv_ltssm_pl_cfg cfg
  );
    this.state_timer = timer;
    this.pl_intf = vif;
    this.pl_cfg = cfg;
    // Initialize to Detect.Quiet state
    this.current_state = DETECT_QUIET;
    this.previous_state = DETECT_QUIET;
    this.timer_active = 0;
    // Reset all counters
    ts1_rcvd_cnt = 0;
    ts2_rcvd_cnt = 0;
    idle_rcvd_cnt = 0;
    ts1_tran_cnt = 0;
    ts2_tran_cnt = 0; 
    idle_tran_cnt = 0;
  endfunction
  

  function int get_next_eq_speed(int cur_speed,int final_speed);
    // 	  // cur_speed and final_speed are the same units as your SPEED_ constants
    if (cur_speed < `SPEED_8_GTS) begin
      return `SPEED_8_GTS;
    end
    else if (cur_speed == `SPEED_8_GTS && final_speed >= `SPEED_16_GTS) begin

      return `SPEED_16_GTS;
    end
    else if (cur_speed == `SPEED_16_GTS && final_speed >= `SPEED_32_GTS) begin

      return `SPEED_32_GTS;
    end 
    else begin
      return cur_speed;
    end
  endfunction

  
  // State Update Task - Complete Implementation
  task update_state();
    case (current_state)
      //------------------------------------------------
      /** DETECT_QUIET: Initial state after reset
         - Starts 12ms timer
         - Waits for timer expiration
         - Moves to DETECT_ACTIVE after timeout
         - Same behavior for RC and EP*/
      //------------------------------------------------
      DETECT_QUIET: begin
       directed_speed_change = 0;
       cur_data_rate = `SPEED_2_5_GTS;
       previous_state = DETECT_QUIET;
       if (!timer_active) begin
         state_timer.start_timer(LTSSM_12MS, pl_cfg.inst_name);
         timer_active = 1;
         `uvm_info("FSM", $sformatf("[%s] 12ms Timer started", pl_cfg.inst_name), UVM_MEDIUM)
       end
       @(posedge pl_intf.clk);
       wait(state_timer.timer_expired);
       current_state = DETECT_ACTIVE;
        
       if (pl_cfg.is_rc)
         ltssm_rc_state = current_state;
       else
         ltssm_ep_state = current_state;
         timer_active = 0;
        `uvm_info("FSM", $sformatf("[%s] -> DETECT_ACTIVE", pl_cfg.inst_name), UVM_LOW)
      end
      
      //------------------------------------------------
      /** DETECT_ACTIVE: Checks for link partner
         - Starts 12ms timer
         - Receiver detection
         - Always transitions to POLLING_ACTIVE
         - Same behavior for RC and EP*/
      //------------------------------------------------
       DETECT_ACTIVE: begin
        previous_state = DETECT_ACTIVE;
        if (!timer_active) begin
          state_timer.start_timer(LTSSM_12MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        wait(state_timer.timer_expired);
        current_state = POLLING_ACTIVE;
        
        if (pl_cfg.is_rc)
          ltssm_rc_state = current_state;
        else
          ltssm_ep_state = current_state;
        timer_active = 0;
        `uvm_info("FSM", $sformatf("[%s] -> POLLING_ACTIVE", pl_cfg.inst_name), UVM_LOW)
      end
      
      //------------------------------------------------
      /** POLLING_ACTIVE: TS1 training sequence exchange
          RC Requirements:
          - 1024 TS1s transmitted and 8 TS1s received
          - 24ms timeout
          EP Requirements:  
          - 1024 TS1s transmitted and 8 TS1s received
          - 24ms timeout
          On success: Moves to POLLING_CONFIG
          On timeout: Returns to DETECT_QUIET*/
      //------------------------------------------------
       POLLING_ACTIVE: begin
        ltssm_state_e next_state;
        previous_state = POLLING_ACTIVE;
        
        // Success case: TS1 counts met
         if (ts1_tran_cnt >= `TS_1024 && ts1_rcvd_cnt >= 8) begin
          previous_state = POLLING_ACTIVE;
          next_state = POLLING_CONFIG;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("FSM", $sformatf("[%s] -> POLLING_CONFIG (TS1 count met)", pl_cfg.inst_name), UVM_LOW)
//           if (ts1_tran_cnt == `TS_1024+1) begin
          ts1_rcvd_cnt = 0;
          ts1_tran_cnt = 0;
//           end
        end
        // Start timer if not active
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_12MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        // Timeout case
        else if (state_timer.timer_expired) begin
          wait(state_timer.timer_expired);
          next_state = DETECT_QUIET;
          current_state = next_state;
          timeout_check=1;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_info("FSM", $sformatf("[%s] -> DETECT_QUIET (Timeout)", pl_cfg.inst_name), UVM_LOW)
        end
      end
      
      //------------------------------------------------
      /* POLLING_CONFIG: TS2 training sequence exchange  
          RC Requirements:
          - 16 TS2s transmitted and 8 TS2s received
          - 2ms timeout
          EP Requirements:
          - 16 TS2s transmitted and 8 TS2s received  
          - 2ms timeout
          On success: Moves to CONFIG_LINKWIDTH_START
          On timeout: Returns to DETECT_QUIET*/
      //------------------------------------------------
      POLLING_CONFIG: begin
        ltssm_state_e next_state;
        previous_state = POLLING_CONFIG;
        
        // Success case: TS2 counts met
        if (ts2_tran_cnt >= 16 && ts2_rcvd_cnt >= 8) begin
          ts1_tran_cnt = 0;
           ts1_rcvd_cnt = 0;
           previous_state = POLLING_CONFIG;
          next_state = CONFIG_LINKWIDTH_START;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("FSM", $sformatf("[%s] -> CONFIG_LINKWIDTH_START (TS2 count met)", pl_cfg.inst_name), UVM_LOW)
          ts2_rcvd_cnt = 0;
          ts2_tran_cnt = 0;
//           timer_active = 0;
        end
        // Start timer if not active
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_48MS, pl_cfg.inst_name);
          timer_active = 1; 
        end
        // Timeout case
        else if (state_timer.timer_expired) begin
          next_state = DETECT_QUIET;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_info("FSM", $sformatf("[%s] -> DETECT_QUIET (Timeout)", pl_cfg.inst_name), UVM_LOW)
        end
      end
      
      //------------------------------------------------
      // Configuration.Linkwidth.Start State
      /*  Devices[0] (RC) Requirements:
          - 2 TS1s transmitted and received link num as non pad value
          - 2ms timeout
          Devices[1] (EP) Requirements:
          - 2 TS1s transmitted and received link num as pad value
          - 2ms timeout
          On success: Moves to CONFIG_LINKWIDTH_ACCEPT and ts1_tran_cnt & ts1_rcvd_cnt =0
          On timeout: Returns to DETECT_QUIET*/
      //------------------------------------------------
       CONFIG_LINKWIDTH_START: begin
        ltssm_state_e next_state;
         //checking disable
          if(pl_cfg.is_rc && ts1_tran_cnt>=16 && ts1_tran_cnt<=32 && link_disable && eios_tran_cnt >=2 && eios_rcvd_cnt>=1) begin
           ts1_tran_cnt = 0;
           ts1_rcvd_cnt = 0;eios_rcvd_cnt =0;eios_tran_cnt=0;
//            timer_active = 0;
           next_state = DISABLE;
		  current_state = next_state;
           ltssm_rc_state = DISABLE;           
         end
         
         if(!pl_cfg.is_rc &&  eios_tran_cnt>=1 && link_disable) begin
           ts1_tran_cnt = 0;
           ts1_rcvd_cnt = 0;eios_rcvd_cnt =0;eios_tran_cnt=0;
//            timer_active = 0;
           wait(ltssm_rc_state==DISABLE)begin
             next_state = DISABLE;
             current_state = next_state;
             ltssm_ep_state = DISABLE;
         	end
          
           
         end
        // Success case: TS1 counts met
         if (ts1_tran_cnt >= 2 && ts1_rcvd_cnt >= 2 && !link_disable) begin
          previous_state = CONFIG_LINKWIDTH_START;
          next_state = CONFIG_LINKWIDTH_ACCEPT;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("FSM", $sformatf("[%s] -> CONFIG_LINKWIDTH_ACCEPT (TS1 count met)", pl_cfg.inst_name), UVM_LOW)
          ts1_rcvd_cnt = 0;
          ts1_tran_cnt = 0;
        end
            // Start timer if not active FOR NORMAL CASE
         else if (!timer_active  && !link_disable) begin
          state_timer.start_timer(pl_cfg.is_rc ? LTSSM_2MS : LTSSM_2MS,pl_cfg.inst_name);
          timer_active = 1;
        end
        // Timeout case
         else if (state_timer.timer_expired && !link_disable) begin
          next_state = DETECT_QUIET;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_info("FSM", $sformatf("[%s] -> DETECT_QUIET (Timeout)", pl_cfg.inst_name), UVM_LOW)
        end
         
        // Start timer if not active FOR DISABLE STATE TRANSTIONING
         else if (!timer_active  && link_disable) begin
           state_timer.start_timer(pl_cfg.is_rc ? LTSSM_48MS : LTSSM_48MS,pl_cfg.inst_name);
           $display("^&&&^");
          timer_active = 1;
        end
        // Timeout case
         else if (state_timer.timer_expired && link_disable) begin
          next_state = DETECT_QUIET;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_info("FSM", $sformatf("[%s] -> DETECT_QUIET (Timeout)", pl_cfg.inst_name), UVM_LOW)
        end
      end
      
      //------------------------------------------------
      // Configuration.Linkwidth.Accept State
      /** Devices[0] (RC) Requirements:
      - 2 TS1s transmitted and received link num as non pad value
      - 2ms timeout
          Devices[1] (EP) Requirements:
      - 2 TS1s transmitted and received link num as non pad value
      - 2ms timeout
          On success: Moves to CONFIG_LINKWIDTH_ACCEPT and ts1_tran_cnt & ts1_rcvd_cnt =0
          On timeout: Returns to DETECT_QUIET*/
      //------------------------------------------------
     CONFIG_LINKWIDTH_ACCEPT: begin
        ltssm_state_e next_state;
        
        // Success case: TS1 counts met
        if (ts1_tran_cnt >= 2 && ts1_rcvd_cnt >= 2) begin
          previous_state = CONFIG_LINKWIDTH_ACCEPT;
          next_state = CONFIG_LANENUM_WAIT;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("FSM", $sformatf("[%s] -> CONFIG_LANENUM_WAIT (TS1 count met)", pl_cfg.inst_name), UVM_LOW)
          ts1_rcvd_cnt = 0;
          ts1_tran_cnt = 0;
        end
        // Start timer if not active
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_2MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        // Timeout case
        else if (state_timer.timer_expired) begin
          next_state = DETECT_QUIET;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_info("FSM", $sformatf("[%s] -> DETECT_QUIET (Timeout)", pl_cfg.inst_name), UVM_LOW)
        end
       end
      
      //------------------------------------------------      
      // Configuration.Lanenum.Wait State
      /*  Devices[0] (RC) and Devices[1] (EP) Requirements:
        - At least 2 TS1s transmitted and received
        - 2ms timeout
        On success: Moves to CONFIG_LANENUM_ACCEPT and resets ts1_tran_cnt & ts1_rcvd_cnt
        On timeout: Returns to DETECT_QUIET*/
      //------------------------------------------------
          CONFIG_LANENUM_WAIT: begin
        ltssm_state_e next_state;
        
        // Success case: TS1 counts met
        if (ts1_tran_cnt >= 2 && ts1_rcvd_cnt >= 2) begin
          previous_state = CONFIG_LANENUM_WAIT;
          next_state = CONFIG_LANENUM_ACCEPT;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("FSM", $sformatf("[%s] -> CONFIG_LANENUM_ACCEPT (TS1 count met)", pl_cfg.inst_name), UVM_LOW)
          ts1_rcvd_cnt = 0;
          ts1_tran_cnt = 0;
        end
        // Start timer if not active
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_2MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        // Timeout case
        else if (state_timer.timer_expired) begin
          next_state = DETECT_QUIET;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_info("FSM", $sformatf("[%s] -> DETECT_QUIET (Timeout)", pl_cfg.inst_name), UVM_LOW)
        end
      end
      
      //------------------------------------------------
      // Configuration.Lanenum.Accept State
      /*  Devices[0] (RC) and Devices[1] (EP) Requirements:
      - At least 2 TS1s transmitted and received
      - 2ms timeout
      On success: Moves to CONFIG_COMPLETE and resets ts1_tran_cnt & ts1_rcvd_cnt
      On timeout: Returns to DETECT_QUIET*/
      //------------------------------------------------
          CONFIG_LANENUM_ACCEPT:begin
         ltssm_state_e next_state;
        
        // Success case: TS1 counts met
        if (ts1_tran_cnt >= 2 && ts1_rcvd_cnt >= 2) begin
          previous_state = CONFIG_LANENUM_ACCEPT;
          next_state = CONFIG_COMPLETE;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("FSM", $sformatf("[%s] -> CONFIG_COMPLETE (TS1 count met)", pl_cfg.inst_name), UVM_LOW)
          ts1_rcvd_cnt = 0;
          ts1_tran_cnt = 0;
        end
        // Start timer if not active
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_2MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        // Timeout case
        else if (state_timer.timer_expired) begin
          next_state = DETECT_QUIET;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_info("FSM", $sformatf("[%s] -> DETECT_QUIET (Timeout)", pl_cfg.inst_name), UVM_LOW)
        end
      end
      
      //------------------------------------------------
      // Configuration.Complete State
      /*  Devices[0] (RC) and Devices[1] (EP) Requirements:
      - At least 2 TS2s transmitted and received
      - 2ms timeout
      On success: Moves to CONFIG_IDLE and resets ts2_tran_cnt & ts2_rcvd_cnt
      On timeout: Returns to DETECT_QUIET*/
      //------------------------------------------------
       CONFIG_COMPLETE: begin
         ltssm_state_e next_state;
        
        // Handle speed negotiation
        if (adv_data_rate > `SPEED_2_5_GTS) begin
         // $display("adv_data_rate = %0b",adv_data_rate);
          changed_speed_recovery = 0;
          if (max_data_rate <= adv_data_rate) begin
            com_data_rate = max_data_rate;
          end else begin
            com_data_rate = adv_data_rate;
          end
        end else com_data_rate = `SPEED_2_5_GTS;
        
        // Success case: TS2 counts met
        if (ts2_tran_cnt >= 2 && ts2_rcvd_cnt >= 2) begin
          previous_state = CONFIG_COMPLETE;
          next_state = CONFIG_IDLE;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = current_state;
          else ltssm_ep_state = current_state;
          `uvm_info("FSM", $sformatf("[%s] -> CONFIG_IDLE", pl_cfg.inst_name), UVM_LOW)
          ts2_rcvd_cnt = 0;
          ts2_tran_cnt = 0;
        end
        // Start timer if not active
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_2MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        // Timeout case
        else if (state_timer.timer_expired) begin
          current_state = DETECT_QUIET;
          if (pl_cfg.is_rc) ltssm_rc_state = current_state;
          else ltssm_ep_state = current_state;
          timer_active = 0;
          `uvm_info("FSM", $sformatf("[%s] -> DETECT_QUIET (Timeout)", pl_cfg.inst_name), UVM_LOW)
        end
      end
      
      //------------------------------------------------
      // Configuration.Idle State
      /*  Devices[0] (RC) and Devices[1] (EP) Requirements:
      - At least 16 IDLEs transmitted and 8 IDLEs received
      - 2ms timeout
      On success: Moves to L0 (Link Up), resets idle_tran_cnt & idle_rcvd_cnt
      On timeout: Returns to DETECT_QUIET
      */
      //------------------------------------------------
        CONFIG_IDLE: begin
        ltssm_state_e next_state;
        
        // Success case: Idle counts met
        if ((idle_tran_cnt >= 16) && (idle_rcvd_cnt >= 8)) begin
          previous_state = CONFIG_IDLE;
          next_state = L0;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = current_state;
          else ltssm_ep_state = current_state;
          `uvm_info("FSM", $sformatf("[%s] -> L0 (Link Up Link successfully trained)", pl_cfg.inst_name), UVM_LOW)
          idle_tran_cnt = 0;
          idle_rcvd_cnt = 0;
        end
        // Start timer if not active
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_2MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        // Timeout case
        else if (state_timer.timer_expired) begin
          current_state = DETECT_QUIET;
          if (pl_cfg.is_rc) ltssm_rc_state = current_state;
          else ltssm_ep_state = current_state;
          timer_active = 0;
          `uvm_info("FSM", $sformatf("[%s] -> DETECT_QUIET (Timeout)", pl_cfg.inst_name), UVM_LOW)
        end
      end
      
     
      //------------------------------------------------
      // L0 State (Operational State)
      // Link is fully operational
      //------------------------------------------------
       L0: begin
        ltssm_state_e next_state;
        previous_state = CONFIG_IDLE;
        
        // Check for speed change
        if (com_data_rate > `SPEED_2_5_GTS && cur_data_rate != com_data_rate) begin
          directed_speed_change = 1;
          original_data_rate = cur_data_rate;  // Store current speed
          previous_state = L0;
          next_state = RECOVERY_RCVRLOCK;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = current_state;
          else ltssm_ep_state = current_state;
          `uvm_info("FSM", $sformatf("[%s] -> RECOVERY_RCVRLOCK(Speed Negotiation)", pl_cfg.inst_name), UVM_LOW)
        end
         else if(pl_cfg.l0s_entry_enable && pl_cfg.aspm_l0s_support && eios_rcvd_cnt>0) begin
                    previous_state =  L0;
                    next_state = L0S_ENTRY;
                    current_state = next_state;
                    if (pl_cfg.is_rc) ltssm_rc_state = next_state;
                    else ltssm_ep_state = next_state;
                    `uvm_info("FSM", $sformatf("[%s] -> L0S_ENTRY", pl_cfg.inst_name), UVM_LOW)
                     timer_active=0;
                     eios_rcvd_cnt=0;
      end
         else if (pl_cfg.l1_entry_enable && pl_cfg.aspm_l1_support&& eios_rcvd_cnt>0) begin
                    previous_state = L0;
                    next_state = L1_ENTRY;
                    current_state = next_state;
                     timer_active=0;
                     eios_rcvd_cnt=0;
                    if (pl_cfg.is_rc) ltssm_rc_state = next_state;
                    else ltssm_ep_state = next_state;
                    `uvm_info("FSM", $sformatf("[%s] -> L1_ENTRY", pl_cfg.inst_name), UVM_LOW)
      end
         //L2
         else if (pl_cfg.l2_entry_enable && eios_rcvd_cnt>0) begin
          previous_state = L0;
          next_state = L2_IDLE;
          current_state = next_state;
          eios_rcvd_cnt=0;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("FSM", $sformatf("[%s] -> L2_IDLE", pl_cfg.inst_name), UVM_LOW)
        end
         
         else
           begin
             pl_cfg.is_active=1;
           end
    end
      


      // RECOVERY_RCVRLOCK State
      /*  Devices[0] (RC) and Devices[1] (EP) Requirements:
      - At least 16 TS1s transmitted and 8 received
      - 24ms timeout
      On success: Moves to RECOVERY_RCFG and resets ts1_tran_cnt & ts1_rcvd_cnt
      On timeout: Returns to RECOVERY_RCFG,RECOVERY_SPEED,CONFIG_LINKWIDTH_START,DETECT_QUIET*/
      //------------------------------------------------
      RECOVERY_RCVRLOCK: begin
        ltssm_state_e next_state;
        previous_state = RECOVERY_RCVRLOCK;
        successful_speed_negotiation = 0;


        if (cur_data_rate >= `SPEED_8_GTS && cur_data_rate <= `SPEED_32_GTS) begin
          // RC SKIPS PHASE 0, GOES DIRECTLY TO PHASE 1
          if (pl_cfg.equalization_link_behaviour_ctrl==`EQ_MODE_BYPASS)
            begin
              if (pl_cfg.is_rc && start_equalization_w_preset) begin
                previous_state = RECOVERY_RCVRLOCK;
                next_state = RECOVERY_EQUALIZATION_PHASE_1;  // Bypass Phase 0 for RC
                current_state = next_state;
                if (pl_cfg.is_rc) ltssm_rc_state = next_state;
                else ltssm_ep_state = next_state;
                `uvm_info("FSM", $sformatf("[%s] RC skipping Phase 0 -> PHASE_1", 
                                           pl_cfg.inst_name), UVM_MEDIUM);
                ts1_rcvd_cnt = 0;
                ts1_tran_cnt = 0;
              end
              // EP follows normal flow (Phase 0->1->2->3)
              else if (!pl_cfg.is_rc && start_equalization_w_preset && 
                       ts1_tran_cnt >= 2 && ts1_rcvd_cnt >= 2) begin
                previous_state = RECOVERY_RCVRLOCK;
                next_state = RECOVERY_EQUALIZATION_PHASE_0;
                current_state = next_state;
                ltssm_ep_state = next_state;
                `uvm_info("FSM", $sformatf("[%s] EP starting Phase 0", 
                                           pl_cfg.inst_name), UVM_MEDIUM);
                ts1_rcvd_cnt = 0;
                ts1_tran_cnt = 0;
              end
            end
          else if( pl_cfg.equalization_link_behaviour_ctrl==`EQ_MODE_NO) begin
            if (ts1_tran_cnt >= 2 && ts1_rcvd_cnt >= 2) begin
              next_state = RECOVERY_RCFG;
              current_state = next_state;

              if (pl_cfg.is_rc) ltssm_rc_state = next_state;
              else ltssm_ep_state = next_state;

              `uvm_info("FSM", $sformatf("[%s] 32G NO EQ -> RECOVERY_RCFG",
                                         pl_cfg.inst_name), UVM_MEDIUM);

              ts1_rcvd_cnt = 0;
              ts1_tran_cnt = 0;
            end

          end
          else if( pl_cfg.equalization_link_behaviour_ctrl==`EQ_MODE_FULL) begin
            if (pl_cfg.is_rc && start_equalization_w_preset) begin
              previous_state = RECOVERY_RCVRLOCK;
              next_state = RECOVERY_EQUALIZATION_PHASE_1;  // Bypass Phase 0 for RC 
               
              current_state = next_state;
              if (pl_cfg.is_rc) ltssm_rc_state = next_state;
              else ltssm_ep_state = next_state;
              `uvm_info("FSM", $sformatf("[%s] RC skipping Phase 0 -> PHASE_1", 
                                         pl_cfg.inst_name), UVM_MEDIUM);
              ts1_rcvd_cnt = 0;
              ts1_tran_cnt = 0;
            end
            // EP follows normal flow (Phase 0->1->2->3)
            else if (!pl_cfg.is_rc && start_equalization_w_preset && 
                     ts1_tran_cnt >= 2 && ts1_rcvd_cnt >= 2) begin
              previous_state = RECOVERY_RCVRLOCK;
              next_state = RECOVERY_EQUALIZATION_PHASE_0;
              current_state = next_state;
              ltssm_ep_state = next_state;
              `uvm_info("FSM", $sformatf("[%s] EP starting Phase 0", 
                                         pl_cfg.inst_name), UVM_MEDIUM);
              ts1_rcvd_cnt = 0;
              ts1_tran_cnt = 0;
            end



          end
        end

        // Equalization completion check (for both RC/EP)
        if((equalization_done_8GT_data_rate || equalization_done_16GT_data_rate || equalization_done_32GT_data_rate ) &&
           ts1_tran_cnt >= `TS_1024 && ts1_rcvd_cnt >= 8) begin
          previous_state = RECOVERY_RCVRLOCK;
          next_state = RECOVERY_RCFG;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("FSM", $sformatf("[%s] (Equalization complete)  -> RECOVERY_RCFG", 
                                     pl_cfg.inst_name), UVM_LOW);
//           if(ts1_tran_cnt==`TS_1024+1)begin
          
            ts1_rcvd_cnt = 0;
            ts1_tran_cnt = 0;
            timer_active = 0;
//           end
        end

        // Normal speed negotiation path (non-equalization)
        else if (ts1_tran_cnt >= 16 && ts1_rcvd_cnt >= 8 && 
                 speed_change == directed_speed_change && 
                 (cur_data_rate <= `SPEED_8_GTS)) begin
          previous_state = RECOVERY_RCVRLOCK;
          next_state = RECOVERY_RCFG;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("FSM", $sformatf("[%s] -> RECOVERY_RCFG (Speed match)", 
                                     pl_cfg.inst_name), UVM_LOW);
          ts1_rcvd_cnt = 0;
          ts1_tran_cnt = 0;
        end

        // Timer and timeout handling
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_24MS, pl_cfg.inst_name);
          timer_active = 1;
          `uvm_info("FSM", $sformatf("[%s] RECOVERY_RCVRLOCK: Timer started (24ms)", 
                                     pl_cfg.inst_name), UVM_MEDIUM);
        end
        else if (state_timer.timer_expired) begin
          // Timeout fallback logic
          if ((speed_change == 1 && ts1_rcvd_cnt >= 8) || 
              (cur_data_rate > `SPEED_2_5_GTS || com_data_rate >= `SPEED_5_GTS)) begin
            previous_state = RECOVERY_RCVRLOCK;
            next_state = RECOVERY_RCFG;
          end
          else if ((changed_speed_recovery == 0 && cur_data_rate > `SPEED_2_5_GTS) || 
                   changed_speed_recovery == 1) begin
            previous_state = RECOVERY_RCVRLOCK;
            next_state = RECOVERY_SPEED;
          end
          else if (changed_speed_recovery == 0 && 
                   ((directed_speed_change == 0 && speed_change == 0) || 
                    (cur_data_rate == `SPEED_2_5_GTS && com_data_rate == `SPEED_2_5_GTS))) begin
            next_state = CONFIG_LINKWIDTH_START;
            directed_speed_change = 0;
          end
          else begin
            next_state = DETECT_QUIET;
          end
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_error("FSM", $sformatf("[%s] RECOVERY_RCVRLOCK Timeout -> %s", 
                                      pl_cfg.inst_name, next_state.name()));
        end
      end

      //------------------------------------------------
      // RECOVERY_EQUALIZATION_PHASE_0 State 
      //------------------------------------------------
      RECOVERY_EQUALIZATION_PHASE_0: begin
        ltssm_state_e next_state;

        // Success case: TS1 counts met
        if (ts1_tran_cnt >= 2 && ts1_rcvd_cnt >= 2) begin
          previous_state = RECOVERY_EQUALIZATION_PHASE_0;
          next_state = RECOVERY_EQUALIZATION_PHASE_1;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("EQ_PH1", $sformatf("[%s] Phase 0 completed -> Phase 1", pl_cfg.inst_name), UVM_MEDIUM)
          ts1_tran_cnt = 0;
          ts1_rcvd_cnt = 0;
        end
        // Start timer if not active
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_24MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        // Timeout case
        else if (state_timer.timer_expired) begin
          previous_state = RECOVERY_EQUALIZATION_PHASE_0; 
          next_state = RECOVERY_SPEED;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_error("FSM", $sformatf("[%s] EQ_PHASE_0 Timeout -> RECOVERY_SPEED", pl_cfg.inst_name))
        end
      end

      //------------------------------------------------
      // RECOVERY_EQUALIZATION_PHASE_1 State
      //------------------------------------------------
      RECOVERY_EQUALIZATION_PHASE_1: begin
        ltssm_state_e next_state;

        // Success case: TS1 counts met
        if (ts1_tran_cnt >= 2 && ts1_rcvd_cnt >= 2) begin
          previous_state = RECOVERY_EQUALIZATION_PHASE_1;
          next_state = RECOVERY_EQUALIZATION_PHASE_2;          
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("EQ_PH1", $sformatf("[%s] Phase 1 completed -> Phase 2", pl_cfg.inst_name), UVM_MEDIUM)
          ts1_tran_cnt = 0;
          ts1_rcvd_cnt = 0;
        end
        // Start timer if not active
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_24MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        // Timeout case
        else if (state_timer.timer_expired) begin
          previous_state = RECOVERY_EQUALIZATION_PHASE_1;
          next_state = RECOVERY_SPEED;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_error("FSM", $sformatf("[%s] EQ_PHASE_1 Timeout -> RECOVERY_SPEED", pl_cfg.inst_name))
        end
      end

      //------------------------------------------------
      // RECOVERY_EQUALIZATION_PHASE_2 State
      //------------------------------------------------
      RECOVERY_EQUALIZATION_PHASE_2: begin
        ltssm_state_e next_state;
        `uvm_info("EQ_PH2_DEBUG", 
                  $sformatf("[%s] TS1 counts - Sent: %0d, Received: %0d",
                            pl_cfg.inst_name, ts1_tran_cnt, ts1_rcvd_cnt),
                  UVM_DEBUG)

        // Success case: TS1 counts met
        if (ts1_tran_cnt >= 2 && ts1_rcvd_cnt >= 2) begin
          if(C0_MIN >= 11 && C0_MAX <= 49) begin
          previous_state = RECOVERY_EQUALIZATION_PHASE_2;
          next_state = RECOVERY_EQUALIZATION_PHASE_3;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("EQ_PH2", $sformatf("[%s] Phase 2 completed -> Phase 3", pl_cfg.inst_name), UVM_MEDIUM)
          ts1_tran_cnt = 0;
          ts1_rcvd_cnt = 0;
          end
          else begin
         previous_state = RECOVERY_EQUALIZATION_PHASE_2;
          next_state = RECOVERY_EQUALIZATION_PHASE_2;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
            `uvm_info("EQ_PH2", $sformatf("[%s] Phase 2 not completed (COEFFICIENTS REJECTED) so remain in phase 2", pl_cfg.inst_name), UVM_MEDIUM)
          ts1_tran_cnt = 0;
          ts1_rcvd_cnt = 0;
            
            
          end
        end
        // Start timer if not active
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_24MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        // Timeout case
        else if (state_timer.timer_expired) begin
          previous_state = RECOVERY_EQUALIZATION_PHASE_2;
          next_state = RECOVERY_SPEED;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_error("FSM", $sformatf("[%s] EQ_PHASE_2 Timeout -> RECOVERY_SPEED", pl_cfg.inst_name))
        end
      end

      //------------------------------------------------
      // RECOVERY_EQUALIZATION_PHASE_3 State
      //------------------------------------------------
      RECOVERY_EQUALIZATION_PHASE_3: begin
        ltssm_state_e next_state;

        // Wait until BOTH devices complete Phase 3
        if (ts1_tran_cnt >= 2 && ts1_rcvd_cnt >= 2) begin
          // RC waits for EP's equalization completion flag
          if (pl_cfg.is_rc) begin
            wait((equalization_done_8GT_data_rate == 1 && cur_data_rate == `SPEED_8_GTS )||( equalization_done_16GT_data_rate == 1 && cur_data_rate == `SPEED_16_GTS)|| (equalization_done_32GT_data_rate == 1 && cur_data_rate == `SPEED_32_GTS));  // Block until EP signals completion
            `uvm_info("SYNC", "RC detected EP's equalization completion", UVM_MEDIUM);
          end
          // EP sets completion flag
          else begin
            if(cur_data_rate == `SPEED_8_GTS)
              equalization_done_8GT_data_rate = 1;
            if(cur_data_rate == `SPEED_16_GTS)
              equalization_done_16GT_data_rate = 1;
            if(cur_data_rate == `SPEED_32_GTS)
              equalization_done_32GT_data_rate = 1;
            `uvm_info("SYNC", "EP signaled equalization completion", UVM_MEDIUM);
          end

          // Common  for both devices
          start_equalization_w_preset = 0;
          directed_speed_change = 0;
          speed_change = 0;

          // Transition back to RCVRLOCK
          previous_state = RECOVERY_EQUALIZATION_PHASE_3;
          next_state = RECOVERY_RCVRLOCK;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;

          `uvm_info("FSM", $sformatf("[%s] -> RECOVERY_RCVRLOCK (Sync complete)", 
                                     pl_cfg.inst_name), UVM_LOW);
          ts1_tran_cnt = 0;
          ts1_rcvd_cnt = 0;
        end
        // Timer fallback (safety)
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_24MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        else if (state_timer.timer_expired) begin
          previous_state = RECOVERY_EQUALIZATION_PHASE_3;
          next_state = RECOVERY_SPEED;  // Fallback if sync fails
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_error("FSM", $sformatf("[%s] EQ_PHASE_3 Timeout -> RECOVERY_SPEED", 
                                      pl_cfg.inst_name));
        end
      end
      //------------------------------------------------
      // RECOVERY_RCFG State
      /*  Devices[0] (RC) and Devices[1] (EP) Requirements:
      - At least 16 TS1s transmitted and 8 received
      On success: Moves to RECOVERY_IDLE and resets ts2_tran_cnt & ts2_rcvd_cnt
      Moves to RECOVERY_SPEED for change speed
      On timeout: Returns to DETECT_QUIET*/
      //------------------------------------------------               
      RECOVERY_RCFG: begin
        ltssm_state_e next_state; 
        previous_state = RECOVERY_RCFG;
        start_equalization_w_preset = 0;


        if (directed_speed_change == 0 && !no_eq_done) begin
          directed_speed_change = speed_change;
        end

        // Equalization done case
        if (((equalization_done_8GT_data_rate && com_data_rate == `SPEED_8_GTS) || (equalization_done_16GT_data_rate && com_data_rate == `SPEED_16_GTS) || (equalization_done_32GT_data_rate  && com_data_rate == `SPEED_32_GTS)) && 
            ts2_tran_cnt >= 2 && ts2_rcvd_cnt >= 2 ) begin
          previous_state = RECOVERY_RCFG;
          next_state = RECOVERY_IDLE;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;

          // Reset all flags to prevent re-entry
          changed_speed_recovery = 0;
          directed_speed_change = 0;
          speed_change = 0;
          ts2_tran_cnt = 0;
          ts2_rcvd_cnt = 0;

          `uvm_info("FSM", $sformatf("[%s] -> RECOVERY_IDLE (Ready for L0)", pl_cfg.inst_name), UVM_LOW);
        end
        // Speed change case
        else if ((ts2_tran_cnt >= 2 && ts2_rcvd_cnt >= 2) && 
                 (speed_change == 1))begin
          $display("####################################################");
          previous_state = RECOVERY_RCFG;
          next_state = RECOVERY_SPEED;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;         
          successful_speed_negotiation = 1;

          // Set equalization flag if needed
          if (((pl_cfg.is_rc && (!equalization_done_8GT_data_rate || !equalization_done_16GT_data_rate || !equalization_done_32GT_data_rate)) || !pl_cfg.is_rc) && (com_data_rate == `SPEED_8_GTS || com_data_rate == `SPEED_16_GTS || com_data_rate == `SPEED_32_GTS)) begin
            start_equalization_w_preset = 1;
          end
          `uvm_info("FSM", $sformatf("[%s] -> RECOVERY_SPEED (Speed Switch)", pl_cfg.inst_name), UVM_LOW)
          ts2_tran_cnt = 0;
          ts2_rcvd_cnt = 0;
        end 
        // Normal transition to IDLE
        else if (ts2_tran_cnt >= 16 && ts2_rcvd_cnt >= 8 && 
                 (speed_change == 0 || (cur_data_rate == `SPEED_2_5_GTS || cur_data_rate == `SPEED_8_GTS || cur_data_rate == `SPEED_16_GTS || cur_data_rate == `SPEED_32_GTS ))) begin
          previous_state = RECOVERY_RCFG;
          next_state = RECOVERY_IDLE;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;          
          changed_speed_recovery = 0;
          directed_speed_change = 0;
          `uvm_info("FSM", $sformatf("[%s] -> RECOVERY_IDLE (TS2 Count met)", pl_cfg.inst_name), UVM_LOW)
          ts2_tran_cnt = 0;
          ts2_rcvd_cnt = 0;
        end
        // Start timer if not active
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_48MS, pl_cfg.inst_name);
          timer_active = 1;
          `uvm_info("FSM", $sformatf("[%s] RECOVERY_RCFG: Timer started (48ms)", pl_cfg.inst_name), UVM_MEDIUM)
        end
        // Timeout handling
        else if (state_timer.timer_expired) begin
          // Timeout transition rules
          if (cur_data_rate == `SPEED_2_5_GTS || cur_data_rate == `SPEED_5_GTS) begin
            next_state = DETECT_QUIET;
            current_state = next_state;
            if (pl_cfg.is_rc) ltssm_rc_state = next_state;
            else ltssm_ep_state = next_state;
            ts2_tran_cnt = 0;
            ts2_rcvd_cnt = 0;
          end 
          else if (cur_data_rate == `SPEED_8_GTS) begin
            next_state = RECOVERY_IDLE;
            current_state = next_state;
            if (pl_cfg.is_rc) ltssm_rc_state = next_state;
            else ltssm_ep_state = next_state;
            changed_speed_recovery = 0;
            directed_speed_change = 0;
            ts2_tran_cnt = 0;
            ts2_rcvd_cnt = 0;
          end
          else begin
            next_state = DETECT_QUIET;
            current_state = next_state;
            if (pl_cfg.is_rc) ltssm_rc_state = next_state;
            else ltssm_ep_state = next_state;
            ts2_tran_cnt = 0;
            ts2_rcvd_cnt = 0;
          end
        end
      end

      //------------------------------------------------
      // RECOVERY_SPEED State
      /*  Devices[0] (RC) and Devices[1] (EP) Requirements:
      - Both Transmitters enters Electrical Idle
      - 800NS timeout
      On success: Moves to RECOVERY_RCVRLOCK after speed negotiated*/
      //------------------------------------------------       
      RECOVERY_SPEED: begin
        ltssm_state_e next_state;
        previous_state = RECOVERY_SPEED;

        // Start timer
        if (!timer_active) begin
          if (successful_speed_negotiation) begin
            state_timer.start_timer(LTSSM_800NS, pl_cfg.inst_name); // 800ns for success
          end 
          timer_active = 1;
          `uvm_info("FSM", $sformatf("[%s] RECOVERY_SPEED: Timer started (%0s)", 
                                     pl_cfg.inst_name, successful_speed_negotiation ? "800ns" : "6us"), 
                    UVM_MEDIUM)
        end

        // Wait for timer expiration
        wait(state_timer.timer_expired);

        // Handle speed change
        `uvm_info("FSM", $sformatf("Old SPEED %s changed to New SPEED %s",
                                   cur_data_rate == `SPEED_2_5_GTS ? "2.5 GT/s" :
                                   cur_data_rate == `SPEED_5_GTS ? "5.0 GT/s" :
                                   cur_data_rate == `SPEED_8_GTS ? "8.0 GT/s" :
                                   cur_data_rate == `SPEED_16_GTS ? "16.0 GT/s" :
                                   cur_data_rate == `SPEED_32_GTS ? "32.0 GT/s" : "64.0 GT/s",
                                   com_data_rate == `SPEED_2_5_GTS ? "2.5 GT/s" :
                                   com_data_rate == `SPEED_5_GTS ? "5.0 GT/s" :
                                   com_data_rate == `SPEED_8_GTS ? "8.0 GT/s" :
                                   com_data_rate == `SPEED_16_GTS ? "16.0 GT/s" :
                                   com_data_rate == `SPEED_32_GTS ? "32.0 GT/s" : "64.0 GT/s"), 
                  UVM_LOW)

        // Update data rate based on conditions
        if (successful_speed_negotiation) begin
          // Successful negotiation - use highest common rate
          if (pl_cfg.equalization_link_behaviour_ctrl==`EQ_MODE_BYPASS) begin
            cur_data_rate = com_data_rate;
            changed_speed_recovery = 1;
          end
          else if (pl_cfg.equalization_link_behaviour_ctrl==`EQ_MODE_FULL && directed_speed_change == 1) begin
            cur_data_rate = get_next_eq_speed(cur_data_rate,com_data_rate);
            $display("current dta rate = %d",cur_data_rate);
            previous_state = RECOVERY_SPEED;
            // Transition to RCVRLOCK
            next_state = RECOVERY_RCVRLOCK;
            current_state = next_state;
            if (pl_cfg.is_rc) ltssm_rc_state = next_state;
            else ltssm_ep_state = next_state;
          end
          else  if (pl_cfg.equalization_link_behaviour_ctrl==`EQ_MODE_NO) begin
            cur_data_rate = com_data_rate;
            changed_speed_recovery = 1;
            no_eq_done = 1;
          end
          changed_speed_recovery = 1;
        end 
        else if (changed_speed_recovery) begin
          // Revert to original speed if second attempt fails
          cur_data_rate = original_data_rate;
          changed_speed_recovery = 0;
        end 
        else begin
          // Default to 2.5 GT/s
          cur_data_rate = `SPEED_2_5_GTS;
        end 

        // Reset speed change flag
        directed_speed_change = 0;
        previous_state = RECOVERY_SPEED;
        // Transition to RCVRLOCK
        next_state = RECOVERY_RCVRLOCK;
        current_state = next_state;
        if (pl_cfg.is_rc) ltssm_rc_state = next_state;
        else ltssm_ep_state = next_state;
        timer_active = 0;

        `uvm_info("FSM", $sformatf("[%s] -> RECOVERY_RCVRLOCK (New speed: %0f GT/s)", 
                                   pl_cfg.inst_name, 
                                   cur_data_rate == `SPEED_2_5_GTS ? 2.5 : 
                                   cur_data_rate == `SPEED_5_GTS ? 5.0 : 
                                   cur_data_rate == `SPEED_8_GTS ? 8.0 : 
                                   cur_data_rate == `SPEED_16_GTS ? 16.0 : 
                                   cur_data_rate == `SPEED_32_GTS ? 32.0 : 64.0), 
                  UVM_LOW)

      end

      //------------------------------------------------
      // RECOVERY.Idle State
      /*  Devices[0] (RC) and Devices[1] (EP) Requirements:
      - At least 16 IDLEs transmitted and 8 IDLEs received
      - 2ms timeout
      On success: Moves to L0 (Link Up), resets idle_tran_cnt & idle_rcvd_cnt
      On timeout: Returns to DETECT_QUIET
      */
      //------------------------------------------------
      RECOVERY_IDLE: begin
        ltssm_state_e next_state;
        previous_state = RECOVERY_IDLE;

        // Success case: Idle counts met
        if ((idle_tran_cnt >= 7) && (idle_rcvd_cnt >= 7)&& (L0_Disable==0)) begin
          next_state = L0;
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("FSM", $sformatf("[%s] -> L0 (Idle count met)", pl_cfg.inst_name), UVM_LOW)
          idle_tran_cnt = 0;
          idle_rcvd_cnt = 0;
        end
        else if(L0_Disable == 1 && (idle_tran_cnt >= 7) && (idle_rcvd_cnt >= 7))begin
           idle_tran_cnt = 0;
           idle_rcvd_cnt = 0;
//            timer_active=0;
           previous_state = RECOVERY_IDLE;
          
           next_state = DISABLE;
           current_state = next_state;
           if (pl_cfg.is_rc)begin 
             ltssm_rc_state = next_state;
             pl_intf.tx_data=8'hxx;
          end
          else begin ltssm_ep_state = next_state;
            pl_intf.tx_data=8'hxx;
          end
          if(ltssm_rc_state == DISABLE && ltssm_ep_state == DISABLE)L0_Disable=0;
          `uvm_info("FSM", $sformatf("[%s] -> DISABLE( L0_Disable)", pl_cfg.inst_name), UVM_LOW)
         end
        else if((idle_tran_cnt >= 2)&& (idle_rcvd_cnt >= 2) && hotreset_ltssm==1) begin
          previous_state = RECOVERY_IDLE;
          next_state =HOTRESET;
          $display("******I M  I N S I D E  H O T R E S E T******");
          current_state=next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          `uvm_info("FSM", $sformatf("[%s] -> HOTRESET", pl_cfg.inst_name), UVM_LOW)
          idle_tran_cnt = 0;
          idle_rcvd_cnt = 0;
        end
        // Start timer if not active
        else if (!timer_active) begin
          state_timer.start_timer(LTSSM_2MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        // Timeout case
        else if(state_timer.timer_expired) begin
          next_state = DETECT_QUIET;       
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_info("FSM", $sformatf("[%s] -> DETECT_QUIET (Timeout)", pl_cfg.inst_name), UVM_LOW)
        end
      end

  
      //------------------------------------------------
      //L0S_ENTRY
      //Waiting for timeout 20ns
      //Next state will be L0s_IDLE
      //------------------------------------------------
      
      L0S_ENTRY: begin
                ltssm_state_e next_state;
        `uvm_info("FSM", $sformatf("[%s] Tx: Starting IDLE Timeout", pl_cfg.inst_name), UVM_HIGH) 
                if (!timer_active) begin
                    state_timer.start_timer(IDLE_MIN, pl_cfg.inst_name); // 20ns
                    timer_active = 1;   
                end  
                if (state_timer.timer_expired) begin
                    previous_state = L0S_ENTRY;
                    next_state = L0S_IDLE;
                    current_state = next_state;
                    if (pl_cfg.is_rc) ltssm_rc_state = next_state;
                    else ltssm_ep_state = next_state;
                    timer_active = 0;
                    `uvm_info("FSM", $sformatf("[%s] -> L0S_IDLE (20ns timeout)", pl_cfg.inst_name), UVM_LOW)
                end
            end
      //------------------------------------------------
      //L0S_IDLE
      //------------------------------------------------
       L0S_IDLE: begin
                ltssm_state_e next_state;
               `uvm_info("FSM", $sformatf("[%s] Tx: Sending EIEOS (00h,11h)", pl_cfg.inst_name), UVM_HIGH)
               if((eie_tran_cnt >=1) && (eie_rcvd_cnt >=1))begin
                previous_state = L0S_IDLE;
                next_state = L0S_FTS;
                current_state = next_state;
                if (pl_cfg.is_rc) ltssm_rc_state = next_state;
                else ltssm_ep_state = next_state;
                 `uvm_info("FSM", $sformatf("[%s] -> L0S_FTS EIEOS DETECTED", pl_cfg.inst_name), UVM_LOW)
                 eie_tran_cnt = 0;
                 eie_rcvd_cnt = 0;
                 timer_active=0;
               end 
                // Start timer if not active
                else if (!timer_active) begin
                state_timer.start_timer(LTSSM_100MS, pl_cfg.inst_name);
                timer_active = 1;
               end
               // Timeout case
               else if (state_timer.timer_expired) begin
               current_state = L0S_FTS;
               if (pl_cfg.is_rc) ltssm_rc_state = current_state;
               else ltssm_ep_state = current_state;
                timer_active = 0;
                  `uvm_info("FSM", $sformatf("[%s] -> L0S_FTS (TIMEOUT IN LOS_IDLE)", pl_cfg.inst_name), UVM_LOW)
                end
            end
      
      //L0S_FTS
       L0S_FTS: begin
                ltssm_state_e next_state;
         //$display("INSIDE L0S_FTS after success eie_255=%0d  %0d",eie_tran_cnt,eie_rcvd_cnt);
         if((eie_tran_cnt>=4) && (eie_rcvd_cnt>=4)) begin
           eie_sent=1;
         if ((fts_tran_cnt >= `FTS_255) && (fts_rcvd_cnt >= `FTS_255)) begin
           fts_sent=1;
           
              // $display("INSIDE L0S_FTS after success FTS_255=%0d  %0d",fts_tran_cnt,fts_rcvd_cnt);
           if ((skp_tran_cnt >0 && skp_rcvd_cnt >0) || (sds_tran_cnt >=1 && sds_rcvd_cnt >=1)) begin
             $display("***********************");
                    previous_state = L0S_FTS;
                    next_state = L0;
                    current_state = next_state;
//                    pl_cfg.l0s_entry_enable=0;    pl_cfg.aspm_l0s_support=0;
             $display("INSIDE L0S_FTS after success skp_os =%0d  %0d",sds_tran_cnt,sds_rcvd_cnt);
                    if (pl_cfg.is_rc) ltssm_rc_state = next_state;
                    else ltssm_ep_state = next_state;
                 `uvm_info("FSM", $sformatf("[%s] FTS Received : Received %s -> L0", pl_cfg.inst_name, skp_rcvd_cnt ? "SKP" : "SDS"), UVM_LOW)
                    fts_tran_cnt = 0;
                    fts_rcvd_cnt = 0;
                    skp_tran_cnt = 0;
                    skp_rcvd_cnt = 0;
                    sds_tran_cnt = 0;
                    sds_rcvd_cnt = 0;
                    eie_tran_cnt = 0;
                	eie_rcvd_cnt = 0;
                end
             end 
         end
                else if (!timer_active) begin
                    state_timer.start_timer(N_FTS_TIMEOUT, pl_cfg.inst_name); 
                    timer_active = 1;
                end
                else if (state_timer.timer_expired) begin
                    next_state = RECOVERY_RCVRLOCK;
                    current_state = next_state;
                    if (pl_cfg.is_rc) ltssm_rc_state = next_state;
                    else ltssm_ep_state = next_state;
                    timer_active = 0;
             `uvm_info("FSM", $sformatf("[%s] -> RECOVERY_RCVRLOCK (L0S_FTS timeout)", pl_cfg.inst_name), UVM_LOW)
                end
            end
      
      //L1_ENTRY
       L1_ENTRY: begin
               ltssm_state_e next_state;
               previous_state = L0;
        `uvm_info("FSM", $sformatf("[%s] Tx: Starting IDLE Timeout", pl_cfg.inst_name), UVM_HIGH)
              
                if (!timer_active) begin
                    state_timer.start_timer(IDLE_MIN, pl_cfg.inst_name); // 20ns
                  $display("activating timer in L1 ENTRY*****");
                    timer_active = 1;   
                end  
                if (state_timer.timer_expired) begin
                    previous_state = L1_ENTRY;
                    next_state = L1_IDLE;
                    current_state = next_state;
                    if (pl_cfg.is_rc) ltssm_rc_state = next_state;
                    else ltssm_ep_state = next_state;
                    timer_active = 0;
                  `uvm_info("FSM", $sformatf("[%s] -> L1_IDLE (20ns timeout)", pl_cfg.inst_name), UVM_LOW)
                end
            end
      
      //L1_IDLE
      
      L1_IDLE: begin
                ltssm_state_e next_state;
                //previous_state = L1_IDLE;
        if((eie_tran_cnt >=10) && (eie_rcvd_cnt >=10) || (!timer_active) )begin
                  previous_state = L1_IDLE;
                  next_state = RECOVERY_RCVRLOCK;
                  current_state = next_state;
                  if (pl_cfg.is_rc) ltssm_rc_state = next_state;
                  else ltssm_ep_state = next_state;
                  timer_active = 0;
      `uvm_info("FSM", $sformatf("[%s] -> RECOVERY_RCVRLOCK (Exit detected or directed)", pl_cfg.inst_name), UVM_LOW)
                eie_tran_cnt = 0;
                eie_rcvd_cnt = 0;
                end
        else if(pl_cfg.l1_exit_enable) begin
                state_timer.start_timer(L1_MIN_STAY, pl_cfg.inst_name);
                timer_active = 1;
        end
              // Start timer if not active
                else if (!timer_active) begin
                state_timer.start_timer(LTSSM_100MS, pl_cfg.inst_name);
                timer_active = 1;
               end
               // Timeout case
               else if (state_timer.timer_expired) begin
               current_state = RECOVERY_RCVRLOCK;
               if (pl_cfg.is_rc) ltssm_rc_state = current_state;
               else ltssm_ep_state = current_state;
                timer_active = 0;
             `uvm_info("FSM", $sformatf("[%s] -> RECOVERY_RCVRLOCK (TIMEOUT IN L1_IDLE)", pl_cfg.inst_name), UVM_LOW)
               end
      end
  // --------------------------------------------------
      // L2_IDLE
      // --------------------------------------------------
      L2_IDLE: begin
        ltssm_state_e next_state;
        previous_state = L2_IDLE;
        pl_cfg.LinkUp = 1;  

        `uvm_info("FSM",
                  $sformatf("[%s] In L2_IDLE: Electrical Idle", pl_cfg.inst_name),
                  UVM_HIGH)

        // ------------------------------------------------
        // Start minimum TX Electrical Idle timer
        // ------------------------------------------------
        if (!timer_active) begin
          state_timer.start_timer(IDLE_MIN, pl_cfg.inst_name);
          timer_active = 1;
        end

        else if (state_timer.timer_expired) begin
          $display("^###^");
          if (pl_cfg.is_rc) begin
            if (pl_cfg.beacon_detected || pl_cfg.beacon_directed) begin
              next_state = DETECT_QUIET;
              current_state = next_state;
              ltssm_ep_state = next_state;
              timer_active = 0;

              `uvm_info("FSM",
                        $sformatf("[%s] L2_IDLE -> DETECT (Beacon detected/directed on DS)",
                                  pl_cfg.inst_name),UVM_LOW)
            end
          end

          else begin
            if (pl_cfg.beacon_directed) begin
              next_state = L2_TRANSMITWAKE;
              current_state = next_state;
              ltssm_rc_state = next_state;
              timer_active = 0;

              `uvm_info("FSM",
                        $sformatf("[%s] L2_IDLE -> L2_TRANSMITWAKE (Directed Beacon TX)",
                                  pl_cfg.inst_name),UVM_LOW)
            end
            else if (pl_cfg.beacon_detected) begin
              next_state = DETECT_QUIET;
              current_state = next_state;
              ltssm_rc_state = next_state;
              timer_active = 0;

              `uvm_info("FSM",
                        $sformatf("[%s] L2_IDLE -> DETECT (Beacon detected on US)",
                                  pl_cfg.inst_name),
                        UVM_LOW)
            end
          end
        end
      end

      // --------------------------------------------------
      // L2_TRANSMITWAKE
      // --------------------------------------------------
      L2_TRANSMITWAKE: begin
        ltssm_state_e next_state;
        previous_state = L2_TRANSMITWAKE;
        pl_cfg.LinkUp = 1;
        `uvm_info("FSM",
                  $sformatf("[%s] L2_TRANSMITWAKE: Beacon being transmitted",
                            pl_cfg.inst_name),UVM_HIGH)


        // Electrical Idle Exit detection
        if (eie_rcvd_cnt > 0) begin
          next_state = DETECT_QUIET;
          current_state = next_state;
          ltssm_rc_state = next_state;

          eie_tran_cnt    = 0;
          eie_rcvd_cnt    = 0;

          `uvm_info("FSM",
                    $sformatf("[%s] L2_TRANSMITWAKE -> DETECT (Electrical Idle Exit)",
                              pl_cfg.inst_name),UVM_LOW)
        end
                  
        		pl_cfg.l1_entry_enable=0; pl_cfg.aspm_l1_support=0;
            end
      
      
      
      //HOTRESET case      
      HOTRESET: begin
        ltssm_state_e next_state;
        previous_state=HOTRESET;
        if (!timer_active) begin
          state_timer.start_timer(LTSSM_2MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        // Timeout case
        else if(state_timer.timer_expired) begin
          next_state = DETECT_QUIET;       
          current_state = next_state;
          if (pl_cfg.is_rc) ltssm_rc_state = next_state;
          else ltssm_ep_state = next_state;
          timer_active = 0;
          `uvm_info("FSM", $sformatf("[%s] -> DETECT_QUIET (Timeout)", pl_cfg.inst_name), UVM_LOW)
        end
      end
 ////// DISABLE state
      DISABLE:begin
        ltssm_state_e next_state;
        previous_state=DISABLE;
        if (!timer_active) begin
          state_timer.start_timer(LTSSM_2MS, pl_cfg.inst_name);
          timer_active = 1;
        end
        wait (state_timer.timer_expired || eie_tran_cnt>0) begin
          timer_active = 0;
          
          next_state = DETECT_QUIET;
          current_state = next_state;
          if (pl_cfg.is_rc)begin
            ltssm_rc_state = current_state;
            $display("**************  RC Exiting ELectrical Idle  ***********************");
          end
          else
            ltssm_ep_state = current_state;
          $display("**************  EP Exiting ELectrical Idle  ***********************");//$stop;
          end
        if(ltssm_rc_state == DETECT_QUIET && ltssm_ep_state == DETECT_QUIET)begin
          link_disable=0;         // $stop;

        end
      end
      
      
      // Default Case
      default: begin
        `uvm_warning("FSM", $sformatf("[%s] Invalid state detected, resetting to DETECT_QUIET", pl_cfg.inst_name))
      end
      
    endcase
  endtask
endclass
    
//--------------------------------------------------------------