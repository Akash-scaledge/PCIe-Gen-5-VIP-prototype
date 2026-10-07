
class siv_ltssm_driver extends uvm_driver #(siv_ltssm_seq_item);
  `uvm_component_utils(siv_ltssm_driver)
  `uvm_register_cb(siv_ltssm_driver,siv_ltssm_ts_pkt_modify_callback)

  // Interface and components
  virtual siv_ltssm_intf    pl_intf;
  siv_ltssm_fsm              state_machine;
  siv_uvm_timer_pl              state_timer;
  siv_ltssm_pl_cfg           pl_cfg=new();
  uvm_blocking_put_port #(global_que_t) pl_sending_dl_port;
  uvm_blocking_get_port #(global_que_t) pl_rcv_dl_port;

  global_que_t  pkt_from_dl;
  global_que_t  pkt_from_dl_stored[$];
  global_que_t pkt_2_dl;

  // Temporary variables
  bit [7:0]                  current_link_num;
  bit [7:0]                  current_lane_num;
  string                     temp_ts;

  //   byte max_data_rate;
  //   bit  speed_change;
  //   byte adv_data_rate;

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction


  function bit coeff_invalid(siv_ltssm_seq_item tx);
    if (tx.c0 <= C0_MIN || tx.c0 >= C0_MAX) return 1;
    //   if (tx.c_minus1 < c_minus1_min || tx.c_minus1 > c_minus1_max) return 1;
    //   if (tx.c_plus1 < c_plus1_min || tx.c_plus1 > c_plus1_max) return 1;
    return 0;
  endfunction






  task unpack_add(input byte pkt[$]);
    bit[11:0]len;
    bit [3:0]crc;
    {STP.len1,STP.len} = pkt.size()/4;
    len={STP.len1,STP.len};
    $display("loccaaal packet len = %0d",len);

    STP.FCRC[0] = len[10] ^ len[7] ^ len[6] ^ len[4] ^ len[2] ^ len[1] ^ len[0]; 
    STP.FCRC[1] = len[10] ^ len[9] ^ len[7] ^ len[5] ^ len[4] ^ len[3] ^ len[2]; 
    STP.FCRC[2] = len[9] ^ len[8] ^ len[6] ^ len[4] ^ len[3] ^ len[2] ^ len[1]; 
    STP.FCRC[3] = len[8] ^ len[7] ^ len[5] ^ len[3] ^ len[2] ^ len[1] ^ len[0]; 
    crc=STP.FCRC;
    STP.FP = len[10] ^ len[9] ^ len[8] ^ len[7] ^ len[6] ^ len[5] ^ len[4] ^ len[3] ^ len[2] ^ len[1] ^ len[0] ^ crc[3] ^ crc[2] ^ crc[1] ^ crc[0];
    STP.fixed1 = 4'b1111;
    //EDS
    EDS.fixed = 4'b0001;
    EDS.fixed1=4'b1111;
    EDS.fixed2=1'b1;
    EDS.fixed3= 7'b0000000;
    EDS.fixed4=4'b1001;
    EDS.fixed5=12'b000000000000;
    //EDB
    EDB.fixed = 8'b11000000;
    EDB.fixed1 = 8'b11000000;
    EDB.fixed2= 8'b11000000;
    EDB.fixed3 = 8'b11000000;
    //SDP
    SDP.fixed = 8'b11110000;
    SDP.fixed1 = 8'b10101100;
    //IDL
    IDL.fixed = 8'b00000000;
  endtask


  task automatic push_stp_token(ref byte q[$]);

    bit [31:0] stp_bits;

    stp_bits = STP;  // packed struct → 32-bit vector

    $display("stp_bits %b",stp_bits);

    $display("STP %b",STP);

    // Push MSB first (PCIe is big-endian at symbol level)
    q.push_front(stp_bits[7:0]);
    q.push_front(stp_bits[15:8]);
    q.push_front(stp_bits[23:16]);
    q.push_front(stp_bits[31:24]);
  endtask

  task automatic push_sdp_token(ref byte q[$]);
    bit [15:0] sdp_bits;
    sdp_bits = SDP;  // packed struct → 32-bit vector
    $display("SDP %b",sdp_bits);
    // Push MSB first (PCIe is big-endian at symbol level)
    q.push_front(sdp_bits[7:0]);
    q.push_front(sdp_bits[15:8]);
  endtask

  function string pkt_to_hex_string(input byte pkt[$]);
    string s = "";
    foreach (pkt[i])
      s = {s, $sformatf("%02x ", pkt[i])};
    return s;
  endfunction





  task automatic drive_raw_bytes_with_tokens(input byte pkt[$],input  pkt_layer_e layer);
    int i;
    byte local_pkt[$];
    $display("b loccaaal packet = %p",local_pkt);

    if (layer == PKT_TLP) begin
      $display("dl packet = %p",pkt);

      foreach(pkt[i]) local_pkt.push_back(pkt[i]);
      $display("b loccaaal packet = %p",local_pkt);

      push_stp_token(local_pkt);
    end
    else begin
      $display("dl packet = %p",pkt);

      foreach(pkt[i]) if(!(i inside{4,5})) local_pkt.push_back(pkt[i]);
      $display("b loccaaal packet = %p",local_pkt);

      push_sdp_token(local_pkt);
    end
    $display("loccaaal packet = %p",local_pkt);
    //     `uvm_info("DRV_RAW",
    //               $sformatf("[%s] Driving RAW packet (%0d bytes)",
    //                         pl_cfg.inst_name, pkt.size()),
    //               UVM_LOW)

    // Optional: print packet content
    `uvm_info("DRV_RAW_PKT",
              pkt_to_hex_string(pkt),
              UVM_LOW)
    $display("Local packet = %p",local_pkt);
    // Drive each byte on TX
    foreach (local_pkt[i]) begin
      @(posedge pl_intf.clk);

      // Ensure we are NOT in Electrical Idle
      pl_intf.tx_elec_idle <= 1'b0;

      // Drive raw byte
      pl_intf.tx_data <= local_pkt[i];
    end
  endtask








  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    pl_sending_dl_port=new("pl_sending_dl_port",this);
    pl_rcv_dl_port=new("pl_rcv_dl_port",this);
    if(!uvm_config_db#(siv_ltssm_pl_cfg)::get(this, "", "pl_cfg", pl_cfg))
      `uvm_fatal("CFG_ERR", "Failed to get device configuration")

      if(uvm_config_db#(virtual siv_ltssm_intf)::get(this, "", pl_cfg.inst_name=="RC"? "rc_vif":"ep_vif", pl_intf)) 
        $display("%s - DRIVER.BUILD - interface recieved: %p",pl_cfg.inst_name,pl_intf);
    else 
      `uvm_fatal("VIF_ERR", "Fail_ed to get virtual interface")

      state_timer = siv_uvm_timer_pl::type_id::create("state_timer", this);
    state_timer.set_vif(pl_intf);
    state_machine = new();
  endfunction



  // Run Phase - Main Driver Operation
  task run_phase(uvm_phase phase);
    // Monitor state changes
    fork
      forever begin
        @state_machine.current_state;       
        `uvm_info(get_type_name(), 
                  $sformatf("State change: %s -> %s", 
                            state_machine.previous_state, 
                            state_machine.current_state), 
                  UVM_MEDIUM)
        state_machine.update_state();
      end
    join_none

    if (pl_intf == null)
      `uvm_fatal("VIF_NULL", "Virtual interface not initialized");

    // Initialize state machine
    state_machine.initialize(state_timer, pl_intf, pl_cfg);

    // Start parallel processes
    fork
      state_updates();
      ltssm_tx();
      ltssm_rx();
    join_none
  endtask


  // State Update Task
  task state_updates();
    forever begin
      @(posedge pl_intf.clk);
      pl_intf.current_state <= state_machine.current_state; 
      state_machine.update_state();
    end
  endtask

//--------------------------------------
// Task to collect Packets from DL layer
//--------------------------------------
  task collect_from_dl();
    forever begin
      pl_rcv_dl_port.get(pkt_from_dl);
      pkt_from_dl_stored.push_back(pkt_from_dl);
      `uvm_info("PL_RCV_DL_PKT",$sformatf("RECIEVED SUCCESS PKT:/n %p",pkt_from_dl_stored),UVM_LOW)




      //--------------------------------------
      // L0 DATA TRANSMISSION
      //--------------------------------------
      if ((ltssm_rc_state == L0)&& ((pkt_from_dl_stored.size()) != 0)) begin
        //         logic to convert 32 bit Queue to 8 bit queue
        byte pkt[$];
        pkt_layer_e layer;
        global_que_t temp_q;
        int m;

        temp_q=pkt_from_dl_stored.pop_front();
        if(temp_q[0] == `SDP)begin
          layer =  PKT_DLLP;
//           $display("*********************************PKT_DLLP*******************************************");
        end
        else  begin
          layer = PKT_TLP ;
//           $display("*********************************PKT_TLP******************************************");
        end
        temp_q.pop_front;
        pl_byte_converter(temp_q,pkt);
        unpack_add(pkt);
        drive_raw_bytes_with_tokens(pkt,layer);


        continue;
      end
    end
  endtask


  // Sequence Transmission Task
  task ltssm_tx();

    fork
      collect_from_dl();
    join_none

    forever begin
      wait (state_machine.current_state != DETECT_QUIET && 
            state_machine.current_state != DETECT_ACTIVE && 
            state_machine.current_state != RECOVERY_SPEED);









      case (state_machine.current_state)
        POLLING_ACTIVE,
        POLLING_CONFIG,
        CONFIG_LINKWIDTH_START,
        CONFIG_LINKWIDTH_ACCEPT,
        CONFIG_LANENUM_WAIT,
        CONFIG_LANENUM_ACCEPT,
        CONFIG_COMPLETE,
        CONFIG_IDLE,L0,
        L0S_ENTRY,
        L0S_IDLE,
        L0S_FTS,
        L1_IDLE,
        L1_ENTRY,
        RECOVERY_RCVRLOCK,
        RECOVERY_RCFG,
        RECOVERY_EQUALIZATION_PHASE_0,  // New state
        RECOVERY_EQUALIZATION_PHASE_1,  // New state
        RECOVERY_EQUALIZATION_PHASE_2,  // New state
        RECOVERY_EQUALIZATION_PHASE_3,  // New state
        RECOVERY_IDLE: begin
          seq_item_port.get_next_item(req);
          `uvm_do_callbacks(siv_ltssm_driver,siv_ltssm_ts_pkt_modify_callback,modify_item(req));
          drive_seq(req);
          seq_item_port.item_done();
        end

        default: begin
          @(posedge pl_intf.clk); 
        end
      endcase
    end
  endtask

 // Sequence Reception Task
task ltssm_rx();
  bit [7:0] os_buffer[$];
  typedef  byte queue[$];

  int symbol_count = 0;
  int hr_count = 0;
  int data_count = 0;
  bit is_ts1, is_ts2, is_idle, is_eios, is_fts, is_skp, is_sds, is_eie, seq_flag;
  

  while (seq_flag != 1) begin
    @(posedge pl_intf.clk);

    

    //##################################################################################
    if ((symbol_count == 0) &&
        (pl_intf.rx_data == COM || pl_intf.rx_data inside{ 8'h00, 8'h66, 8'h55, 8'h87,8'hAA})) begin
      os_buffer[symbol_count++] = pl_intf.rx_data;
    end
    else if (symbol_count > 0 && symbol_count < 16) begin
      os_buffer[symbol_count++] = pl_intf.rx_data;

      if (symbol_count == 4) begin
        adv_data_rate = os_buffer[symbol_count][5:1];
        speed_change  = os_buffer[symbol_count][7];
      end

      if (symbol_count == 16) begin
        classify_os(os_buffer,
                    is_eios, is_fts, is_skp, is_sds,
                    is_eie, is_ts1, is_ts2, is_idle);

        if (is_ts1) begin
          state_machine.ts1_rcvd_cnt++;
          if (req.symbols[5][7])
            hr_count++;
          else
            hr_count = 0;

          if (hr_count >= 2)
            state_machine.hotreset_ltssm = req.symbols[5][7];

          if ((state_machine.current_state ==
               RECOVERY_EQUALIZATION_PHASE_2 ||
               state_machine.current_state ==
               RECOVERY_EQUALIZATION_PHASE_3) &&
              (pl_cfg.is_rc || !pl_cfg.is_rc)) begin

            if (coeff_invalid(req)) begin
              `uvm_warning("EQ_REJECT",
                $sformatf("%s Rejecting invalid coefficients: cm1=%0d c0=%0d cp1=%0d in %s",
                          pl_cfg.is_rc ? "RC" : "EP",
                          req.c_minus1,
                          req.c0,
                          req.c_plus1,
                          state_machine.current_state ==
                          RECOVERY_EQUALIZATION_PHASE_2 ? "phase 2" : "phase 3"))
              req.reject_coeff = 1;
            end
            else begin
              $display("NO rejection good coefficients cm1=%0d c0=%0d cp1=%0d",
                       req.c_minus1, req.c0, req.c_plus1);
              req.reject_coeff = 0;
            end
          end

          `uvm_info("RX_TS1",
                    $sformatf("[%s] Received TS1 (Total: %0d) state=%s",
                              pl_cfg.inst_name,
                              state_machine.ts1_rcvd_cnt,
                              state_machine.previous_state),
                    UVM_MEDIUM)
        end
        else if (is_ts2) begin
          state_machine.ts2_rcvd_cnt++;
          `uvm_info("RX_TS2",
                    $sformatf("[%s] Received TS2 (Total: %0d) state=%s",
                              pl_cfg.inst_name,
                              state_machine.ts2_rcvd_cnt,
                              state_machine.previous_state),
                    UVM_MEDIUM)
        end
        else if (is_idle &&
                 (os_buffer[0] == 8'h00 && os_buffer[15] == 8'h00)) begin
          state_machine.idle_rcvd_cnt++;
          `uvm_info("RX_IDLE",
                    $sformatf("[%s] Received IDLE (Total: %0d)",
                              pl_cfg.inst_name,
                              state_machine.idle_rcvd_cnt),
                    UVM_MEDIUM)
          is_idle = 0;
        end
        else if (is_eios &&
                 (os_buffer[0] == 8'h66 && os_buffer[15] == 8'h66)) begin
          state_machine.eios_rcvd_cnt++;
          `uvm_info("RX_EIOS",
                    $sformatf("[%s] Received EIOS (Total: %0d)",
                              pl_cfg.inst_name,
                              state_machine.eios_rcvd_cnt),
                    UVM_MEDIUM)
          is_eios = 0;
        end
        else if (is_fts &&
                 (os_buffer[0] == 8'h55 && os_buffer[15] == 8'h55)) begin
          state_machine.fts_rcvd_cnt++;
          `uvm_info("RX_FTS",
                    $sformatf("[%s] Received FTS (Total: %0d)",
                              pl_cfg.inst_name,
                              state_machine.fts_rcvd_cnt),
                    UVM_MEDIUM)
          is_fts = 0;
        end
        else if (is_skp &&
                 (os_buffer[0] == SKP_ID && os_buffer[15] == SKP_ID)) begin
          state_machine.skp_rcvd_cnt++;
          `uvm_info("RX_FTS",
                    $sformatf("[%s] Received FTS (Total: %0d)",
                              pl_cfg.inst_name,
                              state_machine.skp_rcvd_cnt),
                    UVM_MEDIUM)
          is_skp = 0;
        end
        else if (is_sds &&
                 (os_buffer[0] == 8'h87 && os_buffer[15] == 8'h87)) begin
          state_machine.sds_rcvd_cnt++;
//           `uvm_info("RX_SDS",
//                     $sformatf("[%s] Received SDS (Total: %0d)",
//                               pl_cfg.inst_name,
//                               state_machine.sds_rcvd_cnt),
//                     UVM_MEDIUM)
          is_sds = 0;
        end
        else if (is_eie &&
          (os_buffer[0] == 8'h00 && os_buffer[1] == 8'hFF)) begin
          state_machine.eie_rcvd_cnt++;
          `uvm_info("RX_EIE",
                    $sformatf("[%s] Received EIE (Total: %0d)",
                              pl_cfg.inst_name,
                              state_machine.eie_rcvd_cnt),
                    UVM_MEDIUM)
          is_eie = 0;
        end

         symbol_count = 0;
          if(pl_cfg.l1_entry_enable && pl_cfg.aspm_l1_support)
          os_buffer.delete;
      end
    end

    uvm_config_db#(bit)::get(null, get_type_name(),
                             "PL_SEQ_STATUS", seq_flag);
  end
  fork
  valid_data_rx();
  join_none
endtask





  // OS Classification 
  function void classify_os(
    input  bit [7:0] symbols[16],   // Array of 16 8-bit symbols as input
    output bit is_eios, is_fts, is_skp, is_sds, is_eie, is_ts1, is_ts2 , is_idle
  );
    // Assume all  types are valid initially
    is_eios = 1; is_fts = 1; is_skp = 1; is_sds = 1; is_eie = 1; is_ts1 = 1; is_ts2 = 1;is_idle = 1;

    // Check only the last 10 symbols (from index 6 to 15)
    for (int i = 10; i < 16; i++) begin
      if (symbols[i] != TS1_ID) begin is_ts1 = 0; end   // If any symbol isn't TS1, mark as not TS1
      if (symbols[i] != TS2_ID) is_ts2 = 0;   // If any symbol isn't TS2, mark as not TS2
      if (symbols[i] != 8'h00)  is_idle = 0;  // If any symbol isn't 0x00, mark as not Idle
      if (symbols[i] != EIOS_ID) is_eios = 0;
      if (symbols[i] != FTS_ID) is_fts = 0;
      if (symbols[i] != SKP_ID) is_skp = 0;
      if (symbols[i] != SDS_ID) is_sds = 0;
//       if (symbols[0] == EIE_ID && symbols[1] == EIE_ID2) is_eie = 1; 
//       else if (symbols[0] == EIE_ID && symbols[1] == EIE_ID && symbols[2] == EIE_ID2) is_eie = 1; 
//       else if (symbols[4] == EIE_ID2 && symbols[5] == EIE_ID2) is_eie = 1; 
      if(symbols[0] == EIE_ID && symbols[1]==8'hff)  begin is_eie = 1; end
 
    end
  endfunction

  // Ordered Set Transmission Task
  task tran_os(
    siv_ltssm_seq_item req, 
    string os_type
  );
    string all_ts_symbols = "";

    `uvm_info("TX_OS", 
              $sformatf("Starting %s transmission @ %0tns", os_type, $time), 
              UVM_MEDIUM)

    current_link_num = req.symbols[1];
    current_lane_num = req.symbols[2];
    `uvm_info("TX_OS_META", 
              $sformatf("Link: 0x%0h, Lane: 0x%0h", 
                        current_link_num, current_lane_num), 
              UVM_MEDIUM)

    // Collect all symbols 
    foreach (req.symbols[i]) begin
      @(posedge pl_intf.clk);
      pl_intf.tx_data <= req.symbols[i];

      case (i)
        0: temp_ts = $sformatf("COM: 0x%h", req.symbols[i]);
        1: temp_ts = $sformatf("LINK: 0x%h", current_link_num);
        2: temp_ts = $sformatf("LANE: 0x%h", current_lane_num);
        4: begin
          max_data_rate = req.symbols[i][5:1];
        end
        default: begin
          if (i >= 10 && i <= 15)
            temp_ts = $sformatf("%s_ID", os_type);
          else
            temp_ts = $sformatf("DATA: 0x%h", req.symbols[i]);
        end
      endcase

      all_ts_symbols = {all_ts_symbols, $sformatf("[%0d] %s ", i, temp_ts)};
    end

    // Print all symbols in one line
    `uvm_info($sformatf("TX_%s", os_type), 
              $sformatf("[%s] %s", (pl_cfg.is_rc ? "RC" : "EP"), all_ts_symbols), 
              UVM_MEDIUM)

    `uvm_info("TX_STATUS", 
              $sformatf("Completed %s #%0d @ %0tns", os_type,
                        (os_type == "OS_TS1") ? state_machine.ts1_tran_cnt : 
                        state_machine.ts2_tran_cnt, 
                        $time), 
              UVM_MEDIUM)
  endtask

  // COMMON OS TASK GENERATOR
  task tran_all_os(siv_ltssm_seq_item req, string os_type, bit use_idle_symbols = 0);
    string all_symbols = "";
    int rc_count = 0;
    int ep_count = 0;
    `uvm_info($sformatf("TX_%s", os_type), 
              $sformatf("Starting %s transmission @ %0tns", os_type, $time), 
              UVM_MEDIUM)


    foreach (req.idle_symbols[i]) begin
      if (use_idle_symbols) begin
        @(posedge pl_intf.clk);
        pl_intf.tx_data <= req.idle_symbols[i];
        if (pl_cfg.is_rc) begin
          rc_count++;
          all_symbols = {all_symbols, $sformatf("[%0d] %s : 0x%h ", rc_count, os_type, req.idle_symbols[i])};
        end else begin
          ep_count++;
          all_symbols = {all_symbols, $sformatf("[%0d] %s : 0x%h ", ep_count, os_type, req.idle_symbols[i])};
        end
      end
      else if (!use_idle_symbols) begin
        @(posedge pl_intf.clk);
        pl_intf.tx_data <= req.symbols[i];
        if (pl_cfg.is_rc) begin
          rc_count++;
          all_symbols = {all_symbols, $sformatf("[%0d] %s : 0x%h ", rc_count, os_type, req.symbols[i])};
        end else begin
          ep_count++;
          all_symbols = {all_symbols, $sformatf("[%0d] %s : 0x%h ", ep_count, os_type, req.symbols[i])};
        end
      end
    end


    if (rc_count > 0) begin
      `uvm_info($sformatf("TX_%s", os_type), 
                $sformatf("[RC]\n%s", all_symbols), 
                UVM_MEDIUM)
    end


    if (ep_count > 0) begin
      `uvm_info($sformatf("TX_%s", os_type), 
                $sformatf("[EP]\n%s", all_symbols), 
                UVM_MEDIUM)
    end

    `uvm_info($sformatf("TX_%s", os_type), 
              $sformatf("Completed %s @ %0tns", os_type, $time), 
              UVM_MEDIUM)
  endtask

  // ORDERED SET TASK GENERATOR
  task tran_idle_os(siv_ltssm_seq_item req, string os_type);
    tran_all_os(req, os_type, 1); // Use idle_symbols for IDLE
  endtask

  task tran_eios_os(siv_ltssm_seq_item req, string os_type);
    tran_all_os(req, os_type, 0); // Use symbols for EIOS
  endtask

  task tran_fts_os(siv_ltssm_seq_item req, string os_type);
    tran_all_os(req, os_type, 0); // Use symbols for FTS
  endtask

  task tran_sds_os(siv_ltssm_seq_item req, string os_type);
    tran_all_os(req, os_type, 0); // Use symbols for SDS
  endtask

  task tran_skp_os(siv_ltssm_seq_item req, string os_type);
    tran_all_os(req, os_type, 0); // Use symbols for SKP
  endtask

  task tran_eieos_os(siv_ltssm_seq_item req, string os_type);
    tran_all_os(req, os_type, 0); // Use symbols for EIEOS
  endtask

  // Main Drive Task
  task drive_seq(siv_ltssm_seq_item req); 
    case (state_machine.current_state)
      POLLING_ACTIVE, 
      CONFIG_LINKWIDTH_START, 
      CONFIG_LINKWIDTH_ACCEPT,
      CONFIG_LANENUM_WAIT,
      CONFIG_LANENUM_ACCEPT,
      RECOVERY_RCVRLOCK,
      RECOVERY_EQUALIZATION_PHASE_0,  // New state
      RECOVERY_EQUALIZATION_PHASE_1,  // New state
      RECOVERY_EQUALIZATION_PHASE_2,  // New state
      RECOVERY_EQUALIZATION_PHASE_3,
      POLLING_CONFIG,
      CONFIG_COMPLETE,
      RECOVERY_RCFG:  begin // New state
        if(req.ts_type == OS_TS1)begin
          tran_os(req, "OS_TS1");
          state_machine.ts1_tran_cnt++;    
          `uvm_info("DRV_TS1", 
                    $sformatf("TS1 transmitted (Total: %0d)", 
                              state_machine.ts1_tran_cnt), 
                    UVM_MEDIUM)
        end
        else if(req.ts_type == OS_TS2)begin
          tran_os(req, "OS_TS2");
          state_machine.ts2_tran_cnt++;    
          `uvm_info("DRV_TS2", 
                    $sformatf("TS2 transmitted (Total: %0d)", 
                              state_machine.ts2_tran_cnt), 
                    UVM_MEDIUM)
        end
      end

      //       POLLING_CONFIG,
      //       CONFIG_COMPLETE,
      //       RECOVERY_RCFG: begin
      //         tran_os(req, "TS2");
      //         state_machine.ts2_tran_cnt++;    
      //         `uvm_info("DRV_TS2", 
      //                  $sformatf("TS2 transmitted (Total: %0d)", 
      //                  state_machine.ts2_tran_cnt), 
      //                  UVM_MEDIUM)
      //       end

      CONFIG_IDLE,
      RECOVERY_IDLE: begin
        tran_idle_os(req,"IDLE");
        state_machine.idle_tran_cnt++;
        `uvm_info("DRV_IDLE", 
                  $sformatf("IDLE transmitted (Total: %0d)", 
                            state_machine.idle_tran_cnt), 
                  UVM_MEDIUM)
      end

      L0S_ENTRY,L0,
      L1_ENTRY: begin
        if(req.ts_type==OS_EIOS) begin
          tran_eios_os(req,"EIOS");
          state_machine.eios_tran_cnt++;
          `uvm_info("DRV_EIOS", 
                    $sformatf("EIOS transmitted  in %s (Total: %0d)", state_machine.current_state, 
                              state_machine.eios_tran_cnt), 
                    UVM_MEDIUM)
        end
      end

      L0S_IDLE,
      L1_IDLE: begin
        if(req.ts_type==OS_EIE) begin
          tran_eieos_os(req,"EIEOS");
          state_machine.eie_tran_cnt++;
          `uvm_info("DRV_EIEOS", 
                    $sformatf("EIEOS transmitted (Total: %0d)", 
                              state_machine.eie_tran_cnt), 
                    UVM_MEDIUM)
        end
      end

      L0S_FTS: begin
        if(req.ts_type == OS_FTS) begin
          tran_fts_os(req, "FTS");
          state_machine.fts_tran_cnt++;
          `uvm_info("DRV_FTS", 
                    $sformatf("FTS transmitted (Total: %0d)", 
                              state_machine.fts_tran_cnt), 
                    UVM_MEDIUM)
        end
        if(req.ts_type == OS_SDS) begin
          tran_sds_os(req, "SDS");
          state_machine.sds_tran_cnt++;
          `uvm_info("DRV_SDS", 
                    $sformatf("SDS transmitted (Total: %0d)", 
                              state_machine.sds_tran_cnt), 
                    UVM_MEDIUM)
        end
        if(req.ts_type==OS_EIE) begin
          tran_eieos_os(req,"EIEOS");
          state_machine.eie_tran_cnt++;
          `uvm_info("DRV_EIEOS", 
                    $sformatf("EIEOS transmitted (Total: %0d)", 
                              state_machine.eie_tran_cnt), 
                    UVM_MEDIUM)
        end
      end

      default: begin
        `uvm_info("DRV_ERR", 
                  $sformatf("Unexpected transmission in state %s", 
                            state_machine.current_state.name()),UVM_LOW)
      end
    endcase
  endtask


//Task to perform Byte stripping

  task pl_byte_converter(input global_que_t p_in, output byte p_out[$] );
    begin

      typedef bit[31:0] loc1[$];
      int k;
      byte l;
      loc1 loc;

      loc=loc1'(p_in);
      foreach(p_in[i]) begin
        $display("pkt[%0d]=%h",i,loc[i]);
        for(int j=0;j<=3;j++) begin 
          l=byte'(loc[i][k+:8]);
          p_out[4*i+j]= l;
          k+=8;
        end
        k=0;
      end
    end    
  endtask
  
  
  task valid_data_rx();
    byte temp_que[$],temp_que1[$];
    int len_tlp;
    global_que_t gbl;
    forever begin
      @(posedge pl_intf.clk);
      if (state_machine.current_state == L0) begin

        if (pl_intf.rx_data == 8'b11110000) begin
          temp_que.push_back(pl_intf.rx_data);
//           $display("UUUUUUUUUUUUUUUUUUUU");
          repeat (7) begin
            @(posedge pl_intf.clk);
            temp_que.push_back(pl_intf.rx_data);
          end
        end
        else if ( pl_intf.rx_data[3:0] == 4'b1111) begin
//           $display("YYYYYYYYYYYYYYYYYYYYYY");
          temp_que.push_back(pl_intf.rx_data);
          repeat (3) begin
            @(posedge pl_intf.clk);
            temp_que.push_back(pl_intf.rx_data);
            `uvm_info("Data buffer",$sformatf(" que %p",temp_que),UVM_NONE)
          end
          `uvm_info("Data buffer",
                    $sformatf(" len %0d",{temp_que[1][6:0],temp_que[0][7:4]}),
                    UVM_NONE)
          len_tlp = {temp_que[1][6:0],temp_que[0][7:4]};

          repeat (({temp_que[1][6:0],temp_que[0][7:4]}) * 4) begin
            @(posedge pl_intf.clk);
            temp_que.push_back(pl_intf.rx_data);
//             `uvm_info("Data buffer",$sformatf(" que %p",temp_que),UVM_NONE)
          end
//           `uvm_info("Data buffer",$sformatf(" que %p",temp_que),UVM_NONE)
        end

        if (temp_que[0] == 8'b11110000 && temp_que.size() == 8) begin
          `uvm_info("Data buffer",
                    $sformatf(" que before SDP removal %p",temp_que),
                    UVM_NONE)
          repeat (2)
            temp_que.pop_front();
          repeat (2)
            temp_que.push_back({0});
          
          temp_que[6]=temp_que[4];
          temp_que[7]=temp_que[5];

          temp_que[4]={0};
          temp_que[5]={0};
          
          `uvm_info("Data buffer",
                    $sformatf(" que after SDP removal %p",temp_que),
                    UVM_NONE)
          for(int i=0; i < 2; i++)
            begin
              temp_que1=temp_que[(4*i)+:4];
              gbl[i]={temp_que1[3],temp_que1[2],temp_que1[1],temp_que1[0]};
            end
          gbl.push_front(`SDP);//deadbef
          `uvm_info("Data buffer",
                    $sformatf(" 32 bit dllp que sendig to dl  %p",gbl),
                    UVM_NONE)
          
          pl_sending_dl_port.put(gbl);
          gbl.delete();
          temp_que.delete();
        end
        else if (temp_que.size() ==
                 (({temp_que[1][6:0],temp_que[0][7:4]}) * 4) + 4) begin
          `uvm_info("Data buffer",
                    $sformatf(" que before STP removal %p",temp_que),
                    UVM_NONE)
          repeat (4)
            temp_que.pop_front();
          `uvm_info("Data buffer",
                    $sformatf(" que after STP removal %p",temp_que),
                    UVM_NONE)
          for(int i=0; i < (len_tlp); i++)
            begin
              temp_que1=temp_que[(4*i)+:4];
              gbl[i]={temp_que1[3],temp_que1[2],temp_que1[1],temp_que1[0]};
            end
          gbl.push_front(`STP);//deadbef
          `uvm_info("Data buffer",
                    $sformatf(" 32 bit Tlp que sendig to dl  %p",gbl),
                    UVM_NONE)
          
          pl_sending_dl_port.put(gbl);
          gbl.delete();
          temp_que.delete();
        end

      end
    end
  endtask
endclass

//--------------------------------------------------------------