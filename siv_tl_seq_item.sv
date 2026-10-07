//--------------------------------------------------------------
// SIV PCIe Training Sequence Item (siv_pcie_tl_sequence_item)
//--------------------------------------------------------------
//=================SEQ ITEM==================
typedef struct packed{
  bit [2:0]fmt;
  bit [4:0] typef;
  bit reserve1;
  bit [2:0] tc;
  bit reserve2;
  bit attr1;
  bit reserve3;
  bit th;
  bit td;
  bit ep;
  bit [1:0] attr2;
  bit [1:0] at;
  bit [9:0] len;
  bit [15:0] requester_id;
  bit [7:0] tag;
  bit [3:0] last_dw;
  bit [3:0] first_dw;
  bit [7:0] bus_no;
  bit [4:0] dev_no;
  bit [2:0] fun_no;
  bit [3:0] reserve4;
  bit [9:0] reg_no;
  bit [1:0] reserve5;
}config_header_field;

typedef struct packed{
  bit [2:0]fmt;
  bit [4:0] typef;
  bit reserve1;
  bit [2:0] tc;
  bit reserve2;
  bit attr1;
  bit reserve3;
  bit th;
  bit td;
  bit ep;
  bit [1:0] attr2;
  bit [1:0] at;
  bit [9:0] len;
  bit [15:0] requester_id;
  bit [7:0] tag;
  bit [3:0] last_dw;
  bit [3:0] first_dw;
  //bit [`WIDTH_29:0] address;
  bit [31:0] address;//added directly giving 32 bit address		USE THIS FOR 64
  bit [31:0] address1;//--------changed for 64bit address		USE THIS FOR 32
  //bit [`WIDTH_1:0] reserve5;
}mem_header_field;//3dw size

typedef struct packed{
  bit [2:0]fmt;
  bit [4:0] typef;
  bit reserve1;
  bit [2:0] tc;
  bit reserve2;
  bit attr1;
  bit reserve3;
  bit th;
  bit td;
  bit ep;
  bit [1:0] attr2;
  bit [1:0] at;
  bit [9:0] len;
  bit [15:0] requester_id;
  bit [7:0] tag;
  bit [3:0] last_dw;
  bit [3:0] first_dw;
  //bit [`WIDTH_29:0] address;
  bit [31:0] address;//added directly giving 32 bit address
  //bit [`WIDTH_1:0] reserve5;
}io_header_field;//3dw size

typedef struct packed{
  bit [2:0]fmt;
  bit [4:0] typef;
  bit reserve1;
  bit [2:0] tc;
  bit reserve2;
  bit attr1;
  bit reserve3;
  bit th;
  bit td;
  bit ep;
  bit [1:0] attr2;
  bit [1:0] at;
  bit [9:0] len;
  bit [15:0] completer_id;
  bit [2:0] cpl_status;
  bit bcm;
  bit [11:0] byte_count;
  bit [15:0] requester_id;
  bit [7:0] tag;
  bit reserve4;
  bit [6:0] lower_address;
}cpl_header_field;//completion header
typedef enum bit [7:0] {
  MSG_PTM_REQ        = 8'h52,
  MSG_PTM_RESP       = 8'h53,
  MSG_UNLOCK		 = 8'h00,
  MSG_LTR  			 = 8'h10,
  MSG_OBFF			 = 8'h12,
  MSG_INVALIDATE_REQ = 8'h01,
  MSG_INVALIDATE_COMP= 8'h02,
  MSG_PAGE_REQ		 = 8'h04,
  MSG_PRG_RESP		 = 8'h05,
  MSG_PM_PME		 = 8'h18,
  MSG_SET_SLOT_LIMIT = 8'h50,
  MSG_PME_TURN_OFF   = 8'h19,
  MSG_PME_ACK        = 8'h1B,
  MSG_INTX_ASSERT    = 8'h20,
  MSG_INTX_DEASSERT  = 8'h21,
  MSG_VDM_TYPE0      = 8'h7E,
  MSG_VDM_TYPE1      = 8'h7F
} pcie_msg_code_e;
typedef struct packed {
  bit [2:0] fmt;            // 010=Msg, 011=MsgD
  bit [4:0] typef;          // Msg/(MsgD)
  bit       rsvd1;
  bit [2:0] tc;
  bit       rsvd2;
  bit       attr1;
  bit       rsvd3;
  bit       th;
  bit       td;
  bit       ep;
  bit [1:0] attr2;
  bit [1:0] at;             // must be zero
  bit [9:0] len;            // payload DW length
  bit [15:0] requester_id;
  bit [7:0]  tag;
  pcie_msg_code_e msg_code;// must fill DW2 byte 3
  bit [31:0] rsvd4;//byte 8 to 11 are reserved
  bit [31:0] rsvd5;//byte 12 to 15 are resevered
} msg_header_field;//Common Message request header



class siv_pcie_tl_sequence_items extends uvm_sequence_item;
  rand config_header_field header_config;
  rand mem_header_field header_mem;
  rand io_header_field header_io;
  rand cpl_header_field header_cpl;
  rand msg_header_field header_msg;//Message header
  
  rand bit [31:0] prefix[$];
  rand bit [31:0] payload_c[$];
  rand bit [31:0] payload_m[$];	
  rand bit [31:0] payload_i[$];
  rand bit [31:0] payload_msg[$];//Message Payload
  static bit [31:0] payload_temp[$];


  bit [31:0] ecrc;
  bit [31:0]TLP_c[$];
  bit [31:0]TLP_m[$];
  bit [31:0]TLP_i[$];
  bit [31:0]TLP_msg[$];//Message TLP

  bit [31:0]headerQ[$]; 
  bit [31:0]TLP_storage[$];
  bit [31:0]prefix_temp[$];
  rand bit [9:0] MPS;
  bit [3:0] last_dw_temp;


  //Randomised values of routing for message
  rand bit [2:0] r;
  //flag_type
  rand int pkt_type;  //1 -:config_pkt
  //2 -:mem_pkt
  //3 -:io_pkt
  //4 -:cpl_pkt  
  //5 -:msg_pkt
  

  function void post_randomize();		
    //config tx
    if(pkt_type==1)begin
      `uvm_info("siv_pcie_tl_sequence_items","CFG packet",UVM_LOW);
      //formation of the config wr and rd pkt
      if(header_config.typef==4 && (header_config.fmt==2 || header_config.fmt==0))begin

        for(int i=0;i<3;i++) begin
          headerQ.push_front(header_config[32*i+:32]);// for temporary storage
        end
        if(prefix[0][28]==1)begin
          prefix_temp={prefix,headerQ};
          ecrc=genCRC32(prefix_temp,payload_c);
        end
        else ecrc=genCRC32(headerQ,payload_c);	  	
        if(header_config.td==1 && header_config.fmt==2)TLP_c={>>int{prefix,headerQ,payload_c,ecrc}};//permanently store inside TLP_c
        //-----streaming operator is used to packs all of them bit-by-bit into a single continuous TLP
        if(header_config.td==0 && header_config.fmt==2) TLP_c={>>int{prefix,headerQ,payload_c}};
        if(header_config.td==1 && header_config.fmt==0)TLP_c={>>int{prefix,headerQ,ecrc}};  
        if(header_config.td==0 && header_config.fmt==0) TLP_c={>>int{prefix,headerQ}};
        headerQ.delete();// as stored permanently inside TLP_c so delete it.
        prefix_temp.delete();
      end
    else if(header_config.typef==4 && (header_config.fmt==1||header_config.fmt==3)) begin
        `uvm_fatal("INSIDE THE SEQUENCE ITEM-INSIDE CONFIG PACKET","MALFORMED TLP")
      end
    end
    else if(pkt_type==3)begin
      `uvm_info("siv_pcie_tl_sequence_items","IO packet",UVM_LOW);
      //formation of the io wr and rd pkt
      if(header_io.typef==2 && (header_io.fmt==2 || header_io.fmt==0))begin
        for(int i=0;i<3;i++) begin
          headerQ.push_front(header_io[32*i+:32]);
        end
        if(prefix[0][28]==1)begin
          prefix_temp={prefix,headerQ};
          ecrc=genCRC32(prefix_temp,payload_c);
        end
        else ecrc=genCRC32(headerQ,payload_c);	  	
        if(header_io.td==1 && header_io.fmt==2)TLP_i={>>int{prefix,headerQ,payload_i,ecrc}};

        if(header_io.td==0 && header_io.fmt==2) TLP_i={>>int{prefix,headerQ,payload_i}};

        if(header_io.td==1 && header_io.fmt==0)TLP_i={>>int{prefix,headerQ,ecrc}};

        if(header_io.td==0 && header_io.fmt==0) TLP_i={>>int{prefix,headerQ}};

        headerQ.delete();
        prefix_temp.delete();
      end
    end
    //3dw,4dw mem tx
    else if(pkt_type==2)begin
      if(header_mem.typef== 0 && (header_mem.fmt inside {0,1,2,3}) )begin
        last_dw_temp=header_mem.last_dw;
        //---------------changes for 4dw start here
        if(MPS== 0)begin
          for(int i=0;i< 4;i++)begin
            headerQ.push_front(header_mem[32*i+:32]);
          end

          if(header_mem.fmt[0]==0)begin
            headerQ.delete(2);
          end
          `uvm_info("seq_ityem",$sformatf("header	%0p",headerQ),UVM_NONE);

          if(prefix[0][28]==1)begin
            prefix_temp={prefix,headerQ};
            ecrc=genCRC32(prefix_temp,payload_m);
          end
          else ecrc=genCRC32(headerQ,payload_m);

          if(header_mem.td==1 && header_mem.fmt==2 || header_mem.fmt==3)TLP_m={>>int{prefix,headerQ,payload_m,ecrc}};
          if(header_mem.td==0 && header_mem.fmt==2 || header_mem.fmt==3) TLP_m={>>int{prefix,headerQ,payload_m}};          
          if(header_mem.td==1 && header_mem.fmt==1 || header_mem.fmt==0)TLP_m={>>int{prefix,headerQ,ecrc}};          
          if(header_mem.td==0 && header_mem.fmt==1 || header_mem.fmt==0) TLP_m={>>int{prefix,headerQ}};
          //---------------changes for 4dw end here
          headerQ.delete();
          prefix_temp.delete();
        end
        else begin
          if(header_mem.len<=MPS)begin
            for(int i=0;i<4;i++)begin //---------------changes for 4dw 
              headerQ.push_front(header_mem[32*i+:32]);
            end
            //---------------changes for 4dw            
            if(header_mem.fmt[0]==0)begin
              headerQ.delete(2);
            end

            `uvm_info("seq_ityem",$sformatf("header	%0p",headerQ),UVM_NONE);

            if(prefix[0][28]==1)begin
              prefix_temp={prefix,headerQ};
              ecrc=genCRC32(prefix_temp,payload_m);
            end
            else ecrc=genCRC32(headerQ,payload_m);

            if(header_mem.td==1 && header_mem.fmt==2 || header_mem.fmt==3)TLP_m={>>int{prefix,headerQ,payload_m,ecrc}};
            if(header_mem.td==0 && header_mem.fmt==2 || header_mem.fmt==3) TLP_m={>>int{prefix,headerQ,payload_m}};          
            if(header_mem.td==1 && header_mem.fmt==1 || header_mem.fmt==0)TLP_m={>>int{prefix,headerQ,ecrc}};          
            if(header_mem.td==0 && header_mem.fmt==1 || header_mem.fmt==0) TLP_m={>>int{prefix,headerQ}};
            headerQ.delete();
            prefix_temp.delete();
          end
        end
      end
      //trying atomicOP sequence item here for 32 bits
      if(header_mem.typef inside {12,13,14} && (header_mem.fmt inside {0,1,2,3}) )begin
        last_dw_temp=header_mem.last_dw;
        //---------------changes for 4dw start here
        if(MPS==0)begin
          for(int i=0;i< 4;i++)begin
            headerQ.push_front(header_mem[32*i+:32]);
          end

          if(header_mem.fmt[0]==0)begin
            headerQ.delete(2);
          end
          `uvm_info("seq_ityem",$sformatf("header	%0p",headerQ),UVM_NONE);

          if(prefix[0][28]==1)begin
            prefix_temp={prefix,headerQ};
            ecrc=genCRC32(prefix_temp,payload_m);
          end
          else ecrc=genCRC32(headerQ,payload_m);

          if(header_mem.td==1 && header_mem.fmt==2 || header_mem.fmt==3)TLP_m={>>int{prefix,headerQ,payload_m,ecrc}};
          if(header_mem.td==0 && header_mem.fmt==2 || header_mem.fmt==3) TLP_m={>>int{prefix,headerQ,payload_m}};          
          if(header_mem.td==1 && header_mem.fmt==1 || header_mem.fmt==0)TLP_m={>>int{prefix,headerQ,ecrc}};          
          if(header_mem.td==0 && header_mem.fmt==1 || header_mem.fmt==0) TLP_m={>>int{prefix,headerQ}};
          //---------------changes for 4dw end here
          headerQ.delete();
          prefix_temp.delete();
        end
        else begin
          if(header_mem.len<=MPS)begin
            for(int i=0;i<4;i++)begin //---------------changes for 4dw 
              headerQ.push_front(header_mem[32*i+:32]);
            end
            //---------------changes for 4dw            
            if(header_mem.fmt[0]==0)begin
              headerQ.delete(2);
            end

            `uvm_info("seq_ityem",$sformatf("header	%0p",headerQ),UVM_NONE);

            if(prefix[0][28]==1)begin
              prefix_temp={prefix,headerQ};
              ecrc=genCRC32(prefix_temp,payload_m);
            end
            else ecrc=genCRC32(headerQ,payload_m);

            if(header_mem.td==1 && header_mem.fmt==2 || header_mem.fmt==3)TLP_m={>>int{prefix,headerQ,payload_m,ecrc}};
            if(header_mem.td==0 && header_mem.fmt==2 || header_mem.fmt==3) TLP_m={>>int{prefix,headerQ,payload_m}};          
            if(header_mem.td==1 && header_mem.fmt==1 || header_mem.fmt==0)TLP_m={>>int{prefix,headerQ,ecrc}};          
            if(header_mem.td==0 && header_mem.fmt==1 || header_mem.fmt==0) TLP_m={>>int{prefix,headerQ}};
            headerQ.delete();
            prefix_temp.delete();
          end
        end


      end
    //end here Rudra code added
    end
    //Message code added here Rudra
    else if(pkt_type==5)begin
      `uvm_info("siv_pcie_tl_sequence_items","Message packet",UVM_LOW);
      //formation of the io wr and rd pkt
      header_msg.typef={header_msg.typef[4:3],r};
      if((header_msg.typef=={2'b10,r}) && (header_msg.fmt==1 || header_msg.fmt==3))begin
        for(int i=0;i<4;i++) begin
          headerQ.push_front(header_msg[32*i+:32]);
        end
        if(prefix[0][28]==1)begin
          prefix_temp={prefix,headerQ};
          ecrc=genCRC32(prefix_temp,payload_msg);
        end
        else ecrc=genCRC32(headerQ,payload_msg);	  	
        if(header_msg.td==1 && header_msg.fmt==3)TLP_msg={>>int{prefix,headerQ,payload_msg,ecrc}};

        if(header_msg.td==0 && header_msg.fmt==3) TLP_msg={>>int{prefix,headerQ,payload_msg}};

        if(header_msg.td==1 && header_msg.fmt==0)TLP_msg={>>int{prefix,headerQ,ecrc}};

        if(header_msg.td==0 && header_msg.fmt==0) TLP_msg={>>int{prefix,headerQ}};

        headerQ.delete();
        prefix_temp.delete();
      end
    end
    
    //Message code finished
    `uvm_info("seq_item print",$sformatf("header %p  TLP_msg %p",header_msg,TLP_msg),UVM_NONE)
    //Message code Print
    
    `uvm_info("seq_item print",$sformatf("header %p  TLP_m %p",header_mem,TLP_m),UVM_NONE)
    `uvm_info("seq_item print",$sformatf("header %p  TLP_i %p",header_io,TLP_i),UVM_NONE)
    `uvm_info("seq_item print",$sformatf("header %p  TLP_c %p",header_config,TLP_c),UVM_NONE)

  endfunction


  //generate 32 bit crc logic
  function bit[31:0] genCRC32(input bit[31:0] packet_header[$],packet_payload[$]);
    bit[31:0] packet [$];
    bit [31:0] crc;
    int count=0;
    bit [31:0] seed_not;
    //     bit [3:0] crc_calc;
    bit [31:0] masked_value;
    bit [31:0] crc_temp;
    bit [31:0] coeff;
    bit [31:0] seed=32'hffff_ffff;
    packet_header[0][15]=1;//ep bit is protected
    packet_header[0][28]=1;//typef 5th number bit is protected and considered one only
    packet={packet_header,packet_payload};
    coeff=32'h04c1adb7;
    foreach(packet[i]) begin
      seed=seed^packet[i];
    end
    foreach(masked_value[i]) begin
      if(coeff[i]==1) begin
        count+=1;
        //         temp_bit=seed[i];
        if(count==0) masked_value=seed[i];
        else begin
          seed[i]=seed[i]^seed[i-1];
        end
      end
    end
    seed_not=~(seed);
    foreach(seed_not[i]) begin
      if(i%4==0) {<<4{crc}}=seed_not;
    end
    return crc;

  endfunction



  `uvm_object_utils_begin(siv_pcie_tl_sequence_items)
  if(header_config.typef==4)begin
    `uvm_field_int(header_config,UVM_ALL_ON)
    if(header_config.fmt==2)begin
      `uvm_field_sarray_int(payload_c,UVM_ALL_ON)
    end
    if(header_config.td==1)begin
      `uvm_field_int(ecrc,UVM_ALL_ON)
    end
    `uvm_field_sarray_int(TLP_c,UVM_ALL_ON)
  end
  if(header_io.typef==2)begin
    `uvm_field_int(header_io,UVM_ALL_ON)
    if(header_io.fmt==2)begin
      `uvm_field_sarray_int(payload_i,UVM_ALL_ON)
    end
    if(header_io.td==1)begin
      `uvm_field_int(ecrc,UVM_ALL_ON)
    end
    `uvm_field_sarray_int(TLP_i,UVM_ALL_ON)
  end
  if(header_mem.typef inside {0,12,13,14})begin//mem
    `uvm_field_int(header_mem,UVM_ALL_ON)
    if(header_mem.fmt==2)begin//mem3dw
      `uvm_field_sarray_int(payload_m,UVM_ALL_ON)
    end
    if(header_mem.td==1)begin
      `uvm_field_int(ecrc,UVM_ALL_ON)
    end
    `uvm_field_sarray_int(TLP_m,UVM_ALL_ON)
  end
  
  //message enabling starts here
  if(header_mem.typef inside {[16:23]})begin//mem
    `uvm_field_int(header_msg,UVM_ALL_ON)
    `uvm_field_int(r,UVM_ALL_ON)
    if(header_msg.fmt==3)begin//mem3dw
      `uvm_field_sarray_int(payload_msg,UVM_ALL_ON)
    end
    if(header_msg.td==1)begin
      `uvm_field_int(ecrc,UVM_ALL_ON)
    end
    `uvm_field_sarray_int(TLP_msg,UVM_ALL_ON)
  end

  `uvm_object_utils_end

  rand bit [31:0] header[3];
  rand bit [31:0] data[3];
  rand bit [31:0] tlp_pkt[6];

  function new(string name = "siv_pcie_tl_sequence_items");
    super.new(name);
  endfunction

  //Constraint: Requester ID
  constraint req_c{
    header_config.requester_id==11;
  }	  
  //Constraint: prefix_size
  constraint prefix_size_c{
    prefix.size()==0;  // by default prefix is zero
  }
  //Constraint for Messages
  
  //Constraint for payload_size for different message codes
  constraint msg_payload_size_c{
    (header_msg.msg_code==MSG_INVALIDATE_REQ)->(header_msg.len==2);
    (header_msg.msg_code==MSG_PTM_RESP)->(header_msg.len==2);
    (header_msg.msg_code==MSG_SET_SLOT_LIMIT)->(header_msg.len==1);
    (header_msg.msg_code==MSG_PTM_RESP && header_msg.fmt==3)->(header_msg.len==1);
    soft (header_msg.msg_code==MSG_VDM_TYPE0 && header_msg.fmt==3)->(header_msg.len==1);
    soft (header_msg.msg_code==MSG_VDM_TYPE1 && header_msg.fmt==3)->(header_msg.len==1);
  }
  
  
  
  //Constraint for MPS
  /********added******/
  /*constraint maximum_payload_size_c{
    MPS==128;// these bits are reserved(It will take last 2 bit(lsb) of address is reserved)
  }*/
  /****************/ 
endclass  
