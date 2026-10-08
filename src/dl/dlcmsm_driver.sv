////////////////////////////////////////////////////
// DRIVER (32-bit with proper ACK/NAK handling)
////////////////////////////////////////////////////
class dlcmsm_driver extends uvm_driver #(pcie_dl_seq_item);
  `uvm_component_utils(dlcmsm_driver)

  // [INSERT IN: testbench.sv -> class dlcmsm_driver]

  // --- FLOW CONTROL VARIABLES ---
  // Posted (Memory Writes)
  int tx_ph_limit = 0;      // 8-bit
  int tx_pd_limit = 0;      // 12-bit
  int tx_ph_consumed = 0;
  int tx_pd_consumed = 0;

  // Non-Posted (Config/IO Reads)
  int tx_nph_limit = 0;
  int tx_npd_limit = 0;
  int tx_nph_consumed = 0;
  int tx_npd_consumed = 0;

  // Completions (Read Data)
  int tx_cplh_limit = 0;
  int tx_cpld_limit = 0;
  int tx_cplh_consumed = 0;
  int tx_cpld_consumed = 0;

  int ph_cost; 
  int pd_cost;
  bit ph_ok, pd_ok;

  process pr[2];

  bit send_tlp;int cntr_tlp;
  timer_uvm_dl update_timer;

  virtual dl_if vif;				//intf to receive/send from/to tx/rx
  dlcmsm_fsm fsm;
  timer_uvm_dl fsm_timer; 				//timer from timing control of fsm
  timer_uvm_dl acknak_latency_timer;	//timer for ack/nak latency timer(instead of sending ack for every good tlp,
  //it waits for the next coming acks or naks, 
  //such that it can send only one ack and that will result same as sending multiple acks)
  pcie_dl_cfg cfg;					//
  pcie_dl_seq_item rx_item, rx_tlp_item;//
  bit is_tlp;						//if its a tlp or dllp
  static bit [11:0] rx_seq_num = 0;	//

  // FIFO queue of good TLPs to be sent to Transaction Layer 
  pcie_dl_seq_item tl_queue[$];

  // Next expected sequence number for RX buffer/ACK logic
  bit [11:0] next_rcv_seq;			//NRS

  // Ack/Nak control flags and tracking variables
  bit ack_timer_running = 0;
  bit nak_scheduled = 0;
  bit [11:0] last_good_seq_num_to_ack = 0;

  // Events and variables for ACK/NAK scheduling
  event ack_needed;
  event nak_needed;
  bit [11:0] ack_seq_num_to_send;
  bit [11:0] nak_seq_num_to_send;

  bit [11:0] ACKD_SEQ = 12'hFFF;           // All 1s at reset
  bit [11:0] NEXT_TRANSMIT_SEQ = 12'h000;  // 0 at reset
  bit [1:0]  REPLAY_NUM = 2'b00;           // 2-bit replay counter
  bit is_acknak_req = 0; 

  dlf_ext_cpb reg_model;
  uvm_reg_data_t local_data;
  uvm_reg_data_t remote_data;
  uvm_status_e status;

  global_que_t dl_getting_que,dl_q,dl_frm_pl_q;
  global_que_t dl_tlp_queue[$];
  //REPLAY_TIMER control 
  timer_uvm_dl replay_timer;                   // timer for replay
  bit replay_timer_running = 0;            // Timer state
  int REPLAY_TIMER_CYCLES = 300;           // 3x ACK/NAK latency (100*3)

  //Forward progress tracking
  bit [11:0] last_ackd_seq = 12'hFFF;     // Track last ACK/NAK sequence

  //Get port declared here only
  uvm_blocking_get_port #(dw_pkt) dl_driver_get_tl_port;
  uvm_blocking_put_port #(dw_pkt) dl_driver_put_tl_port;
  uvm_blocking_put_port #(dw_pkt) dl_sending_pl_port;
  uvm_blocking_get_port #(dw_pkt) dl_rcv_pl_port;


  // UVM TLM FIFO for ACK/NAK requests 
  uvm_tlm_fifo #(pcie_dl_seq_item) acknak_req_fifo;

  // NEW: Replay mode flag and queue for replayed TLPs
  bit replay_mode = 0;  // Flag to indicate if replay is active
  pcie_dl_seq_item replay_queue[$];  // Queue to hold TLPs for replay

  // Device-specific sequence tracking
  bit [11:0] my_device_tx_seq_num = 0;bit f_rcd;
  int i;

  //--------------------------------------------------------------------------
  // Register callback class for driver packet modification
  // Allows pcie_dl_pkt_modify_callback to hook into driver transactions
  // for error injection, corruption, duplication, etc.
  //--------------------------------------------------------------------------
  `uvm_register_cb(dlcmsm_driver, pcie_dl_pkt_modify_callback)


  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name, uvm_component parent); 
    super.new(name, parent);
  endfunction


  //--------------------------------------------------------------------------
  // Build Phase
  // Description:
  //   - Fetches configuration, register model, and virtual interface
  //   - Creates and initializes timers used by FSM, replay, and ACK/NAK logic
  //   - Initializes sequence number tracking registers as per PCIe DL spec
  //--------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    dl_driver_get_tl_port=new("dl_driver_get_tl_port",this);
    dl_driver_put_tl_port=new("dl_driver_put_tl_port",this);
    dl_sending_pl_port=new("dl_sending_pl_port",this);
    dl_rcv_pl_port=new("dl_rcv_pl_port",this);
    // Retrieve device-specific configuration (RC / EP role, feature enables)
    if(!uvm_config_db#(pcie_dl_cfg)::get(this, "", "device_config", cfg))
      `uvm_fatal(get_type_name(),"No device_config")

      // Retrieve Data Link Feature extended capability register model
      if(!uvm_config_db#(dlf_ext_cpb)::get(uvm_root::get(),"",$sformatf("reg_model_%0d",cfg.device_id), reg_model))
        `uvm_fatal(get_type_name(), "Cannot get REG_MODEL from config DB")

        // Retrieve virtual interface for link-level signaling
        if(!uvm_config_db#(virtual dl_if)::get(this, "", "vif", vif))
          `uvm_fatal(get_type_name(),"No VIF")

          // Timer used for UpdateFC / credit-related operations
          update_timer = timer_uvm_dl::type_id::create("update_timer", this);

    // FSM timer used for LTSSM-equivalent state timeouts
    fsm_timer = timer_uvm_dl::type_id::create("fsm_timer", this);
    fsm_timer.set_vif(vif);

    // Create Data Link Control and Management State Machine
    fsm = dlcmsm_fsm::type_id::create("fsm");

    // Timer to model ACK/NAK response latency
    acknak_latency_timer = timer_uvm_dl::type_id::create("acknak_latency_timer", this);
    acknak_latency_timer.set_vif(vif);

    // FIFO to queue ACK/NAK requests (supports backpressure and ordering)
    acknak_req_fifo = new("acknak_req_fifo", this, 10); // TLM FIFO

    // Replay timer used to detect missing ACKs and trigger replay
    replay_timer = timer_uvm_dl::type_id::create("replay_timer", this);
    replay_timer.set_vif(vif);

    // Initialize device-specific transmit sequence number
    my_device_tx_seq_num = 0;

    // Initialize PCIe Data Link Layer tracking registers
    ACKD_SEQ           = 12'hFFF;  // ACKD_SEQ reset value per spec (all 1s)
    NEXT_TRANSMIT_SEQ  = 12'h000;  // Next sequence number starts at 0
    REPLAY_NUM         = 2'b00;    // Replay counter reset
    last_ackd_seq      = 12'hFFF;  // No packets acknowledged at reset

    // Informational log confirming proper initialization
    `uvm_info(get_type_name(),
              $sformatf("Device %0d: PCIe registers initialized - ACKD_SEQ='h%h, NEXT_TRANSMIT_SEQ='h%h, REPLAY_NUM=%0d", 
                        cfg.device_id, ACKD_SEQ, NEXT_TRANSMIT_SEQ, REPLAY_NUM),
              UVM_LOW)

    `uvm_info(get_type_name(),
              $sformatf("Device %0d driver built", cfg.device_id),
              UVM_LOW)
  endfunction


  //--------------------------------------------------------------------------
  // Run Phase
  // Description:
  //   - Reads Data Link Feature capability registers
  //   - Initializes and runs DLCMSM FSM
  //   - Manages feature exchange, transmit/receive paths, and replay logic
  //--------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    //     phase.raise_objection(this);
    if(cfg.device_id==0)
      wait(`SIV_LINK_UP(ltssm_rc_state));
    else
      wait(`SIV_LINK_UP(ltssm_ep_state));      
    `uvm_info(get_type_name(),"################# ENTERED DL DRIVER AFTER L0 ##########################",UVM_NONE);
    // Sanity check for virtual interface
    if (vif == null)
      `uvm_fatal(get_type_name(), "NULL VIF");

    // Synchronize with clock before accessing registers
    @(posedge(vif.clk))

    // Read local Data Link Feature capability register
    local_data = reg_model.local_f_reg.get();
    // $display("local reg=%0h",local_data);

    // Extract feature control bits from register
    cfg.dl_feature_exchange_enable = local_data[31];
    cfg.scaled_flow_control_spprt  = local_data[0];
    cfg.local_feature_support      = local_data[22:0];

    // Initialize FSM with timer, interface, and configuration
    fsm.init(fsm_timer, vif, cfg);

    // Start FSM execution from DL_INACTIVE
    fsm.update_state();

    //--------------------------------------------------------------------------
    // Data Link Feature Exchange Phase
    //--------------------------------------------------------------------------
    if(cfg.dl_feature_exchange_enable) begin
      wait(fsm.curr_state == DL_FEATURE);

      fork
        // Transmit Data Link Feature DLLPs
        begin
          pr[0] = process::self;
          dlcmsm_tx_dlf();
        end

        // Receive and process Data Link Feature DLLPs
        begin
          pr[1] = process::self;
          dlcmsm_rx_dlf();
        end
      join_none
    end

    //--------------------------------------------------------------------------
    // Transition to DL_INIT after feature exchange
    //--------------------------------------------------------------------------
    wait(fsm.curr_state == DL_INIT);

    // Stop feature exchange transmit thread once completed
    if(cfg.dl_feature_exchange_enable) begin
      // pr[1].kill();  // RX allowed to complete naturally
      pr[0].kill();
    end

    // Advance FSM into FC_INIT1
    fsm.update_state();
    wait(fsm.curr_state == FC_INIT1);

    //--------------------------------------------------------------------------
    // Main Data Link Active Operations
    //--------------------------------------------------------------------------
    fork
      update_fsm();              // FSM transition monitoring
      dlcmsm_tx(phase);               // Main transmit path (TLP/DLLP)
      dlcmsm_rx();               // Main receive path
      acknak_timer_manager();    // ACK/NAK latency tracking
      handle_acknak_requests();  // ACK/NAK generation and dispatch
      monitor_replay_timer();    // Replay timeout detection and handling
    join
  endtask

  //--------------------------------------------------------------------------
  // Task: dlcmsm_tx_dlf
  // Description:
  //   Handles transmission of Data Link Feature (DLF) DLLPs during DL_FEATURE
  //   state. Advertises local feature support and acknowledges receipt of
  //   partner DLF DLLPs as per PCIe Data Link Feature Exchange protocol.
  //--------------------------------------------------------------------------
  task dlcmsm_tx_dlf();
    while(fsm.curr_state == DL_FEATURE) begin
      pcie_dl_seq_item req;

      // Wait for clock edge before issuing next DLLP
      @(posedge vif.clk);

      // Get next sequence item from sequencer
      req=pcie_dl_seq_item::type_id::create("req");
      req.dllps_f_pkt.dllp_type = DATA_LINK_FEATURE; req.is_tlp = 0;req.acknak_pkt.dllp_type = 0;

      // Associate transaction with this device (RC/EP)
      req.device_id = cfg.device_id;

      // Populate feature support and ACK bit
      req.dllps_f_pkt.feature_sprt = cfg.local_feature_support;
      req.dllps_f_pkt.feature_ack  = f_rcd;   // ACK remote DLF if already received

      // Clear previous packet contents
      req.dllp_pkt.delete();

      // Pack Data Link Feature DLLP payload (without CRC)
      req.pack_dl_feature();

      // Append CRC16 to DLLP (upper 16 bits valid, lower padded)
      req.dllp_pkt.push_back({req.calculate_dllp_crc16({>>8{req.dllp_pkt[0]}}),16'b0});

      // Insert Start-of-DLLP marker before transmission
      req.dllp_pkt.push_front(32'hDEADBEEA);

      // Transmit only if this is a Data Link Feature DLLP
      if(req.dllp_pkt[1][31:24]==DATA_LINK_FEATURE) begin
        `uvm_info(get_type_name(),
                  $sformatf("SENDING DL FEATURE DLLP=%p",req.dllp_pkt),
                  UVM_NONE)
        drive(req);
      end

      // Complete sequence item handshake
      //       seq_item_port.item_done();     
    end
  endtask


  //--------------------------------------------------------------------------
  // Task: dlcmsm_rx_dlf
  // Description:
  //   Receives and processes Data Link Feature DLLPs during DL_FEATURE state.
  //   Validates CRC, captures remote feature support, and controls FSM
  //   transition to DL_INIT based on feature ACK.
  //--------------------------------------------------------------------------
  task dlcmsm_rx_dlf();
    bit [7:0] raw_dllp_type;
    pcie_dl_seq_item rx_item;
    bit dlf_en;
    bit scl_en;
    bit [31:0] rx_dword;
    bit [7:0] data_bytes[$];
    bit [15:0] comp_crc;
    bit f_ack;

    forever begin
      if(fsm.curr_state != DL_FEATURE) begin
        break; 
      end
//       dl_rcv_pl_port.get(dl_frm_pl_q);
      dw_pkt::get_q(dl_rcv_pl_port, dl_frm_pl_q);

      // Create RX transaction container
      rx_item = pcie_dl_seq_item::type_id::create("rx_item", this);
      rx_item.device_id = cfg.device_id;

      @(posedge vif.clk);
      rx_dword = dl_frm_pl_q[0];



      // Detect start-of-DLLP marker
      if(rx_dword==`SDP) begin
        @(posedge vif.clk);
        rx_dword = dl_frm_pl_q[1];

        rx_item.dllp_pkt.push_back(rx_dword);
        f_rcd = 1;  // Mark that a feature DLLP has been received
//         $display("RECORDED DLF=%0b",f_rcd);
        raw_dllp_type = rx_dword[31:24];
        f_ack          = rx_dword[23]; // Feature ACK bit

        // Handle valid Data Link Feature DLLP
        if(raw_dllp_type == DATA_LINK_FEATURE && fsm.curr_state==DL_FEATURE) begin
          scl_en = rx_dword[0];   // Scaled Flow Control enable
          data_bytes = {>>8{rx_dword}};      
          comp_crc = rx_item.calculate_dllp_crc16(data_bytes);

          @(posedge vif.clk);
          rx_dword = dl_frm_pl_q[2];
          rx_item.dllp_pkt.push_back(rx_dword);

          // CRC validation
          if(comp_crc==rx_dword[31:16]) begin
            cfg.dl_feature_sprt_valid   = 1'b1;
            cfg.remote_feature_support = rx_item.dllp_pkt[1][22:0];
            cfg.scaled_flow_control_spprt = scl_en;

            // Update remote feature status register
            reg_model.remote_f_reg.set({1'b1,30'b0,scl_en});
            remote_data = reg_model.remote_f_reg.get();

            `uvm_info(get_type_name(),
                      $sformatf("LOCAL_REG=%h      REMOTE_REG=%h",local_data,remote_data),
                      UVM_NONE)
            `uvm_info(get_type_name(),
                      $sformatf("Recieved DL_FEATURE DLLP=%p",rx_item.dllp_pkt),
                      UVM_NONE)
          end
          else begin
            // CRC mismatch handling
            `uvm_warning(get_type_name(),$sformatf("rcvd CRC=%b",rx_dword))
            `uvm_warning(get_type_name(),$sformatf("comptd CRC=%b",comp_crc))
            `uvm_error(get_type_name(),
                       $sformatf("CRC MISMATCH Recieved DL_FEATURE DLLP=%p cal_crc=%h",
                                 rx_item.dllp_pkt,comp_crc))
          end

          // Trigger FSM transition based on ACK bit
          fsm.go_init = f_ack;
          fsm.update_state();
        end

        //------------------------------------------------------------------
        // Handling case where remote does NOT support Data Link Feature
        // and directly proceeds with INITFC1
        //------------------------------------------------------------------
        if(raw_dllp_type==INITFC1_P_VC0 && fsm.curr_state==DL_FEATURE) begin
          cfg.dl_feature_sprt_valid   = 1'b0;
          cfg.remote_feature_support = 0;

          `uvm_info(get_type_name(),
                    $sformatf("Recieved DL_INITFC1 DLLP=%p",rx_item.dllp_pkt),
                    UVM_NONE)

          // Force FSM to bypass DL_FEATURE and enter DL_INIT
          fsm.go_init = 1;
          fsm.update_state();

          cfg.curr_state = fsm.curr_state;
          cfg.last_state = fsm.last_state;

          // Stop RX feature exchange thread
          pr[1].kill();
//           $display("************************%%%%%%%%%%%%%%%%%%%%%%%********************************");
        end
      end
    end
  endtask


  //--------------------------------------------------------------------------
  // Replay Timer Management
  //--------------------------------------------------------------------------

  // Starts replay timer if not already running
  task start_replay_timer();
    if (!replay_timer_running) begin
      replay_timer_running = 1;
      replay_timer.start_timer(10000, "REPLAY_TIMER");

      `uvm_info("REPLAY_TIMER",
                $sformatf("Device %0d: REPLAY_TIMER started for %0d cycles", 
                          cfg.device_id, 10000),
                UVM_LOW);
    end
  endtask


  // Stops replay timer (typically upon ACK reception)
  task stop_replay_timer();
    if (replay_timer_running) begin
      replay_timer.stop_timer();
      replay_timer_running = 0;

      `uvm_info("REPLAY_TIMER",
                $sformatf("Device %0d: REPLAY_TIMER stopped", cfg.device_id),
                UVM_LOW);
    end
  endtask


  // Monitors replay timer expiration and triggers replay logic
  task monitor_replay_timer();
    forever begin
      @(posedge vif.clk);

      if (replay_timer_running && replay_timer.done_flag) begin
        `uvm_warning("REPLAY_TIMER",
                     $sformatf("Device %0d: REPLAY_TIMER expired! Initiating replay",
                               cfg.device_id));

        handle_replay_timer_expiration();

        replay_timer_running = 0;
        replay_timer.done_flag = 0;
      end
    end
  endtask


  //--------------------------------------------------------------------------
  // Replay Timer Expiration Handler
  // Description:
  //   - Increments REPLAY_NUM
  //   - Initiates replay or forces link retrain on overflow
  //--------------------------------------------------------------------------
  task handle_replay_timer_expiration();
    REPLAY_NUM = REPLAY_NUM + 1;

    `uvm_info("REPLAY_TIMER",
              $sformatf("Device %0d: REPLAY_NUM incremented to %0d",
                        cfg.device_id, REPLAY_NUM),
              UVM_LOW);

    // After 4 failed replay attempts, force link retrain
    if (REPLAY_NUM == 2'b00) begin // rollover from 11b to 00b
      `uvm_error("REPLAY_TIMER",
                 $sformatf("Device %0d: REPLAY_NUM overflow! 4 failed attempts - forcing link retrain",
                           cfg.device_id));
      force_link_retrain();
    end
    else begin
      // Replay outstanding unacknowledged TLPs
      initiate_buffer_replay();
      start_replay_timer();
    end
  endtask

  // Utility Functions
  function bit is_forward_progress(bit [11:0] received_seq);
    bit [12:0] diff = (received_seq + 4096 - ACKD_SEQ) % 4096;
    return (diff > 0 && diff < 2048);
  endfunction

  function bit is_counter_separation_too_large();
    bit [12:0] diff = (NEXT_TRANSMIT_SEQ + 4096 - ACKD_SEQ) % 4096;
    return (diff >= 2048);
  endfunction

  task force_link_retrain();
    `uvm_error("LINK_RETRAIN", $sformatf("Device %0d: Forcing link retrain due to REPLAY_NUM overflow", cfg.device_id));
    // Implementation would signal Physical Layer to enter Recovery state
  endtask

  task initiate_buffer_replay(bit [11:0] start_seq_num = 0);
    pcie_dl_seq_item replay_items[$];

    `uvm_info("REPLAY", $sformatf("Device %0d: Initiating replay from seq_num %0d", cfg.device_id, start_seq_num), UVM_LOW);

    // Retrieve TLPs from replay buffer starting from start_seq_num using the new method
    pcie_dl_seq_item::get_replay_buffer_items(cfg.device_id, start_seq_num, replay_items);

    if (replay_items.size() == 0) begin
      `uvm_warning("REPLAY", $sformatf("Device %0d: No TLPs to replay from seq_num %0d", cfg.device_id, start_seq_num));
      return;
    end

    // Populate replay_queue with retrieved TLPs (preserve original sequence numbers and data)
    replay_queue = replay_items;
    replay_mode = 1;  // Activate replay mode
    `uvm_info("REPLAY", $sformatf("Device %0d: Queued %0d TLPs for replay starting from seq_num %0d", cfg.device_id, replay_queue.size(), start_seq_num), UVM_LOW);
  endtask


  //Update state each clock cycle
  task update_fsm();
    fork
      begin forever begin
        @(posedge vif.clk);
        fsm.update_state();
        cfg.curr_state = fsm.curr_state;
        cfg.last_state = fsm.last_state;
      end end
      begin forever begin
        @(cfg.curr_state);
        `uvm_info(get_type_name(), $sformatf("Device %0d: DLCMSM state change from %s to %s", cfg.device_id, cfg.last_state, cfg.curr_state), UVM_LOW);
      end end
    join
  endtask

  task collect_tlps(uvm_phase phase);
    int cntr;bit rcv_flag;
    forever begin
      //       if((cntr!=0)&&(dl_tlp_queue.size==0)&&rcv_flag)begin
      //         phase.drop_objection(this);
      //         `uvm_info("COLLECTION_TL_2_DL",$sformatf("DROPING RC::%0b",cfg.device_id==0),UVM_NONE);
      //       end

      dw_pkt::get_q(dl_driver_get_tl_port, dl_getting_que);
//       dl_driver_get_tl_port.get(dl_getting_que);
      rcv_flag=1;
      //       if(cntr==0)begin
      //         phase.raise_objection(this);
      //         `uvm_info("COLLECTION_TL_2_DL",$sformatf("RAISING RC::%0b",cfg.device_id==0),UVM_NONE);
      //       end

      `uvm_info("INSIDE DL DRIVER","SUCCESS RECIEVED FROM TL",UVM_NONE);
      dl_tlp_queue.push_back(dl_getting_que);
      cntr++;
      `uvm_info("COLLECTION_TL_2_DL",$sformatf("PKT RECIEVED=%p   Que_size=%0d",dl_getting_que,dl_tlp_queue.size()),UVM_NONE);
      foreach(dl_getting_que[i])
        `uvm_info("INSIDE DL DRIVER",$sformatf("dl_getting_que= %h ",dl_getting_que[i]),UVM_NONE);

    end
  endtask





  // Enhanced TX task 
  task dlcmsm_tx(uvm_phase phase);
    fork
      collect_tlps(phase);
    join_none

    forever begin
      pcie_dl_seq_item req;


      // Check for ACK/NAK requests first (unchanged)
      if (acknak_req_fifo.used() > 0) begin

        acknak_req_fifo.get(req); 


        is_acknak_req = 1; 
        `uvm_info(get_type_name(), $sformatf("Device %0d: Processing ACK/NAK request from FIFO", cfg.device_id), UVM_LOW);
      end
      else begin
        // NEW: If replay mode is active and replay_queue has items, send from replay_queue instead of sequencer
        if (replay_mode && replay_queue.size() > 0) begin
          req = replay_queue.pop_front();  // Get next replay TLP
          is_acknak_req = 0;
          `uvm_info(get_type_name(), $sformatf("Device %0d: Sending replay TLP seq_num %0d from replay_queue", cfg.device_id, req.seq_num), UVM_LOW);
        end
        else if (!replay_mode) begin
          // Normal mode: Get new item from sequencer

          wait(fsm.curr_state inside {FC_INIT1, FC_INIT2, DL_ACTIVE});


          seq_item_port.get_next_item(req);
          

          is_acknak_req = 0;
        end
        else begin
          // Replay mode but queue empty: Wait for next clock (replay completion will reset mode)
          @(posedge vif.clk);
          continue;
        end
      end

      req.device_id = cfg.device_id;

      // State-based filtering for regular DLLPs (not ACK/NAK) (unchanged)
      if (!req.is_tlp && !(req.acknak_pkt.dllp_type inside {ACK_DLLP_TYPE, NAK_DLLP_TYPE})) begin
        case (fsm.curr_state)
          FC_INIT1: if (!(req.dllps_pkt.dllp_type inside {INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0})) begin
            `uvm_warning(get_type_name(), $sformatf("Device %0d: Blocked non-INITFC1 DLLP (%s) in FC_INIT1", cfg.device_id, req.dllps_pkt.dllp_type.name()));
            if (!is_acknak_req) seq_item_port.item_done(); 
            continue;
          end
          FC_INIT2: if (req.dllps_pkt.dllp_type inside {INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0}) begin
            if (fsm.curr_state != FC_INIT2 || fsm.go_active) begin
              `uvm_warning(get_type_name(), $sformatf("Device %0d: Blocked INITFC2 DLLP from TX in state %s", cfg.device_id, fsm.curr_state.name()));
              if (!is_acknak_req) seq_item_port.item_done(); 
              continue; 
            end
          end
          DL_ACTIVE: begin
            if (req.dllps_pkt.dllp_type inside {INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0,
                                                INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0}) begin
              `uvm_warning(get_type_name(), $sformatf("Device %0d: Blocked INITFC DLLP (%s) in DL_ACTIVE", cfg.device_id, req.dllps_pkt.dllp_type.name()));
              if (!is_acknak_req) seq_item_port.item_done(); 
              continue;
            end
            if (!(req.dllps_pkt.dllp_type inside {UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0,NOP,PM_Enter_L1,PM_Enter_L23,PM_Active_State_Request_L1,PM_Request_Ack})) begin
              `uvm_warning(get_type_name(), $sformatf("Device %0d: Blocked restricted DLLP (%s) in DL_ACTIVE", cfg.device_id, req.dllps_pkt.dllp_type.name()));
              if (!is_acknak_req) seq_item_port.item_done(); 
              continue;
            end
          end
        endcase
      end

      // Block TLPs in non-DL_ACTIVE state (unchanged)
      if (req.is_tlp && fsm.curr_state != DL_ACTIVE) begin
        `uvm_warning(get_type_name(), $sformatf("Device %0d: Blocked TLP in non-DL_ACTIVE state", cfg.device_id));
        if (!is_acknak_req) seq_item_port.item_done(); 
        continue;
      end


      if (!req.is_tlp && fsm.curr_state == DL_ACTIVE && (req.dllps_pkt.dllp_type inside {UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0})) begin
        //         timer_uvm update_timer;
        //         update_timer.start_timer(LTSMM_UPDATE,"Update_timer");
        `uvm_info(get_type_name(),"inside UPDATEFC transmission",UVM_NONE);
        ph_cost = 1; 
        pd_cost = (req.tlps_pkt.length + 3) / 4; 

        // Blocking Wait for Credits (using 2's complement modulo arithmetic)
        // We assume Posted (Memory Write) for generic TLPs here. 
        // If you support reads, you need a case statement on req.tlps_pkt.Fmt/Type.

        // WAIT LOOP
        //         fork


        while (1) begin
          ph_ok = ( (tx_ph_limit - tx_ph_consumed) ) >= ph_cost;
          //             $display("ph %0d %0d",tx_ph_limit, tx_ph_consumed);

          pd_ok = ( (tx_pd_limit - tx_pd_consumed) ) >= pd_cost;
          //             $display("pd %0d %0d",tx_pd_limit, tx_pd_consumed);

          if ((ph_ok && pd_ok) || update_timer.done_flag)begin
            if(ph_ok && pd_ok) begin
              `uvm_info("CREDIT_OK", "Enough Credits Available, Exit While LOOP", UVM_NONE);
              send_tlp=1;
            end
            //               else begin
            //                 `uvm_info("CREDIT_TIMER_RUNOUT", "Update timer Ran out", UVM_NONE);
            //                 send_tlp=0;
            //               end
            break; // We have enough credits! Exit loop.
          end

          // Not enough credits, wait for next clock and check again (Receive updates happen in parallel)
          `uvm_info("FC_WAIT", $sformatf("Device %0d Waiting for Credits. Need PH:%0d PD:%0d. Have PH_Room:%0d PD_Room:%0d", 
                                         cfg.device_id, ph_cost, pd_cost, 
                                         (tx_ph_limit - tx_ph_consumed), 
                                         (tx_pd_limit - tx_pd_consumed)), UVM_NONE);
          //             $display("##################################################################################################################");
          @(posedge vif.clk);
        end

        //         join_none
        //         $display("okhayyy, lets gooo %0d %0d %0d %0d",ph_ok, pd_ok, tx_ph_limit, tx_ph_consumed, tx_pd_limit, tx_pd_consumed);

        //         if (!is_acknak_req) seq_item_port.item_done();
      end

      //TLP transmission
      if(req.is_tlp && fsm.curr_state == DL_ACTIVE && send_tlp && dl_tlp_queue.size()>=0 ) begin

        wait(dl_tlp_queue.size()>0);

        //         if(i==0) phase.raise_objection(this);
        //         i++;
//         $display("%0d *********************************IFPART********************************** ",dl_tlp_queue.size());
      end
      //       if(cntr_tlp == `NUM_TLPS_TO_SEND) phase.drop_objection(this);
      //       else begin

      //         if(req.is_tlp && fsm.curr_state == DL_ACTIVE && send_tlp && dl_tlp_queue.size()>0 )begin
      //           phase.raise_objection(this);
      //           $display("%0d ****************************ELSEPART*********************************** ",dl_tlp_queue.size());
      //         end
      //       end
      if (req.is_tlp && fsm.curr_state == DL_ACTIVE && send_tlp && dl_tlp_queue.size()>0 ) begin
        //         dl_driver_get_tl_port.get(dl_getting_que);
        //         $display("SUCCESS RECIEVED FROM TL");
        //         dl_tlp_queue.push_back(dl_getting_que);
        //         `uvm_info("COLLECTION_TL_2_DL",$sformatf("PKT RECIEVED=%p   Que_size=%0d",dl_getting_que,dl_tlp_queue.size()),UVM_NONE);
        //         foreach(dl_getting_que[i])
        //           $display("%h ",dl_getting_que[i]);
        `uvm_info(get_type_name(),"inside TLP transmission",UVM_NONE);
        phase.raise_objection(this);
        dl_q=dl_tlp_queue.pop_front();

//         `uvm_info(get_full_name,$sformatf("Fmt=%0h",dl_q[0][31:29]),UVM_NONE);
//         `uvm_info(get_full_name,$sformatf("Type=%0h",dl_q[0][28:24]),UVM_NONE);
//         `uvm_info(get_full_name,$sformatf("rsvd1=%0h",dl_q[0][23]),UVM_NONE);
//         `uvm_info(get_full_name,$sformatf("TC=%0h",dl_q[0][22:20]),UVM_NONE); 
//         `uvm_info(get_full_name,$sformatf("rsvd2=%0h",dl_q[0][19]),UVM_NONE);
//         `uvm_info(get_full_name,$sformatf("attr1=%0h",dl_q[0][18]),UVM_NONE);
//         `uvm_info(get_full_name,$sformatf("rsvd3=%0h",dl_q[0][17]),UVM_NONE);
//         `uvm_info(get_full_name,$sformatf("TH=%0h",dl_q[0][16]),UVM_NONE);
//         `uvm_info(get_full_name,$sformatf("TD=%0h",dl_q[0][15]),UVM_NONE);
//         `uvm_info(get_full_name,$sformatf("EP=%0h",dl_q[0][14]),UVM_NONE);
//         `uvm_info(get_full_name,$sformatf("attr2=%0h",dl_q[0][13:12]),UVM_NONE);
//         `uvm_info(get_full_name,$sformatf("AT=%0h",dl_q[0][11:10]),UVM_NONE);
//         `uvm_info(get_full_name,$sformatf("length=%0h",dl_q[0][9:0]),UVM_NONE);
//         `uvm_info(get_full_name,$sformatf("Address=%0h",dl_q[2]),UVM_NONE);
        req.tlps_pkt.Fmt=		dl_q[0][31:29];
        req.tlps_pkt.Type=		dl_q[0][28:24];
        req.tlps_pkt.rsvd1=		dl_q[0][23];
        req.tlps_pkt.TC=		dl_q[0][22:20]; 
        req.tlps_pkt.rsvd2=		dl_q[0][19];
        req.tlps_pkt.attr1=		dl_q[0][18];
        req.tlps_pkt.rsvd3=		dl_q[0][17];
        req.tlps_pkt.TH=		dl_q[0][16];
        req.tlps_pkt.TD=		dl_q[0][15];
        req.tlps_pkt.EP=		dl_q[0][14];
        req.tlps_pkt.attr2=		dl_q[0][13:12];
        req.tlps_pkt.AT=		dl_q[0][11:10];
        req.tlps_pkt.length=	dl_q[0][9:0];
        req.tlps_pkt.sdw=		dl_q[1];
        req.tlps_pkt.Address=	dl_q[2];
        //         req.payload.delete();
//         req.payload=new[dl_q.size()-3](dl_q[3:$]);
        req.payload = new[dl_q.size()-3];
        foreach (req.payload[i]) req.payload[i] = dl_q[i+3];
//         $display("################################################################");
//         $display("%p",req.tlps_pkt);
        req.from_TL=1;

        // NEW: For replay TLPs, skip counter separation check and sequence number assignment (use stored seq_num)
        if (!replay_mode) begin
          // Check counter separation (only for new TLPs)
          if (is_counter_separation_too_large()) begin
            `uvm_warning(get_type_name(), $sformatf("Device %0d: Cannot send TLP - counter separation >= 2048. NEXT_TRANSMIT_SEQ='h%h, ACKD_SEQ='h%h", 
                                                    cfg.device_id, NEXT_TRANSMIT_SEQ, ACKD_SEQ));
            if (!is_acknak_req) seq_item_port.item_done();
            continue;
          end

          //Assign sequence number using NEXT_TRANSMIT_SEQ (only for new TLPs)
          req.assign_sequence_number(NEXT_TRANSMIT_SEQ);
          NEXT_TRANSMIT_SEQ = (NEXT_TRANSMIT_SEQ + 1) % 4096;

          // Pack and store (only for new TLPs)
          req.do_pack_bytes();
          req.store_in_replay_buffer(cfg.device_id);

          //REPLAY_TIMER management - start when TLP sent (only for new TLPs)
          if (!replay_timer_running) begin
            start_replay_timer();
          end
        end
        else begin
          // For replay TLPs: Use stored sequence number, no need to pack/store again
          // Data is already packed from get_replay_buffer_items
        end

        `uvm_info(get_type_name(),
                  $sformatf("Device %0d Sent TLP: [Identifier=%h] | [length=%0d] | [address='h%h] | [seq_num=%0d] | [payload=%p] | [LCRC='h%h] | NEXT_TRANSMIT_SEQ='h%h",
                            cfg.device_id, req.dllp_pkt[0], req.tlps_pkt.length, req.tlps_pkt.Address, req.seq_num, req.payload, req.lcrc, NEXT_TRANSMIT_SEQ), UVM_LOW);
        // 3. Update Consumption (Spend the credits) - Done for both new and replay TLPs
        tx_ph_consumed = (tx_ph_consumed + ph_cost) & 8'hFF;     // Wrap at 8 bits
        tx_pd_consumed = (tx_pd_consumed + pd_cost) & 12'hFFF;   // Wrap at 12 bits

        `uvm_info("FC_SPEND", $sformatf("Device %0d Spent Credits. New Consumed: PH=%0d PD=%0d", 
                                        cfg.device_id, tx_ph_consumed, tx_pd_consumed), UVM_MEDIUM);
      end
      else begin
        req.do_pack_bytes();
      end


      // STATE-BASED LOGGING for DLLPs (unchanged)
      if (!req.is_tlp) begin
        req.dllp_pkt.push_front(32'hDEADBEEA);
        case (fsm.curr_state)
          FC_INIT1: if (req.dllps_pkt.dllp_type inside {INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0}) begin
            `uvm_info(get_type_name(),
                      $sformatf("Device %0d Sent DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:1",
                                cfg.device_id, req.dllps_pkt.dllp_type, req.dllps_pkt.dllp_type.name(), 
                                req.dllps_pkt.rsvd1, req.dllps_pkt.HdrFC, req.dllps_pkt.rsvd2, req.dllps_pkt.DataFC), UVM_LOW);
          end
          FC_INIT2: if (req.dllps_pkt.dllp_type inside {INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0}) begin
            `uvm_info(get_type_name(),
                      $sformatf("Device %0d Sent DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:1",
                                cfg.device_id, req.dllps_pkt.dllp_type, req.dllps_pkt.dllp_type.name(), 
                                req.dllps_pkt.rsvd1, req.dllps_pkt.HdrFC, req.dllps_pkt.rsvd2, req.dllps_pkt.DataFC), UVM_LOW);
          end
          DL_ACTIVE: begin
            if (req.acknak_pkt.dllp_type inside {ACK_DLLP_TYPE, NAK_DLLP_TYPE}) begin
              if (is_acknak_req) begin
                `uvm_info(get_type_name(),
                          $sformatf("Device %0d Sent BATCHED ACK/NAK DLLP: [dllp_type: %0h %s] | [rsvd:'h%0h] | [seq_num:%0d] | [crc16:'h%0h]",
                                    cfg.device_id, req.acknak_pkt.dllp_type, req.acknak_pkt.dllp_type.name(), 
                                    req.acknak_pkt.rsvd, req.acknak_pkt.seq_num, req.acknak_pkt.crc16), UVM_LOW);
              end
            end
            if (req.dllps_pkt.dllp_type inside {UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0}) begin
              `uvm_info(get_type_name(),
                        $sformatf("Device %0d Sent DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:1",
                                  cfg.device_id, req.dllps_pkt.dllp_type, req.dllps_pkt.dllp_type.name(), 
                                  req.dllps_pkt.rsvd1, req.dllps_pkt.HdrFC, req.dllps_pkt.rsvd2, req.dllps_pkt.DataFC), UVM_LOW);
            end
            /////////////////////////////////////////changes for NOP and PM///////////////////////////////////////////
            if (req.is_nop) begin
              `uvm_info(get_type_name(),
                        $sformatf("Device %0d Sent DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:1",
                                  cfg.device_id, req.dllps_pkt.dllp_type, req.dllps_pkt.dllp_type.name(), 
                                  req.dllps_pkt.rsvd1, req.dllps_pkt.HdrFC, req.dllps_pkt.rsvd2, req.dllps_pkt.DataFC), UVM_LOW);
            end
            /////////////////////////////////for PM/////////////////////////////////////////////////////////////
            //             if (req.pm_pkt.dllp_type inside {PM_Enter_L1,PM_Enter_L23,PM_Active_State_Request_L1,PM_Request_Ack}) begin            
            if (req.is_pm) begin
              `uvm_info(get_type_name(),
                        $sformatf("Device %0d Sent Power Management DLLP: [dllp_type: %0h %s] | [rsvd:'h%0h] | [crc16:'h%0h]",
                                  cfg.device_id, req.pm_pkt.dllp_type, req.pm_pkt.dllp_type.name(), 
                                  req.pm_pkt.rsvd,req.pm_pkt.crc16), UVM_LOW);
            end
          end
        endcase
      end
      // callback triggering to corrupt lcrc & for nack (unchanged)
      `uvm_do_callbacks(dlcmsm_driver, pcie_dl_pkt_modify_callback, modify_item(req))


      drive(req);
      if(req.is_tlp)begin
//         $display("+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ %0d",cntr_tlp);
        phase.drop_objection(this);

      end

      // NEW: If replay_queue is now empty, reset replay_mode
      if (replay_mode && replay_queue.size() == 0) begin
        replay_mode = 0;
        `uvm_info("REPLAY", $sformatf("Device %0d: Replay completed, exiting replay mode", cfg.device_id), UVM_LOW);
      end

      if (!is_acknak_req && !replay_mode) begin  // NEW: Don't call item_done for replay TLPs

        seq_item_port.item_done();
      end
    end
  endtask

  // Drive the transaction DWORD-wise on interface
  task drive(pcie_dl_seq_item req);
    //     process drive_p=process::self();

    @(posedge vif.clk)
    if((req.is_tlp))begin
      cntr_tlp+=1;
//       $display("SENDING TLP");
//       foreach(req.dllp_pkt[i])
//         $display("%h ",req.dllp_pkt[i]);
    end
//     dl_sending_pl_port.put(req.dllp_pkt);
    dw_pkt::put_q(dl_sending_pl_port, req.dllp_pkt);
      `uvm_info(get_full_name(),$sformatf("RC::%0b TLP_NO::%0d Dl_DONE:: %p\tIS_TLP::%0b  ::IDENTIFIER::%0h  from_TL::%0b", (cfg.device_id==0),cntr_tlp,req.dllp_pkt,req.is_tlp,req.dllp_pkt[0],req.from_TL),UVM_NONE);

  endtask

  // Enhanced RX task with Forward Progress Logic
  task dlcmsm_rx();
    bit [31:0] rx_dword, rx_length, rx_lcrc, computed_lcrc, received_lcrc;
    int length_dwords;
    bit dllp_P_rcvd = 0, dllp_NP_rcvd = 0, dllp_CPL_rcvd = 0;
    bit [31:0] rx_data_only[$], rx_dllp_pkt[$], rx_tlp_pkt[$];
    pcie_dl_seq_item rx_item, rx_tlp_item;
    bit [11:0] received_seq;
    bit [7:0] received_dllp_bytes[];
    bit [15:0] received_crc;
    bit crc_valid;
    bit seq_flag;
    bit [7:0] raw_dllp_type;
    bit [7:0] dllp_type_field;
    bit [15:0] computed_dllp_crc;
    bit [7:0] data_only_bytes[];bit [11:0]sq_n;

    //     while(seq_flag!=1) begin
    forever begin
      rx_item = pcie_dl_seq_item::type_id::create("rx_item", this);
      rx_item.device_id = cfg.device_id;
      dw_pkt::get_q(dl_rcv_pl_port, dl_frm_pl_q);
//       dl_rcv_pl_port.get(dl_frm_pl_q);
      //       @(posedge vif.clk);
      rx_dword = dl_frm_pl_q[0];

      if (vif.rst) begin
        // Reset logic 
        dllp_P_rcvd = 0;
        dllp_NP_rcvd = 0;
        dllp_CPL_rcvd = 0;
        fsm.go_fc2_state = 0;
        fsm.go_active = 0;
        rx_dllp_pkt.delete();
        rx_tlp_pkt.delete();
        rx_data_only.delete();
        tl_queue.delete();
        next_rcv_seq = 0;
        ack_timer_running = 0;
        nak_scheduled = 0;
        last_good_seq_num_to_ack = 0;
        continue;
      end



      // TLP Processing 
      if (rx_dword == `STP && fsm.curr_state == DL_ACTIVE) begin
        sq_n=dl_frm_pl_q[1][31:20];
        rx_lcrc = dl_frm_pl_q[dl_frm_pl_q.size()-1];
        length_dwords=dl_frm_pl_q[2][9:0];
//         $display("989898988989898989898989989898989898");

        if (1) begin
          rx_tlp_item = pcie_dl_seq_item::type_id::create("rx_tlp_item", this);
          rx_tlp_item.device_id = cfg.device_id;
          rx_tlp_item.tlp_pkt = dl_frm_pl_q[1:$];
          rx_tlp_item.is_tlp = 1;
          rx_tlp_item.do_unpack_bytes();
          computed_lcrc = rx_tlp_item.calculate_lcrc(dl_frm_pl_q[2:dl_frm_pl_q.size()-2]);
          received_lcrc = rx_lcrc;
//           $display("989898988989898989898989989898989898");

          if(computed_lcrc == ~received_lcrc)begin
            received_seq = sq_n;
            `uvm_warning("LCRC",$sformatf("Device %0d: Nulified TLP seq_num %0d received LCRC inverted! Computed=%h Received=%h  - Dropping nulified TLP", cfg.device_id, received_seq, computed_lcrc, received_lcrc));
            next_rcv_seq = (next_rcv_seq + 1) % 4096;
          end

          else if (computed_lcrc != received_lcrc) begin
            `uvm_error("LCRC", $sformatf("Device %0d: LCRC mismatch! Computed=%h Received=%h - Dropping TLP", cfg.device_id, computed_lcrc, received_lcrc));
            nak_scheduled = 1;
            ack_timer_running = 0;
            acknak_latency_timer.stop_timer();
            schedule_nak(next_rcv_seq - 1);
          end
          else begin
            received_seq = sq_n;
//             $display("989898988989898989xxxxxxxxxxxxxxxxxxxxxxxx898989989898989898");
            if (received_seq === next_rcv_seq) begin
//               $display("989898988989898989898989989898989898");
              `uvm_info("SEQ_CHECK", $sformatf("Device %0d: Sequence match: received=%0d expected=%0d - Accepting TLP", cfg.device_id, received_seq, next_rcv_seq), UVM_LOW);
              process_good_tlp(rx_tlp_item);
              last_good_seq_num_to_ack = received_seq;
              next_rcv_seq = (next_rcv_seq + 1) % 4096;
              nak_scheduled = 0;
              dw_pkt::put_q(dl_driver_put_tl_port, dl_frm_pl_q[2:dl_frm_pl_q.size()-2]);
//               dl_driver_put_tl_port.put(dl_frm_pl_q[2:dl_frm_pl_q.size()-2]);
              `uvm_info("DL_2_TL",$sformatf("TLP 2 DL SENT SUCESS=%p",dl_frm_pl_q[2:dl_frm_pl_q.size()-2]),UVM_NONE);

              if (!ack_timer_running) begin
                ack_timer_running = 1;
                acknak_latency_timer.start_timer(100, "AckNakTimer");
                `uvm_info(get_type_name(), $sformatf("Device %0d: AckNak latency timer STARTED - will ACK when timer expires", cfg.device_id), UVM_LOW);
              end
              `uvm_info(get_type_name(), $sformatf("Device %0d: Good TLP seq_num %0d received - timer continues running (will ACK up to %0d)", cfg.device_id, received_seq, received_seq), UVM_LOW);

            end 
            else if (received_seq > next_rcv_seq) begin
              `uvm_warning("SEQ_CHECK", $sformatf("Device %0d: Out-of-sequence: received=%0d expected=%0d - Scheduling Nak", cfg.device_id, received_seq, next_rcv_seq));
              nak_scheduled = 1;
              ack_timer_running = 0;
              acknak_latency_timer.stop_timer();
              schedule_nak(next_rcv_seq - 1);
            end 
            else begin
              `uvm_info("SEQ_CHECK", $sformatf("Device %0d: Duplicate TLP detected: received=%0d expected=%0d - Sending immediate ACK for last good seq %0d", cfg.device_id, received_seq, next_rcv_seq, last_good_seq_num_to_ack), UVM_LOW);
              //schedule_ack(last_good_seq_num_to_ack);
              schedule_ack(last_good_seq_num_to_ack);
            end
          end
          rx_tlp_item.received_lcrc = received_lcrc;
          rx_tlp_item.lcrc = computed_lcrc;

          `uvm_info(get_type_name(), $sformatf("Device %0d RX TLP: Identifier=%h length=%0d address='h%h seq_num=%0d payload=%p received_lcrc='h%h",
                                               cfg.device_id, rx_tlp_pkt[0], rx_tlp_item.tlps_pkt.length, rx_tlp_item.tlps_pkt.Address, rx_tlp_item.seq_num, rx_tlp_item.payload, rx_tlp_item.received_lcrc), UVM_LOW);

          rx_tlp_pkt.delete();
          rx_data_only.delete();
        end
      end
      // DLLP Processing with Enhanced ACK/NAK handling
      else if(rx_dword == `SDP)begin
        //         @(posedge vif.clk);
        rx_dword = dl_frm_pl_q[1];
        if (rx_item.is_dllp_start(rx_dword)) begin
          rx_dllp_pkt = {};
          rx_dllp_pkt.push_back(rx_dword);
          //           @(posedge vif.clk);
          rx_dword = dl_frm_pl_q[2];
          if (rx_dword != 0) rx_dllp_pkt.push_back(rx_dword);
          rx_item.dllp_pkt = rx_dllp_pkt;
          rx_item.is_tlp = 0; 

          raw_dllp_type = rx_dllp_pkt[0][31:24];


          if (raw_dllp_type inside {ACK_DLLP_TYPE, NAK_DLLP_TYPE, NOP}) begin
            rx_item.acknak_pkt.dllp_type = raw_dllp_type;
            rx_item.acknak_pkt.rsvd = rx_dllp_pkt[0][23:12];
            rx_item.acknak_pkt.seq_num = rx_dllp_pkt[0][11:0];
            rx_item.acknak_pkt.crc16 = rx_dllp_pkt[1][31:16];
            rx_item.dllps_pkt.dllp_type = raw_dllp_type;
          end
          /////////////////////Powermanagement///////////
          else if (raw_dllp_type inside {PM_Enter_L1,PM_Enter_L23,PM_Active_State_Request_L1,PM_Request_Ack}) begin
            rx_item.pm_pkt.dllp_type = raw_dllp_type;
            rx_item.dllps_pkt.dllp_type = raw_dllp_type;
            rx_item.is_pm=1;
            rx_item.pm_pkt.rsvd = rx_dllp_pkt[0][23:0];
            rx_item.pm_pkt.crc16 = rx_dllp_pkt[1][31:16];
            rx_item.pm_pkt.dllp_type = raw_dllp_type;
          end
          else begin
            rx_item.do_unpack_bytes();
          end

          // Don't process ACK/NAK during  flow control phases
          if (raw_dllp_type inside {ACK_DLLP_TYPE, NAK_DLLP_TYPE,PM_Enter_L1,PM_Enter_L23,PM_Active_State_Request_L1,PM_Request_Ack, NOP} && 
              fsm.curr_state != DL_ACTIVE && raw_dllp_type!=DATA_LINK_FEATURE) begin
            `uvm_info(get_type_name(), 
                      $sformatf("Device %0d: Ignoring %0h during %s state - ACK/NAK only valid in DL_ACTIVE", 
                                cfg.device_id, raw_dllp_type, 
                                fsm.curr_state.name()), UVM_LOW);
            rx_dllp_pkt.delete();
            continue;
          end
          // CRC Verification for DLLPs
          crc_valid = 1; // Default to valid

          // Convert DLLP to byte array for CRC check
          received_dllp_bytes = new[6];  // 6 bytes total for DLLP

          // Check DLLP type and extract bytes accordingly  
          if (raw_dllp_type inside {ACK_DLLP_TYPE, NAK_DLLP_TYPE, NOP}) begin
            // ACK/NAK DLLP - CORRECTED to match packing exactly
            received_dllp_bytes[0] = rx_dllp_pkt[0][31:24]; // dllp_type
            received_dllp_bytes[1] = rx_dllp_pkt[0][23:16]; // rsvd[11:4] 
            received_dllp_bytes[2] = rx_dllp_pkt[0][15:8];  // rsvd[3:0] + seq_num[11:8] as single byte
            received_dllp_bytes[3] = rx_dllp_pkt[0][7:0];   // seq_num[7:0]
            received_dllp_bytes[4] = rx_dllp_pkt[1][31:24]; // crc16[15:8]
            received_dllp_bytes[5] = rx_dllp_pkt[1][23:16]; // crc16[7:0]
            received_crc = rx_dllp_pkt[1][31:16];
          end
          ////////For the pm dllps
          if (raw_dllp_type inside {PM_Enter_L1,PM_Enter_L23,PM_Active_State_Request_L1,PM_Request_Ack}) begin
            //         if (is_pm) begin
            // ACK/NAK DLLP - CORRECTED to match packing exactly
            received_dllp_bytes[0] = rx_dllp_pkt[0][31:24]; // dllp_type
            received_dllp_bytes[1] = rx_dllp_pkt[0][23:16]; // rsvd
            received_dllp_bytes[2] = rx_dllp_pkt[0][15:8];  // rsvd
            received_dllp_bytes[3] = rx_dllp_pkt[0][7:0];   // rsvd
            received_dllp_bytes[4] = rx_dllp_pkt[1][31:24]; // crc16[15:8]
            received_dllp_bytes[5] = rx_dllp_pkt[1][23:16]; // crc16[7:0]
            received_crc = rx_dllp_pkt[1][31:16];
            //             foreach(received_dllp_bytes[i]) $display("%h",received_dllp_bytes[i]);////for debugging
          end
          else begin
            // Regular DLLP
            received_dllp_bytes[0] = rx_dllp_pkt[0][31:24]; // dllp_type
            received_dllp_bytes[1] = {rx_dllp_pkt[0][23:22], rx_dllp_pkt[0][21:16]}; // rsvd1 + HdrFC[7:2]
            received_dllp_bytes[2] = {rx_dllp_pkt[0][15:14], rx_dllp_pkt[0][13:12], rx_dllp_pkt[0][11:8]}; // HdrFC[1:0] + rsvd2 + DataFC[11:8]
            received_dllp_bytes[3] = rx_dllp_pkt[0][7:0];   // DataFC[7:0]
            received_dllp_bytes[4] = rx_dllp_pkt[1][31:24]; // crc16[15:8]
            received_dllp_bytes[5] = rx_dllp_pkt[1][23:16]; // crc16[7:0]
            received_crc = rx_dllp_pkt[1][31:16];
            //             foreach(received_dllp_bytes[i]) $display("%b",received_dllp_bytes[i]);
          end

          // Extract data bytes (exclude CRC field - last 2 bytes)
          data_only_bytes = new[received_dllp_bytes.size() - 2];
          for (int i = 0; i < data_only_bytes.size(); i++)
            data_only_bytes[i] = received_dllp_bytes[i];

          // Calculate CRC using sequence item function
          computed_dllp_crc = rx_item.calculate_dllp_crc16(data_only_bytes);

          // CRC comparison with proper DLLP type identification
          if (computed_dllp_crc == received_crc) begin
            if (raw_dllp_type inside {ACK_DLLP_TYPE, NAK_DLLP_TYPE}) begin
              `uvm_info("CRC_MATCH", 
                        $sformatf("Device %0d: DLLP CRC match! Computed=%h Received=%h - Processing DLLP type %s", 
                                  cfg.device_id, computed_dllp_crc, received_crc, rx_item.acknak_pkt.dllp_type.name()), UVM_LOW);
            end
            else begin
//               `uvm_info("CRC_MATCH", 
//                         $sformatf("Device %0d: DLLP CRC match! Computed=%h Received=%h - Processing DLLP type %s", 
//                                   cfg.device_id, computed_dllp_crc, received_crc, rx_item.dllps_pkt.dllp_type.name()), UVM_LOW);
            end
            crc_valid = 1;
          end
          else begin
            if (raw_dllp_type inside {ACK_DLLP_TYPE, NAK_DLLP_TYPE}) begin
              `uvm_error("DLLP_CRC", 
                         $sformatf("Device %0d: DLLP CRC mismatch! Computed=%h Received=%h - Dropping DLLP type %s", 
                                   cfg.device_id, computed_dllp_crc, received_crc, rx_item.acknak_pkt.dllp_type.name()));
            end
            else begin
              `uvm_error("DLLP_CRC", 
                         $sformatf("Device %0d: DLLP CRC mismatch! Computed=%h Received=%h - Dropping DLLP type %s", 
                                   cfg.device_id, computed_dllp_crc, received_crc, rx_item.dllps_pkt.dllp_type.name()));
            end
            rx_dllp_pkt.delete(); 
            continue;  // Drop the DLLP
          end

          if (fsm.curr_state == DL_ACTIVE &&
              rx_item.dllps_pkt.dllp_type inside {INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0}) begin
            `uvm_warning(get_type_name(), $sformatf("Device %0d: Blocked INITFC2 DLLP in DL_ACTIVE: %s", cfg.device_id, rx_item.dllps_pkt.dllp_type.name()));
            rx_dllp_pkt.delete(); continue;
          end

          case (rx_item.dllps_pkt.dllp_type)
            ACK_DLLP_TYPE: begin
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX ACK DLLP: seq_num=%0d, rsvd='h%0h, CRC_Valid=%0b", 
                                  cfg.device_id, rx_item.acknak_pkt.seq_num, rx_item.acknak_pkt.rsvd, crc_valid), UVM_LOW);

              // Check for forward progress
              if (is_forward_progress(rx_item.acknak_pkt.seq_num)) begin
                `uvm_info("ACK_PROGRESS", $sformatf("Device %0d: Forward progress detected! ACK seq='h%h > last_ack='h%h", 
                                                    cfg.device_id, rx_item.acknak_pkt.seq_num, ACKD_SEQ), UVM_LOW);

                //Update ACKD_SEQ register
                ACKD_SEQ = rx_item.acknak_pkt.seq_num;
                last_ackd_seq = ACKD_SEQ;

                //Reset REPLAY_NUM and REPLAY_TIMER on forward progress
                REPLAY_NUM = 2'b00;
                stop_replay_timer();

                //Purge acknowledged TLPs from replay buffer
                rx_item.clear_replay_buffer_up_to_ack(cfg.device_id, ACKD_SEQ);

                //Check if more TLPs remain in replay buffer
                if (pcie_dl_seq_item::get_replay_count_static(cfg.device_id) > 0) begin
                  start_replay_timer();
                end
              end else begin
                `uvm_info("ACK_PROGRESS", $sformatf("Device %0d: No forward progress - ACK seq='h%h <= last_ack='h%h", 
                                                    cfg.device_id, rx_item.acknak_pkt.seq_num, ACKD_SEQ), UVM_LOW);
              end
            end

            NAK_DLLP_TYPE: begin
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX NAK DLLP: seq_num=%0d, rsvd='h%0h, CRC_Valid=%0b", 
                                  cfg.device_id, rx_item.acknak_pkt.seq_num, rx_item.acknak_pkt.rsvd, crc_valid), UVM_LOW);

              //Check for forward progress first
              if (is_forward_progress(rx_item.acknak_pkt.seq_num)) begin
                ACKD_SEQ = rx_item.acknak_pkt.seq_num;
                last_ackd_seq = ACKD_SEQ;
                REPLAY_NUM = 2'b00;
                stop_replay_timer();
                rx_item.clear_replay_buffer_up_to_ack(cfg.device_id, ACKD_SEQ);
              end

              // Initiate replay regardless of forward progress
              REPLAY_NUM = REPLAY_NUM + 1;
              handle_nak_replay(rx_item.acknak_pkt.seq_num);
            end

            // DLLP types
            INITFC1_P_VC0: begin
              dllp_P_rcvd = 1;
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:%0b",
                                  cfg.device_id, rx_item.dllps_pkt.dllp_type, rx_item.dllps_pkt.dllp_type.name(),
                                  rx_item.dllps_pkt.rsvd1, rx_item.dllps_pkt.HdrFC,
                                  rx_item.dllps_pkt.rsvd2, rx_item.dllps_pkt.DataFC, crc_valid), UVM_LOW);
              tx_ph_limit = rx_item.dllps_pkt.HdrFC;   // Capture Header Limit
              tx_pd_limit = rx_item.dllps_pkt.DataFC;  // Capture Data Limit


              if(local_data[0]&&remote_data[0])begin
                rx_item.scale_h();
                rx_item.scale_d();
                tx_ph_limit = rx_item.dllps_pkt.HdrFC<<rx_item.sclh;
                tx_pd_limit = rx_item.dllps_pkt.DataFC<<rx_item.scld;

              end

              // Keep your existing state logic for INITFC1/2 completion
              if (rx_item.dllps_pkt.dllp_type == INITFC1_P_VC0) dllp_P_rcvd = 1;

              // Keep your existing uvm_info
              `uvm_info(get_type_name(), $sformatf("Device %0d Updated POSTED Credits: PH_Limit=%0d PD_Limit=%0d", 
                                                   cfg.device_id, tx_ph_limit, tx_pd_limit), UVM_NONE);
            end

            INITFC1_NP_VC0: begin
              if (dllp_P_rcvd) dllp_NP_rcvd = 1;
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:%0b",
                                  cfg.device_id, rx_item.dllps_pkt.dllp_type, rx_item.dllps_pkt.dllp_type.name(),
                                  rx_item.dllps_pkt.rsvd1, rx_item.dllps_pkt.HdrFC,
                                  rx_item.dllps_pkt.rsvd2, rx_item.dllps_pkt.DataFC, crc_valid), UVM_LOW);
              tx_nph_limit = rx_item.dllps_pkt.HdrFC;
              tx_npd_limit = rx_item.dllps_pkt.DataFC;

              if(local_data[0]&&remote_data[0])begin
                rx_item.scale_h();
                rx_item.scale_d();
                tx_nph_limit = rx_item.dllps_pkt.HdrFC<<rx_item.sclh;
                tx_npd_limit = rx_item.dllps_pkt.DataFC<<rx_item.scld;
              end

              if (rx_item.dllps_pkt.dllp_type == INITFC1_NP_VC0 && dllp_P_rcvd) dllp_NP_rcvd = 1;

              `uvm_info(get_type_name(), $sformatf("Device %0d Updated NON-POSTED Credits: NPH_Limit=%0d NPD_Limit=%0d", 
                                                   cfg.device_id, tx_nph_limit, tx_npd_limit), UVM_NONE);
            end

            INITFC1_CPL_VC0: begin
              if (dllp_P_rcvd && dllp_NP_rcvd) begin
                dllp_CPL_rcvd = 1;
                fsm.go_fc2_state = 1;
                `uvm_info(get_type_name(), $sformatf("Device %0d: INITFC1 sequence completed, moving to FC_INIT2", cfg.device_id), UVM_LOW);
              end
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:%0b",
                                  cfg.device_id, rx_item.dllps_pkt.dllp_type, rx_item.dllps_pkt.dllp_type.name(),
                                  rx_item.dllps_pkt.rsvd1, rx_item.dllps_pkt.HdrFC,
                                  rx_item.dllps_pkt.rsvd2, rx_item.dllps_pkt.DataFC, crc_valid), UVM_NONE);
              tx_cplh_limit = rx_item.dllps_pkt.HdrFC;
              tx_cpld_limit = rx_item.dllps_pkt.DataFC;

              if(local_data[0]&&remote_data[0])begin
                rx_item.scale_h();
                rx_item.scale_d();
                tx_cplh_limit = rx_item.dllps_pkt.HdrFC<<rx_item.sclh;
                tx_cpld_limit = rx_item.dllps_pkt.DataFC<<rx_item.scld;
              end

              // Existing FSM transition logic
              if (rx_item.dllps_pkt.dllp_type == INITFC1_CPL_VC0 && dllp_P_rcvd && dllp_NP_rcvd) begin
                dllp_CPL_rcvd = 1;
                fsm.go_fc2_state = 1;
                `uvm_info(get_type_name(), $sformatf("Device %0d: INITFC1 sequence completed", cfg.device_id), UVM_LOW);
              end

              `uvm_info(get_type_name(), $sformatf("Device %0d Updated CPL Credits: CPLH_Limit=%0d CPLD_Limit=%0d", 
                                                   cfg.device_id, tx_cplh_limit, tx_cpld_limit), UVM_NONE);
            end

            INITFC2_P_VC0: begin
              if (fsm.curr_state == FC_INIT2 && fsm.go_fc2_state && !fsm.go_active) begin
                fsm.go_active = 1;
                repeat(2) @(posedge vif.clk);
                `uvm_info(get_type_name(), $sformatf("Device %0d: FSM: Transitioning to DL_ACTIVE after INITFC2", cfg.device_id), UVM_LOW);
              end
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:%0b",
                                  cfg.device_id, rx_item.dllps_pkt.dllp_type, rx_item.dllps_pkt.dllp_type.name(),
                                  rx_item.dllps_pkt.rsvd1, rx_item.dllps_pkt.HdrFC,
                                  rx_item.dllps_pkt.rsvd2, rx_item.dllps_pkt.DataFC, crc_valid), UVM_LOW);
              tx_ph_limit = rx_item.dllps_pkt.HdrFC;   // Capture Header Limit
              tx_pd_limit = rx_item.dllps_pkt.DataFC;  // Capture Data Limit


              if(local_data[0]&&remote_data[0])begin
                rx_item.scale_h();
                rx_item.scale_d();
                tx_ph_limit = rx_item.dllps_pkt.HdrFC<<rx_item.sclh;
                tx_pd_limit = rx_item.dllps_pkt.DataFC<<rx_item.scld;
              end

              // Keep your existing state logic for INITFC1/2 completion
              if (rx_item.dllps_pkt.dllp_type == INITFC1_P_VC0) dllp_P_rcvd = 1;

              // Keep your existing uvm_info
              `uvm_info(get_type_name(), $sformatf("Device %0d Updated POSTED Credits: PH_Limit=%0d PD_Limit=%0d", 
                                                   cfg.device_id, tx_ph_limit, tx_pd_limit), UVM_NONE);
            end

            INITFC2_NP_VC0: begin
              if (fsm.curr_state == FC_INIT2 && fsm.go_fc2_state && !fsm.go_active) begin
                fsm.go_active = 1;
                repeat(2) @(posedge vif.clk);
                `uvm_info(get_type_name(), $sformatf("Device %0d: FSM: Transitioning to DL_ACTIVE after INITFC2", cfg.device_id), UVM_LOW);
              end
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:%0b",
                                  cfg.device_id, rx_item.dllps_pkt.dllp_type, rx_item.dllps_pkt.dllp_type.name(),
                                  rx_item.dllps_pkt.rsvd1, rx_item.dllps_pkt.HdrFC,
                                  rx_item.dllps_pkt.rsvd2, rx_item.dllps_pkt.DataFC, crc_valid), UVM_NONE);
              tx_nph_limit = rx_item.dllps_pkt.HdrFC;
              tx_npd_limit = rx_item.dllps_pkt.DataFC;

              if(local_data[0]&&remote_data[0])begin
                rx_item.scale_h();
                rx_item.scale_d();
                tx_nph_limit = rx_item.dllps_pkt.HdrFC<<rx_item.sclh;
                tx_npd_limit = rx_item.dllps_pkt.DataFC<<rx_item.scld;
              end

              if (rx_item.dllps_pkt.dllp_type == INITFC1_NP_VC0 && dllp_P_rcvd) dllp_NP_rcvd = 1;

              `uvm_info(get_type_name(), $sformatf("Device %0d Updated NON-POSTED Credits: NPH_Limit=%0d NPD_Limit=%0d", 
                                                   cfg.device_id, tx_nph_limit, tx_npd_limit), UVM_HIGH);
            end

            INITFC2_CPL_VC0: begin
              if (fsm.curr_state == FC_INIT2 && fsm.go_fc2_state && !fsm.go_active) begin
                fsm.go_active = 1;
                repeat(2) @(posedge vif.clk);
                `uvm_info(get_type_name(), $sformatf("Device %0d: FSM: Transitioning to DL_ACTIVE after INITFC2", cfg.device_id), UVM_LOW);
              end
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:%0b",
                                  cfg.device_id, rx_item.dllps_pkt.dllp_type, rx_item.dllps_pkt.dllp_type.name(),
                                  rx_item.dllps_pkt.rsvd1, rx_item.dllps_pkt.HdrFC,
                                  rx_item.dllps_pkt.rsvd2, rx_item.dllps_pkt.DataFC, crc_valid), UVM_NONE);
              tx_cplh_limit = rx_item.dllps_pkt.HdrFC;
              tx_cpld_limit = rx_item.dllps_pkt.DataFC;

              if(local_data[0]&&remote_data[0])begin
                rx_item.scale_h();
                rx_item.scale_d();
                tx_cplh_limit = rx_item.dllps_pkt.HdrFC<<rx_item.sclh;
                tx_cpld_limit = rx_item.dllps_pkt.DataFC<<rx_item.scld;
              end

              // Existing FSM transition logic
              if (rx_item.dllps_pkt.dllp_type == INITFC1_CPL_VC0 && dllp_P_rcvd && dllp_NP_rcvd) begin
                dllp_CPL_rcvd = 1;
                fsm.go_fc2_state = 1;
                `uvm_info(get_type_name(), $sformatf("Device %0d: INITFC1 sequence completed", cfg.device_id), UVM_LOW);
              end

              `uvm_info(get_type_name(), $sformatf("Device %0d Updated CPL Credits: CPLH_Limit=%0d CPLD_Limit=%0d", 
                                                   cfg.device_id, tx_cplh_limit, tx_cpld_limit), UVM_NONE);
            end

            //ACK/NAK DLLP processing with device-specific replay buffer handling
            ACK_DLLP_TYPE: begin
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX ACK DLLP: seq_num=%0d, rsvd='h%0h, CRC_Valid=%0b", 
                                  cfg.device_id, rx_item.acknak_pkt.seq_num, rx_item.acknak_pkt.rsvd, crc_valid), UVM_LOW);


            end

            NAK_DLLP_TYPE: begin
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX NAK DLLP: seq_num=%0d, rsvd='h%0h, CRC_Valid=%0b", 
                                  cfg.device_id, rx_item.acknak_pkt.seq_num, rx_item.acknak_pkt.rsvd, crc_valid), UVM_LOW);

              //Handle NAK - might need to replay from the NAK'd sequence number
              handle_nak_replay(rx_item.acknak_pkt.seq_num);
            end

            UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0: begin
              if(fsm.curr_state == FC_INIT2)
                fsm.go_active = 1;
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:%0b",
                                  cfg.device_id, rx_item.dllps_pkt.dllp_type, rx_item.dllps_pkt.dllp_type.name(),
                                  rx_item.dllps_pkt.rsvd1, rx_item.dllps_pkt.HdrFC,
                                  rx_item.dllps_pkt.rsvd2, rx_item.dllps_pkt.DataFC, crc_valid), UVM_LOW);
              if(rx_item.dllps_pkt.dllp_type==UPDATEFC_P_VC0)begin
                tx_ph_limit = rx_item.dllps_pkt.HdrFC;   // Capture Header Limit
                tx_pd_limit = rx_item.dllps_pkt.DataFC;  // Capture Data Limit

                if(local_data[0]&&remote_data[0])begin
                  rx_item.scale_h();
                  rx_item.scale_d();
                  tx_ph_limit = rx_item.dllps_pkt.HdrFC<<rx_item.sclh;
                  tx_pd_limit = rx_item.dllps_pkt.DataFC<<rx_item.scld;
                end

                // Keep your existing state logic for INITFC1/2 completion
                if (rx_item.dllps_pkt.dllp_type == INITFC1_P_VC0) dllp_P_rcvd = 1;

                // Keep your existing uvm_info
                `uvm_info(get_type_name(), $sformatf("Device %0d Updated POSTED Credits: PH_Limit=%0d PD_Limit=%0d", 
                                                     cfg.device_id, tx_ph_limit, tx_pd_limit), UVM_HIGH);
              end
              if(rx_item.dllps_pkt.dllp_type==UPDATEFC_NP_VC0)begin
                tx_nph_limit = rx_item.dllps_pkt.HdrFC;
                tx_npd_limit = rx_item.dllps_pkt.DataFC;

                if(local_data[0]&&remote_data[0])begin
                  rx_item.scale_h();
                  rx_item.scale_d();
                  tx_nph_limit = rx_item.dllps_pkt.HdrFC<<rx_item.sclh;
                  tx_npd_limit = rx_item.dllps_pkt.DataFC<<rx_item.scld;
                end

                if (rx_item.dllps_pkt.dllp_type == INITFC1_NP_VC0 && dllp_P_rcvd) dllp_NP_rcvd = 1;

                `uvm_info(get_type_name(), $sformatf("Device %0d Updated NON-POSTED Credits: NPH_Limit=%0d NPD_Limit=%0d", 
                                                     cfg.device_id, tx_nph_limit, tx_npd_limit), UVM_HIGH);
              end
              if(rx_item.dllps_pkt.dllp_type==UPDATEFC_CPL_VC0)begin
                tx_cplh_limit = rx_item.dllps_pkt.HdrFC;
                tx_cpld_limit = rx_item.dllps_pkt.DataFC;

                if(local_data[0]&&remote_data[0])begin
                  rx_item.scale_h();
                  rx_item.scale_d();
                  tx_cplh_limit = rx_item.dllps_pkt.HdrFC<<rx_item.sclh;
                  tx_cpld_limit = rx_item.dllps_pkt.DataFC<<rx_item.scld;
                end

                // Existing FSM transition logic
                if (rx_item.dllps_pkt.dllp_type == INITFC1_CPL_VC0 && dllp_P_rcvd && dllp_NP_rcvd) begin
                  dllp_CPL_rcvd = 1;
                  fsm.go_fc2_state = 1;
                  `uvm_info(get_type_name(), $sformatf("Device %0d: INITFC1 sequence completed", cfg.device_id), UVM_LOW);
                end

                `uvm_info(get_type_name(), $sformatf("Device %0d Updated CPL Credits: CPLH_Limit=%0d CPLD_Limit=%0d", 
                                                     cfg.device_id, tx_cplh_limit, tx_cpld_limit), UVM_HIGH);
              end

            end
            //////////////////////////////Power Management AND NOP DLLP Handling////////////////////////////
            NOP:begin 
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX NOP DLLP: CRC_Valid=%0b", 
                                  cfg.device_id,crc_valid), UVM_LOW);
            end
            PM_Enter_L1:begin 
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX PM_Enter_L1 DLLP: rsvd='h%0h, CRC_Valid=%0b", 
                                  cfg.device_id, rx_item.pm_pkt.rsvd, crc_valid), UVM_LOW);
            end
            PM_Enter_L23:begin 
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX PM_Enter_L23 DLLP: rsvd='h%0h, CRC_Valid=%0b", 
                                  cfg.device_id, rx_item.pm_pkt.rsvd, crc_valid), UVM_LOW);
            end
            PM_Active_State_Request_L1:begin 
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX PM_Active_State_Request_L1 DLLP: rsvd='h%0h, CRC_Valid=%0b", 
                                  cfg.device_id, rx_item.pm_pkt.rsvd, crc_valid), UVM_LOW);
            end
            PM_Request_Ack: begin
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX PM_Request_Ack DLLP: rsvd='h%0h, CRC_Valid=%0b", 
                                  cfg.device_id, rx_item.pm_pkt.rsvd, crc_valid), UVM_LOW);
            end
            DATA_LINK_FEATURE:begin
//               `uvm_info(get_type_name(), 
//                         $sformatf("Device %0d RX Feature DLLP: [dllp_type: %0h %s] | [Feature_ack'h%0h] | [feature_sprt:'h%0h] | [crc16:'h%0h] |",
//                                   cfg.device_id, rx_item.dllps_f_pkt.dllp_type, rx_item.dllps_f_pkt.dllp_type.name(),
//                                   rx_item.dllps_f_pkt.feature_ack,
//                                   rx_item.dllps_f_pkt.feature_sprt, rx_item.dllps_f_pkt.crc16), UVM_LOW);
            end

            DATA_LINK_FEATURE:begin
              `uvm_info(get_type_name(), 
                        $sformatf("Device %0d RX Feature DLLP: [dllp_type: %0h %s] | [Feature_ack'h%0h] | [feature_sprt:'h%0h] | [crc16:'h%0h] |",
                                  cfg.device_id, rx_item.dllps_f_pkt.dllp_type, rx_item.dllps_f_pkt.dllp_type.name(),
                                  rx_item.dllps_f_pkt.feature_ack,
                                  rx_item.dllps_f_pkt.feature_sprt, rx_item.dllps_f_pkt.crc16), UVM_LOW);
            end


          endcase
          rx_dllp_pkt.delete();
        end
      end
      uvm_config_db#(bit)::get(null,"*","DL_SEQ_STATUS",seq_flag);
    end
  endtask : dlcmsm_rx

  //NAK replay handling
  task handle_nak_replay(bit [11:0] nak_seq_num);
    replay_mode = 1;  // Ensure replay mode is active
    initiate_buffer_replay(nak_seq_num+1);
    start_replay_timer();
  endtask


  // Rest of your existing tasks remain the same
  task schedule_ack(bit [11:0] seq_num);
    pcie_dl_seq_item ack_pkt = pcie_dl_seq_item::type_id::create("ack_pkt");
    ack_pkt.device_id = cfg.device_id;
    ack_pkt.is_tlp = 0;
    ack_pkt.acknak_pkt.dllp_type = ACK_DLLP_TYPE;
    ack_pkt.acknak_pkt.rsvd = 12'h0;
    ack_pkt.acknak_pkt.seq_num = seq_num;
    ack_pkt.acknak_pkt.crc16 = 16'h0;

    acknak_req_fifo.put(ack_pkt);
    `uvm_info(get_type_name(), $sformatf("Device %0d: Scheduled ACK for seq_num %0d", cfg.device_id, seq_num), UVM_LOW);
  endtask

  task schedule_nak(bit [11:0] seq_num);
    pcie_dl_seq_item nak_pkt = pcie_dl_seq_item::type_id::create("nak_pkt");
    nak_pkt.device_id = cfg.device_id;
    nak_pkt.is_tlp = 0;
    nak_pkt.acknak_pkt.dllp_type = NAK_DLLP_TYPE;
    nak_pkt.acknak_pkt.rsvd = 12'h0;
    nak_pkt.acknak_pkt.seq_num = seq_num;
    nak_pkt.acknak_pkt.crc16 = 16'h0;

    acknak_req_fifo.put(nak_pkt);
    `uvm_info(get_type_name(), $sformatf("Device %0d: Scheduled NAK for seq_num %0d", cfg.device_id, seq_num), UVM_LOW);
  endtask

  // Rest of your existing tasks (acknak_timer_manager, handle_acknak_requests, process_good_tlp, print_tl_queue)
  task acknak_timer_manager();
    forever begin
      @(posedge vif.clk);
      wait (ack_timer_running == 1);  
      do @(posedge vif.clk);
      while (acknak_latency_timer.done_flag !== 1);

      `uvm_info(get_type_name(), 
                $sformatf("Device %0d: AckNak latency timer EXPIRED - scheduling ACK for seq_num %0d", 
                          cfg.device_id, last_good_seq_num_to_ack), UVM_LOW);

      acknak_latency_timer.done_flag = 0;
      ack_timer_running = 0;  

      if (!nak_scheduled) begin
        schedule_ack(last_good_seq_num_to_ack);
        `uvm_info(get_type_name(), $sformatf("Device %0d: BATCHED ACK scheduled - acknowledging all TLPs from 0 to %0d", cfg.device_id, last_good_seq_num_to_ack), UVM_LOW);
      end
    end
  endtask

  task handle_acknak_requests();
    forever begin
      fork
        begin
          @(ack_needed);
          `uvm_info(get_type_name(), 
                    $sformatf("Device %0d: Generating ACK DLLP for seq_num %0d", cfg.device_id, ack_seq_num_to_send), UVM_LOW);
          schedule_ack(ack_seq_num_to_send);
        end

        begin
          @(nak_needed);
          `uvm_info(get_type_name(), 
                    $sformatf("Device %0d: Generating NAK DLLP for seq_num %0d", cfg.device_id, nak_seq_num_to_send), UVM_LOW);
          schedule_nak(nak_seq_num_to_send);
        end
      join_any;
    end
  endtask

  // Process a good TLP by cleaning sequence number and LCRC, preserving header and payload
  task process_good_tlp(pcie_dl_seq_item tlp_item);
    pcie_dl_seq_item clean_tlp;
    bit [31:0] clean_packet[$];
    int header_start, header_end, payload_start, payload_end;
    int tlp_pkt_size;
    int clean_pkt_bytes;

    clean_tlp = pcie_dl_seq_item::type_id::create("clean_tlp", this);
    clean_tlp.device_id = cfg.device_id;

    //copy header and payload
    clean_tlp.tlps_pkt = tlp_item.tlps_pkt;
    clean_tlp.payload = new[tlp_item.payload.size()];
    foreach (tlp_item.payload[i])
      clean_tlp.payload[i] = tlp_item.payload[i];

    clean_tlp.num_payload_dwords = tlp_item.num_payload_dwords;
    clean_tlp.payload_bytes = tlp_item.payload_bytes;


    tlp_pkt_size = tlp_item.tlp_pkt.size();
    clean_packet.delete();

    header_start = 0;
    header_end = 2;                // first 3 DWORDs = header
    payload_start = 4;             // payload starts after seq_num dword at index 3
    payload_end = tlp_pkt_size - 2; // exclude last DWORD which is LCRC

    // Copy header DWORDs
    for (int i = header_start; i <= header_end; i++)
      clean_packet.push_back(tlp_item.tlp_pkt[i]);

    // Copy payload DWORDs
    for (int i = payload_start; i <= payload_end; i++)
      clean_packet.push_back(tlp_item.tlp_pkt[i]);

    clean_tlp.tlp_pkt = clean_packet;

    // Clear unnecessary fields
    clean_tlp.seq_num = 0;
    clean_tlp.lcrc = 0;
    clean_tlp.received_lcrc = 0;
    clean_tlp.is_tlp = 1;

    // Add to queue
    tl_queue.push_back(clean_tlp);

    `uvm_info(get_type_name(),
              $sformatf("Device %0d: Added clean TLP with seq_num=%0d to TL queue. Queue size: %0d",
                        cfg.device_id, tlp_item.seq_num, tl_queue.size()), UVM_LOW);

    clean_pkt_bytes = clean_tlp.tlp_pkt.size() * 4;
    `uvm_info("CLEAN_TLP",
              $sformatf("Device %0d Clean TLP: [length=%0d] | [address='h%016x] | [payload=%p] | [clean_pkt_size=%0d bytes]",
                        cfg.device_id, clean_tlp.tlps_pkt.length,
                        clean_tlp.tlps_pkt.Address,
                        clean_tlp.payload,
                        clean_pkt_bytes), UVM_LOW);

    // Print the entire TL queue
    print_tl_queue();
  endtask

  // Print the contents of the TL queue with detailed info including device ID
  task print_tl_queue();
    `uvm_info("TL_QUEUE_CONTENTS", $sformatf("Device %0d: === TL Queue Status: %0d entries ===", cfg.device_id, tl_queue.size()), UVM_LOW);

    if (tl_queue.size() == 0) begin
      `uvm_info("TL_QUEUE_CONTENTS", $sformatf("Device %0d: Queue is empty", cfg.device_id), UVM_LOW);
      return;
    end

    for (int i = 0; i < tl_queue.size(); i++) begin
      pcie_dl_seq_item queue_item = tl_queue[i];
      int pkt_bytes = queue_item.tlp_pkt.size() * 4;
      `uvm_info("TL_QUEUE_CONTENTS",
                $sformatf("Device %0d Entry[%0d]: [length=%0d] | [address='h%016x] | [payload=%p] | [clean_pkt_size=%0d bytes]",
                          cfg.device_id, i,
                          queue_item.tlps_pkt.length,
                          queue_item.tlps_pkt.Address,
                          queue_item.payload,
                          pkt_bytes), UVM_LOW);
    end

    `uvm_info("TL_QUEUE_CONTENTS", $sformatf("Device %0d: === End of TL Queue ===", cfg.device_id), UVM_LOW);
  endtask

endclass