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

  // --- Flow-control initialisation / credit gating ---
  // Index 0 = Posted, 1 = Non-Posted, 2 = Completion
  bit  fc_init_rcvd[3];            // FC_INIT1: credits recorded for this type (from InitFC1 or InitFC2)
  bit  tx_fc_hdr_inf[3];           // partner advertised infinite header credits (HdrFC = 0 in InitFC)
  bit  tx_fc_data_inf[3];          // partner advertised infinite data credits (DataFC = 0 in InitFC)
  int  initfc_resend_cycles = 200; // InitFC1/InitFC2 repeat interval in clocks (spec: at least every 34 us; LTSSM_1MS = 250 clocks here)
  int  initfc_idle_cycles   = 0;   // cycles since the last InitFC DLLP was sent
  pcie_dl_seq_item initfc_sent[bit [7:0]]; // last InitFC DLLP sent, per DLLP type (used for resends)
  bit  dlf_ack_sent = 0;           // a Data Link Feature DLLP with Feature Ack = 1 has been sent

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
  bit replay_requested = 0;  // Nak / REPLAY_TIMER expiry during a replay: replay again when it is done

  // Device-specific sequence tracking
  bit [11:0] my_device_tx_seq_num = 0;bit f_rcd;
  int i;

  // Transmit arbiter bookkeeping (see dlcmsm_tx)
  bit fc_wait_reported = 0;  // FC_WAIT/separation message already printed for the TLP at the queue head
  bit seq_tlp_warned   = 0;  // warning about TLP items from the DL sequence already printed

  // --- Receiver flow control (credits this device advertised to the partner) ---
  // Index 0 = Posted, 1 = Non-Posted, 2 = Completion. Unscaled credit units.
  int  rx_fc_hdr_alloc[3];    // CREDITS_ALLOCATED: last header value advertised (InitFC/UpdateFC)
  int  rx_fc_data_alloc[3];
  int  rx_fc_hdr_rcvd[3];     // CREDITS_RECEIVED
  int  rx_fc_data_rcvd[3];
  bit  rx_fc_hdr_inf[3];      // infinite credits advertised (0 in InitFC)
  bit  rx_fc_data_inf[3];
  bit  rx_fc_init_seen[3];    // InitFC values of this type captured
  bit  rx_fc_scaled[3];       // advertised with a scale factor > 1: overflow check not done
  bit  rx_fc_dirty[3];        // credits freed, UpdateFC pending

  // --- DL_Down handling ---
  bit     dl_force_down = 0;  // test hook: behave as if LinkUp = 0
  bit     dl_down_done  = 0;  // DL_Down handled, waiting for LinkUp
  int     dl_down_count = 0;
  process rx_proc;            // dlcmsm_rx thread, restarted after a DL_Down

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
      dlcmsm_rx_restartable();   // Main receive path (restarted after a DL_Down)
      dl_link_monitor();         // LinkUp / reset -> DL_Down handling
      rx_fc_updater();           // UpdateFC for credits freed by the receiver
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
    dlf_ack_sent = 0;
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
        if (req.dllps_f_pkt.feature_ack) dlf_ack_sent = 1;
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
            // rx_item.dllp_pkt holds no SDP marker: [0] = DLF DW, [1] = CRC DW
            cfg.remote_feature_support = rx_item.dllp_pkt[0][22:0];
            cfg.scaled_flow_control_spprt = scl_en;

            // Update remote feature status register: [31] valid, [22:0] remote feature support
            reg_model.remote_f_reg.set({1'b1, 8'b0, rx_item.dllp_pkt[0][22:0]});
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

          // Leave DL_FEATURE when the partner acknowledged our feature DLLP and
          // we have already sent an acknowledging DLLP ourselves (otherwise the
          // partner, now with its own DLCMSM, could wait forever for our Ack).
          // A DLLP with a bad CRC is discarded and never moves the FSM.
          if (comp_crc == rx_dword[31:16] && f_ack && dlf_ack_sent) begin
            fsm.go_init = 1;
            fsm.update_state();
          end
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

        // clear first: the replay below restarts the timer
        replay_timer_running = 0;
        replay_timer.done_flag = 0;

        handle_replay_timer_expiration();
      end
    end
  endtask


  //--------------------------------------------------------------------------
  // Replay Timer Expiration Handler
  //   Spec: replay every unacknowledged TLP (see start_replay)
  //--------------------------------------------------------------------------
  task handle_replay_timer_expiration();
    start_replay("REPLAY_TIMER expired");
  endtask


  //--------------------------------------------------------------------------
  // Task: start_replay
  //   Common replay entry for Nak and REPLAY_TIMER expiry:
  //   - a replay already in progress is finished first; one more replay is
  //     then started (replay_requested)
  //   - nothing to replay -> nothing to do
  //   - REPLAY_NUM is incremented; on rollover 11b -> 00b the Physical Layer
  //     must retrain the link (not modelled yet: uvm_error only)
  //   - every TLP not yet acknowledged is replayed, oldest first
  //     (from ACKD_SEQ + 1), and REPLAY_TIMER is restarted
  //--------------------------------------------------------------------------
  task start_replay(string reason);
    bit [11:0] from_seq;
    if (replay_mode) begin
      replay_requested = 1;
      `uvm_info("REPLAY", $sformatf("Device %0d: %s during a replay - will replay again after the current one", cfg.device_id, reason), UVM_LOW);
      return;
    end
    if (pcie_dl_seq_item::get_replay_count_static(cfg.device_id) == 0) begin
      `uvm_info("REPLAY", $sformatf("Device %0d: %s - replay buffer empty, nothing to replay", cfg.device_id, reason), UVM_LOW);
      stop_replay_timer();
      return;
    end
    if (REPLAY_NUM == 2'b11) begin
      `uvm_error("REPLAY_TIMER",
                 $sformatf("Device %0d: REPLAY_NUM rollover (11b -> 00b) on %s - 4 replays without forward progress",
                           cfg.device_id, reason));
      force_link_retrain();
    end
    REPLAY_NUM = REPLAY_NUM + 1;
    from_seq = ACKD_SEQ + 12'd1;   // oldest unacknowledged TLP
    `uvm_info("REPLAY", $sformatf("Device %0d: %s - replaying from seq_num %0d, REPLAY_NUM=%0d",
                                  cfg.device_id, reason, from_seq, REPLAY_NUM), UVM_LOW);
    initiate_buffer_replay(from_seq);
    stop_replay_timer();
    start_replay_timer();
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

  // Spec: on REPLAY_NUM rollover the Physical Layer retrains the link and the
  // replay follows. Retrain is not modelled yet: report it and go on with the
  // replay so the simulation continues.
  task force_link_retrain();
    `uvm_error("LINK_RETRAIN", $sformatf("Device %0d: REPLAY_NUM rollover - link retrain required (not modelled; replay continues)", cfg.device_id));
  endtask

  // AckNak_Seq_Num must be ACKD_SEQ or the sequence number of an
  // unacknowledged TLP; anything else is a Data Link protocol error.
  function bit acknak_seq_valid(bit [11:0] seq);
    bit [11:0] d, outstanding;
    d           = seq - ACKD_SEQ;
    outstanding = NEXT_TRANSMIT_SEQ - 12'd1 - ACKD_SEQ;   // TLPs sent but not acknowledged
    return (d <= outstanding);
  endfunction

  // TLP with sequence number seq is still unacknowledged
  function bit seq_unacked(bit [11:0] seq);
    bit [11:0] d, outstanding;
    d           = seq - ACKD_SEQ;
    outstanding = NEXT_TRANSMIT_SEQ - 12'd1 - ACKD_SEQ;
    return (d != 0 && d <= outstanding);
  endfunction

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
      initfc_retransmit();
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


  //--------------------------------------------------------------------------
  // Task: initfc_retransmit
  //   Spec (FC_INIT1/FC_INIT2): InitFC1 (resp. InitFC2) DLLPs for P, NP and
  //   Cpl are sent in that order and repeated at least every 34 us until the
  //   state is left. The DL sequence sends each set once, so a single lost or
  //   corrupted DLLP used to hang initialisation. If no InitFC DLLP was sent
  //   for initfc_resend_cycles, the set for the current state is sent again,
  //   with the credit values the sequence used.
  //   Also clears the FC_INIT1 bookkeeping whenever the DLCMSM is not in
  //   flow-control initialisation or DL_ACTIVE (e.g. after a DL_Down).
  //--------------------------------------------------------------------------
  task initfc_retransmit();
    forever begin
      @(posedge vif.clk);
      if (!(fsm.curr_state inside {FC_INIT1, FC_INIT2, DL_ACTIVE})) begin
        fc_init_rcvd = '{0, 0, 0};
      end
      if (!(fsm.curr_state inside {FC_INIT1, FC_INIT2})) begin
        initfc_idle_cycles = 0;
        continue;
      end
      initfc_idle_cycles++;
      if (initfc_idle_cycles < initfc_resend_cycles) continue;
      initfc_idle_cycles = 0;
      resend_initfc(fsm.curr_state == FC_INIT1);
    end
  endtask

  task resend_initfc(bit fc1);
    bit [7:0] t1[3];
    bit [7:0] t2[3];
    pcie_dl_seq_item src, req;
    t1 = '{INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0};
    t2 = '{INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0};
    for (int c = 0; c < 3; c++) begin
      // InitFC1 and InitFC2 of one credit type carry the same credit values
      src = null;
      if (initfc_sent.exists(fc1 ? t1[c] : t2[c]))      src = initfc_sent[fc1 ? t1[c] : t2[c]];
      else if (initfc_sent.exists(fc1 ? t2[c] : t1[c])) src = initfc_sent[fc1 ? t2[c] : t1[c]];
      if (src == null) continue;   // the sequence never advertised this type: nothing to repeat
      req = pcie_dl_seq_item::type_id::create("initfc_resend");
      req.device_id = cfg.device_id;
      req.is_tlp = 0;
      req.is_nop = 0;
      req.is_pm  = 0;
      req.acknak_pkt.dllp_type = ACK_DLLP_TYPE;   // 0: not an Ack/Nak
      req.dllps_pkt = src.dllps_pkt;
      req.dllps_pkt.dllp_type = dllp_type_e'(fc1 ? t1[c] : t2[c]);
      `uvm_info(get_type_name(), $sformatf("Device %0d: %s - repeating %s (HdrFC=%0d DataFC=%0d)",
                                           cfg.device_id, fsm.curr_state.name(), req.dllps_pkt.dllp_type.name(),
                                           req.dllps_pkt.HdrFC, req.dllps_pkt.DataFC), UVM_LOW)
      send_dllp(req);
    end
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





  //--------------------------------------------------------------------------
  // Task: dlcmsm_tx  (transmit arbiter)
  // Description:
  //   Each pass picks ONE packet to send, in the order of the PCIe Base Spec
  //   transmit-priority implementation note (Data Link Layer):
  //     1. ACK/NAK DLLPs                      (acknak_req_fifo)
  //     2. Replay of unacknowledged TLPs      (replay_queue)
  //     3. New TLPs from the Transaction Layer (dl_tlp_queue), if FC credits allow
  //     4. DLLPs from the DL sequence (InitFC/UpdateFC/NOP/PM), via try_next_item
  //   TLPs from the TL are sent by the driver itself, so the DL sequence no
  //   longer has to provide "TLP slot" items. The TL, DL and PL sequences are
  //   independent of each other.
  //   try_next_item never blocks, so a finished DL sequence can no longer stop
  //   ACK/NAK or replay traffic (this was the "ACK never sent" bug).
  //--------------------------------------------------------------------------
  task dlcmsm_tx(uvm_phase phase);
    pcie_dl_seq_item req;
    bit tlp_sent;

    fork
      collect_tlps(phase);
    join_none

    forever begin
      req = null;

      // Nothing is transmitted before flow-control initialisation starts
      if (!(fsm.curr_state inside {FC_INIT1, FC_INIT2, DL_ACTIVE})) begin
        @(posedge vif.clk);
        continue;
      end

      //------------------------------------------------------------------
      // 1. ACK / NAK DLLPs
      //------------------------------------------------------------------
      if (acknak_req_fifo.used() > 0) begin
        acknak_req_fifo.get(req);
        is_acknak_req = 1;
        `uvm_info(get_type_name(), $sformatf("Device %0d: Processing ACK/NAK request from FIFO", cfg.device_id), UVM_LOW);
        send_dllp(req);
        is_acknak_req = 0;
        continue;
      end
      is_acknak_req = 0;

      //------------------------------------------------------------------
      // 2. Replay of unacknowledged TLPs (no new TLPs until replay is done)
      //------------------------------------------------------------------
      if (replay_mode) begin
        if (replay_queue.size() > 0) begin
          req = replay_queue.pop_front();
          if (seq_unacked(req.seq_num))
            send_replay_tlp(req, phase);
          else
            `uvm_info("REPLAY", $sformatf("Device %0d: seq_num %0d was acknowledged during the replay - not resent", cfg.device_id, req.seq_num), UVM_LOW)
        end
        if (replay_queue.size() == 0) begin
          replay_mode = 0;
          `uvm_info("REPLAY", $sformatf("Device %0d: Replay completed, exiting replay mode", cfg.device_id), UVM_LOW);
          if (replay_requested) begin
            replay_requested = 0;
            start_replay("Nak/REPLAY_TIMER during the previous replay");
          end
        end
        continue;
      end

      //------------------------------------------------------------------
      // 3. New TLP from the Transaction Layer
      //------------------------------------------------------------------
      if (fsm.curr_state == DL_ACTIVE && dl_tlp_queue.size() > 0) begin
        send_tl_tlp(phase, tlp_sent);
        if (tlp_sent) continue;
      end

      //------------------------------------------------------------------
      // 4. DLLP from the DL sequence (non-blocking)
      //------------------------------------------------------------------
      seq_item_port.try_next_item(req);
      if (req != null) begin
        req.device_id = cfg.device_id;
        if (req.is_tlp) begin
          // TLPs come from the Transaction Layer now. TLP items from the DL
          // sequence (old "TLP slots") are not needed and are ignored.
          if (!seq_tlp_warned) begin
            `uvm_warning(get_type_name(), $sformatf("Device %0d: TLP item from the DL sequence ignored - TLPs are taken from the Transaction Layer queue", cfg.device_id));
            seq_tlp_warned = 1;
          end
        end
        else if (dllp_allowed_in_state(req)) begin
          send_dllp(req);
        end
        seq_item_port.item_done();
        continue;
      end

      // Nothing to send this cycle
      @(posedge vif.clk);
    end
  endtask


  //--------------------------------------------------------------------------
  // Function: dllp_allowed_in_state
  //   State-based filtering of DLLPs coming from the DL sequence.
  //   Note: the Ack DLLP type is 00h, and every sequence item has
  //   acknak_pkt.dllp_type == 0, so the old check "acknak_pkt.dllp_type inside
  //   {ACK, NAK}" matched EVERY item and the filter never ran. It also sent
  //   the register-model write item (dlf_reg_adapter, all fields 0) on the
  //   link as a junk "Ack seq 0". ACK/NAK DLLPs are generated by the driver
  //   itself (acknak_req_fifo), so items without a DLLP type are completed
  //   here without being sent.
  //--------------------------------------------------------------------------
  function bit dllp_allowed_in_state(pcie_dl_seq_item req);
    if (req.dllps_pkt.dllp_type == ACK_DLLP_TYPE && !req.is_nop && !req.is_pm) begin
      `uvm_info(get_type_name(), $sformatf("Device %0d: Sequence item without a DLLP type (register access) completed without sending", cfg.device_id), UVM_HIGH);
      return 0;
    end
    if (req.is_nop) return 1;   // NOP DLLPs may be sent in any state
    case (fsm.curr_state)
      FC_INIT1: if (!(req.dllps_pkt.dllp_type inside {INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0})) begin
        `uvm_warning(get_type_name(), $sformatf("Device %0d: Blocked non-INITFC1 DLLP (%s) in FC_INIT1", cfg.device_id, req.dllps_pkt.dllp_type.name()));
        return 0;
      end
      FC_INIT2: if (req.dllps_pkt.dllp_type inside {INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0}) begin
        if (fsm.go_active) begin
          `uvm_warning(get_type_name(), $sformatf("Device %0d: Blocked INITFC2 DLLP from TX in state %s", cfg.device_id, fsm.curr_state.name()));
          return 0;
        end
      end
      DL_ACTIVE: begin
        if (req.dllps_pkt.dllp_type inside {INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0,
                                            INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0}) begin
          `uvm_warning(get_type_name(), $sformatf("Device %0d: Blocked INITFC DLLP (%s) in DL_ACTIVE", cfg.device_id, req.dllps_pkt.dllp_type.name()));
          return 0;
        end
        if (!(req.dllps_pkt.dllp_type inside {UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0,NOP,PM_Enter_L1,PM_Enter_L23,PM_Active_State_Request_L1,PM_Request_Ack})) begin
          `uvm_warning(get_type_name(), $sformatf("Device %0d: Blocked restricted DLLP (%s) in DL_ACTIVE", cfg.device_id, req.dllps_pkt.dllp_type.name()));
          return 0;
        end
      end
    endcase
    return 1;
  endfunction


  //--------------------------------------------------------------------------
  // Task: send_dllp
  //   Packs, logs and drives one DLLP (ACK/NAK, InitFC, UpdateFC, NOP, PM).
  //--------------------------------------------------------------------------
  task send_dllp(pcie_dl_seq_item req);
    req.device_id = cfg.device_id;
    if (!req.is_tlp && !req.is_nop && !req.is_pm &&
        req.dllps_pkt.dllp_type inside {INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0,
                                        INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0}) begin
      initfc_sent[req.dllps_pkt.dllp_type] = req;
      initfc_idle_cycles = 0;
    end
    req.do_pack_bytes();
    req.dllp_pkt.push_front(32'hDEADBEEA);

    // STATE-BASED LOGGING for DLLPs (unchanged)
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
          `uvm_info(get_type_name(),
                    $sformatf("Device %0d Sent BATCHED ACK/NAK DLLP: [dllp_type: %0h %s] | [rsvd:'h%0h] | [seq_num:%0d] | [crc16:'h%0h]",
                              cfg.device_id, req.acknak_pkt.dllp_type, req.acknak_pkt.dllp_type.name(),
                              req.acknak_pkt.rsvd, req.acknak_pkt.seq_num, req.acknak_pkt.crc16), UVM_LOW);
        end
        else if (req.dllps_pkt.dllp_type inside {UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0}) begin
          `uvm_info(get_type_name(),
                    $sformatf("Device %0d Sent DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:1",
                              cfg.device_id, req.dllps_pkt.dllp_type, req.dllps_pkt.dllp_type.name(),
                              req.dllps_pkt.rsvd1, req.dllps_pkt.HdrFC, req.dllps_pkt.rsvd2, req.dllps_pkt.DataFC), UVM_LOW);
        end
        if (req.is_nop) begin
          `uvm_info(get_type_name(),
                    $sformatf("Device %0d Sent NOP DLLP", cfg.device_id), UVM_LOW);
        end
        if (req.is_pm) begin
          `uvm_info(get_type_name(),
                    $sformatf("Device %0d Sent Power Management DLLP: [dllp_type: %0h %s] | [rsvd:'h%0h] | [crc16:'h%0h]",
                              cfg.device_id, req.pm_pkt.dllp_type, req.pm_pkt.dllp_type.name(),
                              req.pm_pkt.rsvd,req.pm_pkt.crc16), UVM_LOW);
        end
      end
    endcase

    // callback hook (error injection: corrupt CRC, drop, modify ...)
    `uvm_do_callbacks(dlcmsm_driver, pcie_dl_pkt_modify_callback, modify_item(req))
    drive(req);
  endtask


  //--------------------------------------------------------------------------
  // Task: send_replay_tlp
  //   Re-sends one TLP from the replay buffer (sequence number, header, data
  //   and LCRC are the stored ones; no new credits are consumed).
  //--------------------------------------------------------------------------
  task send_replay_tlp(pcie_dl_seq_item req, uvm_phase phase);
    req.device_id = cfg.device_id;
    `uvm_info(get_type_name(), $sformatf("Device %0d: Sending replay TLP seq_num %0d from replay_queue", cfg.device_id, req.seq_num), UVM_LOW);
    phase.raise_objection(this);
    `uvm_do_callbacks(dlcmsm_driver, pcie_dl_pkt_modify_callback, modify_item(req))
    drive(req);
    phase.drop_objection(this);
  endtask


  //--------------------------------------------------------------------------
  // Task: send_tl_tlp
  //   Takes the TLP at the head of dl_tlp_queue (DWORDs from the TL), checks
  //   sequence-number separation and flow-control credits, then adds the
  //   sequence number + LCRC, stores it in the replay buffer and drives it.
  //   sent = 0 if the TLP has to wait (no credits / too many unACKed TLPs);
  //   it then stays at the head of the queue and is retried later.
  //--------------------------------------------------------------------------
  task send_tl_tlp(uvm_phase phase, output bit sent);
    pcie_dl_seq_item req;
    global_que_t     q;
    int              fc_type, hdr_cost, data_cost;
    int              hdr_dws, exp_dws;

    sent = 0;
    q = dl_tlp_queue[0];

    // Header is 4 DW when Fmt[0] = 1 (64-bit address), else 3 DW
    hdr_dws = (q.size() > 0 && q[0][29]) ? 4 : 3;
    if (q.size() < hdr_dws) begin
      `uvm_error(get_type_name(), $sformatf("Device %0d: TLP from TL has only %0d DWORDs (need a %0d DW header) - dropped: %p", cfg.device_id, q.size(), hdr_dws, q));
      q = dl_tlp_queue.pop_front();
      return;
    end

    // Sequence number rule: no new TLP if NEXT_TRANSMIT_SEQ - ACKD_SEQ >= 2048
    if (is_counter_separation_too_large()) begin
      if (!fc_wait_reported) begin
        `uvm_warning(get_type_name(), $sformatf("Device %0d: TLP waiting - counter separation >= 2048. NEXT_TRANSMIT_SEQ='h%h, ACKD_SEQ='h%h",
                                                cfg.device_id, NEXT_TRANSMIT_SEQ, ACKD_SEQ));
        fc_wait_reported = 1;
      end
      return;
    end

    // Flow-control credit check (Posted / Non-Posted / Completion)
    get_tlp_fc_cost(q[0], fc_type, hdr_cost, data_cost);
    if (!fc_credits_available(fc_type, hdr_cost, data_cost)) begin
      if (!fc_wait_reported) begin
        `uvm_info("FC_WAIT", $sformatf("Device %0d: TLP waiting for %s credits. Need H:%0d D:%0d",
                                       cfg.device_id, fc_type_name(fc_type), hdr_cost, data_cost), UVM_LOW);
        fc_wait_reported = 1;
      end
      return;
    end
    fc_wait_reported = 0;

    q = dl_tlp_queue.pop_front();
    `uvm_info(get_type_name(),"inside TLP transmission",UVM_NONE);
    exp_dws = hdr_dws + (q[0][30] ? ((q[0][9:0] == 0) ? 1024 : q[0][9:0]) : 0);
    if (q.size() != exp_dws)
      `uvm_warning("TLP_FORMAT", $sformatf("Device %0d: TLP from TL has %0d DWORDs, header says %0d (%0d DW header, Length=%0d) - sent as received",
                                           cfg.device_id, q.size(), exp_dws, hdr_dws, q[0][9:0]))

    req = pcie_dl_seq_item::type_id::create("tl_tlp");
    req.device_id = cfg.device_id;
    req.is_tlp    = 1;
    req.tlps_pkt.Fmt=		q[0][31:29];
    req.tlps_pkt.Type=		q[0][28:24];
    req.tlps_pkt.rsvd1=		q[0][23];
    req.tlps_pkt.TC=		q[0][22:20];
    req.tlps_pkt.rsvd2=		q[0][19];
    req.tlps_pkt.attr1=		q[0][18];
    req.tlps_pkt.rsvd3=		q[0][17];
    req.tlps_pkt.TH=		q[0][16];
    req.tlps_pkt.TD=		q[0][15];
    req.tlps_pkt.EP=		q[0][14];
    req.tlps_pkt.attr2=		q[0][13:12];
    req.tlps_pkt.AT=		q[0][11:10];
    req.tlps_pkt.length=	q[0][9:0];
    req.tlps_pkt.sdw=		q[1];
    if (hdr_dws == 4) req.tlps_pkt.Address = {q[2], q[3]};   // DW2 = Address[63:32], DW3 = Address[31:0]
    else              req.tlps_pkt.Address = q[2];
    req.payload = new[q.size()-hdr_dws];
    foreach (req.payload[k]) req.payload[k] = q[k+hdr_dws];
    req.from_TL=1;

    // Assign sequence number, add LCRC, keep a copy for replay
    req.assign_sequence_number(NEXT_TRANSMIT_SEQ);
    NEXT_TRANSMIT_SEQ = (NEXT_TRANSMIT_SEQ + 1) % 4096;
    req.do_pack_bytes();
    req.store_in_replay_buffer(cfg.device_id);

    // REPLAY_TIMER starts when a TLP is sent and is not already running
    if (!replay_timer_running) begin
      start_replay_timer();
    end

    // Spend the credits (new TLPs only, not replays)
    fc_consume(fc_type, hdr_cost, data_cost);

    `uvm_info(get_type_name(),
              $sformatf("Device %0d Sent TLP: [Identifier=%h] | [length=%0d] | [address='h%h] | [seq_num=%0d] | [payload=%p] | [LCRC='h%h] | NEXT_TRANSMIT_SEQ='h%h",
                        cfg.device_id, req.dllp_pkt[0], req.tlps_pkt.length, req.tlps_pkt.Address, req.seq_num, req.payload, req.lcrc, NEXT_TRANSMIT_SEQ), UVM_LOW);

    phase.raise_objection(this);
    // callback hook (e.g. corrupt LCRC to force a NAK); the replay buffer
    // already holds the good copy, so a replay sends the correct TLP
    `uvm_do_callbacks(dlcmsm_driver, pcie_dl_pkt_modify_callback, modify_item(req))
    drive(req);
    phase.drop_objection(this);
    sent = 1;
  endtask


  //--------------------------------------------------------------------------
  // Flow-control helpers
  //   fc_type: 0 = Posted, 1 = Non-Posted, 2 = Completion
  //   1 header credit per TLP, 1 data credit per 4 DW of payload.
  //--------------------------------------------------------------------------
  function void get_tlp_fc_cost(bit [31:0] hdr0, output int fc_type, output int hdr_cost, output int data_cost);
    bit [2:0] fmt;
    bit [4:0] typ;
    int       len_dw;
    fmt    = hdr0[31:29];
    typ    = hdr0[28:24];
    len_dw = (hdr0[9:0] == 0) ? 1024 : hdr0[9:0];
    hdr_cost  = 1;
    data_cost = fmt[1] ? (len_dw + 3) / 4 : 0;           // Fmt[1] = TLP carries data
    if (typ == 5'b01010 || typ == 5'b01011)  fc_type = 2; // Cpl/CplD/CplLk/CplDLk
    else if (typ[4:3] == 2'b10)              fc_type = 0; // Msg/MsgD   -> Posted
    else if (typ == 5'b00000 && fmt[1])      fc_type = 0; // MWr        -> Posted
    else                                     fc_type = 1; // MRd, MRdLk, IO, Cfg, AtomicOp -> Non-Posted
  endfunction

  function string fc_type_name(int fc_type);
    case (fc_type)
      0: return "Posted";
      1: return "Non-Posted";
      default: return "Completion";
    endcase
  endfunction

  // Field widths for the modulo credit arithmetic (wider when Scaled FC is on)
  function int fc_hdr_width();
    return (local_data[0] && remote_data[0]) ? 12 : 8;
  endfunction
  function int fc_data_width();
    return (local_data[0] && remote_data[0]) ? 16 : 12;
  endfunction

  // Spec gating rule: (CREDIT_LIMIT - (CREDITS_CONSUMED + cost)) mod 2^N <= 2^(N-1)
  // Infinite credits (0 advertised in InitFC for that field) are never gated.
  // A CREDIT_LIMIT of 0 reached through UpdateFC is a real limit.
  function bit fc_credit_ok(bit infinite, int limit, int consumed, int cost, int width);
    int modv;
    int r;
    if (cost == 0 || infinite) return 1;
    modv = 1 << width;
    r = (limit - (consumed + cost)) % modv;
    if (r < 0) r += modv;
    return (r <= modv/2);
  endfunction

  function bit fc_credits_available(int fc_type, int hdr_cost, int data_cost);
    int hw, dw;
    hw = fc_hdr_width();
    dw = fc_data_width();
    case (fc_type)
      0:       return fc_credit_ok(tx_fc_hdr_inf[0], tx_ph_limit,   tx_ph_consumed,   hdr_cost, hw) && fc_credit_ok(tx_fc_data_inf[0], tx_pd_limit,   tx_pd_consumed,   data_cost, dw);
      1:       return fc_credit_ok(tx_fc_hdr_inf[1], tx_nph_limit,  tx_nph_consumed,  hdr_cost, hw) && fc_credit_ok(tx_fc_data_inf[1], tx_npd_limit,  tx_npd_consumed,  data_cost, dw);
      default: return fc_credit_ok(tx_fc_hdr_inf[2], tx_cplh_limit, tx_cplh_consumed, hdr_cost, hw) && fc_credit_ok(tx_fc_data_inf[2], tx_cpld_limit, tx_cpld_consumed, data_cost, dw);
    endcase
  endfunction

  function void fc_consume(int fc_type, int hdr_cost, int data_cost);
    int hm, dm;
    hm = 1 << fc_hdr_width();
    dm = 1 << fc_data_width();
    case (fc_type)
      0: begin
        tx_ph_consumed  = (tx_ph_consumed  + hdr_cost)  % hm;
        tx_pd_consumed  = (tx_pd_consumed  + data_cost) % dm;
      end
      1: begin
        tx_nph_consumed = (tx_nph_consumed + hdr_cost)  % hm;
        tx_npd_consumed = (tx_npd_consumed + data_cost) % dm;
      end
      default: begin
        tx_cplh_consumed = (tx_cplh_consumed + hdr_cost)  % hm;
        tx_cpld_consumed = (tx_cpld_consumed + data_cost) % dm;
      end
    endcase
    `uvm_info("FC_SPEND", $sformatf("Device %0d Spent %s credits H:%0d D:%0d. Consumed now P:%0d/%0d NP:%0d/%0d CPL:%0d/%0d",
                                    cfg.device_id, fc_type_name(fc_type), hdr_cost, data_cost,
                                    tx_ph_consumed, tx_pd_consumed, tx_nph_consumed, tx_npd_consumed,
                                    tx_cplh_consumed, tx_cpld_consumed), UVM_MEDIUM);
  endfunction

  // Receive rule: duplicate if (NEXT_RCV_SEQ - seq) mod 4096 <= 2048 (seq != NEXT_RCV_SEQ)
  function bit seq_is_duplicate(bit [11:0] seq);
    bit [11:0] d;
    d = next_rcv_seq - seq;
    return (d != 0 && d <= 12'd2048);
  endfunction

  //--------------------------------------------------------------------------
  // Receive side of flow-control initialisation and credit updates
  //--------------------------------------------------------------------------
  // Credit type from the DLLP type: bits [5:4] = 00 P, 01 NP, 10 Cpl
  function int fc_class(bit [7:0] t);
    case (t[5:4])
      2'b00:   return 0;
      2'b01:   return 1;
      default: return 2;
    endcase
  endfunction

  function bit scaled_fc_active();
    return (local_data[0] && remote_data[0]);
  endfunction

  // Scaled FC: HdrScale/DataScale 01 = x1, 10 = x4, 11 = x16 (00 = not used)
  function int fc_scale_shift(bit [1:0] sc);
    case (sc)
      2'b10:   return 2;
      2'b11:   return 4;
      default: return 0;
    endcase
  endfunction

  // Record the credit limit the partner advertised for credit type c.
  //   is_init = 1 : InitFC1/InitFC2 (a value of 0 means infinite credits)
  //   is_init = 0 : UpdateFC        (ignored for a field advertised as infinite)
  function void set_tx_fc_limit(int c, bit [7:0] hdr, bit [11:0] data, bit [1:0] hs, bit [1:0] ds, bit is_init);
    int h, d;
    if (is_init) begin
      tx_fc_hdr_inf[c]  = (hdr  == 0);
      tx_fc_data_inf[c] = (data == 0);
    end
    h = hdr;
    d = data;
    if (scaled_fc_active()) begin
      h = h << fc_scale_shift(hs);
      d = d << fc_scale_shift(ds);
    end
    case (c)
      0: begin
        if (!tx_fc_hdr_inf[0])  tx_ph_limit   = h;
        if (!tx_fc_data_inf[0]) tx_pd_limit   = d;
      end
      1: begin
        if (!tx_fc_hdr_inf[1])  tx_nph_limit  = h;
        if (!tx_fc_data_inf[1]) tx_npd_limit  = d;
      end
      default: begin
        if (!tx_fc_hdr_inf[2])  tx_cplh_limit = h;
        if (!tx_fc_data_inf[2]) tx_cpld_limit = d;
      end
    endcase
    `uvm_info(get_type_name(), $sformatf("Device %0d %s %s credit limit: Hdr=%s Data=%s",
                                         cfg.device_id, is_init ? "InitFC" : "UpdateFC", fc_type_name(c),
                                         tx_fc_hdr_inf[c]  ? "infinite" : $sformatf("%0d", h),
                                         tx_fc_data_inf[c] ? "infinite" : $sformatf("%0d", d)), UVM_LOW)
  endfunction

  // InitFC1 / InitFC2 received
  //   FC_INIT1: record the credits from InitFC1 OR InitFC2 of each type, in
  //             any order; FI1 (-> FC_INIT2) once P, NP and Cpl are recorded.
  //   FC_INIT2: credit values are ignored; any InitFC2 sets FI2 (-> DL_ACTIVE).
  //   Other states: ignored.
  function void rx_initfc(pcie_dl_seq_item rx_item);
    int c;
    c = fc_class(rx_item.dllps_pkt.dllp_type);
    case (fsm.curr_state)
      FC_INIT1: begin
        if (!fc_init_rcvd[c]) begin
          set_tx_fc_limit(c, rx_item.dllps_pkt.HdrFC, rx_item.dllps_pkt.DataFC,
                          rx_item.dllps_pkt.rsvd1, rx_item.dllps_pkt.rsvd2, 1);
          fc_init_rcvd[c] = 1;
        end
        if (fc_init_rcvd[0] && fc_init_rcvd[1] && fc_init_rcvd[2] && !fsm.go_fc2_state) begin
          fsm.go_fc2_state = 1;
          `uvm_info(get_type_name(), $sformatf("Device %0d: credits for P, NP and Cpl recorded (FI1), moving to FC_INIT2", cfg.device_id), UVM_LOW);
        end
      end
      FC_INIT2: begin
        if (rx_item.dllps_pkt.dllp_type inside {INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0} && !fsm.go_active) begin
          fsm.go_active = 1;
          `uvm_info(get_type_name(), $sformatf("Device %0d: InitFC2 received (FI2), moving to DL_ACTIVE", cfg.device_id), UVM_LOW);
        end
      end
      default: begin
        `uvm_info(get_type_name(), $sformatf("Device %0d: %s ignored in %s", cfg.device_id,
                                             rx_item.dllps_pkt.dllp_type.name(), fsm.curr_state.name()), UVM_MEDIUM);
      end
    endcase
  endfunction

  // UpdateFC received: sets FI2 in FC_INIT2; updates the limit in FC_INIT2/DL_ACTIVE
  function void rx_updatefc(pcie_dl_seq_item rx_item);
    if (fsm.curr_state == FC_INIT2 && !fsm.go_active) begin
      fsm.go_active = 1;
      `uvm_info(get_type_name(), $sformatf("Device %0d: UpdateFC received (FI2), moving to DL_ACTIVE", cfg.device_id), UVM_LOW);
    end
    if (!(fsm.curr_state inside {FC_INIT2, DL_ACTIVE})) begin
      `uvm_info(get_type_name(), $sformatf("Device %0d: %s ignored in %s", cfg.device_id,
                                           rx_item.dllps_pkt.dllp_type.name(), fsm.curr_state.name()), UVM_MEDIUM);
      return;
    end
    set_tx_fc_limit(fc_class(rx_item.dllps_pkt.dllp_type), rx_item.dllps_pkt.HdrFC, rx_item.dllps_pkt.DataFC,
                    rx_item.dllps_pkt.rsvd1, rx_item.dllps_pkt.rsvd2, 0);
  endfunction

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
    if (!req.is_tlp) rx_fc_note_tx_dllp(req);
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

          // Nullified TLP (LCRC inverted): discard silently - NEXT_RCV_SEQ
          // unchanged, no Ack/Nak
          if(computed_lcrc == ~received_lcrc)begin
            received_seq = sq_n;
            `uvm_warning("LCRC",$sformatf("Device %0d: Nulified TLP seq_num %0d received LCRC inverted! Computed=%h Received=%h  - Dropping nulified TLP (NEXT_RCV_SEQ stays %0d)", cfg.device_id, received_seq, computed_lcrc, received_lcrc, next_rcv_seq));
          end

          // Bad LCRC: discard; Nak NEXT_RCV_SEQ - 1 unless a Nak is already
          // scheduled (NAK_SCHEDULED is cleared by the next good TLP)
          else if (computed_lcrc != received_lcrc) begin
            `uvm_error("LCRC", $sformatf("Device %0d: LCRC mismatch! Computed=%h Received=%h - Dropping TLP", cfg.device_id, computed_lcrc, received_lcrc));
            if (!nak_scheduled) begin
              nak_scheduled = 1;
              ack_timer_running = 0;
              acknak_latency_timer.stop_timer();
              schedule_nak(next_rcv_seq - 12'd1);
            end
            else begin
              `uvm_info("LCRC", $sformatf("Device %0d: NAK already scheduled - no new NAK", cfg.device_id), UVM_LOW);
            end
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
            // Spec: if (NEXT_RCV_SEQ - Sequence Number) mod 4096 <= 2048 the TLP is a
            // duplicate (discard, Ack NEXT_RCV_SEQ - 1); otherwise it is out of
            // sequence (discard, Nak NEXT_RCV_SEQ - 1 unless a Nak is already scheduled).
            else if (seq_is_duplicate(received_seq)) begin
              `uvm_info("SEQ_CHECK", $sformatf("Device %0d: Duplicate TLP detected: received=%0d expected=%0d - Sending immediate ACK for seq %0d", cfg.device_id, received_seq, next_rcv_seq, next_rcv_seq - 12'd1), UVM_LOW);
              schedule_ack(next_rcv_seq - 12'd1);
            end
            else begin
              `uvm_warning("SEQ_CHECK", $sformatf("Device %0d: Out-of-sequence: received=%0d expected=%0d - Scheduling Nak", cfg.device_id, received_seq, next_rcv_seq));
              if (!nak_scheduled) begin
                nak_scheduled = 1;
                ack_timer_running = 0;
                acknak_latency_timer.stop_timer();
                schedule_nak(next_rcv_seq - 12'd1);
              end
              else begin
                `uvm_info("SEQ_CHECK", $sformatf("Device %0d: NAK already scheduled - no new NAK", cfg.device_id), UVM_LOW);
              end
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

              if (!acknak_seq_valid(rx_item.acknak_pkt.seq_num)) begin
                `uvm_error("DL_PROTOCOL", $sformatf("Device %0d: Ack for seq_num %0d which was never sent (ACKD_SEQ=%0d NEXT_TRANSMIT_SEQ=%0d) - discarded",
                                                    cfg.device_id, rx_item.acknak_pkt.seq_num, ACKD_SEQ, NEXT_TRANSMIT_SEQ));
              end
              // Check for forward progress
              else if (is_forward_progress(rx_item.acknak_pkt.seq_num)) begin
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

              if (!acknak_seq_valid(rx_item.acknak_pkt.seq_num)) begin
                `uvm_error("DL_PROTOCOL", $sformatf("Device %0d: Nak for seq_num %0d which was never sent (ACKD_SEQ=%0d NEXT_TRANSMIT_SEQ=%0d) - discarded",
                                                    cfg.device_id, rx_item.acknak_pkt.seq_num, ACKD_SEQ, NEXT_TRANSMIT_SEQ));
              end
              else begin
                // A Nak also acknowledges every TLP up to AckNak_Seq_Num
                if (is_forward_progress(rx_item.acknak_pkt.seq_num)) begin
                  ACKD_SEQ = rx_item.acknak_pkt.seq_num;
                  last_ackd_seq = ACKD_SEQ;
                  REPLAY_NUM = 2'b00;
                  stop_replay_timer();
                  rx_item.clear_replay_buffer_up_to_ack(cfg.device_id, ACKD_SEQ);
                end
                // then all TLPs that are still unacknowledged are replayed
                // (REPLAY_NUM is incremented in start_replay)
                handle_nak_replay(rx_item.acknak_pkt.seq_num);
              end
            end

            // DLLP types
            INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0,
            INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0: begin
              `uvm_info(get_type_name(),
                        $sformatf("Device %0d RX DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:%0b",
                                  cfg.device_id, rx_item.dllps_pkt.dllp_type, rx_item.dllps_pkt.dllp_type.name(),
                                  rx_item.dllps_pkt.rsvd1, rx_item.dllps_pkt.HdrFC,
                                  rx_item.dllps_pkt.rsvd2, rx_item.dllps_pkt.DataFC, crc_valid), UVM_LOW);
              rx_initfc(rx_item);
            end

            UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0: begin
              `uvm_info(get_type_name(),
                        $sformatf("Device %0d RX DLLP: [dllp_type: %0h %s] | [rsvd1:'h%0h] | [HdrFC:'h%0h] | [rsvd2:'h%0h] | [DataFC:'h%0h] | CRC_Valid:%0b",
                                  cfg.device_id, rx_item.dllps_pkt.dllp_type, rx_item.dllps_pkt.dllp_type.name(),
                                  rx_item.dllps_pkt.rsvd1, rx_item.dllps_pkt.HdrFC,
                                  rx_item.dllps_pkt.rsvd2, rx_item.dllps_pkt.DataFC, crc_valid), UVM_LOW);
              rx_updatefc(rx_item);
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
    start_replay($sformatf("Nak (AckNak_Seq_Num %0d)", nak_seq_num));
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
    int hdr_dws;

    rx_fc_on_tlp_received(tlp_item.tlp_pkt[1]);

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

    // tlp_pkt = {seq DW, header (3 or 4 DW), payload..., LCRC}
    hdr_dws = tlp_item.tlp_pkt[1][29] ? 4 : 3;   // Fmt[0]
    header_start = 1;
    header_end = hdr_dws;
    payload_start = hdr_dws + 1;
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


  //==========================================================================
  // Receiver flow control
  //   CREDITS_ALLOCATED = what this device advertised (taken from the InitFC /
  //   UpdateFC DLLPs it transmits), CREDITS_RECEIVED = credits of the good
  //   TLPs it accepted. Receiver overflow is checked for every TLP.
  //   With cfg.rx_fc_auto_update = 1 the TL is treated as consuming every TLP
  //   at once: its credits are freed and returned with an UpdateFC.
  //==========================================================================
  function int rx_fc_class(bit [7:0] t);   // DLLP type bits [5:4]: 00 P, 01 NP, 10 Cpl
    case (t[5:4])
      2'b00:   return 0;
      2'b01:   return 1;
      default: return 2;
    endcase
  endfunction

  // Called for every DLLP this device transmits
  function void rx_fc_note_tx_dllp(pcie_dl_seq_item req);
    bit [7:0] t;
    int c;
    if (req.is_tlp || req.is_nop || req.is_pm) return;
    t = req.dllps_pkt.dllp_type;
    if (!(t inside {INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0,
                    INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0,
                    UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0})) return;
    c = rx_fc_class(t);
    if (t[6]) begin   // InitFC1 (01xx_xxxx) / InitFC2 (11xx_xxxx)
      if (!rx_fc_init_seen[c]) begin
        rx_fc_init_seen[c]  = 1;
        rx_fc_hdr_inf[c]    = (req.dllps_pkt.HdrFC  == 0);
        rx_fc_data_inf[c]   = (req.dllps_pkt.DataFC == 0);
        rx_fc_hdr_alloc[c]  = req.dllps_pkt.HdrFC;
        rx_fc_data_alloc[c] = req.dllps_pkt.DataFC;
        rx_fc_hdr_rcvd[c]   = 0;
        rx_fc_data_rcvd[c]  = 0;
        rx_fc_scaled[c]     = (req.dllps_pkt.rsvd1 > 1 || req.dllps_pkt.rsvd2 > 1);
      end
    end
    else if (!cfg.rx_fc_auto_update) begin
      // UpdateFC from the DL sequence. With auto update the driver itself
      // owns CREDITS_ALLOCATED and sequence values are not taken over.
      if (!rx_fc_hdr_inf[c])  rx_fc_hdr_alloc[c]  = req.dllps_pkt.HdrFC;
      if (!rx_fc_data_inf[c]) rx_fc_data_alloc[c] = req.dllps_pkt.DataFC;
    end
  endfunction

  // Called for every good TLP accepted (hdr0 = first header DW)
  function void rx_fc_on_tlp_received(bit [31:0] hdr0);
    int c, h, d;
    get_tlp_fc_cost(hdr0, c, h, d);
    if (!rx_fc_init_seen[c]) return;
    rx_fc_hdr_rcvd[c]  = (rx_fc_hdr_rcvd[c]  + h) % 256;
    rx_fc_data_rcvd[c] = (rx_fc_data_rcvd[c] + d) % 4096;
    // Receiver overflow: (CREDITS_ALLOCATED - CREDITS_RECEIVED) mod 2^N >= 2^(N-1)
    if (!rx_fc_scaled[c]) begin
      if (!rx_fc_hdr_inf[c] && (((rx_fc_hdr_alloc[c] - rx_fc_hdr_rcvd[c]) & 8'hFF) >= 128))
        `uvm_error("FC_OVERFLOW", $sformatf("Device %0d: Receiver overflow - %s header credits: allocated %0d, received %0d",
                                            cfg.device_id, fc_type_name(c), rx_fc_hdr_alloc[c], rx_fc_hdr_rcvd[c]))
      if (!rx_fc_data_inf[c] && (((rx_fc_data_alloc[c] - rx_fc_data_rcvd[c]) & 12'hFFF) >= 2048))
        `uvm_error("FC_OVERFLOW", $sformatf("Device %0d: Receiver overflow - %s data credits: allocated %0d, received %0d",
                                            cfg.device_id, fc_type_name(c), rx_fc_data_alloc[c], rx_fc_data_rcvd[c]))
    end
    if (cfg.rx_fc_auto_update) begin
      if (!rx_fc_hdr_inf[c])  rx_fc_hdr_alloc[c]  = (rx_fc_hdr_alloc[c]  + h) % 256;
      if (!rx_fc_data_inf[c]) rx_fc_data_alloc[c] = (rx_fc_data_alloc[c] + d) % 4096;
      if (!(rx_fc_hdr_inf[c] && rx_fc_data_inf[c])) rx_fc_dirty[c] = 1;
    end
  endfunction

  // Sends an UpdateFC for every credit type whose credits were freed, and
  // repeats the UpdateFC of every type periodically (spec: UpdateFC is also
  // sent at regular intervals; this also restores a limit that a DL
  // sequence's UpdateFC may have lowered).
  task rx_fc_updater();
    int cnt, idle;
    cnt  = 0;
    idle = 0;
    forever begin
      @(posedge vif.clk);
      if (!cfg.rx_fc_auto_update || fsm.curr_state != DL_ACTIVE) begin
        cnt  = 0;
        idle = 0;
        continue;
      end
      idle++;
      if (rx_fc_dirty[0] || rx_fc_dirty[1] || rx_fc_dirty[2]) cnt++;
      if (cnt >= cfg.rx_fc_update_cycles) begin
        cnt  = 0;
        idle = 0;
        for (int c = 0; c < 3; c++) begin
          if (rx_fc_dirty[c]) begin
            rx_fc_dirty[c] = 0;
            send_updatefc(c);
          end
        end
      end
      else if (idle >= cfg.rx_fc_refresh_cycles) begin
        idle = 0;
        for (int c = 0; c < 3; c++)
          if (rx_fc_init_seen[c] && !(rx_fc_hdr_inf[c] && rx_fc_data_inf[c])) send_updatefc(c);
      end
    end
  endtask

  task send_updatefc(int c);
    pcie_dl_seq_item req;
    req = pcie_dl_seq_item::type_id::create("updatefc");
    req.device_id = cfg.device_id;
    req.is_tlp = 0;
    req.is_nop = 0;
    req.is_pm  = 0;
    req.acknak_pkt.dllp_type = ACK_DLLP_TYPE;   // 0: not an Ack/Nak
    case (c)
      0:       req.dllps_pkt.dllp_type = UPDATEFC_P_VC0;
      1:       req.dllps_pkt.dllp_type = UPDATEFC_NP_VC0;
      default: req.dllps_pkt.dllp_type = UPDATEFC_CPL_VC0;
    endcase
    req.dllps_pkt.rsvd1  = 0;
    req.dllps_pkt.rsvd2  = 0;
    req.dllps_pkt.HdrFC  = rx_fc_hdr_inf[c]  ? 0 : rx_fc_hdr_alloc[c];
    req.dllps_pkt.DataFC = rx_fc_data_inf[c] ? 0 : rx_fc_data_alloc[c];
    `uvm_info(get_type_name(), $sformatf("Device %0d: returning %s credits - UpdateFC HdrFC=%0d DataFC=%0d",
                                         cfg.device_id, fc_type_name(c), req.dllps_pkt.HdrFC, req.dllps_pkt.DataFC), UVM_LOW)
    send_dllp(req);
  endtask


  //==========================================================================
  // DL_Down
  //   LinkUp = 0 (LTSSM in Detect/Polling/Disabled/Hot Reset), reset, or the
  //   dl_force_down test hook: the DLCMSM goes to DL_INACTIVE, the replay
  //   buffer, pending TLPs and all sequence-number / Ack-Nak / flow-control
  //   state are discarded. When LinkUp returns, the DLCMSM initialises again
  //   (DL_INACTIVE -> DL_FEATURE -> DL_INIT -> FC_INIT1 -> FC_INIT2 -> DL_ACTIVE).
  //   InitFC/UpdateFC for the new initialisation come from a DL sequence
  //   started by the test/env.
  //==========================================================================
  function bit dl_link_is_up();
    ltssm_state_e s;
    if (dl_force_down || vif.rst === 1'b1) return 0;
    s = (cfg.device_id == 0) ? ltssm_rc_state : ltssm_ep_state;
    return !(s inside {DETECT_QUIET, DETECT_ACTIVE, POLLING_ACTIVE, POLLING_CONFIG,
                       DISABLED, DISABLE, HOTRESET});
  endfunction

  task dlcmsm_rx_restartable();
    forever begin
      fork
        begin
          rx_proc = process::self();
          dlcmsm_rx();
        end
      join
      // dlcmsm_rx was killed by a DL_Down: start it again for the next
      // flow-control initialisation
      wait (fsm.curr_state == FC_INIT1);
    end
  endtask

  task dl_link_monitor();
    forever begin
      @(posedge vif.clk);
      if (dl_down_done || dl_link_is_up()) continue;
      dl_down();
      // wait for LinkUp, then the DLCMSM starts again from DL_INACTIVE
      do @(posedge vif.clk); while (!dl_link_is_up());
      `uvm_info("DL_DOWN", $sformatf("Device %0d: LinkUp again - DLCMSM initialises again", cfg.device_id), UVM_NONE)
      dl_down_done = 0;
      fsm.link_up  = 1;
      if (cfg.dl_feature_exchange_enable) begin
        wait (fsm.curr_state == DL_FEATURE);
        fork
          begin pr[0] = process::self(); dlcmsm_tx_dlf(); end
          begin pr[1] = process::self(); dlcmsm_rx_dlf(); end
        join_none
      end
    end
  endtask

  task dl_down();
    int n_tlps;
    dl_down_count++;
    dl_down_done = 1;
    `uvm_info("DL_DOWN", $sformatf("Device %0d: DL_Down (LinkUp = 0) in %s - discarding Data Link Layer state",
                                   cfg.device_id, fsm.curr_state.name()), UVM_NONE)
    // stop the receive path and a feature exchange still in progress
    if (rx_proc != null && rx_proc.status() != process::FINISHED && rx_proc.status() != process::KILLED) rx_proc.kill();
    for (int i = 0; i < 2; i++)
      if (pr[i] != null && pr[i].status() != process::FINISHED && pr[i].status() != process::KILLED) pr[i].kill();

    // DLCMSM -> DL_INACTIVE; it waits there for LinkUp
    fsm.link_up = 0;
    fsm.dl_down();
    cfg.curr_state = fsm.curr_state;
    cfg.last_state = fsm.last_state;

    // transmit side: replay buffer, TLPs not yet sent, sequence numbers
    n_tlps = dl_tlp_queue.size();
    dl_tlp_queue.delete();
    pcie_dl_seq_item::clear_replay_buffer_static(cfg.device_id);
    replay_queue.delete();
    replay_mode       = 0;
    NEXT_TRANSMIT_SEQ = 12'h000;
    ACKD_SEQ          = 12'hFFF;
    last_ackd_seq     = 12'hFFF;
    REPLAY_NUM        = 2'b00;
    stop_replay_timer();

    // receive side: sequence numbers, Ack/Nak
    acknak_latency_timer.stop_timer();
    ack_timer_running        = 0;
    nak_scheduled            = 0;
    acknak_req_fifo.flush();
    next_rcv_seq             = 12'h000;
    last_good_seq_num_to_ack = 12'h000;
    tl_queue.delete();

    // flow control, both directions
    tx_ph_limit  = 0; tx_pd_limit  = 0; tx_ph_consumed  = 0; tx_pd_consumed  = 0;
    tx_nph_limit = 0; tx_npd_limit = 0; tx_nph_consumed = 0; tx_npd_consumed = 0;
    tx_cplh_limit = 0; tx_cpld_limit = 0; tx_cplh_consumed = 0; tx_cpld_consumed = 0;
    for (int c = 0; c < 3; c++) begin
      rx_fc_init_seen[c] = 0;
      rx_fc_dirty[c]     = 0;
      rx_fc_hdr_rcvd[c]  = 0;
      rx_fc_data_rcvd[c] = 0;
    end

    // Data Link Feature exchange is done again
    f_rcd = 0;
    cfg.dl_feature_sprt_valid  = 0;
    cfg.remote_feature_support = 0;

    `uvm_info("DL_DOWN", $sformatf("Device %0d: %0d TLP(s) not yet sent were discarded", cfg.device_id, n_tlps), UVM_LOW)
  endtask

endclass