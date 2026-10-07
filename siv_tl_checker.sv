module tl_checker(rc_tx_data,rc_rx_data,clk,rst);
  input reg clk,rst;
  input bit [31:0] rc_tx_data,rc_rx_data;
  siv_pcie_tl_sequence_items item=new();
  bit [31:0] rc_tlp_pkt_queue[$];
  bit [31:0] ep_tlp_pkt_queue[$];
  bit [31:0] rc_tx_data_pkt[$];
  bit [31:0] rc_rx_data_pkt[$];
  //     bit [31:0] hdr [$];
  struct {bit [2:0] fmt ;
          bit [4:0] typef ;
          bit [2:0] tc;
          bit reserve1;
          bit attr1;
          bit ln;
          bit reserve2;
          bit reserve3;
          bit th;
          bit ep;
          bit [1:0] at;
          bit [1:0] attr2;
          bit [15:0] requester_id;
          bit [7:0] tag;
          bit td ;        // TD bit (ECRC present)
          bit[9:0] len;
          bit[3:0] first_be;} request_header;
  int length;
  int pkt_start;
  int pkt_length;
  bit [31:0] payload_c[$],payload_m[$],payload_io[$];
  int pc_m,pc_c,pc_io;//payload count for memory,config,io
//   int clk_pc_m;//clockwise pc_m count
  //   int request_header_dw_count ;
  //   int expected;
  //   uvm_config_db#(siv_tl_intf)::get(uvm_root::get(*),"vif",rc_if);
  
  always #5 $display("size=%0d payload=%p,	td=%0d",pc_io,payload_io,request_header.td,$time);
  
  initial begin
    forever begin
      wait(rst==0 && rc_tx_data);
      @(posedge clk);
      pkt_start=1;
      rc_tx_data_pkt.push_back(rc_tx_data);
      if(rc_tx_data_pkt.size()==1) begin
        //         hdr=rc_tx_data_pkt[0];
        request_header.fmt=rc_tx_data_pkt[0][31:29];
        request_header.typef=rc_tx_data_pkt[0][28:24];
        request_header.reserve1=rc_tx_data_pkt[0][23];
        request_header.tc=rc_tx_data_pkt[0][22:20];
        request_header.reserve2=rc_tx_data_pkt[0][19];
        request_header.attr1=rc_tx_data_pkt[0][18];
        request_header.ln=rc_tx_data_pkt[0][17];
        request_header.th=rc_tx_data_pkt[0][16];
        request_header.td=rc_tx_data_pkt[0][15];
        request_header.ep=rc_tx_data_pkt[0][14];
        request_header.attr2=rc_tx_data_pkt[0][13:12];
        request_header.at=rc_tx_data_pkt[0][11:10];
        request_header.len=rc_tx_data_pkt[0][9:0];
        `uvm_info("INSIDE CHECKER",$sformatf("Now the packet value\n ---------------------------------------------------\n fmt=%0h typef=%0h reserve1=%0h tc=%0h reserve2=%0h attr1=%0h ln=%0h th=%0h td=%0h ep=%0h attr2=%0h at=%0h len=%0h ",request_header.fmt,request_header.typef,request_header.reserve1,request_header.tc,request_header.reserve2,request_header.attr1,request_header.ln,request_header.th,request_header.td,request_header.ep,request_header.attr2,request_header.at,request_header.len),UVM_NONE)
        length=get_length(rc_tx_data_pkt[0]);
        for(int i=0;i<length-1; i++) begin
          @(posedge clk);
          if(rc_tx_data_pkt.size()==2) request_header.first_be=rc_tx_data_pkt[1][3:0];
          if(request_header.fmt==2 && request_header.typef==0)begin
            if (i>=2)
              payload_m.push_back(rc_tx_data);
          end
          else if (request_header.fmt==3 && request_header.typef==0) begin 
            if (i>2)
              payload_m.push_back(rc_tx_data);
          end
          else if (request_header.fmt==2 && (request_header.typef==4 || request_header.typef==5)) begin
            if (i>1) 
              payload_c.push_back(rc_tx_data);   
          end
          else if (request_header.fmt==3 && (request_header.typef==4 || request_header.typef==5)) begin
            if (i>2) 
              payload_c.push_back(rc_tx_data);
          end
          else if (request_header.fmt==2 && request_header.typef==2) begin
            if (i>1) begin
              payload_io.push_back(rc_tx_data);
              $display("######################### %0p",payload_io);
            end
          end
          else if (request_header.fmt==3 && request_header.typef==2) begin
            if (i>2) 
              payload_io.push_back(rc_tx_data);
          end
//           `uvm_info("In CHECKER",$sformatf("The packet is=%0s and the payload is \n ___________________________________\n %0p",(request_header.typef==0)?"Memory":(request_header.typef==4 || request_header.typef==5)?"Config":(request_header.typef==2)?"I/O":"Undefined",(request_header.typef==0)?payload_m:(request_header.typef==4 || request_header.typef==5)?payload_c:(request_header.typef==2)?payload_io:payload_m),UVM_NONE)
          pc_m=payload_m.size();
          pc_c=payload_c.size();
          pc_io=payload_io.size();
          rc_tx_data_pkt.push_back(rc_tx_data);
        end
        pkt_length=(request_header.td==1)?rc_tx_data_pkt.size()-1:rc_tx_data_pkt.size();
        `uvm_info("INSIDE CHECKER",$sformatf("Now the rc_packet is=\n ----------------------------------------------\n rc_packet=%0p length=%0h first_be=%0h",rc_tx_data_pkt,get_length(rc_tx_data_pkt[0]),request_header.first_be),UVM_NONE)
        @(posedge clk);
        rc_tx_data_pkt.delete();
//         clk_pc_m=0;//make the count of clockwise memory payload size 0 
        pkt_start=0;//trying this to debug typef=0 and fmt=0 scenario
        //         end
        `uvm_info("INSIDE CHECKER",$sformatf("Now the rc_packet is=\n ----------------------------------------------\n rc_packet=%0p length=%0h",rc_tx_data_pkt,get_length(rc_tx_data_pkt[0])),UVM_NONE)
      end
    end
  end
  function int get_length(bit [31:0]hdr_field);
    int tot_length;
    if(hdr_field[31:29]==0) begin
      if(hdr_field[15]) begin
        tot_length=4;
      end
      else begin
        tot_length=3;
      end
    end
    else if(hdr_field[31:29]==1) begin
      if(hdr_field[15]) begin
        tot_length=5;
      end
      else begin
        tot_length=4;
      end
    end
    else if(hdr_field[31:29]==2) begin
      if(hdr_field[15]) begin
        tot_length=4+ hdr_field[9:0];
      end
      else begin
        tot_length=3+hdr_field[9:0];
      end
    end
    else if(hdr_field[31:29]==3) begin
      if(hdr_field[15]) begin
        tot_length=5+ hdr_field[9:0];
      end
      else begin
        tot_length=4+hdr_field[9:0];
      end
    end
    //       else if(hdr_field[31:29]==4) begin
    //         if(hdr_field[15]) begin
    //           tot_length=5+ hdr_field[9:0];
    //         end
    //         else begin
    //           tot_length=4+hdr_field[9:0];
    //         end
    //       end
    return tot_length;
  endfunction



  //Assertion check starter-
  //Assertion for length check for 3dw request_header type value with no data
//   property length_check ;
//     @(posedge clk) disable iff(rst==1) 
//     (request_header.fmt==0 && request_header.td==0)|-> ##[0:2] length==3;
//   endproperty
//     LENGTH_CHECK:assert property(length_check) `uvm_info("IN ASSERTION LENGTH CHECK",$sformatf("fmt=%0h and length=%0h",request_header.fmt,length),UVM_NONE);
//       else
//         `uvm_warning("LENGTH CHECK","Assertion failed");


  //valid assertion starts from here
  //Length check with payloads
  //Working fine
  property length_check2 ;
    @(posedge clk) disable iff(rst==1)
    ((request_header.fmt==3 && request_header.td==0 &&pkt_start==1) |-> ##[0:2] length>4);
  endproperty
      LENGTH_CHECK2:assert property(length_check2) `uvm_info("IN ASSERTION LENGTH2 CHECK",$sformatf("fmt=%0h and length2=%0h",request_header.fmt,length),UVM_NONE)
        else
          `uvm_warning("LENGTH2 CHECK","Assertion failed");

  //Invalid read request or malformed tlp check
  //for 3dw it is working fine; for 4dw it is not checked because the address is not defined and code is not written
  property read_request_tlp_length ;
    @(posedge clk) disable iff(rst==1)
    (request_header.fmt==0 && request_header.typef==0 && request_header.td==0 &&pkt_start==1 ) |-> ##[0:1] length==3 ;
  endproperty
            READ_REQUEST_TLP_LEGNTH:assert property(read_request_tlp_length) `uvm_info("IN ASSERTION NO PAYLOAD READ REQUEST FOR 3 DW request_header",$sformatf("fmt=%0h td=%0h and typef=%0h and length=%0h",request_header.fmt,request_header.td,request_header.typef,length),UVM_NONE)
              else
                `uvm_warning("LENGTH CHECK FOR READ 3 DW request_header","Assertion failed");
  property read_request_tlp_length_type_2 ;
    @(posedge clk) disable iff(rst==1)
    ((request_header.fmt==1) && request_header.typef==0 && request_header.td==0 &&pkt_start==1 ) |-> ##[0:1] length==4 ;
  endproperty
              READ_REQUEST_TLP_LEGNTH_TYPE_2:assert property(read_request_tlp_length_type_2) `uvm_info("IN ASSERTION NO PAYLOAD READ REQUEST FOR 4DW request_header",$sformatf("fmt=%0h td=%0h and typef=%0h and length=%0h",request_header.fmt,request_header.td,request_header.typef,length),UVM_NONE)
                else
                  `uvm_warning("LENGTH CHECK FOR READ 4 DW request_header","Assertion failed");
  // CONFIG and io writes tmust have one payload only.
  //For config it is working and io also it is working
  property io_write_payload;
    @(posedge clk) disable iff(rst==1)
    (request_header.typef==2)|-> (request_header.fmt==2||request_header.fmt==3) |-> ##[0:4] pc_io==(1+request_header.td);
  endproperty
  IO_WRITE_PAYLOAD:assert property(io_write_payload) `uvm_info("IN ASSERTION IO PAYLOAD",$sformatf("The value of header type packet=%s and its payload size is=%0h",(request_header.typef==2)?"IO type":"Ur",pc_io),UVM_NONE)
    else
      `uvm_warning("PAYLOAD LENGTH 1DW FOR IO","Assertion failed");
  property config_write_payload;
    @(posedge clk) disable iff(rst==1)
    (request_header.typef inside {4,5})|-> (request_header.fmt==2||request_header.fmt==3) |-> ##[0:4] pc_c==1;
  endproperty
  CONFIG_WRITE_PAYLOAD:assert property(config_write_payload) `uvm_info("IN ASSERTION CONFIG PAYLOAD",$sformatf("The value of header type packet=%s and its payload size is=%0h","CONFIG type",pc_c),UVM_NONE)
    else
      `uvm_warning("PAYLOAD LENGTH 1DW FOR IO","Assertion failed");
  //ECRC Present or not for io/config 			//Logic looks fine but ecrc is not implemented
    
  property ecrc_present;
    @(posedge clk) disable iff(rst==1)
    (request_header.td==1 && (request_header.typef inside {2,4,5}))|->##4 (length-pkt_length)==1;
  endproperty
  ECRC_PRESENT:assert property(ecrc_present) `uvm_info("IN ASSERTION IO PAYLOAD",$sformatf("The value of header type packet=%s and its payload size is=%0h",(request_header.typef==4|| request_header.typef==5)?"CONFIG type":(request_header.typef==2)?"IO":"Ur",length),UVM_NONE)
    else
      `uvm_warning("PAYLOAD LENGTH 1DW FOR IO","Assertion failed");
  
  //How to check for memory assertion for td bit high?
  
  
  //   Length vs captured payload DWs (no truncation) for memory //working fine
//   sequence len_check;
// //     request_header.len ==pc_m-2;  //Error condition to check where the timing starts
//     request_header.len==pc_m;
//   endsequence
//   property len_payload_size_check;
//     @(posedge clk) disable iff(rst==1)
//     ((request_header.fmt==2|| request_header.fmt==3) && request_header.typef==0 )|-> ##[0:1024] len_check;
//   endproperty
//      LEN_PAYLOAD_SIZE_CHECK: assert property(len_payload_size_check) `uvm_info("IN ASSERTION MEM PAYLOAD",$sformatf("The value of header type packet=%s and its payload size is=%0h","Memory WRITE",request_header.len),UVM_NONE)
//     else
//       `uvm_warning("PAYLOAD SIZE IS NOT EQUAL TO LENGTH","Assertion failed");
  //For 5 payload the timing starts from the 425 and checks till a lot of time
   
  //first byte enable are in a range of values for the io and config write  //working fine
  property config_io_first_be;
    @(posedge clk) disable iff(rst==1)
    ((request_header.fmt==2|| request_header.fmt==3) && (request_header.typef inside {2,4,5}))|-> ##[0:5] request_header.first_be inside {8,12,14,15};
  endproperty
  CONFIG_IO_FIRST_BE: assert property(config_io_first_be) `uvm_info("IN ASSERTION BE FOR CONFIG AND IO",$sformatf("The value of header type packet=%s and its First BE is=%0h",(request_header.typef==2)?"IO":(request_header.typef==4|| request_header.typef==5)?"CONFIG":"Invalid"  ,request_header.first_be),UVM_NONE)
    else
      `uvm_warning("First BE is not all 1s","Assertion failed");
      
      
      
//   //Trying no completion till if i get posted header //working fine
  property p_posted_no_completion;
   @(posedge clk) disable iff(rst==1)
  pkt_start &&
    (request_header.fmt inside {2,3}) && (request_header.typef inside {5'd0})
    |-> ##[0:5] rc_rx_data==0;
endproperty
  P_POSTED_NO_COMPLETION:assert property(p_posted_no_completion) `uvm_info("IN ASSERTION COMPLETION FOR MEMORY",$sformatf("The value of header type packet=%s and its Completion is=%0h","Memory"  ,rc_rx_data),UVM_NONE)
      else
        `uvm_warning("IN ASSERTION TO CHECK POSTED COMPLETIOn","Assertion failed");
    
        //did this for the 5 payload size timing constraint problem for higher order payloads or variable payloads.
endmodule
      



