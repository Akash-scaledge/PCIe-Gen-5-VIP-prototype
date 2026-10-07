temp_ao_comp_data// Unconditional Swap AtomicOp Request
// Swap
// fmt==  010
// 		  011 
// typef= 01101
// Swap
// 010
// 011 0 1101 Unconditional Swap AtomicOp Request
// CAS 010
// 011 0 1110
// bit [31:0] temp_ao_comp_data[$];
// int temp_atomic_cas_count;
// atomic_op_payload[];
// else if(typef_temp==14) begin
//   //               start_add= compl_address+4*len;
//   //               $display("entry 3");
//   for(int i=0;i<(len/2);i++)begin
//     `uvm_info("INSIDE THE COMPL_HEADER",$psprintf("atomicop coming here and starting address=%0h",start_add),UVM_NONE);
//     payload_m[i]={mem_space[((start_add)+(4*(len-i)))-4],mem_space[((start_add)-3+(4*(len-i)))],mem_space[((start_add)-2+(4*(len-i)))],mem_space[((start_add)-1+(4*(len-i)))]};
//     //                 `uvm_info("ATOMICOP NEW MEMORY SPACE VALUE ",$psprintf("********payload_m=%0h and start_add=%0h and i=%0h and a mem_space valus is=%0h   and the value of the calculated address= %0h ***",payload_m[i],start_add,i,mem_space[((start_add)+(4*(len-i)))],((start_add)+(4*(len-i)))),UVM_LOW)
//   end
//   `uvm_info("INSIDE THE ATOMICOP_COMP MADE",$sformatf("The payload for atomicop write to do inside the memory is given by=%0p",atomic_op_payload),UVM_NONE)
//   for(int i=0;i<len/2;i++) begin
//     for(int j=0;j<4;j++) begin
//       if(mem_space[start_add+temp_value+j]==temp_ao_comp_data[i]) begin
//         mem_space[start_add+temp_value+j]=atomic_op_payload[i][8*j+:8];
//         //                   `uvm_info("ATOMICOP NEW MEMORY SPACE VALUE ",$psprintf("********mem_space=%p and start_add=%0h and j=%0h and atomic_op_payload=%h ***",mem_space,start_add,j,atomic_op_payload[i][8*j+:8]),UVM_LOW)
//       end
//     end
//     temp_value+=4;
//   end
// end





// typedef struct packed {
//   bit [2:0] fmt;            // 010=Msg, 011=MsgD
//   bit [4:0] typef;          // Msg/(MsgD)
//   bit       rsvd1;
//   bit [2:0] tc;
//   bit       rsvd2;
//   bit       attr1;
//   bit       rsvd3;
//   bit       th;
//   bit       td;
//   bit       ep;
//   bit [1:0] attr2;
//   bit [1:0] at;             // must be zero
//   bit [9:0] len;            // payload DW length
//   bit [15:0] requester_id;
//   bit [7:0]  tag;
//   pcie_msg_code_e msg_code;// must fill DW2 byte 3
//   bit [31:0] rsvd4;//byte 8 to 11 are reserved
//   bit [31:0] rsvd5;//byte 12 to 15 are resevered
// } msg_header_field;//Common Message request header
// typedef enum bit [7:0] {
//    MSG_PTM_REQ        = 8'h52,
//   MSG_PTM_RESP       = 8'h53,
//   MSG_UNLOCK		 = 8'h00,
//   MSG_LTR  			 = 8'h10,
//   MSG_OBFF			 = 8'h12,
//   MSG_INVALIDATE_REQ = 8'h01,
//   MSG_INVALIDATE_COMP= 8'h02,
//   MSG_PAGE_REQ		 = 8'h04,
//   MSG_PRG_RESP		 = 8'h05,
//   MSG_PM_PME		 = 8'h18,
//   MSG_SET_SLOT_LIMIT = 8'h50,
//   MSG_PME_TURN_OFF   = 8'h19,
//   MSG_PME_ACK        = 8'h1B,
//   MSG_INTX_ASSERT    = 8'h20,
//   MSG_INTX_DEASSERT  = 8'h21,
//   MSG_VDM_TYPE0      = 8'h7E,
//   MSG_VDM_TYPE1      = 8'h7F
// } pcie_msg_code_e;

// rand msg_header_field header_msg;//Message header
//   rand bit [31:0] payload_msg[$];//Message Payload
//   bit [31:0]TLP_msg[$];//Message TLP
// rand bit [2:0] r;


//271 line after that added the message completion//but message has no completion so did not add
//306 line packet_tc
//validate tc_vc_before_packet---> go to tcvc map
// 406
// do unpack() 
//   display_pkt()
// 420 line do the msg_write()
// bit [7:0]  message_code;
//779
// bit [31:0] msg_rsvd1;
//   bit [31:0] msg_rsvd2;
//  bit [31:0] payload_msg[];
//1013 line now
// update_vc_io_usage
// display_vc_memory_stats