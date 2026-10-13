////////////////////////////////////////////////////
// SEQ ITEM (32-bit)
////////////////////////////////////////////////////

class pcie_dl_seq_item extends uvm_sequence_item;
  int num_payload_dwords;
  int payload_bytes;
  int payload_start;
  bit [31:0] tx_buffer[$];
  bit [31:0] header_seq1,header_seq2,header_seq3;
  bit [31:0] tlp_header1, tlp_header2, tlp_header3;

  bit [31:0] addr_reg;
  bit [31:0] data_reg;
  bit rd_or_wr;

  `uvm_object_utils(pcie_dl_seq_item)

  rand header_dllp_structure dllps_pkt;
  rand header_dllp_sfc_structure dllps_scl_pkt;
  rand dllp_feature_structure dllps_f_pkt;
  rand header_tlp_structure  tlps_pkt;
  rand dllp_acknak acknak_pkt;//added for ack_nak
  //   rand dllp_acknak acknak_pkt;//added for ack_nak
  rand dllp_pm pm_pkt;//added for pm


  rand bit [31:0] payload[];
  bit [31:0] lcrc;
  bit from_TL=0;
  rand bit is_tlp;rand bit scl_en;
  rand bit is_nop;
  rand bit is_pm;
  constraint nop_dllp{
    soft is_nop==0;
    if(is_nop) acknak_pkt.dllp_type==NOP;
  }
  constraint pm_dllp{
    soft is_pm==0;
    solve is_pm before pm_pkt.dllp_type;
    pm_pkt.dllp_type inside {PM_Enter_L1,PM_Enter_L23,PM_Active_State_Request_L1,PM_Request_Ack};
    if(is_pm) dllps_pkt.dllp_type==pm_pkt.dllp_type;
  }

  bit [31:0] received_lcrc;

  bit [31:0] dllp_pkt[$]; // 32-bit queue (DWORDs)
  bit [31:0] tlp_pkt[$];  // 32-bit queue (DWORDs)

  rand bit [11:0] seq_num;bit sclh;bit scld;


  //replay buffers and tracking
  static bit [31:0] device_replay_buffer[int][$]; // Associative array indexed by device_id
  static int device_replay_count[int];            // Track replay buffer size per device
  static bit [11:0] device_oldest_unacked_seq[int]; // Track oldest unACKed sequence per device
  static bit [11:0] device_next_tx_seq[int];        // Track next TX sequence number per device

  // Device identification
  int device_id; 
  constraint rsvd_c {
    soft scl_en==0;
    (scl_en==0)->dllps_pkt.rsvd1 == 0; 
    (scl_en==0)->dllps_pkt.rsvd2 == 0; 
    (scl_en==1)->dllps_pkt.rsvd1 inside {1,2,3}; 
    (scl_en==1)->dllps_pkt.rsvd1 inside {1,2,3}; 
    acknak_pkt.rsvd == 12'h0;
    pm_pkt.rsvd==0;
    !(is_tlp == 0 && acknak_pkt.dllp_type inside {ACK_DLLP_TYPE, NAK_DLLP_TYPE}) || (acknak_pkt.seq_num < 4096);  // Ensure valid range if ACK/NAK
  }

  function new(string name = "pcie_dl_seq_item"); 
    super.new(name); 
  endfunction

  //helper function to your existing seq_item
  function void assign_sequence_number(bit [11:0] assigned_seq);
    this.seq_num = assigned_seq;
  endfunction


  function void post_randomize();
    if (is_tlp) begin
      tlps_pkt.length = $urandom_range(1, 10);
      payload = new[tlps_pkt.length];
      foreach (payload[i]) payload[i] = $urandom_range(0, 1024);
    end
    do_pack_bytes();
  endfunction

  // Device-specific replay buffer management functions
  function void init_device_replay_buffer(int dev_id);
    if (!device_replay_count.exists(dev_id)) begin
      device_replay_count[dev_id] = 0;
      device_oldest_unacked_seq[dev_id] = 0;
      device_next_tx_seq[dev_id] = 0;
      device_replay_buffer[dev_id] = {};
      `uvm_info("REPLAY_INIT", $sformatf("Initialized replay buffer for device %0d", dev_id), UVM_LOW);
    end
  endfunction

  function void scale_h();
    if(dllps_pkt.rsvd1==3)
      sclh=4;
    else if(dllps_pkt.rsvd1==2)
      sclh=2;
    else
      sclh=0;

  endfunction
  function void scale_d();
    if(dllps_pkt.rsvd2==3)
      scld=4;
    else if(dllps_pkt.rsvd2==2)
      scld=2;
    else
      scld=0;
  endfunction


  function void store_in_replay_buffer(int dev_id);
    bit [19:0] pl_dws;  // payload DWORDs of this TLP (everything after the 3 header DWs)
    if (is_tlp && tx_buffer.size() > 0) begin
      init_device_replay_buffer(dev_id);

      // Store sequence number first
      // Entry layout: {payload_dw_count[19:0], seq_num[11:0]}, hdr1, hdr2, hdr3, payload..., LCRC
      // (the DW count is stored explicitly: read requests have Length != 0 but no payload)
      pl_dws = tx_buffer.size() - 3;
      device_replay_buffer[dev_id].push_back({pl_dws, seq_num});

      // Store the complete TLP data with sequence number header
      device_replay_buffer[dev_id].push_back(header_seq1);
      device_replay_buffer[dev_id].push_back(header_seq2);  
      device_replay_buffer[dev_id].push_back(header_seq3);

      // Store payload data
      for(int i = 3; i < tx_buffer.size(); i++) begin
        device_replay_buffer[dev_id].push_back(tx_buffer[i]);
      end

      // Store LCRC at the end
      device_replay_buffer[dev_id].push_back(lcrc);

      // Update count to include seq_num + tx_buffer.size() + LCRC
      device_replay_count[dev_id] += (1 + tx_buffer.size() + 1);

      print_replay_buffer_by_tlp(dev_id);
    end
  endfunction

  function void print_replay_buffer_by_tlp(int dev_id);
    string buffer_str;
    int tlp_index = 0;
    int data_index = 0;
    int payload_length;
    bit [11:0] stored_seq_num;
    init_device_replay_buffer(dev_id);
    buffer_str = $sformatf("Device %0d replay_buffer=\n", dev_id);

    // Parse through replay buffer TLP by TLP
    while (data_index < device_replay_buffer[dev_id].size()) begin
      if (data_index + 3 < device_replay_buffer[dev_id].size()) begin
        // Extract stored sequence number
        stored_seq_num = device_replay_buffer[dev_id][data_index][11:0];

        // Extract payload length from header (bits [19:10] of second stored word - header1)
        payload_length = device_replay_buffer[dev_id][data_index][31:12];  // stored payload DW count

        // Print TLP with sequence number
        buffer_str = {buffer_str, $sformatf("  TLP%0d (seq:%0d): ", tlp_index, stored_seq_num)};

        // Print 3 header words (skip seq_num word)
        buffer_str = {buffer_str, $sformatf("'h%h 'h%h 'h%h", 
                                            device_replay_buffer[dev_id][data_index + 1],  // header_seq1
                                            device_replay_buffer[dev_id][data_index + 2],  // header_seq2
                                            device_replay_buffer[dev_id][data_index + 3])}; // header_seq3

        // Print payload words if they exist
        for (int i = 0; i < payload_length && (data_index + 4 + i) < device_replay_buffer[dev_id].size(); i++) begin
          buffer_str = {buffer_str, $sformatf(" 'h%h", device_replay_buffer[dev_id][data_index + 4 + i])};
        end

        // Print LCRC (should be the last DWORD of this TLP)
        if ((data_index + 4 + payload_length) < device_replay_buffer[dev_id].size()) begin
          buffer_str = {buffer_str, $sformatf(" LCRC:'h%h", device_replay_buffer[dev_id][data_index + 4 + payload_length])};
        end

        buffer_str = {buffer_str, "\n"};

        // Move to next TLP (1 seq_num + 3 headers + payload + 1 LCRC)
        data_index += (1 + 3 + payload_length + 1);
        tlp_index++;
      end
      else begin
        break; // Not enough data for complete TLP
      end
    end

    `uvm_info(get_type_name(), buffer_str, UVM_LOW);
  endfunction


  // Add this function to your pcie_dl_seq_item class
  function void clear_replay_buffer_up_to_ack(int dev_id, bit [11:0] ack_seq_num);
    int tlps_to_remove = 0;
    int dwords_to_remove = 0;
    bit [11:0] current_seq;
    int payload_length; 
    init_device_replay_buffer(dev_id);
    // Calculate number of TLPs to remove (from oldest_unacked_seq to ack_seq_num inclusive)
    current_seq = device_oldest_unacked_seq[dev_id];
    while (current_seq != ((ack_seq_num + 1) % 4096)) begin
      tlps_to_remove++;
      current_seq = (current_seq + 1) % 4096;
      if (tlps_to_remove > 4096) break; // Safety check
    end

    if (tlps_to_remove > 0) begin
      // Remove TLPs from the front of the buffer
      int removed_dwords = 0;
      int data_index = 0;   
      for (int tlp = 0; tlp < tlps_to_remove && device_replay_buffer[dev_id].size() > 0; tlp++) begin
        if (data_index + 3 < device_replay_buffer[dev_id].size()) begin
          // Payload DW count is stored in bits [31:12] of the seq_num DWORD
          payload_length = device_replay_buffer[dev_id][0][31:12];
          // Remove sequence number (1 DWORD)
          if (device_replay_buffer[dev_id].size() > 0) begin
            device_replay_buffer[dev_id].pop_front();
            removed_dwords++;
          end       

          // Remove header (3 DWORDs)
          for (int hdr = 0; hdr < 3 && device_replay_buffer[dev_id].size() > 0; hdr++) begin
            device_replay_buffer[dev_id].pop_front();
            removed_dwords++;
          end

          // Remove payload DWORDs
          for (int pay = 0; pay < payload_length && device_replay_buffer[dev_id].size() > 0; pay++) begin
            device_replay_buffer[dev_id].pop_front();
            removed_dwords++;
          end

          // Remove LCRC (1 DWORD)
          if (device_replay_buffer[dev_id].size() > 0) begin
            device_replay_buffer[dev_id].pop_front();
            removed_dwords++;
          end
        end
        else begin
          break; // Not enough data for complete TLP
        end
      end

      device_replay_count[dev_id] -= removed_dwords;
      device_oldest_unacked_seq[dev_id] = (ack_seq_num + 1) % 4096;

      `uvm_info("REPLAY", 
                $sformatf("Device %0d: Cleared replay buffer up to seq_num %0d. Removed %0d TLPs (%0d DW). Remaining = %0d DW", 
                          dev_id, ack_seq_num, tlps_to_remove, removed_dwords, device_replay_count[dev_id]), UVM_LOW);
    end
  endfunction

  // NEW: Static method to retrieve replay buffer items starting from a specific sequence number
  static function void get_replay_buffer_items(int dev_id, bit [11:0] start_seq, output pcie_dl_seq_item items[$]);
    bit [31:0] buffer[$];
    int data_index = 0;
    bit [11:0] current_seq;
    int payload_length;
    bit [31:0] hdr;
    pcie_dl_seq_item replay_item;

    // Get the raw buffer
    get_replay_buffer_static(dev_id, buffer);
    if (buffer.size() == 0) return;

    // Parse the buffer TLP by TLP, starting from start_seq
    while (data_index < buffer.size()) begin
      if (data_index + 3 < buffer.size()) begin  // Ensure enough for seq_num + 3 headers
        // Extract sequence number from the stored seq_num DWORD
        current_seq = buffer[data_index][11:0];

        // Only process if this seq_num >= start_seq (handle wrap-around)
        if (((current_seq >= start_seq) && (start_seq <= current_seq)) ||
            ((start_seq > current_seq) && ((current_seq + 4096 - start_seq) < 2048))) begin  // Forward progress check

          // Payload DW count is stored in bits [31:12] of the seq_num DWORD
          payload_length = buffer[data_index][31:12];
          if (data_index + 4 + payload_length >= buffer.size()) break;  // incomplete entry

          // Rebuild the TLP from the stored DWORDs: same sequence number,
          // header and payload, so do_pack_bytes() gives the same LCRC.
          replay_item = pcie_dl_seq_item::type_id::create("replay_item");
          replay_item.device_id = dev_id;
          replay_item.is_tlp = 1;
          replay_item.from_TL = 1;
          replay_item.seq_num = current_seq;
          hdr = buffer[data_index + 1];
          replay_item.tlps_pkt.Fmt     = hdr[31:29];
          replay_item.tlps_pkt.Type    = hdr[28:24];
          replay_item.tlps_pkt.rsvd1   = hdr[23];
          replay_item.tlps_pkt.TC      = hdr[22:20];
          replay_item.tlps_pkt.rsvd2   = hdr[19];
          replay_item.tlps_pkt.attr1   = hdr[18];
          replay_item.tlps_pkt.rsvd3   = hdr[17];
          replay_item.tlps_pkt.TH      = hdr[16];
          replay_item.tlps_pkt.TD      = hdr[15];
          replay_item.tlps_pkt.EP      = hdr[14];
          replay_item.tlps_pkt.attr2   = hdr[13:12];
          replay_item.tlps_pkt.AT      = hdr[11:10];
          replay_item.tlps_pkt.length  = hdr[9:0];
          replay_item.tlps_pkt.sdw     = buffer[data_index + 2];
          replay_item.tlps_pkt.Address = buffer[data_index + 3];
          replay_item.payload = new[payload_length];
          foreach (replay_item.payload[k]) replay_item.payload[k] = buffer[data_index + 4 + k];
          replay_item.do_pack_bytes();
          // Add to output queue
          items.push_back(replay_item);
        end

        // Move to next TLP: 1 (seq_num) + 3 (headers) + payload_length + 1 (LCRC)
        data_index += (1 + 3 + payload_length + 1);
      end else begin
        break;  // Not enough data for a complete TLP
      end
    end

    //  `uvm_info("REPLAY", $sformatf("Device %0d: Retrieved %0d TLPs from replay buffer starting from seq %0d", dev_id, items.size(), start_seq), UVM_LOW);
  endfunction


  static function void get_replay_buffer_static(int dev_id, output bit [31:0] buffer[$]);
    if (!device_replay_count.exists(dev_id)) begin
      device_replay_count[dev_id] = 0;
      device_oldest_unacked_seq[dev_id] = 0;
      device_next_tx_seq[dev_id] = 0;
      device_replay_buffer[dev_id] = {};
    end
    buffer = device_replay_buffer[dev_id];
  endfunction

  static function int get_replay_count_static(int dev_id);
    if (!device_replay_count.exists(dev_id)) begin
      device_replay_count[dev_id] = 0;
    end
    return device_replay_count[dev_id];
  endfunction

  function bit [11:0] get_oldest_unacked_seq(int dev_id);
    init_device_replay_buffer(dev_id);
    return device_oldest_unacked_seq[dev_id];
  endfunction

  function bit [11:0] get_and_increment_tx_seq(int dev_id);
    bit [11:0] current_seq;
    init_device_replay_buffer(dev_id);
    current_seq = device_next_tx_seq[dev_id];
    device_next_tx_seq[dev_id] = (device_next_tx_seq[dev_id] + 1) % 4096;
    return current_seq;
  endfunction

  function void set_tx_seq_num(int dev_id, bit [11:0] seq_val);
    init_device_replay_buffer(dev_id);
    device_next_tx_seq[dev_id] = seq_val;
  endfunction

  // 16-bit CRC calculation for DLLPs 
  function bit [15:0] calculate_dllp_crc16(input bit [7:0] data_bytes[]);
    bit [15:0] crc = 16'hFFFF;           // Seed value FFFFh
    bit [15:0] poly = 16'h100B;          // Polynomial coefficient 100Bh

    foreach (data_bytes[i]) begin
      bit [7:0] curr_byte = data_bytes[i];

      // Process bits from bit 0 to bit 7 of each byte
      for (int b = 0; b <= 7; b++) begin
        bit input_bit = curr_byte[b];     // Bit 0 first, then bit 1, ..., bit 7
        bit crc_msb = crc[15];            // Take current MSB of CRC
        crc = {crc[14:0], 1'b0};          // Shift left
        if (crc_msb ^ input_bit)          // XOR check
          crc ^= poly;                    // XOR with polynomial if needed
      end
    end
    return ~crc; // Final complement
  endfunction

  //PACK FOR DL_FEATURE
  function void pack_dl_feature();
    bit[31:0]dword[$];bit[15:0]crc16;bit[7:0] data_bytes[$];

    dllp_pkt.push_back({dllps_f_pkt.dllp_type,dllps_f_pkt.feature_ack,dllps_f_pkt.feature_sprt});
    //     data_bytes={8>>{dllp_pkt[0]}};
    //     crc16=calculate_dllp_crc16(data_bytes);
    //     dllp_pkt.push_back({crc16,16'b0});

  endfunction


  function bit[31:0] calculate_lcrc(input bit [31:0] data_words[$]);
    int len=data_words.size();
    bit [31:0] crc = 32'hFFFF_FFFF;
    bit [31:0] poly = 32'h04C11DB7;
    int j,LSB,MSB;bit[2:0] cnt=3'b000; bit input_bit; bit crc_msb;
    foreach(data_words[i])begin
      bit [31:0] curr_word=data_words[i];

      for (int b = 31; b>=0; b--) begin         
        j=b/8;
        LSB=j*8;
        MSB=LSB+7;
        input_bit = curr_word[LSB+cnt];  // LSB-first processing
        crc_msb = crc[31];         // take current MSB of crc
        crc = {crc[30:0], 1'b0};// shift left
        if (crc_msb ^ input_bit)       // XOR check
          crc ^= poly;
        cnt++;

      end

    end
    return ~crc;
  endfunction

  // LCRC Calculator
  //   function bit [31:0] calculate_lcrc(input bit [31:0] data_words[$]);
  //     bit [31:0] crc = 32'hFFFF_FFFF;
  //     bit [31:0] poly = 32'h04C11DB7;

  //     foreach (data_words[i]) begin
  //       bit [31:0] curr_word = data_words[i];

  //       // Process bits from MSB to LSB (bit 31 down to bit 0)
  //       for (int b = 31; b >=0; b--) begin
  //         bit input_bit = curr_word[b];  // MSB-first processing
  //         bit crc_msb = crc[31];         // take current MSB of crc
  //         crc = {crc[30:0], 1'b0};       // shift left
  //         if (crc_msb ^ input_bit)       // XOR check
  //           crc ^= poly;                 // XOR with polynomial if needed
  //       end
  //     end
  //     return ~crc; // Final complement
  //   endfunction

  // ACK/NAK DLLP packing with CRC calculation
  function void do_pack_acknak();
    bit [47:0] raw_packet_bits;
    bit [31:0] dword_lo, dword_hi;
    bit [7:0] acknak_data_bytes[];
    bit [15:0] calculated_crc;

    // Calculate CRC for first 4 bytes (excluding CRC field)
    acknak_data_bytes = new[4]; 
    acknak_data_bytes[0] = (is_nop==1)? NOP:acknak_pkt.dllp_type;                    // 8 bits
    acknak_data_bytes[1] = acknak_pkt.rsvd[11:4];                   // Upper 8 bits of rsvd
    acknak_data_bytes[2] = {acknak_pkt.rsvd[3:0], acknak_pkt.seq_num[11:8]}; // Lower 4 bits rsvd + upper 4 bits seq_num
    acknak_data_bytes[3] = acknak_pkt.seq_num[7:0];                 // Lower 8 bits of seq_num

    // Calculate and assign CRC
    calculated_crc = calculate_dllp_crc16(acknak_data_bytes);
    acknak_pkt.crc16 = calculated_crc;

    // Pack into 48-bit structure
    raw_packet_bits = {
      acknak_data_bytes[0],    // 8 bits
      acknak_pkt.rsvd,         // 12 bits
      acknak_pkt.seq_num,      // 12 bits
      acknak_pkt.crc16         // 16 bits
    };

    // Split into DWORDs
    dword_lo = raw_packet_bits[47:16];
    dword_hi = {raw_packet_bits[15:0], 16'b0};
    dllp_pkt.push_back(dword_lo);
    dllp_pkt.push_back(dword_hi);
  endfunction

  function void do_pack_tlp();
    tx_buffer.delete(); // Clear previous contents
    	tlp_header1 = {tlps_pkt.Fmt,tlps_pkt.Type,tlps_pkt.rsvd1,tlps_pkt.TC,tlps_pkt.rsvd2,tlps_pkt.attr1,tlps_pkt.rsvd3,tlps_pkt.TH,tlps_pkt.TD,tlps_pkt.EP,tlps_pkt.attr2,tlps_pkt.AT,tlps_pkt.length};
//     tlp_header1 = {tlps_pkt.length, tlps_pkt.Address[63:42]};
    tlp_header2 = {tlps_pkt.sdw};
    tlp_header3 = {tlps_pkt.Address};
    tx_buffer.push_back(tlp_header1);
    tx_buffer.push_back(tlp_header2);
    tx_buffer.push_back(tlp_header3);
    foreach (payload[i]) 
      tx_buffer.push_back(payload[i]);    
  endfunction

  // Updated packing function with CRC calculation for DLLPs
  function void do_pack_bytes();
    bit [31:0] dword_lo, dword_hi;
    bit [31:0] lcrc_calc_data[$];
    bit [47:0] raw_packet_bits;
    bit [7:0] dllp_data_bytes[];
    bit [15:0] calculated_crc;
    dllp_pkt = {};

    if (!is_tlp) begin 
      // Check both acknak_pkt and dllps_pkt for DLLP type
      bit [7:0] current_dllp_type;
      current_dllp_type = (acknak_pkt.dllp_type != 0) ? acknak_pkt.dllp_type : dllps_pkt.dllp_type;

      if (current_dllp_type inside {ACK_DLLP_TYPE, NAK_DLLP_TYPE}) begin
        do_pack_acknak();  
      end
      else if(is_nop) begin
        do_pack_acknak(); 
        $display("Packed NOP");
      end
      else begin
        // Regular DLLP: Calculate CRC for first 4 bytes (excluding CRC field)
        dllp_data_bytes = new[4];
        dllp_data_bytes[0] = dllps_pkt.dllp_type;
        dllp_data_bytes[1] = (dllps_pkt.dllp_type==8'b00100???)?{8'b00000000}:{dllps_pkt.rsvd1, dllps_pkt.HdrFC[7:2]};///
        dllp_data_bytes[2] = (dllps_pkt.dllp_type==8'b00100???)?{8'b00000000}:{dllps_pkt.HdrFC[1:0], dllps_pkt.rsvd2, dllps_pkt.DataFC[11:8]};
        dllp_data_bytes[3] = (dllps_pkt.dllp_type==8'b00100???)?{8'b00000000}: dllps_pkt.DataFC[7:0];


        // Calculate CRC
        calculated_crc = calculate_dllp_crc16(dllp_data_bytes);
        dllps_pkt.crc16 = calculated_crc;
        if(is_pm) pm_pkt.crc16=calculated_crc;

        // Pack into 48-bit structure
        if(dllps_pkt.dllp_type==?8'b00100???) begin
          raw_packet_bits = {
            pm_pkt.dllp_type,
            pm_pkt.rsvd,
            pm_pkt.crc16
          };
        end
        else begin
          raw_packet_bits = {
            dllps_pkt.dllp_type,
            dllps_pkt.rsvd1,
            dllps_pkt.HdrFC,
            dllps_pkt.rsvd2,
            dllps_pkt.DataFC,
            dllps_pkt.crc16
          };
        end
        dword_lo = raw_packet_bits[47:16];
        dword_hi = {raw_packet_bits[15:0], 16'b0};

        dllp_pkt.push_back(dword_lo);
        dllp_pkt.push_back(dword_hi);
      end
    end 
    else begin 
      // TLP logic
      do_pack_tlp();
      //`uvm_info(get_type_name(), $sformatf("[tx_buffer=%p]", tx_buffer), UVM_LOW);
      header_seq1 = {tx_buffer[0]};
      header_seq2 = {tx_buffer[1]};
      header_seq3 = {tx_buffer[2]};

      dllp_pkt.push_back(32'hDEADBEEF);
      dllp_pkt.push_back({seq_num[11:0],20'b0});

      dllp_pkt.push_back(header_seq1);
      lcrc_calc_data.push_back(header_seq1);
      dllp_pkt.push_back(header_seq2);
      lcrc_calc_data.push_back(header_seq2);
      dllp_pkt.push_back(header_seq3);
      lcrc_calc_data.push_back(header_seq3);

      for(int i=3; i<tx_buffer.size(); i++) begin
        dllp_pkt.push_back(tx_buffer[i]);
        lcrc_calc_data.push_back(tx_buffer[i]);
      end
      lcrc = calculate_lcrc(lcrc_calc_data);
      dllp_pkt.push_back(lcrc);
    end
  endfunction

  function void do_unpack_acknak();
    // Extract fields from received DWORD 
    acknak_pkt.dllp_type = dllp_pkt[0][31:24];  // 8 bits
    acknak_pkt.rsvd      = dllp_pkt[0][23:12];  // 12 bits
    acknak_pkt.seq_num   = dllp_pkt[0][11:0];   // 12 bits
    acknak_pkt.crc16     = dllp_pkt[1][31:16];  // From second DWORD
  endfunction

  // Updated unpacking function
  function void do_unpack_bytes();
    if (!is_tlp) begin 
      // Simple type extraction 
      bit [7:0] dllp_type_field = dllp_pkt[0][31:24];

      if (dllp_type_field inside {ACK_DLLP_TYPE, NAK_DLLP_TYPE, NOP}) begin
        do_unpack_acknak();
      end
      else begin
        // Regular DLLP unpacking
        dllps_pkt.dllp_type = dllp_pkt[0][31:24];
        dllps_pkt.rsvd1     = dllp_pkt[0][23:22];
        dllps_pkt.HdrFC     = dllp_pkt[0][21:14];
        dllps_pkt.rsvd2     = dllp_pkt[0][13:12];
        dllps_pkt.DataFC    = dllp_pkt[0][11:0];
        dllps_pkt.crc16     = dllp_pkt[1][31:16];
      end
    end 
    else begin // TLP
      seq_num[11:0]=tlp_pkt[0][31:20];
      tlps_pkt.length = tlp_pkt[0][19:10];
      tlps_pkt.Address = {tlp_pkt[0][9:0], tlp_pkt[1], tlp_pkt[2][31:10]};
      num_payload_dwords = tlps_pkt.length;
      payload = new[num_payload_dwords];
      for (int i = 0; i < num_payload_dwords; i++)
        payload[i] = tlp_pkt[3 + i];
    end
    received_lcrc = tlp_pkt[tlp_pkt.size()-1];
  endfunction

  function bit is_dllp_start(bit [31:0] rx_dword);
    bit [7:0] msb = rx_dword[31:24];

    return (msb inside {INITFC1_P_VC0, INITFC1_NP_VC0, INITFC1_CPL_VC0,
                        INITFC2_P_VC0, INITFC2_NP_VC0, INITFC2_CPL_VC0,
                        UPDATEFC_P_VC0, UPDATEFC_NP_VC0, UPDATEFC_CPL_VC0,
                        ACK_DLLP_TYPE, NAK_DLLP_TYPE, DATA_LINK_FEATURE, NOP,
                        PM_Enter_L1,PM_Enter_L23,PM_Active_State_Request_L1,PM_Request_Ack});//add NOP
  endfunction

endclass