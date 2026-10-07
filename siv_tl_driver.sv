//--------------------------------------------------------------
// SIV PCIe Driver (siv_pcie_tl_driver)k
//--------------------------------------------------------------
uvm_reg_data_t data_value_reg;
class siv_pcie_tl_driver extends uvm_driver #(siv_pcie_tl_sequence_items);
  // this events is used for the synchronization.
  event pktc_done;
  event completion_done;
  event clps_done;
  event vc_config_updated;
  //This code is added to do the register part here
  RegModel_SFR reg_model;

  int pkt_len; //len pkt added for macro used
  bit[127:0] fetch_data;

  // local varibles
  bit [2:0]  fmt;
  bit [4:0]  typef;
  bit        reserve1;
  bit [2:0]  tc;
  bit        reserve2;
  bit        attr1;
  bit        reserve3;
  bit        th;
  bit [7:0]  tag;                    // Updated width for proper tag size
  bit        td;
  bit        ep;
  bit [1:0]  attr2;
  bit [1:0]  at;
  bit [9:0]  len;
  bit [15:0] requester_id;
  bit [31:0] address;
  bit [63:0] address1;
  bit [31:0] ecrc;

//   bit [31:0] tl_ep_getting_que[$];          // used to store the pkts in receiver side
  bit [31:0] rx_cpl_pkt[$];          // used to store the cpl pkt

  // Memory read specific fields
  bit [3:0]  last_dw_be;             // Last DW Byte Enable
  bit [3:0]  first_dw_be;            // First DW Byte Enable
  bit [31:0] address_upper;          // Upper 32 bits for 64-bit addressing
  bit [31:0] address_lower;          // Lower 32 bits for 64-bit addressing

  // Completion fields
  bit [15:0] completer_id;
  bit [2:0]  completion_status;      // Standardized name (or keep compl_status)

  //message specific fields
  bit [7:0]  message_code;  //Message code added
  bit [31:0] msg_rsvd1;
  bit [31:0] msg_rsvd2;
  bit [31:0] payload_msg[];//message payload if it is a message with data
  //						ENDED MESSAGE FIELD

  bit        bcm;
  bit [11:0] byte_count;
  bit        reserve4;               // Additional reserved field
  bit [6:0]  lower_address;
  bit [31:0] headerQ_comp[$:3];
  bit [31:0] payload_store[];
  bit [31:0] payload[];
  bit [31:0] payload_cpl[];          // Completion payload array

  bit [9:0]  reg_no;
  bit [31:0] payload_c[];
  bit [31:0] payload_m[];
  bit [31:0] payload_i[];          //io_payload
  bit [4:0]  typef_temp;
  bit [2:0]  fmt_temp;
  bit [31:0] TLP_comp_pkt[];
  bit [31:0] TLP_comp_pkt_1[];
  bit [31:0] recived_comp[$];
  bit [7:0]RCB;//if RCB=1 RCB_64=16DW
  //if RCB=2 RCB_128=32DW
  bit [8:0] rcb_size;

  int count;
  int temp;
  int no_tx;
  int rem_data;
  bit [31:0] payload_temp[$];
  virtual mem_intf vif_1;

  //mem space memory
  reg [7:0]mem_space[*];
  //   reg [7:0]mem_space[(2**29-1):0];
  reg [7:0]io_space[(2**16-1):0];
  bit [63:0]start_add;//----------------modified to 64 due to completion issue 
  bit [63:0]start_add1;
  bit [31:0] current_data[];
  bit [63:0] current_data1[];
  bit [31:0] payload_data[];
  bit [63:0] payload_data1[];
  bit [31:0] result_data[];
  bit[63:0] result_4dw;
  logic [7:0] c_byte, p_byte, r_byte;

  bit carry;
  logic [8:0] sum;  // 9-bit to hold carry
  bit [31:0] original_data[];
  bit[63:0] original_data1[];
  int expected_splits;
  int received_splits;

  bit flag;
  bit[9:0] temp_length;

  //Port implementation again
  global_que_t dl_rc_sending_que;
  global_que_t tl_rc_getting_que;
  global_que_t dl_ep_sending_que;
  global_que_t tl_ep_getting_que;
  uvm_blocking_put_port #(global_que_t) tl_driver_dl_put_port;
  uvm_blocking_get_port #(global_que_t) tl_driver_dl_get_port;
  //

  global_que_t dl_rcv_data;

  //semaphore is used for the synchronization if we are transmitting non-posted pkt it should wait for the completion then only we need to transmit the packet 

  //This code to access ral front door for now
  uvm_status_e status_value_reg;

  semaphore cfg_sem; // <<== Add this 

  `uvm_component_utils(siv_pcie_tl_driver)

  // Interface and components
  virtual siv_tl_if        vif;
  timer_uvm_tl              state_timer;
  siv_tl_cfg                 device_cfg;
  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    //creating one key for the semaphore
    cfg_sem = new(1); 
    if (!uvm_config_db#(RegModel_SFR)::get(uvm_root::get(), "", "mreg_model", reg_model))
      `uvm_fatal(get_type_name(), "reg_model is not set at top level");

    if(!uvm_config_db#(siv_tl_cfg)::get(this, "", "device_cfg", device_cfg))// agent ru patha hauchi
      `uvm_fatal("CFG_ERR", "Failed to get device configuration")

      `uvm_info("TL_DRV",$sformatf("Check for device config %0d",device_cfg.is_rc),UVM_NONE)

      if(!uvm_config_db#(virtual siv_tl_if)::get(this, "", "vif", vif))
        `uvm_fatal("VIF_ERR", "Failed to get virtual interface") 
        if(! uvm_config_db#(virtual mem_intf)::get(this,"*","vif",vif_1))    
          `uvm_fatal("No_Vif", {"virtual interface must be set for: ",get_full_name(),".apb_ep_pif"});

    state_timer = timer_uvm_tl::type_id::create("state_timer", this);
    state_timer.set_vif(vif);
    // Initialize TC-VC mapping structures but don't configure yet
    initialize_tc_vc_structures();
    //TL PORTS INIITIALIZED;
    tl_driver_dl_put_port=new("tl_driver_dl_put_port",this);
    tl_driver_dl_get_port=new("tl_driver_dl_get_port",this);
  endfunction

  task run_phase(uvm_phase phase);
    wait(dlcmsm_rc_state==DL_ACTIVE);
    
    `uvm_info(get_type_name(),"################# ENTERED TL DRIVER AFTER DL_ACTIVE ##########################",UVM_NONE);
    if (vif == null) 
      `uvm_fatal(get_type_name(),"Got NULL VIF");
    fork
      tlp_tx();
      tlp_rx();
      vc_config_monitor();
    join    
  endtask

  task vc_config_monitor();
    forever begin
      wait(vc_config_updated.triggered);
      `uvm_info(get_type_name(), "VC configuration change detected, updating TC-VC mapping", UVM_LOW)
      repeat(2) @(posedge vif.clk);
      tc_vc_map();
    end
  endtask

  task validate_tc_vc_before_packet(bit [2:0] packet_tc, string packet_type);
    bit [2:0] assigned_vc;

    // Ensure TC-VC mapping is initialized
    if(!tc_vc_initialized) begin
      `uvm_warning(get_type_name(), "TC-VC mapping not initialized, performing setup")
      tc_vc_map();
      tc_vc_initialized = 1;
    end

    // Get assigned VC for this TC
    assigned_vc = get_vc_for_tc(packet_tc);

    // Validate VC is enabled
    if(active_vcs[assigned_vc] == 1'b0) begin
      `uvm_warning(get_type_name(), $sformatf("%s packet TC%0d assigned to disabled VC%0d, using VC0", 
                                              packet_type, packet_tc, assigned_vc))
      assigned_vc = 3'b000;
    end

    `uvm_info(get_type_name(), $sformatf("Pre-packet validation: %s TC%0d -> VC%0d", 
                                         packet_type, packet_tc, assigned_vc), UVM_DEBUG)
  endtask

  function bit should_update_tc_vc_mapping();
    return (!tc_vc_initialized || 
      (tl_ep_getting_que.size() > 0 && tl_ep_getting_que[0][28:24] == 4)); // Config packet detected
  endfunction

  //tx logic
  task tlp_tx();
    //logic for the confic pkt transmit from rc
    if(device_cfg.is_rc) begin

      forever begin
        siv_pcie_tl_sequence_items req;
        seq_item_port.get_next_item(req);
        `uvm_info("here0","here",UVM_NONE)
        if(req.pkt_type==1) dl_rc_sending_que=req.TLP_c;
        else if(req.pkt_type==2) dl_rc_sending_que=req.TLP_m;
        else if(req.pkt_type==3) dl_rc_sending_que=req.TLP_i;
        else if(req.pkt_type==5) dl_rc_sending_que=req.TLP_msg;
//         if(vif.rst == 0);
        tl_driver_dl_put_port.put(dl_rc_sending_que);
        // Drives actual signals
        //it is blocking to send next pkt
        `uvm_info("here0","here",UVM_NONE)


        if(((req.TLP_m[0][28:24]==5'b0 && req.TLP_m[0][30]== 1'b0)||req.TLP_c[0][28:24]== 4||req.TLP_i[0][28:24]== 2 || req.TLP_m[0][28:24]==12)&& req.pkt_type!=5) begin
          // Compute expected_splits based on req.header_mem.len and RCB

          `uvm_info("here0",$sformatf("%0d",flag),UVM_NONE)
          wait(flag==0);
          `uvm_info("here0","here",UVM_NONE)

          flag=1;
          if(device_cfg.get_rcb()) begin 
            $display("->get_rcb = %0d",device_cfg.get_rcb());
            RCB=128;
            $display("->151 get_rcb = %0d",RCB);
          end
          else begin
            $display("->get_rcb = %0d",device_cfg.get_rcb());
            RCB=64;
            $display("-> get_rcb = %0d",RCB);
          end 

          rcb_size=RCB/4;

          if(req.TLP_c[0][28:24]== 4||req.TLP_i[0][28:24]== 2)
            begin
              expected_splits=1;
              $display("no_of splits = 1");
              cfg_sem.get();
              $display("-----------------211----------->received_splits=%0d,expected_splits=%0d",received_splits,expected_splits);
            end
          else if(req.TLP_m[0][28:24]==5'b0)
            begin
              //  expected_splits = (req.TLP_m[0][9:0] + 16 - 1) / 16;  //expected_splits = (req.header_mem.len + RCB_size - 1) / RCB_size;	            
              expected_splits = (req.TLP_m[0][9:0] + rcb_size - 1) / rcb_size;
              cfg_sem.get();
              $display("-----------------219----------->received_splits=%0d,expected_splits=%0d",received_splits,expected_splits);
            end

        end

        `uvm_info(get_type_name(), $sformatf("RC sent config pkt seq_item:\n%s",     req.sprint()), UVM_LOW)
        //         req.print();
        // **Pre-packet TC-VC setup**
        pre_packet_tc_vc_setup(req);
        `uvm_info("here","here",UVM_NONE)

//         drive_tx(req);
        `uvm_info("here","here",UVM_NONE)

        /*  if(req.TLP_m[0][28:24]==5'b0 && req.TLP_m[0][30]== 1'b1) begin
          cfg_sem.put(); //need to improve that
        end*/
        seq_item_port.item_done();
//         @(posedge vif.clk);
        //config pkt transmission is Done
        //->clps_done; //clps_done trigger after the sending the pkt only
      end
    end
    //logic for the compl pkt from Ep
    else if(!(device_cfg.is_rc))begin 
      forever begin
        //wait untill  non-posted pkt received at ep
        wait(pktc_done.triggered);  
        `uvm_info("max meter","at wait",UVM_NONE)
        TLP_comp_pkt.delete();  // delete the before completion created 

        // **Pre-completion TC-VC setup**
        pre_completion_tc_vc_setup();

        compl_header_formation(); // create the cpl pkt based on the pkt received

        if (typef_temp==4)drive_config_comp(); // if the pkt is cpl the it transmit to rc
        //else if (typef_temp== 0 && fmt_temp==0 )drive_mem_comp();
        else if (typef_temp== 2) drive_io_comp();
        //  else if (typef_temp== 0 || typef==5'b011_00 || typef==5'b011_01 || typef==5'b011_10)drive_mem_comp();

      end
    end
  endtask

  task pre_packet_tc_vc_setup(siv_pcie_tl_sequence_items req);
    bit [2:0] packet_tc;
    string packet_type;

    // Update TC-VC mapping before processing any packet
    tc_vc_map();

    if(req.pkt_type == 1) begin // Config packet
      if(req.TLP_c.size() > 0) begin
        packet_tc = req.TLP_c[0][22:20];
        packet_type = "CONFIG";
      end
    end else if(req.pkt_type == 2) begin // Memory packet
      if(req.TLP_m.size() > 0) begin
        packet_tc = req.TLP_m[0][22:20];
        packet_type = "MEMORY";
      end
    end else if(req.pkt_type == 3) begin // IO packet
      if(req.TLP_i.size() > 0) begin
        packet_tc = req.TLP_i[0][22:20];
        packet_type = "IO";
      end
    end
    else if (req.pkt_type==5) begin //MSG packet
      if(req.TLP_msg.size()>0) begin
        //         packet_tc = 3'b000;
        packet_tc = req.TLP_msg[0][22:20];
        packet_type = "MSG";
        `uvm_info("IN PRE PACKET TC VC SETUP",$sformatf("The forced tc value is =%h and current vc=%h",packet_tc,current_vc),UVM_NONE)
      end
    end

    // Validate TC-VC mapping before packet transmission
    validate_tc_vc_before_packet(packet_tc, packet_type);

    `uvm_info(get_type_name(), $sformatf("Pre-packet TC-VC setup completed for %s packet", packet_type), UVM_DEBUG)//get_type_name return the components class name
  endtask

  task pre_completion_tc_vc_setup();
    bit [2:0] response_tc;

    // Update TC-VC mapping before generating completion
    tc_vc_map();
    `uvm_info("max_meter","1st write",UVM_NONE)
    response_tc = tc; // Use TC from received packet
    validate_tc_vc_before_packet(response_tc, "COMPLETION");

    `uvm_info(get_type_name(), "Pre-completion TC-VC setup completed", UVM_DEBUG)
  endtask
  // rx logic

  task tlp_rx();
    int cpl_temp;
    `uvm_info("TL_DRV",$sformatf("on tlp rx side %0d",device_cfg.is_rc),UVM_NONE)
    // Logic for the receiving of config pkt EP
    if (!(device_cfg.is_rc))
      begin  
        `uvm_info("TL_DRV","on tlp rx side EP",UVM_NONE)

//                 wait(dlcmsm_ep_state==DL_ACTIVE);

        `uvm_info("TL_DRV","on tlp rx side EP",UVM_NONE)

        //         @(posedge vif.clk); // Let TX send the first word
        forever
          begin
            tl_ep_getting_que.delete();
            //             @(posedge vif.clk);
            tl_driver_dl_get_port.get(tl_ep_getting_que);
            `uvm_info("RECIEVED DATA FROM DL",$sformatf("DATA = %p",tl_ep_getting_que),UVM_NONE)

            // **MINIMAL TC-VC ADDITION**: Pre-process TC-VC mapping for received packets
            if (should_update_tc_vc_mapping()) 
              begin
                tc_vc_map();
              end
            `uvm_info("max run line",$sformatf("size %0d  ep_getting=%p",tl_ep_getting_que.size,tl_ep_getting_que),UVM_NONE)
            `uvm_info(get_full_name(),$sformatf("%h",tl_ep_getting_que),UVM_NONE);
            // Logic to receive config packet
            if (tl_ep_getting_que[0][28:24] == 4)
              begin // if the pkt is config then only it need to enter the loop
                `uvm_info("max config",$sformatf("size %0d  tl_ep_getting_que=%p",tl_ep_getting_que.size,tl_ep_getting_que),UVM_NONE)

                if (tl_ep_getting_que[0][31:29] == 2)
                  begin // if it is config write then enter into the loop    

                    // **MINIMAL TC-VC ADDITION**: Extract and validate TC before unpacking
                    validate_tc_vc_before_packet(tl_ep_getting_que[0][22:20], "RX_CONFIG_WRITE");

                    unpack();        // Unpaking the pkt
                    display_pkt();   // Displaying the PKT

                    if (typef == 4 && fmt == 2)
                      begin
                        config_write();
                      end

                    tl_ep_getting_que.delete();       // after unpaking the pkt Deleting that tl_ep_getting_que
                    ->pktc_done;               // receiving of completion pkt is done   
                    `uvm_info("max config write","5000",UVM_NONE)
                  end
                //               end  
                else if (tl_ep_getting_que[0][31:29] == 0)
                  begin // if the received pkt is config read enter the loop

                    // **MINIMAL TC-VC ADDITION**: Extract and validate TC before unpacking
                    validate_tc_vc_before_packet(tl_ep_getting_que[0][22:20], "RX_CONFIG_READ");

                    unpack();        // Unpaking the pkt
                    display_pkt();   // Displaying the PKT
                    tl_ep_getting_que.delete();    // after unpaking the pkt Deleting that tl_ep_getting_que
                    ->pktc_done;            // receiving of completion pkt is done   
                    `uvm_info("max run line 1","5000",UVM_NONE)
                    //                 `uvm_info("shark",$sformatf("unpacking %0d",first_dw_be),UVM_NONE)
                  end
              end
            // Logic to receive message packet
            else if (tl_ep_getting_que[0][28:24] inside {[16:23]})
              begin // if the pkt is msg then only it need to enter the loop
                `uvm_info("max message tlp size",$sformatf("size %0d  rx_tlp=%p",tl_ep_getting_que.size,tl_ep_getting_que),UVM_NONE)

                if (tl_ep_getting_que[0][31:29] inside {1,3})
                  begin // if it is message without data then enter into the loop    

                    // **MINIMAL TC-VC ADDITION**: Extract and validate TC before unpacking
                    validate_tc_vc_before_packet(tl_ep_getting_que[0][22:20], "RX_MSG_W_DATA");

                    //                         `uvm_info("max config write","5000",UVM_NONE)
                    unpack();        // Unpaking the pkt
                    display_pkt();   // Displaying the PKT
                    msg_write();
                  end

                tl_ep_getting_que.delete();       // after unpaking the pkt Deleting that tl_ep_getting_que
                //                         ->pktc_done;               // receiving of completion pkt is done   
              end
            //    
            // Logic to receive memory packet
            else if (tl_ep_getting_que[0][28:24] inside {0,12,13,14})
              begin // if the pkt is memory then only it need to enter the loop
                if (tl_ep_getting_que[0][31:29] == 2 || tl_ep_getting_que[0][31:29] == 3) 
                  begin // if it is mem write then enter into the loop    

                    `uvm_info("max run line 2",$sformatf("size %0d",tl_ep_getting_que.size()),UVM_NONE)
                    `uvm_info("max run line 2",$sformatf("count %0d",count),UVM_NONE)
                    `uvm_info("max run line 2",$sformatf("%p",tl_ep_getting_que),UVM_NONE)

                    // **MINIMAL TC-VC ADDITION**: Extract and validate TC before unpacking
                    validate_tc_vc_before_packet(tl_ep_getting_que[0][22:20], "RX_MEMORY_WRITE");

                    unpack();        // Unpaking the pkt
                    display_pkt();   // Displaying the PKT         

                    //                 `uvm_info("shark",$sformatf("before mem_write f %0d",first_dw_be),UVM_NONE)
                    //                 `uvm_info("shark",$sformatf("before mem_write l %0d",last_dw_be),UVM_NONE)
                    if ((typef == 0 || typef == 5'b011_00 || typef == 5'b011_01 || typef == 5'b011_10) && (fmt == 2 || fmt == 3))
                      begin
                        mem_write();
                        if(typef inside {12,13,14})
                          begin
                            ->pktc_done;
                            `uvm_info("max run line 3","5000",UVM_NONE)
                          end
                      end
                    // need to store the mem pkt in one place 
                    tl_ep_getting_que.delete();    // after unpaking the pkt Deleting that tl_ep_getting_que

                    `uvm_info("max run line 4",$sformatf("%0d",tl_ep_getting_que.size()),UVM_NONE)
                    `uvm_info("max run line 4",$sformatf("%p",tl_ep_getting_que),UVM_NONE)

                  end  
                else if (tl_ep_getting_que[0][31:29] == 0 || tl_ep_getting_que[0][31:29] == 1)
                  begin // if the received pkt is mem read enter the loop

                    // **MINIMAL TC-VC ADDITION**: Extract and validate TC before unpacking
                    validate_tc_vc_before_packet(tl_ep_getting_que[0][22:20], "RX_MEMORY_READ");

                    `uvm_info("pktc_done","hello",UVM_NONE)

                    unpack();        // Unpaking the pkt
                    display_pkt();   // Displaying the PKT
                    tl_ep_getting_que.delete();    // after unpaking the pkt Deleting that tl_ep_getting_que
                    //                       count = 0;
                    ->pktc_done;
                    `uvm_info("max run line 5","5000",UVM_NONE)

                    //                 `uvm_info("shark",$sformatf("unpacking %0d",first_dw_be),UVM_NONE)
                  end
              end

            // Logic to receive IO packet
            else if (tl_ep_getting_que[0][28:24] == 2)
              begin // if the pkt is IO then enter the loop (Type = 2 for IO)
                `uvm_info("here0","here",UVM_NONE)

                if (tl_ep_getting_que[0][31:29] == 2 || 3)
                  begin // if it is IO write then enter into the loop    

                    // **MINIMAL TC-VC ADDITION**: Extract and validate TC before unpacking
                    validate_tc_vc_before_packet(tl_ep_getting_que[0][22:20], "RX_IO_WRITE");


                    unpack();        // Unpaking the pkt
                    display_pkt();   // Displaying the PKT

                    if (typef == 2 && fmt == 2)
                      begin
                        io_write();
                      end

                    count = 0;                  // need to store the IO pkt in one place 
                    tl_ep_getting_que.delete();       // after unpaking the pkt Deleting that tl_ep_getting_que
                    ->pktc_done;               // receiving of completion pkt is done   
                    `uvm_info("max run line 6","5000",UVM_NONE)

                  end
                //           end  
                else if (tl_ep_getting_que[0][31:29] == 0)
                  begin // if the received pkt is IO read enter the loop

                    // **MINIMAL TC-VC ADDITION**: Extract and validate TC before unpacking
                    validate_tc_vc_before_packet(tl_ep_getting_que[0][22:20], "RX_IO_READ");


                    unpack();        // Unpaking the pkt
                    display_pkt();   // Displaying the PKT
                    count = 0;
                    tl_ep_getting_que.delete();    // after unpaking the pkt Deleting that tl_ep_getting_que
                    ->pktc_done;            // receiving of completion pkt is done   
                    `uvm_info("max run line 7","5000",UVM_NONE)

                  end
              end
            else
              begin
                `uvm_info("no one selected","oh no",UVM_NONE)
              end


          end 
      end
    // Logic for the receiving the compl pkt rc
    else if (device_cfg.is_rc) begin
      // wait(clps_done.triggered); // waiting for the config packet needs to complete 
      wait(dlcmsm_rc_state==DL_ACTIVE);

      `uvm_info("rc is here","hello ",UVM_NONE)
      `uvm_info("TL_DRV","on tlp rx side RC",UVM_NONE)

      // rx_cpl_pkt.delete();
      forever
        begin     
          @(posedge vif.clk);

          //           if(vif.rx_data!=0)
            begin
              `uvm_info("flag","pass2",UVM_NONE)
              tl_driver_dl_get_port.get(tl_rc_getting_que);
              `uvm_info("INSIDE TL DRIVER",$sformatf("The RC Got the completion=%p",tl_rc_getting_que),UVM_NONE)

              rx_cpl_pkt.push_back(vif.rx_data); // tl_ep_getting_que in this queue, storing the rx_data

              `uvm_info("pkt info",$sformatf("size %0d  rx_tlp=%p",tl_ep_getting_que.size,tl_ep_getting_que),UVM_NONE)

              //             `define pkt_len(PAYLOAD, HS, LENGTH, TD)  // (30, 29, [9:0], 15)
              `pkt_len(rx_cpl_pkt[0][30], rx_cpl_pkt[0][29], rx_cpl_pkt[0][9:0], rx_cpl_pkt[0][15])

              for(int i=0; i < pkt_len - 1; i++)
                begin
                  @(posedge vif.clk)
                  #0
                  //                   `uvm_info("pkt info",$sformatf("size %0d  rx_tlp=%p",rx_cpl_pkt.size,rx_cpl_pkt),UVM_NONE)
                  rx_cpl_pkt.push_back(vif.rx_data);
                end
              `uvm_info("pkt info",$sformatf("size %0d  rx_tlp=%p",rx_cpl_pkt.size,rx_cpl_pkt),UVM_NONE)

              `uvm_info("pkt info",$sformatf("0th place %0h",rx_cpl_pkt[0][28:24]),UVM_NONE)



              if (rx_cpl_pkt[0][28:24] == 10) begin     // checking for pket is completion
                `uvm_info("flag","pass3",UVM_NONE)
                if (rx_cpl_pkt[0][31:29] == 0) begin   // checking for pkt is cpl

                  // Extract and validate TC from completion
                  validate_tc_vc_before_packet(rx_cpl_pkt[0][22:20], "RX_COMPLETION");

                  `uvm_info("RC RECEIVE CONFIG COMP", $psprintf("rx_cpl_pkt=%p", rx_cpl_pkt), UVM_LOW)
                  rx_cpl_pkt.delete();   
                  received_splits=0;
                  flag=0;
                  cfg_sem.put();  // after receiving the cpl then only put the key
                end          

                if (rx_cpl_pkt[0][31:29] == 2) begin   // checking for pkt is cplD
                  // Extract and validate TC from completion
                  validate_tc_vc_before_packet(rx_cpl_pkt[0][22:20], "RX_COMPLETION_DATA");
                  received_splits++;

                  //                   `uvm_info("flag",$sformatf("recieved_split %0d, expected split %0d", received_splits, expected_splits),UVM_NONE)
                  `uvm_info("RC RECEIVE CONFIG COMP", $psprintf("rx_cpl_pkt=%p", rx_cpl_pkt), UVM_LOW)
                  rx_cpl_pkt.delete();   
                  $display("-----------------491----------->received_splits=%0d,expected_splits=%0d",received_splits,expected_splits);
                  if (received_splits == expected_splits) begin
                    received_splits=0;
                    `uvm_info(get_full_name(),"insid rc cpl",UVM_NONE);
                    flag=0;
                    cfg_sem.put(); // Only release when all expected splits received
                  end
                end
              end
            end
        end
    end
  endtask


  //unpacking the tlp pkat
  task unpack();
    fmt = tl_ep_getting_que[0][31:29];
    typef = tl_ep_getting_que[0][28:24];
    reserve1 = tl_ep_getting_que[0][23];
    tc = tl_ep_getting_que[0][22:20];
    reserve2 = tl_ep_getting_que[0][19];
    attr1 = tl_ep_getting_que[0][18];
    reserve3 = tl_ep_getting_que[0][17];
    th = tl_ep_getting_que[0][16];
    td = tl_ep_getting_que[0][15];
    ep = tl_ep_getting_que[0][14];
    attr2 = tl_ep_getting_que[0][13:12];
    at = tl_ep_getting_que[0][11:10];
    len = tl_ep_getting_que[0][9:0];
    temp_length = len;


    if (typef == 4 && fmt == 2) begin
      // Configuration Write Request
      tag = tl_ep_getting_que[1][15:8];
      reg_no = tl_ep_getting_que[2][11:2];

      payload_c = new[len];
      foreach (payload_c[i])
        payload_c[i] = tl_ep_getting_que[3+i][31:0];
    end
    else if (typef == 4 && fmt == 0) begin
      // Configuration Read Request
      requester_id = tl_ep_getting_que[1][31:16];
      tag = tl_ep_getting_que[1][15:8];			
      last_dw_be = tl_ep_getting_que[1][7:4];			
      first_dw_be = tl_ep_getting_que[1][3:0];			
      reg_no = tl_ep_getting_que[2][11:2];
    end
    else if((typef inside{0,12,13,14}) && (fmt == 2 || fmt == 3)) begin
      // Memory Write Request
      tag = tl_ep_getting_que[1][15:8];

      address_upper = tl_ep_getting_que[2][31:0];
      address_lower = tl_ep_getting_que[3][31:0];

      address = tl_ep_getting_que[2][31:0];

      if(tl_ep_getting_que[0][29]==0)
        address1 = {tl_ep_getting_que[2][31:0]};
      else
        address1 = {{tl_ep_getting_que[2][31:0]},{tl_ep_getting_que[3][31:0]}};

      `uvm_info("unpack dis",$sformatf("%0h,	%0h",address1,tl_ep_getting_que[2][31:0]),UVM_NONE)
      first_dw_be = tl_ep_getting_que[1][3:0];		//ADDED 
      last_dw_be = tl_ep_getting_que[1][7:4];		//ADDED 

      payload = new[len];
      foreach (payload[i])
        begin
          if(fmt==2)
            payload[i] = tl_ep_getting_que[3+i][31:0];
          else
            payload[i] = tl_ep_getting_que[4+i][31:0];

        end
    end
    else if(typef == 0 && fmt == 0) begin
      // Memory Read Request (3DW 4DW header, no data)
      requester_id = tl_ep_getting_que[1][31:16];
      tag = tl_ep_getting_que[1][15:8];
      last_dw_be = tl_ep_getting_que[1][7:4];
      first_dw_be = tl_ep_getting_que[1][3:0];
      address = tl_ep_getting_que[2][31:0];
      payload = new[0];
    end
    else if (typef == 0 && fmt == 1) begin
      // Memory Read Request (4DW header, no data)
      requester_id = tl_ep_getting_que[1][31:16];
      tag = tl_ep_getting_que[1][15:8];
      last_dw_be = tl_ep_getting_que[1][7:4];
      first_dw_be = tl_ep_getting_que[1][3:0];
      address_upper = tl_ep_getting_que[2][31:0];
      address_lower = tl_ep_getting_que[3][31:0];
    end
    else if (typef == 2 && fmt == 2) begin
      // IO Write Request (only 32-bit address support)
      requester_id = tl_ep_getting_que[1][31:16];
      tag = tl_ep_getting_que[1][15:8];
      last_dw_be = tl_ep_getting_que[1][7:4];  // Must be 0000b for 1DW payload
      first_dw_be = tl_ep_getting_que[1][3:0];
      address = tl_ep_getting_que[2][31:2];
      payload_i = new[len];  // len is always 1 for IO transactions
      foreach (payload_i[i])
        payload_i[i] = tl_ep_getting_que[3+i][31:0];
      //       `uvm_info("check on io",$sformatf("first dw %p",payload_i),UVM_NONE)
      //       `uvm_info("check on io",$sformatf("first dw %p",tl_ep_getting_que),UVM_NONE)

    end
    else if (typef == 2 && fmt == 0) begin
      // IO Read Request (only 32-bit address support)
      requester_id = tl_ep_getting_que[1][31:16];
      tag = tl_ep_getting_que[1][15:8];
      last_dw_be = tl_ep_getting_que[1][7:4];  // Must be 0000b for 1DW payload
      first_dw_be = tl_ep_getting_que[1][3:0];
      address = tl_ep_getting_que[2][31:2];
      payload_i = new[0];  // No payload for read request
      //       `uvm_info("check on io read",$sformatf("first dw %p",payload_i),UVM_NONE)
      //       `uvm_info("check on io read",$sformatf("first dw %p",tl_ep_getting_que),UVM_NONE)
    end
    else if (typef == 10 && fmt == 2) begin
      // Completion with Data (CplD)
      completer_id = tl_ep_getting_que[1][31:16];
      completion_status = tl_ep_getting_que[1][15:13];
      bcm = tl_ep_getting_que[1][12];
      byte_count = tl_ep_getting_que[1][11:0];

      requester_id = tl_ep_getting_que[2][31:16];
      tag = tl_ep_getting_que[2][15:8];
      reserve4 = tl_ep_getting_que[2][7];
      lower_address = tl_ep_getting_que[2][6:0];

      payload_cpl = new[len];
      foreach (payload_cpl[i])
        payload_cpl[i] = tl_ep_getting_que[3+i][31:0];
    end
    else if (typef == 10 && fmt == 0) begin
      // Completion without Data (Cpl)
      completer_id = tl_ep_getting_que[1][31:16];
      completion_status = tl_ep_getting_que[1][15:13];
      bcm = tl_ep_getting_que[1][12];
      byte_count = tl_ep_getting_que[1][11:0];

      requester_id = tl_ep_getting_que[2][31:16];
      tag = tl_ep_getting_que[2][15:8];
      reserve4 = tl_ep_getting_que[2][7];
      lower_address = tl_ep_getting_que[2][6:0];
    end

    //	____________		MESSAGE UNPACKING CODE 
    //Message with Data 
    else if ((typef inside {[16:23]}) && fmt==3) begin
      message_code = tl_ep_getting_que[1][7:0];
      requester_id = tl_ep_getting_que[1][31:16];
      tag = tl_ep_getting_que[1][15:8];
      msg_rsvd1 = tl_ep_getting_que[2][31:0];
      msg_rsvd2 = tl_ep_getting_que[3][31:0];
      payload_msg=new[len];
      foreach(payload_msg[i]) begin
        payload_msg[i]=tl_ep_getting_que[3+i];
      end
    end
    //Message without Data 
    else if ((typef inside {[16:23]}) && fmt==1) begin
      message_code = tl_ep_getting_que[1][7:0];
      requester_id = tl_ep_getting_que[1][31:16];
      tag = tl_ep_getting_que[1][15:8];
      msg_rsvd1 = tl_ep_getting_que[2][31:0];
      msg_rsvd2 = tl_ep_getting_que[3][31:0];
      payload_msg= new[0];
    end
    //			MESSAGE UNPACKING CODE DONE ____________

    else begin
      // Unsupported or invalid TLP type
      $display("Warning: Unsupported TLP type - fmt=%0d, typef=%0d", fmt, typef);
    end
  endtask

  task display_pkt();  // This task is used for displaying purpose
    bit [2:0] packet_tc;
    bit [2:0] assigned_vc;

    fmt = tl_ep_getting_que[0][31:29];
    typef = tl_ep_getting_que[0][28:24];
    packet_tc = tl_ep_getting_que[0][22:20];
    assigned_vc = get_vc_for_tc(packet_tc);

    //this is the code i have added to show this...
    first_dw_be = tl_ep_getting_que[1][3:0];
    //this is the code i have added to show the last_dw_be...
    last_dw_be =  tl_ep_getting_que[1][7:4];

    //   case (at)
    //     2'b00: begin
    //       // Default addressing (no translation)
    //       `uvm_info(get_type_name(), "AT = 00 : Default addressing mode",UVM_LOW)
    //     end
    //     2'b01: begin
    //       // Request is translated
    //       `uvm_info(get_type_name(),"AT = 01 :Address Translated request",UVM_LOW)
    //     end
    //     2'b10: begin
    //       // Also considered translated
    //       `uvm_info(get_type_name(),"AT = 10 :Address is Translated",UVM_LOW)
    //     end
    //     2'b11: begin
    //       // UNSUPPORTED REQUEST
    //       `uvm_error(get_type_name(),"AT = 11 : Unsupported Request detected")
    //     end
    //   endcase

    //							MESSAGE PRINT IS HERE
    if((typef inside {[16:23]})) begin
      // Messaged
      `uvm_info((fmt==3)?"EP receive TLP message pkt with data":(fmt==1)? "EP receive TLP message pkt without data":"Wrong TLP Packet", $psprintf("tl_ep_getting_que=%p", tl_ep_getting_que), UVM_LOW)
      `uvm_info((fmt==3)?"EP receive TLP message pkt with data":(fmt==1)? "EP receive TLP message pkt without data":"Wrong TLP Packet", $psprintf("Header field={fmt=%0h,typef=%0h,reserve1=%0h,tc=%0h,vc=%0h,reserve2=%0h,attr1=%0h,reserve3=%0h,th=%0h,td=%0h,ep=%0h,attr2=%0h,at=%0h,len=%0h,tag=%0h,message code= %s,msg_rsvd1=%0h, msg_rsvd2=%0h,payload=%p}", 
                                                                                                                                                  fmt, typef, reserve1, tc, assigned_vc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len, tag,message_code,msg_rsvd1,msg_rsvd2, payload_msg), UVM_LOW)
    end
    // 							MESSAGE PRINT ENDS

    else if (typef == 0 && fmt == 2) begin
      // Memory Write Request
      `uvm_info("EP receive TLP mem write pkt", $psprintf("tl_ep_getting_que=%p", tl_ep_getting_que), UVM_LOW)
      `uvm_info("Memory Write packet at receiver", $psprintf("Header field={fmt=%0h,typef=%0h,reserve1=%0h,tc=%0h,vc=%0h,reserve2=%0h,attr1=%0h,reserve3=%0h,th=%0h,td=%0h,ep=%0h,attr2=%0h,at=%0h,len=%0h,tag=%0h,payload=%p}", 
                                                             fmt, typef, reserve1, tc, assigned_vc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len, tag, payload), UVM_LOW)
    end
    else if (typef == 0 && fmt == 3) begin
      // Memory Write Request (4DW)
      `uvm_info("EP receive TLP mem write pkt (4DW)", $psprintf("tl_ep_getting_que=%p", tl_ep_getting_que), UVM_LOW)
      `uvm_info("Memory Write packet at receiver (4DW)", $psprintf("Header field={fmt=%0h,typef=%0h,reserve1=%0h,tc=%0h,vc=%0h,reserve2=%0h,attr1=%0h,reserve3=%0h,th=%0h,td=%0h,ep=%0h,attr2=%0h,at=%0h,len=%0h,tag=%0h,address1=%0h,payload=%p}", 
                                                                   fmt, typef, reserve1, tc, assigned_vc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len, tag, address1, payload), UVM_LOW)
    end
    else if (typef inside {12,13,14} && fmt inside {2,3}) begin
      // AtomicOp 3DW 4DW
      `uvm_info($sformatf("EP receive TLP Atomic Operation (%s)", fmt==2 ? "3DW":"4DW"), $psprintf("tl_ep_getting_que=%p", tl_ep_getting_que), UVM_LOW)
      `uvm_info($sformatf("Atomic operation %s ( %s )",typef==12 ? "FetchAdd": typef == 13 ? "Swap" : "CAS" ,fmt==2 ? "3DW":"4DW"), $psprintf("Header field={fmt=%0h,typef=%0h,reserve1=%0h,tc=%0h,vc=%0h,reserve2=%0h,attr1=%0h,reserve3=%0h,th=%0h,td=%0h,ep=%0h,attr2=%0h,at=%0h,len=%0h,tag=%0h,address1=%0h,payload=%p}", 
                                                                                                                                              fmt, typef, reserve1, tc, assigned_vc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len, tag, address1, payload), UVM_LOW)
    end
    else if (typef == 0 && fmt == 0) begin
      // Memory Read Request (3DW)
      `uvm_info("EP receive TLP mem read pkt (3DW)", $psprintf("tl_ep_getting_que=%p", tl_ep_getting_que), UVM_LOW)
      `uvm_info("Memory Read packet at receiver", $psprintf("Header field={fmt=%0h,typef=%0h,reserve1=%0h,tc=%0h,vc=%0h,reserve2=%0h,attr1=%0h,reserve3=%0h,th=%0h,td=%0h,ep=%0h,attr2=%0h,at=%0h,len=%0h,req_id=%0h,tag=%0h,last_be=%0h,first_be=%0h,address=%0h,payload=%p}", 
                                                            fmt, typef, reserve1, tc, assigned_vc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len, requester_id, tag, last_dw_be, first_dw_be, address,payload), UVM_LOW)
    end
    else if (typef == 0 && fmt == 1) begin
      // Memory Read Request (4DW)
      `uvm_info("EP receive TLP mem read pkt (4DW)", $psprintf("tl_ep_getting_que=%p", tl_ep_getting_que), UVM_LOW)
      `uvm_info("Memory Read packet at receiver", $psprintf("Header field={fmt=%0h,typef=%0h,reserve1=%0h,tc=%0h,vc=%0h,reserve2=%0h,attr1=%0h,reserve3=%0h,th=%0h,td=%0h,ep=%0h,attr2=%0h,at=%0h,len=%0h,req_id=%0h,tag=%0h,last_be=%0h,first_be=%0h,addr_upper=%0h,addr_lower=%0h,payload=%p}", 
                                                            fmt, typef, reserve1, tc, assigned_vc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len, requester_id, tag, last_dw_be, first_dw_be, address_upper, address_lower,payload), UVM_LOW)
    end
    else if (typef == 4 && fmt == 2) begin
      // Configuration Write Request
      `uvm_info("EP receive TLP config write pkt", $psprintf("tl_ep_getting_que=%p", tl_ep_getting_que), UVM_LOW)
      `uvm_info("Config Write packet at receiver", $psprintf("Header field={fmt=%0h,typef=%0h,reserve1=%0h,tc=%0h,vc=%0h,reserve2=%0h,attr1=%0h,reserve3=%0h,th=%0h,td=%0h,ep=%0h,attr2=%0h,at=%0h,len=%0h,tag=%0h,reg_no=%0h,payload_c=%p}", 
                                                             fmt, typef, reserve1, tc, assigned_vc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len, tag, reg_no, payload_c), UVM_LOW)
    end
    else if (typef == 4 && fmt == 0) begin
      // Configuration Read Request
      `uvm_info("EP receive TLP config read pkt", $psprintf("tl_ep_getting_que=%p", tl_ep_getting_que), UVM_LOW)
      `uvm_info("Config Read packet at receiver", $psprintf("Header field={fmt=%0h,typef=%0h,reserve1=%0h,tc=%0h,vc=%0h,reserve2=%0h,attr1=%0h,reserve3=%0h,th=%0h,td=%0h,ep=%0h,attr2=%0h,at=%0h,len=%0h,req_id=%0h,tag=%0h,last_be=%0h,first_be=%0h,reg_no=%0h}", 
                                                            fmt, typef, reserve1, tc, assigned_vc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len, requester_id, tag, last_dw_be, first_dw_be,reg_no), UVM_LOW)
    end
    else if (typef == 2 && fmt == 2) begin
      // IO Write Request
      `uvm_info("EP receive TLP IO write pkt", $psprintf("tl_ep_getting_que=%p", tl_ep_getting_que), UVM_LOW)
      `uvm_info("IO Write packet at receiver", $psprintf("Header field={fmt=%0h,typef=%0h,reserve1=%0h,tc=%0h,vc=%0h,reserve2=%0h,attr1=%0h,reserve3=%0h,th=%0h,td=%0h,ep=%0h,attr2=%0h,at=%0h,len=%0h,req_id=%0h,tag=%0h,last_be=%0h,first_be=%0h,io_address=%0h,payload_io=%p}", 
                                                         fmt, typef, reserve1, tc, assigned_vc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len, requester_id, tag, last_dw_be, first_dw_be, address, payload_i), UVM_LOW)
    end
    else if (typef == 2 && fmt == 0) begin
      // IO Read Request
      `uvm_info("EP receive TLP IO read pkt", $psprintf("tl_ep_getting_que=%p", tl_ep_getting_que), UVM_LOW)
      `uvm_info("IO Read packet at receiver", $psprintf("Header field={fmt=%0h,typef=%0h,reserve1=%0h,tc=%0h,vc=%0h,reserve2=%0h,attr1=%0h,reserve3=%0h,th=%0h,td=%0h,ep=%0h,attr2=%0h,at=%0h,len=%0h,req_id=%0h,tag=%0h,last_be=%0h,first_be=%0h,io_address=%0h}", 
                                                        fmt, typef, reserve1, tc, assigned_vc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len, requester_id, tag, last_dw_be, first_dw_be, address), UVM_LOW)
    end
    else if (typef == 10 && fmt == 2) begin
      // Completion with Data
      `uvm_info("EP receive TLP completion with data pkt", $psprintf("tl_ep_getting_que=%p", tl_ep_getting_que), UVM_LOW)
      `uvm_info("Completion with Data packet at receiver", $psprintf("Header field={fmt=%0h,typef=%0h,reserve1=%0h,tc=%0h,vc=%0h,reserve2=%0h,attr1=%0h,reserve3=%0h,th=%0h,td=%0h,ep=%0h,attr2=%0h,at=%0h,len=%0h,cpl_id=%0h,cpl_status=%0h,bcm=%0h,byte_count=%0h,req_id=%0h,tag=%0h,lower_addr=%0h,payload_cpl=%p}", 
                                                                     fmt, typef, reserve1, tc, assigned_vc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len, completer_id, completion_status, bcm, byte_count, requester_id, tag, lower_address, payload_cpl), UVM_LOW)
    end
    else if (typef == 10 && fmt == 0) begin
      // Completion without Data
      `uvm_info("EP receive TLP completion without data pkt", $psprintf("tl_ep_getting_que=%p", tl_ep_getting_que), UVM_LOW)
      `uvm_info("Completion without Data packet at receiver", $psprintf("Header field={fmt=%0h,typef=%0h,reserve1=%0h,tc=%0h,vc=%0h,reserve2=%0h,attr1=%0h,reserve3=%0h,th=%0h,td=%0h,ep=%0h,attr2=%0h,at=%0h,len=%0h,cpl_id=%0h,cpl_status=%0h,bcm=%0h,byte_count=%0h,req_id=%0h,tag=%0h,lower_addr=%0h}", 
                                                                        fmt, typef, reserve1, tc, assigned_vc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len, completer_id, completion_status, bcm, byte_count, requester_id, tag, lower_address), UVM_LOW)
    end
    else begin
      // Unsupported TLP type
      `uvm_info("EP receive unsupported TLP pkt", $psprintf("tl_ep_getting_que=%p, fmt=%0h, typef=%0h", tl_ep_getting_que, fmt, typef), UVM_LOW)
      `uvm_warning("UNSUPPORTED_TLP", $psprintf("Received unsupported TLP type: fmt=%0h, typef=%0h", fmt, typef))
    end
  endtask



  task drive_tx(siv_pcie_tl_sequence_items req);
    bit [2:0] packet_tc;
    bit [2:0] assigned_vc;

    // Config packet transmission
    if(req.pkt_type == 1) begin
      if(req.TLP_c.size() > 0) begin // **FIXED**: Check array size first
        packet_tc = req.TLP_c[0][22:20];
        assigned_vc = get_vc_for_tc(packet_tc);

        `uvm_info("RC SEND TLP CONFIG PKT", $sformatf("TLP_c=%p on TC%0d->VC%0d", 
                                                      req.TLP_c, packet_tc, assigned_vc), UVM_LOW)

        foreach(req.TLP_c[i]) begin
          @(posedge vif.clk);
          vif.tx_data <= req.TLP_c[i];       
        end  

        @(posedge vif.clk);
        vif.tx_data <= 0;

        // **Call TC-VC mapping after config transmission**
        tc_vc_map();
      end

    end else if(req.pkt_type == 2) begin // Memory packet
      if(req.TLP_m.size() > 0) begin // **FIXED**: Check array size first
        // Extract TC from memory packet and apply mapping
        packet_tc = req.TLP_m[0][22:20]; // TC field from header
        assigned_vc = get_vc_for_tc(packet_tc);

        `uvm_info("RC SEND TLP MEMORY PKT", $sformatf("TLP_m=%p on TC%0d->VC%0d", 
                                                      req.TLP_m, packet_tc, assigned_vc), UVM_LOW)

        // Check VC availability
        if(active_vcs[assigned_vc] == 1'b0) begin
          `uvm_warning(get_type_name(), $sformatf("VC%0d not enabled, using VC0", assigned_vc))
          assigned_vc = 3'b000;
        end
        //         `uvm_info("drive_tx","hello0",UVM_NONE)
        foreach(req.TLP_m[i]) begin
          @(posedge vif.clk);
          //           `uvm_info("drive_tx","hello0",UVM_NONE)
          vif.tx_data <= req.TLP_m[i];     
        end  

        @(posedge vif.clk);
        vif.tx_data <= 0;
      end
    end else if(req.pkt_type == 3) begin // IO packet
      if(req.TLP_i.size() > 0) begin // **FIXED**: Check array size first
        // Extract TC from io packet and apply mapping
        packet_tc = req.TLP_i[0][22:20]; // TC field from header
        assigned_vc = get_vc_for_tc(packet_tc);

        `uvm_info("RC SEND TLP IO PKT", $sformatf("TLP_i=%p on TC%0d->VC%0d", 
                                                  req.TLP_i, packet_tc, assigned_vc), UVM_LOW)

        // Check VC availability
        if(active_vcs[assigned_vc] == 1'b0) begin
          `uvm_warning(get_type_name(), $sformatf("VC%0d not enabled, using VC0", assigned_vc))
          assigned_vc = 3'b000;
        end

        foreach(req.TLP_i[i]) begin
          @(posedge vif.clk);
          vif.tx_data <= req.TLP_i[i];   
          `uvm_info("Drive io tx","driving",UVM_NONE);
        end  

        @(posedge vif.clk);
        vif.tx_data <= 0;
      end
    end else if(req.pkt_type == 5) begin // Message packet
      `uvm_info("INSIDE MSG DRIVE","MSG PACKET",UVM_NONE)
      if(req.TLP_msg.size() > 0) begin // **FIXED**: Check array size first
        // Extract TC from MSG packet and apply mapping
        `uvm_info("INSIDE MSG DRIVE","MSG PACKET 1",UVM_NONE)
        packet_tc = req.TLP_msg[0][22:20]; // TC field from header
        assigned_vc = get_vc_for_tc(packet_tc);

        `uvm_info("RC SEND TLP MSG PKT", $sformatf("TLP_msg=%p on Packet given TC%0d->VC%0d", 
                                                   req.TLP_msg, packet_tc, assigned_vc), UVM_LOW)

        //         // Check VC availability		// If it is not 
        if(active_vcs[assigned_vc] == 1'b0) begin
          `uvm_warning(get_type_name(), $sformatf("VC%0d not enabled, using VC0", assigned_vc))
          assigned_vc = 3'b000;
        end

        foreach(req.TLP_msg[i]) begin
          @(posedge vif.clk);
          vif.tx_data <= req.TLP_msg[i];     
        end  

        @(posedge vif.clk);
        vif.tx_data <= 0;
      end
    end

  endtask


  //=================================================================
  // ENHANCED CONFIG AND MEMORY OPERATIONS WITH TC-VC
  //=================================================================

  task config_write();
    // Config space write
    if (typef == 'd4 && fmt == 'd2 && len == 'd1) begin
      payload_store = new[1];
      payload_store = payload_c;

      // Wait for interface clocking block
      @(posedge vif_1.clk_i);
      // Drive address and control signals
      vif_1.addr_i <= reg_no;
      vif_1.write_i <= 1;
      vif_1.wdata_i <= payload_c[0];
      vif_1.enable_i <= 1;

      // Wait for DUT to be ready
      wait(vif_1.ready_o == 1);

      $display("Writing in DUT for reg_no[%0h]=%0h", reg_no, $root.top.dut.mem[reg_no]);

      // **Check if this is a VC-related register and update TC-VC mapping**
      if (is_vc_register(reg_no)) begin
        `uvm_info(get_type_name(), $sformatf("VC register 0x%0h updated, refreshing TC-VC mapping", reg_no), UVM_LOW)
        // Small delay to ensure register write is complete
        repeat(2) @(posedge vif_1.clk_i);
        -> vc_config_updated;
      end
    end 
  endtask


  task mem_write();
    bit [127:0]comp_data;//add
    bit [127:0]mem_comp_data;//add

    if((typef==0 || typef==5'b011_00 || typef==5'b011_01 || typef==5'b011_10) && (fmt==2 || fmt==3))begin
      current_data=new[len];
      current_data1=new[len];
      payload_data=new[len];
      payload_data1=new[len];
      original_data1=new[len];
      result_data=new[len];


      if(first_dw_be==0)payload[0]=0;
      else if(first_dw_be==8)payload[0][23:0]=0;
      else if(first_dw_be==12)payload[0][15:0]=0;
      else if(first_dw_be==14)payload[0][7:0]=0;

      if(last_dw_be==0)payload[(len-1)]=0;
      else if(last_dw_be==1)payload[(len-1)][31:8]=0;
      else if(last_dw_be==3)payload[(len-1)][31:16]=0;
      else if(last_dw_be==7)payload[(len-1)][31:24]=0;

      //       if(fmt==3)
      start_add=address1;
      //         begin
      //       start_add={address};
      `uvm_info("EP MEMORY SPACE CALCULATION",$psprintf("start_add=%0h,first_dw_be=%0h,address=%0h,len=%0h,address1=%0h",start_add,first_dw_be,address,len,address1),UVM_LOW)
      if(typef==0)
        begin
          for(int i=0;i<len;i++)begin
            for(int j=0;j<4;j++)begin          
              mem_space[(start_add+temp+j)]=payload[i][8*j +:8];

            end
            temp=temp+4;
          end
        end
      else if(typef inside{12,13,14})
        begin
          `uvm_info("mem_write here",$sformatf("len %0d",len),UVM_NONE)
          if(len==1)
            begin
              fetch_data = {96'd0,mem_space[start_add+3],mem_space[start_add+2],mem_space[start_add+1],mem_space[start_add]};
              if(typef==12){mem_space[start_add+3],mem_space[start_add+2],mem_space[start_add+1],mem_space[start_add]} += payload[0];
              if(typef==13){mem_space[start_add+3],mem_space[start_add+2],mem_space[start_add+1],mem_space[start_add]} = payload[0];
            end
          else if(len==2)
            begin

              if(typef inside {12,13})
                begin
                  fetch_data = {64'd0,mem_space[start_add+7],mem_space[start_add+6],mem_space[start_add+5],mem_space[start_add+4],mem_space[start_add+3],mem_space[start_add+2],mem_space[start_add+1],mem_space[start_add]};

                  `uvm_info("mem_write here",$sformatf("fetch data %0d",fetch_data),UVM_NONE)
                  if(typef==12)
                    begin
                      {mem_space[start_add+3],mem_space[start_add+2],mem_space[start_add+1],mem_space[start_add]} += payload[0];
                      {mem_space[start_add+7],mem_space[start_add+6],mem_space[start_add+5],mem_space[start_add+4]} += payload[1];
                    end
                  if(typef==13)
                    begin
                      {mem_space[start_add+3],mem_space[start_add+2],mem_space[start_add+1],mem_space[start_add]} = payload[0];
                      {mem_space[start_add+7],mem_space[start_add+6],mem_space[start_add+5],mem_space[start_add+4]} = payload[1];
                    end
                end
              else if(typef == 14)
                begin
                  comp_data = payload[0];
                  if(comp_data == {mem_space[start_add+3],mem_space[start_add+2],mem_space[start_add+1],mem_space[start_add]})
                    begin
                      fetch_data = {mem_space[start_add+3],mem_space[start_add+2],mem_space[start_add+1],mem_space[start_add]};
                      {mem_space[start_add+3],mem_space[start_add+2],mem_space[start_add+1],mem_space[start_add]}=payload[1];
                    end
                  else
                    fetch_data=comp_data;
                  comp_data=0;
                end
            end
          else if(len inside {4,8} && typef ==14)
            begin
              int temp;

              //                 mem_compa = {mem_space[(start_add+((len*2)-1)):start_add]};
              mem_comp_data=0;
              for(int i=0; i < (len / 2); i++)
                begin
                  mem_comp_data={mem_comp_data,mem_space[start_add+3+(temp*i)],mem_space[start_add+2+(temp*i)],mem_space[start_add+1+(temp*i)],mem_space[start_add+(temp*i)]};
                  `uvm_info("mem_comp_data FOR",$sformatf("mem comp %0h  start add %0h",mem_comp_data,(start_add+(temp*i))),UVM_NONE)
                  temp=temp+4;
                end
              //               `uvm_info("mem_comp_data",$sformatf("%0h",mem_comp_data),UVM_NONE)

              //               mem_comp_data={mem_comp_data[31:0],mem_comp_data[63:32],mem_comp_data[95:64],mem_comp_data[127:96]};

              if(len==8) comp_data = {payload[3],payload[2],payload[1],payload[0]};
              else comp_data = {payload[1],payload[0]};

              if(comp_data == mem_comp_data)
                begin
                  fetch_data = mem_comp_data;

                  for(int i=0; i < ((len/2)-1); i++)
                    begin
                      int temp;
                      {mem_space[start_add+temp+3],mem_space[start_add+temp+2],mem_space[start_add+temp+1],mem_space[start_add+temp]}=payload[i];
                      temp+=4;
                    end



                  //                     {mem_space[(start_add+((len*2)-1)):start_add]} = payload[(len-1):(len/2)];
                end
              else
                fetch_data=mem_comp_data;
              comp_data=0;
            end
        end





      $display("mem_space %p",mem_space);

      $display("*******************************************************mem_space_write******************************************************************");
      for(bit[31:0] i=start_add;i<2**32;i++)begin
        if(mem_space[i]!=0)$write("				mem_space[%0h]=%0h",i,mem_space[i]);
      end
      $display(" ");

      //       end
      //       if(fmt==3)begin
      //         //         start_add1 = address1;
      //         `uvm_info("EP MEMORY SPACE CALCULATION",$psprintf("start_add1=%0h,first_dw_be=%0h,address=%0h,len=%0h",address1,first_dw_be,address,len),UVM_LOW)
      //         if(typef==0)
      //           begin
      //             for(int i=0;i<len;i++)begin
      //               for(int j=0;j<4;j++)begin
      //                 mem_space[(address1 + temp + j)]=payload[i][8*j +:8];
      //                 //             $display("1");
      //               end
      //               temp=temp+4;
      //             end
      //           end
      //         else if(typef==12)
      //           begin
      //             fetch_data = {mem_space[address1+3],mem_space[address1+2],mem_space[address1+1],mem_space[address1]};
      //             {mem_space[address1+3],mem_space[address1+2],mem_space[address1+1],mem_space[address1]} += payload[0];
      //           end

      //         $display("%0p",mem_space);
      //         $display("*******************************************************mem_space_write******************************************************************");
      //         for(int i=address1;i<2**64;i++)begin
      //           if(mem_space[i]!=0)$write("				mem_space[%0h]=%0h",i,mem_space[i]);
      //         end
      //         $display(" ");

      //       end
      temp=0;
    end

  endtask

  task io_write();
    bit [2:0] packet_tc;
    bit [2:0] assigned_vc;
    bit [31:0] io_byte_addr;

    if (typef == 2 && fmt == 2 && len == 1) begin  // IO writes are always 1DW

      // **Extract TC and get assigned VC**
      packet_tc = tc;
      assigned_vc = get_vc_for_tc(packet_tc);

      `uvm_info(get_type_name(), $sformatf("IO write: TC%0d mapped to VC%0d", 
                                           packet_tc, assigned_vc), UVM_LOW)

      // **Validate VC is enabled**
      if (active_vcs[assigned_vc] == 1'b0) begin
        `uvm_warning(get_type_name(), $sformatf("VC%0d not enabled for TC%0d, using VC0", 
                                                assigned_vc, packet_tc))
        assigned_vc = 3'b000;
      end

      // Calculate byte address from IO address (word-aligned)
      io_byte_addr = {address, 2'b00};

      `uvm_info("EP IO SPACE CALCULATION", $psprintf("io_byte_addr=%0h,io_address=%0h,len=%0h,TC=%0d,VC=%0d", 
                                                     io_byte_addr, address, len, packet_tc, assigned_vc), UVM_LOW)

      // **Update VC IO usage tracking**
      update_vc_io_usage(assigned_vc, packet_tc, io_byte_addr, len, "WRITE");

      // Write to IO space (byte-addressable like mem_space)
      if (io_byte_addr <= (2**16 - 4)) begin  // Within 64KB IO space
        for (int j = 0; j < 4; j++) begin
          io_space[io_byte_addr + j] = payload_i[0][8*j +: 8];
        end
      end else begin
        `uvm_warning(get_type_name(), $sformatf("IO write address 0x%0h out of range", io_byte_addr))
      end

      $display("********* io_space_write on VC%0d (TC%0d) *********", assigned_vc, packet_tc);
      for (int i = 0; i < 2**16; i++) begin
        if (io_space[i] != 0) $write("    io_space[%0h]=%0h (VC%0d) ", i, io_space[i], assigned_vc);
      end
      $display(" ");
    end
  endtask

  //=================================================================
  // VC MEMORY USAGE TRACKING
  //=================================================================

  task update_vc_memory_usage(bit [2:0] vc_id, bit [2:0] tc, bit [31:0] addr, bit [9:0] len, string op);
    vc_memory_transaction_t mem_txn;

    mem_txn.vc_id = vc_id;
    mem_txn.tc = tc;
    mem_txn.address = addr;
    mem_txn.length = len;
    mem_txn.operation = op;
    mem_txn.timestamp = $time;

    vc_memory_log.push_back(mem_txn);

    `uvm_info(get_type_name(), $sformatf("VC%0d: %s operation at 0x%0h, len=%0d (TC%0d)", 
                                         vc_id, op, addr, len, tc), UVM_DEBUG)

    if (vc_memory_log.size() > 1000) vc_memory_log.pop_front();
  endtask

  //=================================================================
  // VC IO USAGE TRACKING  
  //=================================================================

  task update_vc_io_usage(bit [2:0] vc_id, bit [2:0] tc, bit [31:0] addr, bit [9:0] len, string op);
    vc_io_transaction_t io_txn;

    io_txn.vc_id = vc_id;
    io_txn.tc = tc;
    io_txn.address = addr;
    io_txn.length = len;
    io_txn.operation = op;
    io_txn.timestamp = $time;

    vc_io_log.push_back(io_txn);

    `uvm_info(get_type_name(), $sformatf("VC%0d: IO %s operation at 0x%0h, len=%0d (TC%0d)", 
                                         vc_id, op, addr, len, tc), UVM_DEBUG)

    if (vc_io_log.size() > 1000) vc_io_log.pop_front();
  endtask

  //ADDING ECRC FOR COMPLETION SIDE SO THAT WE GET PROPER ECRC DURING NON-POSTED
  //generate 32 bit crc logic
  ////////////-------------------------------------------ANANDITA----------------------------------------------------------/////////////
  function automatic bit [31:0] genCRC32(
    input bit [31:0] headerQ_comp [0:2],
    input bit [31:0] payload [$] = '{}   // default empty array
  );
    genCRC32 = 32'h0000_0000;
  endfunction
  ///////////-------------------------------------------ANANDITA----------------------------------------------------------//////////////

  //=================================================================
  // ENHANCED COMPLETION HEADER FORMATION WITH TC-VC
  //=================================================================

  //in this task formation of the completion header
  task compl_header_formation();
    int temp_swap_var; //add
    bit[63:0]address;//---------changed
    bit [2:0] response_vc;
    bit [31:0] empty_payload [$];  // declare once at the top of task
    bit [31:0] payload_c[$]; // queue
    bit [31:0] io_address;
    int split_count = 1;
    if(ep==1 && (typef==0 || typef==2)) completion_status=1;
    else if(typef==1 || typef==3 || typef==5) completion_status=1;
    else if(typef==4 && (len>1 || tc>0)) completion_status=2;
    else if(at>0) completion_status=3;
    else completion_status=0;

    response_vc = get_vc_for_tc(tc);
    //-----changed start
    if(fmt inside {0, 2})
      address=this.address;
    else
      address={address_upper,address_lower}; 
    `uvm_info("address update",$sformatf("%0h fmt %0d",address,fmt),UVM_NONE)
    ////-----changed end    
    if(typef==4) begin
      typef_temp = typef;
      typef = 10;
      completer_id = 0;
      bcm = 0;
      byte_count = 0;
      reserve4 = 0;
      // Use fmt = 2 for Cpl with data
      if(fmt == 0 || fmt == 1) fmt = 2;
      else if(fmt == 2 || fmt == 3) fmt = 0;
      lower_address = 0;
      headerQ_comp[0] = {fmt, typef, reserve1, tc, reserve2, attr1, reserve3, th, td, ep, attr2, at, len};
      headerQ_comp[1] = {completer_id, completion_status, bcm, byte_count};
      headerQ_comp[2] = {requester_id, tag, reserve4, lower_address};
      payload_c[0] = $root.top.dut.mem[reg_no];

      //////////------------------------------------------------------------------------------------------////////////////
      //Driver code change started here for ecrc 
      if(fmt==0) begin 
        if(td==1) begin
          ecrc=genCRC32(headerQ_comp,payload_c);
          TLP_comp_pkt = {>>int{headerQ_comp,ecrc}};
          $display("Hello 2 ecrc hit");
        end
        else begin
          TLP_comp_pkt ={>>int{headerQ_comp}};
        end
      end
      else if(fmt==2) begin
        if(td==1) begin
          ecrc=genCRC32(headerQ_comp,payload_c); TLP_comp_pkt = {>>int{headerQ_comp,payload_c,ecrc}};
        end
        else TLP_comp_pkt = {>>int{headerQ_comp,payload_c}};
      end
      dl_ep_sending_que= TLP_comp_pkt;
      tl_driver_dl_put_port.put(dl_ep_sending_que);

      `uvm_info(get_type_name(), $sformatf("Config completion formed for VC%0d (TC%0d)", response_vc, tc), UVM_LOW)
      //Ends here
      //  TLP_comp_pkt = {>>int{headerQ_comp}};
      //`uvm_info("EP SEND CONFIG COMP", $psprintf("386 EP_TLP_confg_comp=%p", TLP_confg_comp), UVM_LOW)
    end
    //////////-------------------------------------------------------------------------------------------////////////////


    else if((typef==0 && fmt==0 || fmt==1) || typef inside {12,13,14}) begin
      typef_temp = typef;
      fmt_temp = fmt;
      typef = 10;
      completer_id = 0;
      bcm = 0;
      byte_count = 0;
      reserve4 = 0;
      // Use fmt = 2 for Cpl with data
      if(fmt == 0 || fmt == 1 || (fmt inside{2,3} && typef_temp inside{12,13,14})) fmt = 2;
      lower_address = 0;

      //*****************************************************************************************************************   

      /*get_rcd we can get the RCB value from the register if get_rcb = 1 RCB is 128 
                                                             if get_rcb = 0 RCB is 64
                                                              default it is 64 */ 
      if(device_cfg.get_rcb()) begin 
        $display("->get_rcb = %0d",device_cfg.get_rcb());
        RCB=128;
        $display("->get_rcb = %0d",RCB);
      end
      else begin
        $display("->get_rcb = %0d",device_cfg.get_rcb());
        RCB=64;
        $display("->get_rcb = %0d",RCB);
      end 

      if(RCB==64)begin
        if(len%16==0)begin
          no_tx=len/16;
        end
        else begin
          no_tx=(len/16)+1;
          rem_data=len%16;
        end

        `uvm_info("EP_RCB_CHECK",$psprintf("**************************len=%0d,no_tx=%0d,rem_data=%0d**********",len,no_tx,rem_data),UVM_LOW)
        if(no_tx==1)begin     // if length and rcb are equal

          //******************compl header *******************
          headerQ_comp[0]={fmt,typef,reserve1,tc,reserve2,attr1,reserve3,th,td,ep,attr2,at,len};
          headerQ_comp[1]={completer_id,completion_status,bcm,byte_count};
          headerQ_comp[2]={requester_id,tag,reserve4,lower_address};
          //  byte_count=byte_count-(16*4);
          if(typef_temp!=14)
            payload_m = new[len];
          else
            payload_m = new[len/2];

          start_add= address;
          `uvm_info("address_update",$sformatf("%0h",start_add),UVM_NONE)
          `uvm_info("memory space",$sformatf("%p",mem_space),UVM_NONE)

          if(typef_temp inside {12,13,14})
            begin
              `uvm_info("after operation",$sformatf("%0h",fetch_data),UVM_NONE)

              if(typef_temp inside {12,13})
                for(int i=0;i<(len);i++)begin
                  payload_m[i]=fetch_data[(i*32)+:32];
                end
              else
                begin
                  for(int i=0;i<(len/2);i++)begin
                    payload_m[i]=fetch_data[(i*32)+:32];
                  end

                  for(int i=0; i < (payload_m.size()/2); i++)
                    begin
                      `uvm_info("payload here",$sformatf("%p",payload_m),UVM_NONE)
                      temp_swap_var={payload_m[payload_m.size()-1-i]};
                      payload_m[payload_m.size()-1-i]=payload_m[i];
                      payload_m[i]=temp_swap_var;
                    end
                end

            end
          else
            begin
              for(int i=0;i<(len);i++)begin
                payload_m[i]={mem_space[((start_add)+3+(4*i))],mem_space[((start_add)+2+(4*i))],mem_space[((start_add)+1+(4*i))],mem_space[((start_add)+(4*i))]};
              end
            end


          `uvm_info("payload",$psprintf("********payload_m=%p***",payload_m),UVM_LOW)

          `uvm_info("EP_RCB_HEADER",$psprintf("####################EP_headerQ_comp=%p###########################",headerQ_comp),UVM_LOW)

          //  if(td==1)ecrc=genCRC32(headerQ_comp,payload_temp);
          //  else ecrc=0;

          if(td==1 && fmt==2)TLP_comp_pkt={>>int{headerQ_comp,payload_m,ecrc}};
          else if(td==0 && fmt==2) TLP_comp_pkt={>>int{headerQ_comp,payload_m}};
          else if(td==1 && fmt==0)TLP_comp_pkt={>>int{headerQ_comp,ecrc}};//added
          else if(td==0 && fmt==0)TLP_comp_pkt={>>int{headerQ_comp}};//added
          dl_ep_sending_que= TLP_comp_pkt;
          tl_driver_dl_put_port.put(dl_ep_sending_que);
          `uvm_info("completion pkt",$psprintf("####################TLP_comp_pkt=%p###########################",TLP_comp_pkt),UVM_LOW)
          drive_mem_comp();          
        end

        else begin     //if length and rcb are not equal
          for(int j=0;j<no_tx-1;j++)begin
            for(int i=0;i<16;i++)begin
              payload_temp.push_back(payload_m[i+(16*j)]);
            end
            len=16;
            //`uvm_info("EP SIDE HEADERQ_COMP", $psprintf("###############payload_temp=%p########################",payload_temp),UVM_LOW)

            //******************compl header *******************
            headerQ_comp[0]={fmt,typef,reserve1,tc,reserve2,attr1,reserve3,th,td,ep,attr2,at,len};
            headerQ_comp[1]={completer_id,completion_status,bcm,byte_count};
            headerQ_comp[2]={requester_id,tag,reserve4,lower_address};
            byte_count=byte_count-(16*4);
            `uvm_info("EP SIDE HEADERQ_COMP", $psprintf("###############headerQ_comp=%p########################",headerQ_comp),UVM_LOW)
            payload_m = new[len];
            start_add= address+(j * len * 4);
            for(int i=0;i<(len*4);i++)begin
              payload_m[i]={mem_space[((start_add)+3+(4*i))],mem_space[((start_add)+2+(4*i))],mem_space[((start_add)+1+(4*i))],mem_space[((start_add)+(4*i))]};
            end
            `uvm_info("payload",$psprintf("********payload_m=%p***",payload_m),UVM_LOW)
            // if(td==1)ecrc=genCRC32(headerQ_comp,payload_temp);
            // else ecrc=0;

            if(td==1 && fmt==2)TLP_comp_pkt={>>int{headerQ_comp,payload_m,ecrc}};
            else if(td==0 && fmt==2) TLP_comp_pkt={>>int{headerQ_comp,payload_m}};
            else if(td==1 && fmt==0)TLP_comp_pkt={>>int{headerQ_comp,ecrc}};//added
            else if(td==0 && fmt==0)TLP_comp_pkt={>>int{headerQ_comp}};//added
            dl_ep_sending_que= TLP_comp_pkt;
            tl_driver_dl_put_port.put(dl_ep_sending_que);
            `uvm_info("EP SIDE TLP_comp_pkt", $psprintf("###############TLP_comp_pkt=%p########################",TLP_comp_pkt),UVM_LOW)
            `uvm_info("TLP MEM COMP",$psprintf("  TLP_confg_comp=%p",TLP_comp_pkt),UVM_FULL)
            /*  for (int k=0;k<TLP_comp_pkt.size();k++)begin
               TLP_storage.push_back(TLP_comp_pkt[k]);
              end */
            //`uvm_info("EP SIDE TLP_STORAGE",$psprintf("###############TLP_storage=%p########################",TLP_storage),UVM_FULL) 
            `uvm_info("EP SEND MEMORY COMP ",$psprintf("split_count =%0d",  split_count), UVM_LOW)
            split_count++;
            drive_mem_comp();
          end
          if(rem_data>0)begin
            for(int i=0;i<rem_data;i++)begin
              payload_temp.push_back(payload_m[i+(16*(no_tx-1))]);
            end
            len=rem_data;
            //address=address+16;

            //******************compl header *******************
            headerQ_comp[0]={fmt,typef,reserve1,tc,reserve2,attr1,reserve3,th,td,ep,attr2,at,len};
            headerQ_comp[1]={completer_id,completion_status,bcm,byte_count};
            headerQ_comp[2]={requester_id,tag,reserve4,lower_address};

            `uvm_info("EP SIDE HEADERQ_COMP",$psprintf("####################headerQ_comp=%p###########################",headerQ_comp),UVM_FULL)
            payload_m = new[len];
            start_add= address+(16*4);
            for(int i=0;i<(len*4);i++)begin
              payload_m[i]={mem_space[((start_add)+3+(4*i))],mem_space[((start_add)+2+(4*i))],mem_space[((start_add)+1+(4*i))],mem_space[((start_add)+(4*i))]};
            end
            `uvm_info("payload",$psprintf("********payload_m=%p***",payload_m),UVM_LOW)
            //  if(td==1)ecrc=genCRC32(headerQ_comp,payload_temp);
            //  else ecrc=0;

            if(td==1 && fmt==2)TLP_comp_pkt={>>int{headerQ_comp,payload_m,ecrc}};
            else if(td==0 && fmt==2) TLP_comp_pkt={>>int{headerQ_comp,payload_m}};
            dl_ep_sending_que= TLP_comp_pkt;
            tl_driver_dl_put_port.put(dl_ep_sending_que);
            `uvm_info(get_type_name(), $sformatf("Memory completion formed for VC%0d (TC%0d)", response_vc, tc), UVM_LOW)

            `uvm_info("TLP MEM COMP",$psprintf("  TLP_comp_pkt=%p",TLP_comp_pkt_1),UVM_FULL)
            /*for (int k=0;k<TLP_comp_pkt_1.size();k++)begin
                TLP_storage.push_back(TLP_comp_pkt[k]);
              end */
            //  `uvm_info("EP SIDE TLP_STORAGE",$psprintf("###############TLP_storage=%p########################",TLP_storage),UVM_FULL)
            `uvm_info("EP SEND MEMORY COMP - LAST SPLIT", "", UVM_LOW)
            drive_mem_comp();

          end
        end
      end
      else if(RCB==128) begin 
        if(len%32==0)begin
          no_tx=len/32;
        end
        else begin
          no_tx=(len/32)+1;
          rem_data=len%32;
        end

        `uvm_info("EP_RCB_CHECK",$psprintf("**************************len=%0d,no_tx=%0d,rem_data=%0d**********",len,no_tx,rem_data),UVM_LOW)
        if(no_tx==1)begin     // if length and rcb are equal
          //******************compl header *******************
          headerQ_comp[0]={fmt,typef,reserve1,tc,reserve2,attr1,reserve3,th,td,ep,attr2,at,len};
          headerQ_comp[1]={completer_id,completion_status,bcm,byte_count};
          headerQ_comp[2]={requester_id,tag,reserve4,lower_address};
          //  byte_count=byte_count-(32*4);
          payload_m = new[len];
          start_add= address;
          for(int i=0;i<(len*4);i++)begin
            payload_m[i]={mem_space[((start_add)+3+(4*i))],mem_space[((start_add)+2+(4*i))],mem_space[((start_add)+1+(4*i))],mem_space[((start_add)+(4*i))]};
          end
          `uvm_info("payload",$psprintf("********payload_m=%p***",payload_m),UVM_LOW)
          `uvm_info("EP_RCB_HEADER",$psprintf("####################EP_headerQ_comp=%p###########################",headerQ_comp),UVM_LOW)

          if(td==1 && fmt==2)TLP_comp_pkt={>>int{headerQ_comp,payload_m,ecrc}};
          else if(td==0 && fmt==2) TLP_comp_pkt={>>int{headerQ_comp,payload_m}};
          else if(td==1 && fmt==0)TLP_comp_pkt={>>int{headerQ_comp,ecrc}};//added
          else if(td==0 && fmt==0)TLP_comp_pkt={>>int{headerQ_comp}};//added
          dl_ep_sending_que= TLP_comp_pkt;
          tl_driver_dl_put_port.put(dl_ep_sending_que);

          `uvm_info("completion pkt",$psprintf("####################TLP_comp_pkt=%p###########################",TLP_comp_pkt),UVM_LOW)
          drive_mem_comp();
        end

        else begin     //if length and rcb are not equal
          for(int j=0;j<no_tx-1;j++)begin
            for(int i=0;i<32;i++)begin
              payload_temp.push_back(payload_m[i+(32*j)]);
            end
            len=32;
            //`uvm_info("EP SIDE HEADERQ_COMP", $psprintf("###############payload_temp=%p########################",payload_temp),UVM_LOW)

            //******************compl header *******************
            headerQ_comp[0]={fmt,typef,reserve1,tc,reserve2,attr1,reserve3,th,td,ep,attr2,at,len};
            headerQ_comp[1]={completer_id,completion_status,bcm,byte_count};
            headerQ_comp[2]={requester_id,tag,reserve4,lower_address};
            byte_count=byte_count-(32*4);
            `uvm_info("EP SIDE HEADERQ_COMP", $psprintf("###############headerQ_comp=%p########################",headerQ_comp),UVM_LOW)
            payload_m = new[len];
            start_add= address;
            for(int i=0;i<(len*4);i++)begin
              payload_m[i]={mem_space[((start_add)+3+(4*i))],mem_space[((start_add)+2+(4*i))],mem_space[((start_add)+1+(4*i))],mem_space[((start_add)+(4*i))]};
            end
            `uvm_info("payload",$psprintf("********payload_m=%p***",payload_m),UVM_LOW)
            // if(td==1)ecrc=genCRC32(headerQ_comp,payload_temp);
            // else ecrc=0;

            if(td==1 && fmt==2)TLP_comp_pkt={>>int{headerQ_comp,payload_m,ecrc}};
            else if(td==0 && fmt==2) TLP_comp_pkt={>>int{headerQ_comp,payload_m}};
            else if(td==1 && fmt==0)TLP_comp_pkt={>>int{headerQ_comp,ecrc}};//added
            else if(td==0 && fmt==0)TLP_comp_pkt={>>int{headerQ_comp}};//added
            dl_ep_sending_que= TLP_comp_pkt;
            tl_driver_dl_put_port.put(dl_ep_sending_que);
            `uvm_info("EP SIDE TLP_comp_pkt", $psprintf("###############TLP_comp_pkt=%p########################",TLP_comp_pkt),UVM_LOW)
            `uvm_info("TLP MEM COMP",$psprintf("  TLP_confg_comp=%p",TLP_comp_pkt),UVM_FULL)
            /*  for (int k=0;k<TLP_comp_pkt.size();k++)begin
              TLP_storage.push_back(TLP_comp_pkt[k]);
            end */
            //  `uvm_info("EP SIDE TLP_STORAGE",$psprintf("###############TLP_storage=%p########################",TLP_storage),UVM_FULL) 
            `uvm_info("EP SEND MEMORY COMP ",$psprintf("split_count =%0d",  split_count), UVM_LOW)
            split_count++;
            drive_mem_comp();
          end
          if(rem_data>0)begin
            for(int i=0;i<rem_data;i++)begin
              payload_temp.push_back(payload_m[i+(32*(no_tx-1))]);
            end
            len=rem_data;
            //address=address+32;

            //******************compl header *******************
            headerQ_comp[0]={fmt,typef,reserve1,tc,reserve2,attr1,reserve3,th,td,ep,attr2,at,len};
            headerQ_comp[1]={completer_id,completion_status,bcm,byte_count};
            headerQ_comp[2]={requester_id,tag,reserve4,lower_address};

            `uvm_info("EP SIDE HEADERQ_COMP",$psprintf("####################headerQ_comp=%p###########################",headerQ_comp),UVM_FULL)
            payload_m = new[len];
            start_add= address+(32*4);
            for(int i=0;i<(len*4);i++)begin
              payload_m[i]={mem_space[((start_add)+3+(4*i))],mem_space[((start_add)+2+(4*i))],mem_space[((start_add)+1+(4*i))],mem_space[((start_add)+(4*i))]};
            end
            `uvm_info("payload",$psprintf("********payload_m=%p***",payload_m),UVM_LOW)
            //  if(td==1)ecrc=genCRC32(headerQ_comp,payload_temp);
            //  else ecrc=0;

            if(td==1 && fmt==2)TLP_comp_pkt={>>int{headerQ_comp,payload_m,ecrc}};
            else if(td==0 && fmt==2) TLP_comp_pkt={>>int{headerQ_comp,payload_m}};
            dl_ep_sending_que= TLP_comp_pkt;
            tl_driver_dl_put_port.put(dl_ep_sending_que);
            `uvm_info("TLP MEM COMP",$psprintf("  TLP_comp_pkt=%p",TLP_comp_pkt_1),UVM_FULL)
            /*  for (int k=0;k<TLP_comp_pkt_1.size();k++)begin
              TLP_storage.push_back(TLP_comp_pkt[k]);
            end */
            //  `uvm_info("EP SIDE TLP_STORAGE",$psprintf("###############TLP_storage=%p########################",TLP_storage),UVM_FULL)
            `uvm_info("EP SEND MEMORY COMP - LAST SPLIT", "", UVM_LOW)
            drive_mem_comp();
          end
        end
      end
    end
    else if (typef == 2 && fmt == 2) begin
      // IO Write Completion (no data)
      typef_temp = typef;
      fmt_temp = fmt;
      typef = 10;
      completer_id = 0;
      bcm = 0;
      byte_count = 0;  // IO completions always have byte count = 4
      reserve4 = 0;
      fmt = 0;  // IO write completion has no data (fmt=0)
      lower_address = 0;

      headerQ_comp[0] = {fmt, typef, reserve1, tc, reserve2, attr1, reserve3, th, td, ep, attr2, at, 10'h000};
      headerQ_comp[1] = {completer_id, completion_status, bcm, byte_count};
      headerQ_comp[2] = {requester_id, tag, reserve4, lower_address};

      `uvm_info(get_type_name(), $sformatf("IO COMP BUILD: fmt=%0d typef=%0d td=%0d len=%0d byte_count=%0d tc=%0d VC=%0d tag=%0h requester=%0h completer=%0h",
                                           fmt, typef, td, 10'h001, byte_count, tc, response_vc, tag, requester_id, completer_id), UVM_LOW)

      `uvm_info(get_type_name(), $sformatf("io_address=%0h payload_i[0]=%0h", io_address, payload_i[0]), UVM_LOW)
      `uvm_info(get_type_name(), $sformatf("headerQ_comp[0]=%p headerQ_comp[1]=%p headerQ_comp[2]=%p", headerQ_comp[0], headerQ_comp[1], headerQ_comp[2]), UVM_LOW)


      `uvm_info(get_type_name(), $sformatf("TLP_comp_pkt (packed) = %p", TLP_comp_pkt), UVM_LOW)




      //-------------------------------------------ANANDITA----------------------------------------------------------
      if (td == 1) begin
        ecrc = genCRC32(headerQ_comp, empty_payload);
        TLP_comp_pkt = {>>int{headerQ_comp, ecrc}};
      end else begin
        TLP_comp_pkt = {>>int{headerQ_comp}};
      end
      dl_ep_sending_que= TLP_comp_pkt;
      tl_driver_dl_put_port.put(dl_ep_sending_que);
      //-------------------------------------------ANANDITA----------------------------------------------------------


      // No payload for IO write completion

      `uvm_info(get_type_name(), $sformatf("IO Write completion formed for VC%0d (TC%0d)", response_vc, tc), UVM_LOW)
    end
    else if (typef == 2 && fmt == 0) begin
      // IO Read Completion (with data)
      typef_temp = typef;
      fmt_temp = fmt;
      typef = 10;
      completer_id = 0;
      bcm = 0;
      byte_count = 4;  // IO completions always have byte count = 4
      reserve4 = 0;
      fmt = 2;  // IO read completion has data (fmt=2)
      lower_address = 0;

      headerQ_comp[0] = {fmt, typef, reserve1, tc, reserve2, attr1, reserve3, th, td, ep, attr2, at, 10'h001};  // len=1 for read completion
      headerQ_comp[1] = {completer_id, completion_status, bcm, byte_count};
      headerQ_comp[2] = {requester_id, tag, reserve4, lower_address};

      // Read data from IO space
      payload_i = new[1];
      io_address = address << 2 ;
      payload_i[0] = {io_space[io_address+3],io_space[io_address+2],io_space[io_address+1],io_space[io_address+0]};  // Read from IO space

      //-------------------------------------------ANANDITA----------------------------------------------------------
      if (td == 1) begin
        // cif (td == 1) begin
        ecrc = genCRC32(headerQ_comp, payload_i);
        TLP_comp_pkt = {>>int{headerQ_comp, payload_i, ecrc}};
      end else begin
        TLP_comp_pkt = {>>int{headerQ_comp, payload_i}};
      end
      //-------------------------------------------ANANDITA----------------------------------------------------------
      dl_ep_sending_que= TLP_comp_pkt;
      tl_driver_dl_put_port.put(dl_ep_sending_que);
      `uvm_info(get_type_name(), $sformatf("IO Read completion formed for VC%0d (TC%0d)", response_vc, tc), UVM_LOW)
    end
    else if(typef inside {12,13,14} && fmt == 2 || fmt == 3) begin//add
      typef_temp = typef;
      fmt_temp = fmt;
      typef = 10;
      completer_id = 0;
      bcm = 0;
      byte_count = 0;
      reserve4 = 0;
      // Use fmt = 2 for Cpl with data
      if(fmt == 0 || fmt == 1) fmt = 2;
      lower_address = 0;

      headerQ_comp[0]={fmt,typef,reserve1,tc,reserve2,attr1,reserve3,th,td,ep,attr2,at,len};
      headerQ_comp[1]={completer_id,completion_status,bcm,byte_count};
      headerQ_comp[2]={requester_id,tag,reserve4,lower_address};
      //  byte_count=byte_count-(16*4);
      payload_m = new[len];
      //       payload_m = new[4];
      start_add= address;
      `uvm_info("address_update",$sformatf("%0h",start_add),UVM_NONE)
      `uvm_info("memory space",$sformatf("%p",mem_space),UVM_NONE)


      if(len==8)
      {payload_m[3], payload_m[2], payload_m[1], payload_m[0]} = fetch_data;
      else
      {payload_m[1], payload_m[0]} = fetch_data[63:0];


    end




  endtask


  //=================================================================
  // COMPLETION DRIVE TASKS (UNCHANGED)
  //=================================================================

  task drive_config_comp();
    int count_cfg;
    if (fmt == 2) begin
      count_cfg = 3 + td + len;
    end
    else if (fmt == 0) begin
      count_cfg = 3 + td;
    end

    if (TLP_comp_pkt.size() == count_cfg) begin
      `uvm_info("EP SEND CONFIG COMP", $psprintf("EP_TLP_config_comp=%p", TLP_comp_pkt), UVM_LOW)
      foreach (TLP_comp_pkt[i]) begin
        @(posedge vif.clk);
        vif.tx_data <= TLP_comp_pkt[i];
      end
      count_cfg = 0;
      //----------------------------------Added this to properly 0 data-------------------------------------------------
      @(posedge vif.clk) vif.tx_data<=0;
    end 
  endtask

  task drive_mem_comp();
    int count_cfg;
    int rcb_dw ; // RCB = 64 bytes = 16 DW
    int total_len_dw ; // len is in DW
    int first_pkt_len_dw;
    int second_pkt_len_dw;
    int index = 0;
    int header_len; 
    int total_pkt_len;  

    // Calculate total DWs in TLP packet
    if(typef_temp==14)
      count_cfg = 3 + td + (len/2); // 3 header + td + data
    else if (fmt == 2) begin
      count_cfg = 3 + td + len; // 3 header + td + data
    end 
    else if (fmt == 0) begin
      count_cfg = 3 + td;
    end

    `uvm_info("mem_completion",$sformatf("conu %0d size %0d TLP %p",count_cfg,TLP_comp_pkt.size(),TLP_comp_pkt),UVM_NONE)


    if(RCB == 64) rcb_dw = 16;
    else if(RCB == 128) rcb_dw = 32;
    total_len_dw = temp_length;
    // Split handling only if packet is larger than RCB
    if (total_len_dw > rcb_dw) begin
      first_pkt_len_dw  = rcb_dw;    //16
      second_pkt_len_dw = total_len_dw - rcb_dw;  //4

      // Assume each DW in payload has a corresponding entry in TLP_comp_pkt (after header)
      header_len = 3 + td; // Number of header DWs
      total_pkt_len = TLP_comp_pkt.size(); //23

      // 1st Completion Packet: Header + first RCB's worth of data
      `uvm_info("EP SEND MEMORY COMP", $psprintf("TLP_comp_pkt=%p",TLP_comp_pkt),UVM_LOW)
      ///for (int i = 0; i < header_len + first_pkt_len_dw; i++) begin
      foreach (TLP_comp_pkt[i]) begin
        @(posedge vif.clk);
        vif.tx_data <= TLP_comp_pkt[i];
      end
    end
    else begin
      // Normal case: No split required
      if (TLP_comp_pkt.size() == count_cfg) begin
        `uvm_info("EP SEND MEMORY COMP", $psprintf("EP_TLP_Mem_comp=%p", TLP_comp_pkt), UVM_LOW)
        foreach (TLP_comp_pkt[i]) begin
          @(posedge vif.clk);
          vif.tx_data <= TLP_comp_pkt[i];
        end
        @(posedge vif.clk);
        vif.tx_data<=0;
      end
    end
  endtask

  task drive_io_comp();
    int count_cfg;
    if (fmt == 2) begin
      count_cfg = 3 + td + len;  // IO read completion with data
    end
    else if (fmt == 0) begin
      count_cfg = 3 + td;        // IO write completion without data
    end

    if (TLP_comp_pkt.size() == count_cfg) begin
      `uvm_info("EP SEND IO COMP", $psprintf("EP_TLP_IO_comp=%p", TLP_comp_pkt), UVM_LOW)
      foreach (TLP_comp_pkt[i]) begin
        @(posedge vif.clk);
        vif.tx_data <= TLP_comp_pkt[i];
      end
      @(posedge vif.clk)
      vif.tx_data <= 0;
      count_cfg = 0;
    end 
  endtask



  //=================================================================
  // TC-VC MAPPING CORE FUNCTIONS
  //=================================================================

  task tc_vc_map();
    bit [2:0] vc_count;
    bit [7:0] old_active_vcs;

    // Store previous state for comparison
    old_active_vcs = active_vcs;

    // Get current VC count from device configuration
    vc_count = device_cfg.get_vc();

    `uvm_info(get_type_name(), $sformatf("Updating TC-VC mapping for %0d VCs", vc_count), UVM_LOW)

    // Reset active VCs (except VC0 which is always available)
    active_vcs = 8'b00000001;

    // Clear current TC-VC mapping (reset to default VC0)
    foreach(tc_to_vc_map[i]) tc_to_vc_map[i] = 0;

    // Read and configure each VC
    for(int i = 0; i <= vc_count; i++) begin
      int reg_no = 'h90 + (i * 'hc);

      // Read VC Resource Control Register
      vc_res_ctrl_reg[i].vc_enable       = $root.top.dut.mem[reg_no][31];
      vc_res_ctrl_reg[i].rsvdp_3         = $root.top.dut.mem[reg_no][30:27];
      vc_res_ctrl_reg[i].vc_id           = $root.top.dut.mem[reg_no][26:24];
      vc_res_ctrl_reg[i].rsvdp_2         = $root.top.dut.mem[reg_no][23:20];
      vc_res_ctrl_reg[i].port_arb_select = $root.top.dut.mem[reg_no][19:17];
      vc_res_ctrl_reg[i].load_pat        = $root.top.dut.mem[reg_no][16];
      vc_res_ctrl_reg[i].rsvdp_1         = $root.top.dut.mem[reg_no][15:8];
      vc_res_ctrl_reg[i].tc_vc_map       = $root.top.dut.mem[reg_no][7:0];

      //    $display($time, " vc_res_ctrl_reg[%0d] = %p", i, vc_res_ctrl_reg[i]);

      // Configure TC-VC mapping if VC is enabled
      if(vc_res_ctrl_reg[i].vc_enable == 1'b1) begin
        configure_tc_vc_mapping(i, vc_res_ctrl_reg[i]);
        `uvm_info("run time chek"," check ",UVM_NONE)
        active_vcs[vc_res_ctrl_reg[i].vc_id] = 1'b1;
      end
    end
    //     `uvm_info("run time chek", $sformatf("old_active %0d active_vc",old_active_vcs,active_vcs),UVM_NONE)

    // Display changes
    if(old_active_vcs != active_vcs) begin
      `uvm_info(get_type_name(), $sformatf("Active VCs changed: 0b%08b -> 0b%08b", 
                                           old_active_vcs, active_vcs), UVM_LOW)
    end

    // display_tc_vc_mapping();
  endtask

  function bit is_vc_register(bit [9:0] register_address);
    // VC Resource Control registers start at 0x90 with 0xC spacing
    // 0x90, 0x9C, 0xA8, 0xB4, 0xC0, 0xCC, 0xD8, 0xE4

    for(int i = 0; i < 8; i++) begin
      bit [9:0] vc_reg_addr = 'h90 + (i * 'hc);
      if(register_address == vc_reg_addr) begin
        return 1'b1;
      end
    end

    // Also check VC capability register at 0x80 (VC count)
    if(register_address == 'h80) return 1'b1;

    return 1'b0;
  endfunction

  task configure_tc_vc_mapping(int vc_index, vc_res_ctrl_reg_t vc_reg);
    bit [7:0] tc_map = vc_reg.tc_vc_map;
    bit [2:0] vc_id = vc_reg.vc_id;

    // Map each TC bit to this VC
    for(int tc = 0; tc < 8; tc++) begin
      if(tc_map[tc] == 1'b1) begin
        tc_to_vc_map[tc] = vc_id;
        `uvm_info(get_type_name(), $sformatf("TC%0d mapped to VC%0d", tc, vc_id), UVM_LOW)
      end
    end
  endtask

  function bit [2:0] get_vc_for_tc(bit [2:0] traffic_class);
    if(traffic_class > 7) begin
      `uvm_warning(get_type_name(), $sformatf("Invalid TC: %0d, using VC0", traffic_class))
      return 3'b000;
    end
    return tc_to_vc_map[traffic_class];
  endfunction

  task display_vc_memory_stats();
    int vc_counts[8] = '{default:0};
    int tc_counts[15] = '{default:0};

    `uvm_info(get_type_name(), "=== VC Memory Transaction Statistics ===", UVM_LOW)

    foreach(vc_memory_log[i]) begin
      vc_counts[vc_memory_log[i].vc_id]++;
      tc_counts[vc_memory_log[i].tc]++;
    end

    for(int i = 0; i < 8; i++) begin
      if(vc_counts[i] > 0) begin
        `uvm_info(get_type_name(), $sformatf("VC%0d: %0d memory transactions", i, vc_counts[i]), UVM_LOW)
      end
      if(tc_counts[i] > 0) begin
        `uvm_info(get_type_name(), $sformatf("TC%0d: %0d memory transactions", i, tc_counts[i]), UVM_LOW)
      end
    end
  endtask

  task initialize_tc_vc_structures();
    // Initialize arrays and default mappings
    vc_res_ctrl_reg = new[8]; // Max 8 VCs

    // Default all TCs to VC0
    tc_to_vc_map[0] = 0;

    active_vcs = 8'b00000001; // Only VC0 active by default
    current_vc = 0;

    `uvm_info(get_type_name(), "TC-VC mapping structures initialized", UVM_LOW)
  endtask


  // Do message write for message packet
  task msg_write();
    bit [2:0] packet_tc;
    bit [2:0] assigned_vc;
    if ((typef inside {[16:23]}) && (fmt inside {1,3})) begin  // IO writes are always 1DW

      // **Extract TC and get assigned VC**
      packet_tc = tc;
      assigned_vc = get_vc_for_tc(packet_tc);

      `uvm_info(get_type_name(), $sformatf("IO write: TC%0d mapped to VC%0d", 
                                           packet_tc, assigned_vc), UVM_LOW)

      // **Validate VC is enabled**
      if (active_vcs[assigned_vc] == 1'b0) begin
        `uvm_warning(get_type_name(), $sformatf("VC%0d not enabled for TC%0d, using VC0", 
                                                assigned_vc, packet_tc))
        assigned_vc = 3'b000;
      end 
      `uvm_info("FOR MESSAGE TLP,MSG WRITE",$sformatf("The message tlp value code=%d and typef =%d",message_code,typef),UVM_NONE)
      if((typef inside {[16:23]}) && (message_code inside {['h20:'h23]})) begin 
        assert_msg();//Assrting INTA by BACKDOOR
      end
      else if((typef inside {[16:23]}) && (message_code inside {['h24:'h27]})) begin
        deassert_intterupt();
      end
    end
  endtask
  task assert_msg();
    if(message_code =='h20) data_value_reg = 1;
    else if(message_code =='h21) data_value_reg = 2;
    else if(message_code =='h22) data_value_reg = 3;
    else if(message_code =='h23) data_value_reg = 4;
    reg_model.mod_reg.intr_pin_reg.print();
    reg_model.mod_reg.intr_pin_reg.predict(
      .value (data_value_reg),
      .kind  (UVM_PREDICT_DIRECT),
      .path  (UVM_BACKDOOR)
    );

    if (status_value_reg != UVM_IS_OK)
      `uvm_error("INTR_PIN", "intr_pin_reg write failed")
      reg_model.mod_reg.intr_pin_reg.print();

  endtask
  task deassert_intterupt();
    // If asserted, deassert it
    if (data_value_reg != 0) begin
      data_value_reg = 0;
      reg_model.mod_reg.intr_pin_reg.print();
      reg_model.mod_reg.intr_pin_reg.predict(
        .value (data_value_reg),
        .kind  (UVM_PREDICT_DIRECT),
        .path  (UVM_BACKDOOR)
      );
    end
    else `uvm_warning("IN DEASSERT INT A","DEASSERT IS NOT DONE")

      if (status_value_reg != UVM_IS_OK)
        `uvm_error("INTR_PIN", "intr_pin_reg write failed")
        reg_model.mod_reg.intr_pin_reg.print();
  endtask
endclass

