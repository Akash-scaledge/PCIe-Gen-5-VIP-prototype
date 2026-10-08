class siv_pcie_tl_seq extends uvm_sequence #(siv_pcie_tl_sequence_items);
  `uvm_object_utils(siv_pcie_tl_seq)
  virtual siv_tl_if tl_intf;
  siv_tl_cfg device_cfg;
  bit[2:0] mps_in_seq;
  bit[12:0] mps_in_bytes;
  bit[2:0] mrrs_in_seq;
  bit[12:0] mrrs_in_bytes;
  bit[0:0] rcb_in_seq;
  bit[7:0] rcb_in_bytes;
  
  function new(string name="siv_pcie_tl_seq");
    super.new(name);
  endfunction
  
  task pre_body();
  /*  if (!uvm_config_db#(virtual siv_tl_if)::get(null, "", "vif", tl_intf)) begin
    
    `uvm_fatal("CFG_ERR", "Failed to get physical interface handle")
  end*/

  // Get device_cfg from driver
    if (!uvm_config_db#(siv_tl_cfg)::get(null,get_full_name(),"device_cfg", device_cfg)) begin
    `uvm_fatal("CFG_ERR", "Failed to get device configuration from driver")
  end
    $display("-----is_rc=%0d-----------",device_cfg.is_rc);
  endtask
 
   task post_body();
     #100;
    mps_in_seq = device_cfg.get_mps();
     $display("Value of mps from task post_body is = %0b", mps_in_seq);
    case(mps_in_seq)
      3'b000 : mps_in_bytes = 128;
      3'b001 : mps_in_bytes = 256;
      3'b010 : mps_in_bytes = 512;
      3'b011 : mps_in_bytes = 1024;
      3'b100 : mps_in_bytes = 2048;
      3'b101 : mps_in_bytes = 4096;
      default : $display("Invalid MPS value");
    endcase
     $display("Value of mps_in_bytes from task post_body is = %0d", mps_in_bytes);
    
    mrrs_in_seq = device_cfg.get_mrrs();
     $display("Value of mrrs from task post_body is = %0b", mrrs_in_seq);
    case(mrrs_in_seq)
      3'b000 : mrrs_in_bytes = 128;
      3'b001 : mrrs_in_bytes = 256;
      3'b010 : mrrs_in_bytes = 512;
      3'b011 : mrrs_in_bytes = 1024;
      3'b100 : mrrs_in_bytes = 2048;
      3'b101 : mrrs_in_bytes = 4096;
      default : $display("Invalid MRRS value");
    endcase
     $display("Value of mrrs_in_bytes from task post_body is = %0d", mrrs_in_bytes);
    
    rcb_in_seq = device_cfg.get_rcb();
     $display("Value of rcb from task post_body is = %0b", rcb_in_seq);
    case(rcb_in_seq)
      1'b0 : rcb_in_bytes = 64;
      1'b1 : rcb_in_bytes = 128;
      
      default : $display("Invalid RCB value");
    endcase
    $display("Value of rcb_in_bytes from task post_body is = %0d", rcb_in_bytes);     
  endtask
endclass

//seq for write and read of the I/O packet
class io_wr_rd_seq extends siv_pcie_tl_seq;
  `uvm_object_utils(io_wr_rd_seq)
  function new(string name="siv_pcie_tl_seq");
    super.new(name);
  endfunction
  task body();
    //if device is rc it enter the loop and start sendin
    if(device_cfg.is_rc) begin
      
      repeat(1) begin
        
         `uvm_do_with(req, {req.pkt_type == 3;             //io write
      						req.header_io.typef == 2;
     						req.header_io.fmt == 2;// 3DW + data
      						req.header_io.td ==1;
      						req.header_io.address == 32'h0000_1000;
                            req.header_io.len ==1;
                            req.header_io.tc == 2;
                            req.header_io.last_dw ==4'b0000;
                            req.header_io.first_dw ==4'b1111;
                            req.payload_i.size() == req.header_io.len;});
      end
      repeat(1) begin
        
        `uvm_do_with(req, {	req.pkt_type == 3;             //io read
      						req.header_io.typef == 2;
      						req.header_io.fmt == 0;// 3DW header, no data
      						req.header_io.td == 1;
      						req.header_io.address == 32'h0000_1000;
      						req.header_io.len == 1;
                            req.header_io.tc == 3;
                            req.header_io.last_dw ==4'b0000;
                            req.header_io.first_dw ==4'b1111;
                            req.payload_i.size() == req.header_io.len;});       
      end
    end
  endtask 
endclass

//seq for write and read of the memory packet
class mem_wr_rd_seq extends siv_pcie_tl_seq;
  `uvm_object_utils(mem_wr_rd_seq)
  function new(string name="siv_pcie_tl_seq");
    super.new(name);
  endfunction
  task body();begin
    if(device_cfg.is_rc)begin
//       `uvm_warning(get_type_name(),"///////////////////INSIDE TL SEQUENCE/////////////////////////////");
      repeat(1) begin
        `uvm_do_with(req, {req.pkt_type == 2;             //memory write
                           req.header_mem.typef == 0;
                           req.header_mem.fmt == 2;
                           req.header_mem.td == 0;
                           req.header_mem.tc == 0;
                           req.header_mem.address1 == 32'h1000;
                           req.header_mem.len ==3;
                           req.payload_m.size() == req.header_mem.len;});

      end
//       `uvm_warning(get_type_name(),"///////////////////AFTER UVM DO/////////////////////////////");
      repeat(1) begin
        `uvm_do_with(req, {req.pkt_type == 2;             //memory read
                           req.header_mem.typef == 0;
                           req.header_mem.fmt == 0;
                           req.header_mem.td == 0;//ecrc not implemented
                           req.header_mem.tc == 3;
                           req.header_mem.address1 == 32'h1000;
                           req.header_mem.len ==3;
                           req.payload_m.size() == req.header_mem.len;
                          });
      end  
//       `uvm_warning(get_type_name(),"///////////////////LAST UVM DO DONE/////////////////////////////");
    end
  end
  endtask 
endclass


//seq for write and read byte enable of the memory packet
class mem_wr_rd_byte_enable_seq extends siv_pcie_tl_seq;
  `uvm_object_utils(mem_wr_rd_byte_enable_seq)
  function new(string name="siv_pcie_tl_mem_byte_enable_seq");
    super.new(name);
  endfunction
  task body();
    //if device is rc it enter the loop and start sendin
    if(device_cfg.is_rc) begin
      
      repeat(1) begin
          `uvm_do_with(req, {req.pkt_type == 2;             //memory write
      						req.header_mem.typef == 0;
     						req.header_mem.fmt == 2;
      						req.header_mem.td == 1;
                            req.header_mem.tc == 4;
      						req.header_mem.address == 32'h1000;
      						req.header_mem.len ==3;
                            req.header_mem.last_dw==3;
                            req.header_mem.first_dw==12;
                            req.payload_m.size() == req.header_mem.len;});
      end
      repeat(1)begin
          `uvm_do_with(req, {req.pkt_type == 2;             //memory read
      						req.header_mem.typef == 0;
      						req.header_mem.fmt == 0;
      						req.header_mem.td == 1;
                            req.header_mem.tc == 4;
      						req.header_mem.address == 32'h1000;
      						req.header_mem.len ==3;
                            req.header_mem.last_dw==4'b0011;//read is always 1111 as per specs and it is not being overriden. Sanity test done
                            req.header_mem.first_dw==4'b1100;
                            req.payload_m.size() == req.header_mem.len;
                            });
        end
    end
  endtask 
endclass


//seq for zero write and read byte enable of the memory packet
class mem_wr_rd_zero_length_write_seq extends siv_pcie_tl_seq;
  `uvm_object_utils(mem_wr_rd_zero_length_write_seq)
  function new(string name="mem_wr_rd_zero_length_write_seq");
    super.new(name);
  endfunction
  task body();
    //if device is rc it enter the loop and start sendin
    if(device_cfg.is_rc) begin
      
      repeat(1) begin
          `uvm_do_with(req, {req.pkt_type == 2;             //memory write
      						req.header_mem.typef == 0;
     						req.header_mem.fmt == 2;
      						req.header_mem.td == 0;
                            req.header_mem.tc == 4;
      						req.header_mem.address1 == 32'h1000;
      						req.header_mem.len ==3;
                            req.header_mem.last_dw==4'b0000;
                            req.header_mem.first_dw==4'b0000;
                            req.payload_m.size() == req.header_mem.len;});
      end
      repeat(1)begin
          `uvm_do_with(req, {req.pkt_type == 2;             //memory read
      						req.header_mem.typef == 0;
      						req.header_mem.fmt == 0;
      						req.header_mem.td == 0;
                            req.header_mem.tc == 4;
      						req.header_mem.address1 == 32'h1000;
      						req.header_mem.len ==3;
                            req.payload_m.size() == req.header_mem.len;
                            });
        end
    end
  endtask 
endclass

//seq for write and read invalid AT field of the memory packet
class mem_wr_rd_invalid_at_seq extends siv_pcie_tl_seq;
  `uvm_object_utils(mem_wr_rd_invalid_at_seq)
  function new(string name="siv_pcie_tl_mem_invalid_at_seq");
    super.new(name);
  endfunction
  task body();
    //if device is rc it enter the loop and start sendin
    if(device_cfg.is_rc) begin
      
      repeat(1) begin
          `uvm_do_with(req, {req.pkt_type == 2;             //memory write
      						req.header_mem.typef == 0;
     						req.header_mem.fmt == 2;
      						req.header_mem.td == 0;
                            req.header_mem.tc == 4;
      						req.header_mem.address1 == 32'h1000;
      						req.header_mem.len ==1;
                            req.header_mem.last_dw==3;
                            req.header_mem.first_dw==12;
                            req.payload_m.size() == req.header_mem.len;});
      end
      repeat(1)begin
          `uvm_do_with(req, {req.pkt_type == 2;             //memory read
      						req.header_mem.typef == 0;
      						req.header_mem.fmt == 0;
      						req.header_mem.td == 0;
                            req.header_mem.tc == 4;
                            req.header_mem.at==2'b11; 
      						req.header_mem.address1 == 32'h1000;
      						req.header_mem.len ==1;
                            req.header_mem.last_dw==4'b0011;//read is always 1111 as per specs and it is not being overriden. Sanity test done
                            req.header_mem.first_dw==4'b1100;
                            req.payload_m.size() == req.header_mem.len;
                            });
        end
    end
  endtask 
endclass


//seq for write and read of the config packet
class config_wr_rd_seq extends siv_pcie_tl_seq;
  `uvm_object_utils(config_wr_rd_seq)
  function new(string name="siv_pcie_tl_seq");
    super.new(name);
  endfunction
  task body();
    //if device is rc it enter the loop and start sendin
    if(device_cfg.is_rc) begin
      repeat(1) begin
        `uvm_do_with(req,{req.pkt_type == 1; // config write
          				  req.header_config.typef == 4;
                          req.header_config.fmt==2;
                          req.header_config.len==1;
                          req.header_config.td==1;
                          req.payload_c.size()==req.header_config.len;
                          req.header_config.reg_no=='h50;
                          req.payload_c[0]==16'h8888;}); // this seq for the RCB purpose if 8880 == 64; 8888==128
      end
      repeat(1) begin       
        `uvm_do_with(req,{ req.pkt_type == 1;// config read 
                         req.header_config.typef == 4;
                         req.header_config.fmt==0;
                         req.header_config.td==1;
                         req.header_config.len==1;
                         req.payload_c.size()== req.header_config.len;
                         req.header_config.reg_no=='h48;
                         });
      end
    end
  endtask 
endclass


class mem_write_read_64_seq extends siv_pcie_tl_seq;	//write read both 64
  `uvm_object_utils(mem_write_read_64_seq)
  function new(string name=" ");
    super.new(name);
  endfunction


  task body();
    //if device is rc it enter the loop and start sendin
    if(device_cfg.is_rc) begin
      repeat(1)
      `uvm_do_with(req, {req.pkt_type == 2;             //memory
                         req.header_mem.typef == 0;
                         req.header_mem.fmt == 3;		//write
                         req.header_mem.td == 1;
                         req.header_mem.first_dw == 4'b0111;
                         req.header_mem.last_dw == 4'b1111;
                         {req.header_mem.address1,req.header_mem.address} == 64'h1245_6212_4523_2523;
                         req.header_mem.len ==3;
                         req.payload_m.size() == req.header_mem.len;});
      $display("after randomize %p",req);


      repeat(1)
        `uvm_do_with(req, {req.pkt_type == 2;             //memory
                           req.header_mem.typef == 0;
                           req.header_mem.fmt == 1;		//read
                           req.header_mem.td == 1;
                           req.header_mem.first_dw == 4'b1111;
                           req.header_mem.last_dw == 4'b1111;
                           {req.header_mem.address1,req.header_mem.address} == 64'h1245_6212_4523_2523;
                           req.header_mem.len == 3;
                           req.payload_m.size() == req.header_mem.len;});
      $display("after randomize %p",req);

    end
    else// device is ep
      begin
      end
  endtask
endclass








//First byte enable and its behaviour for memory write and read
class seq_mem_wr_rd_first_dw_be extends siv_pcie_tl_seq;
  `uvm_object_utils(seq_mem_wr_rd_first_dw_be)
  function new(string name="seq_mem_wr_rd_first_dw_be");
    super.new(name);
  endfunction
  task body();
    if(device_cfg.is_rc) begin
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory write
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 2;
                          req.header_mem.td == 0;
                          req.header_mem.requester_id==34;
                          req.header_mem.first_dw== 4'b1100;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==1;
                          req.payload_m.size() == req.header_mem.len;});
      end
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory read
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 0;
                          req.header_mem.td == 0;
                          req.header_mem.requester_id==34;
                          req.header_mem.first_dw==15;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==1;
                          req.payload_m.size() == req.header_mem.len;});
      end
    end
  endtask
endclass


//0 length memory write
class seq_mem_wr_zero_length extends siv_pcie_tl_seq;
  `uvm_object_utils(seq_mem_wr_zero_length)
  function new(string name="seq_mem_wr_zero_length");
    super.new(name);
  endfunction
  task body();
    if(device_cfg.is_rc) begin
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory write
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 2;
                          req.header_mem.td == 0;
                          req.header_mem.requester_id==34;
                          req.header_mem.first_dw== 4'b0000;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==1;
                          req.payload_m.size() == req.header_mem.len;});
      end
    end
  endtask
endclass
//Trying 0 length memory read
class seq_mem_wr_zero_rd_length extends siv_pcie_tl_seq;
  `uvm_object_utils(seq_mem_wr_zero_rd_length)
  function new(string name="seq_mem_wr_zero_rd_length");
    super.new(name);
  endfunction
  task body();
    if(device_cfg.is_rc) begin
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory write
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 2;
                          req.header_mem.td == 0;
                          req.header_mem.requester_id==34;
                          req.header_mem.first_dw== 4'b1111;
                          req.header_mem.last_dw== 4'b1111;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==3;
                          req.payload_m.size() == req.header_mem.len;});
      end
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory read
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 0;
                          req.header_mem.td == 0;
                          req.header_mem.requester_id==34;
                          req.header_mem.first_dw==0;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==1;
                          req.payload_m.size() == req.header_mem.len;});
      end
    end
  endtask
endclass
//trying relax ordering
class seq_mem_wr_rd_ro extends siv_pcie_tl_seq;
  `uvm_object_utils(seq_mem_wr_rd_ro)
  function new(string name="seq_mem_wr_rd_ro");
    super.new(name);
  endfunction
  task body();
    if(device_cfg.is_rc) begin
      fork 
        begin
          repeat(1)begin
            `uvm_do_with(req,{req.pkt_type == 2;             //memory write
                              req.header_mem.typef == 0;
                              req.header_mem.fmt == 2;
                              req.header_mem.td == 0;
                              req.header_mem.requester_id==34;
                              req.header_mem.first_dw== 4'b1111;
                              req.header_mem.last_dw== 4'b1111;
                              req.header_mem.address1 == 32'h0000_3000;
                              req.header_mem.attr2==0;
                              req.header_mem.len ==3;
                              req.header_mem.ep==1;
                              req.payload_m.size() == req.header_mem.len;});
          end
        end
        begin
          repeat(1) begin
            `uvm_do_with(req,{req.pkt_type == 2;             //memory write
                              req.header_mem.typef == 0;
                              req.header_mem.fmt == 2;
                              req.header_mem.td == 0;
                              req.header_mem.requester_id==34;
                              req.header_mem.first_dw== 4'b1111;
                              req.header_mem.last_dw== 4'b1111;
                              req.header_mem.address1 == 32'h0000_4000;
                              req.header_mem.attr2==2;
                              req.header_mem.len ==3;
                              req.payload_m.size() == req.header_mem.len;});
          end
        end
      join
      fork
        repeat(1)begin
          `uvm_do_with(req,{req.pkt_type == 2;             //memory read
                            req.header_mem.typef == 0;
                            req.header_mem.fmt == 0;
                            req.header_mem.td == 0;
                            req.header_mem.requester_id==34;
                            req.header_mem.first_dw==0;
                            req.header_mem.address1 == 32'h0000_3000;
                            req.header_mem.len ==3;
                            req.header_mem.attr2==0;
                            req.header_mem.ep==0;
                            req.payload_m.size() == req.header_mem.len;});
        end
        repeat(1)begin
          `uvm_do_with(req,{req.pkt_type == 2;             //memory read
                            req.header_mem.typef == 0;
                            req.header_mem.fmt == 0;
                            req.header_mem.td == 0;
                            req.header_mem.requester_id==34;
                            req.header_mem.first_dw==0;
                            req.header_mem.address1 == 32'h0000_4000;
                            req.header_mem.len ==3;
                            req.header_mem.attr2==2;
                            req.payload_m.size() == req.header_mem.len;});
        end
      join
    end
  endtask
endclass



//One i/o write and read try with 1 length 
class seq_io_wr_rd extends siv_pcie_tl_seq;
  `uvm_object_utils(seq_io_wr_rd)
  function new(string name="seq_io_wr_rd");
    super.new(name);
  endfunction
  task body();
    if(device_cfg.is_rc) begin
      repeat(1) begin
        `uvm_do_with(req,{req.pkt_type == 3;             //io write
                          req.header_io.typef == 2;
                          req.header_io.fmt == 2;
                          req.header_mem.first_dw== 4'b1111;
                          //                           req.header_mem.last_dw== 4'b1111;
                          req.header_io.address == 32'h0000_4000;
                          req.header_io.len ==1;
//                           req.header_io.td==1;//infinity loop because ecrc is not there
                          req.payload_i.size() == req.header_io.len;});
      end
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 3;             //io read
                          req.header_io.typef == 2;
                          req.header_io.fmt == 0;
                          req.header_io.td == 0;
                          req.header_io.requester_id==34;
//                           req.header_io.td==1;//not infinity loop but not working
                          req.header_io.address == 32'h0000_4000;
                          req.header_io.len ==1;
                          req.payload_i.size() == req.header_io.len;});
      end
    end
  endtask
endclass



//Mem write and read test with ecrc (TLP Digest=1)
class mem_wr_rd_td_seq extends siv_pcie_tl_seq;
  `uvm_object_utils(mem_wr_rd_td_seq)
  function new(string name="mem_wr_rd_td_seq");
    super.new(name);
  endfunction
  task body();
    if(device_cfg.is_rc) begin
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory write
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 2;
                          req.header_mem.td == 1;
                          req.header_mem.requester_id==34;
                          req.header_mem.first_dw== 4'b1111;
                          req.header_mem.last_dw== 4'b1111;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==3;
                          req.payload_m.size() == req.header_mem.len;});
      end
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory read
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 0;
                          req.header_mem.td == 1;
                          req.header_mem.requester_id==34;
                          req.header_mem.first_dw==15;
                          req.header_mem.last_dw==15;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==3;
                          req.payload_m.size() == req.header_mem.len;});
      end
    end
  endtask
endclass

//Mem write and read test with different tc-vc mapping
class seq_mem_wr_rd_diff_vc extends siv_pcie_tl_seq;
  `uvm_object_utils(seq_mem_wr_rd_diff_vc)
  function new(string name="seq_mem_wr_rd_diff_vc");
    super.new(name);
  endfunction
  task body();
    if(device_cfg.is_rc) begin
      repeat(1) begin
        `uvm_do_with(req,{req.pkt_type == 1; // config write
                          req.header_config.typef == 4;
                          req.header_config.fmt==2;
                          req.header_config.len==1;
                          req.header_config.first_dw==4'b1111;
                          req.header_config.td==0;
                          req.payload_c.size()== req.header_config.len;
                          req.header_config.reg_no==10'h80;

                          req.payload_c[0]==32'h0000_001c;}); // this seq for the port vc resource capability register to set that vc lower priority=vc3 and vc count=5
        
      end
      repeat(1) begin
        `uvm_do_with(req,{req.pkt_type == 1; // config write
                          req.header_config.typef == 4;
                          req.header_config.fmt==2;
                          req.header_config.len==1;
                          req.header_config.first_dw==4'b1111;
                          req.header_config.td==0;
                          req.payload_c.size()== req.header_config.len;
                          req.header_config.reg_no==10'h90;

                          req.payload_c[0]==32'h8000_000f;}); // this seq for the port vc resource control register0 to set that vc 0 is enable and it only supports vc0-1-2-3
        
      end
      repeat(1) begin
        `uvm_do_with(req,{req.pkt_type == 1; // config write
                          req.header_config.typef == 4;
                          req.header_config.fmt==2;
                          req.header_config.first_dw==4'b1111;
                          req.header_config.len==1;
                          req.header_config.td==0;
                          req.payload_c.size()== req.header_config.len;
                          req.header_config.reg_no==10'ha8;

                          req.payload_c[0]==32'h8200_0030;}); // this seq for the port vc resource control register2 to set that vc 2 is enable and it only supports tc4-5
        
      end
      repeat(1) begin       
        `uvm_do_with(req,{ req.pkt_type == 1;// config read 
                          req.header_config.typef == 4;
                          req.header_config.fmt==0;
                          req.header_config.td==1'b0;
                          req.header_config.first_dw==4'b1111;
                          req.header_config.len==1;
                          req.payload_c.size()== req.header_config.len;
                          req.header_config.reg_no==10'h04;
                         });
      end
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory write
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 2;
                          req.header_mem.td == 1;
                          req.header_mem.tc ==3;
                          req.header_mem.requester_id==34;
                          req.header_mem.first_dw== 4'b1111;
                          req.header_mem.last_dw== 4'b1111;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==3;
                          req.payload_m.size() == req.header_mem.len;});
      end
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory write
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 2;
                          req.header_mem.td == 1;
                          req.header_mem.tc ==5;
                          req.header_mem.requester_id==34;
                          req.header_mem.first_dw== 4'b1111;
                          req.header_mem.last_dw== 4'b1111;
                          req.header_mem.address1 == 32'h0000_5000;
                          req.header_mem.len ==3;
                          req.payload_m.size() == req.header_mem.len;});
      end
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory read
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 0;
                          req.header_mem.td == 1;
                          req.header_mem.tc ==3;
                          req.header_mem.requester_id==34;
                          req.header_mem.first_dw==15;
                          req.header_mem.last_dw==15;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==3;
                          req.payload_m.size() == req.header_mem.len;});
      end
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory read
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 0;
                          req.header_mem.td == 1;
                          req.header_mem.tc ==5;
                          req.header_mem.requester_id==34;
                          req.header_mem.first_dw==15;
                          req.header_mem.last_dw==15;
                          req.header_mem.address1 == 32'h0000_5000;
                          req.header_mem.len ==3;
                          req.payload_m.size() == req.header_mem.len;});
      end
    end
  endtask
endclass


//Config one wr rd with td bit high and test
class seq_config_wr_rd_td extends siv_pcie_tl_seq;
  `uvm_object_utils(seq_config_wr_rd_td)
  function new(string name="seq_config_wr_rd_td");
    super.new(name);
  endfunction
  task body();
    //if device is rc it enter the loop and start sendin
    if(device_cfg.is_rc) begin
      repeat(1) begin
        `uvm_do_with(req,{req.pkt_type == 1; // config write
          				  req.header_config.typef == 4;
                          req.header_config.fmt==2;
                          req.header_config.len==1;
                          req.header_config.td==1;
                          req.payload_c.size()== req.header_config.len;
                          req.header_config.reg_no=='h50;
                          req.payload_c[0]==16'h8888;}); // this seq for the RCB purpose if 8880 == 64; 8888==128
      end
      repeat(1) begin       
        `uvm_do_with(req,{ req.pkt_type == 1;// config read 
                         req.header_config.typef == 4;
                         req.header_config.fmt==0;
                         req.header_config.td==1;
                         req.header_config.len==1;
                         req.payload_c.size()== req.header_config.len;
                         req.header_config.reg_no=='h50;
                         });
      end
    end
  endtask 
endclass

//RCB=64 bytes check
class mem_wr_rd_rcb_seq extends siv_pcie_tl_seq;
  `uvm_object_utils(mem_wr_rd_rcb_seq)
  function new(string name="mem_wr_rd_rcb_seq");
    super.new(name);
  endfunction
  task body();
    if(device_cfg.is_rc) begin
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory write
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 2;
                          req.header_mem.td == 0;
//                           req.header_mem.requester_id==34;
                          req.header_mem.first_dw== 4'b1111;
                          req.header_mem.last_dw== 4'b1111;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==60;
                          req.payload_m.size() == req.header_mem.len;});
      end
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory read
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 0;
                          req.header_mem.td == 0;
//                           req.header_mem.requester_id==34;
                          req.header_mem.last_dw==15;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==60;
                          req.payload_m.size() == req.header_mem.len;});
      end
    end
  endtask
endclass


//4dw header format config packet sending
//One config write and read with 1 length
class seq_config_wr_rd_4dw_header extends siv_pcie_tl_seq;
  `uvm_object_utils(seq_config_wr_rd_4dw_header)
  function new(string name="seq_config_wr_rd_4dw_header");
    super.new(name);
  endfunction
  task body();
    //if device is rc it enter the loop and start sendin
    if(device_cfg.is_rc) begin
      repeat(1) begin
        `uvm_do_with(req,{req.pkt_type == 1; // config write
          				  req.header_config.typef == 4;
                          req.header_config.fmt==3;
                          req.header_config.len==1;
                          req.header_config.td==0;
                          req.payload_c.size()== req.header_config.len;
                          req.header_config.reg_no=='h50;
                          req.payload_c[0]==16'h8888;}); // this seq for the RCB purpose if 8880 == 64; 8888==128
      end
      repeat(1) begin       
        `uvm_do_with(req,{ req.pkt_type == 1;// config read 
                         req.header_config.typef == 4;
                         req.header_config.fmt==1;
                         req.header_config.td==1'b0;
                         req.header_config.len==1;
                         req.payload_c.size()== req.header_config.len;
                         req.header_config.reg_no=='h50;
                         });
      end
    end
  endtask 
endclass


//Trying unconditional swap
class seq_unconditional_swap_atomicop extends siv_pcie_tl_seq;
  `uvm_object_utils(seq_unconditional_swap_atomicop)
  function new(string name="seq_unconditional_swap_atomicop");
    super.new(name);
  endfunction
  task body();
    if(device_cfg.is_rc) begin
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory write
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 2;
                          req.header_mem.td == 0;
//                           req.header_mem.requester_id==34;
                          req.header_mem.first_dw== 4'b1111;
                          req.header_mem.last_dw== 4'b1111;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==3;
//                           req.payload_m[0] == 32'h0011_2233;// a dummy write at address
                          req.payload_m.size() == req.header_mem.len;});
      end
//       repeat(1)begin
//         `uvm_do_with(req,{req.pkt_type == 2;             //memory read to check 
//                           req.header_mem.typef == 0;
//                           req.header_mem.fmt == 0;
//                           req.header_mem.td == 0;
// //                           req.header_mem.requester_id==34;
//                           req.header_mem.first_dw==15;
//                           req.header_mem.last_dw==15;
//                           req.header_mem.address1 == 32'h0000_3000;
//                           req.header_mem.len ==1;
//                           req.payload_m.size() == req.header_mem.len;});
//       end
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory read to check 
                          req.header_mem.typef == 5'b01101;
                          req.header_mem.fmt == 2;
                          req.header_mem.td == 0;
//                           req.header_mem.requester_id==34;
                          req.header_mem.first_dw==15;
                          req.header_mem.last_dw==15;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==3;
//                           req.payload_m[0]==32'h0022_3344;
                          req.payload_m.size() == req.header_mem.len;});
      end
    end
  endtask
endclass
//unconditional swap for 4dw headers
// seq_unconditional_swap_atomicop_64_bits

class seq_unconditional_swap_atomicop_64_bits extends siv_pcie_tl_seq;
  `uvm_object_utils(seq_unconditional_swap_atomicop_64_bits)
  function new(string name="seq_unconditional_swap_atomicop_64_bits");
    super.new(name);
  endfunction
  task body();
    if(device_cfg.is_rc) begin
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory write
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 3;
                          req.header_mem.td == 0;
//                           req.header_mem.requester_id==34;
                          req.header_mem.first_dw== 4'b1111;
                          req.header_mem.last_dw== 4'b1111;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.address == 32'h0000_1000;
                          req.header_mem.len ==3;
//                           req.payload_m[0] == 32'h0011_2233;// a dummy write at address
                          req.payload_m.size() == req.header_mem.len;});
      end
//       repeat(1)begin
//         `uvm_do_with(req,{req.pkt_type == 2;             //memory read to check 
//                           req.header_mem.typef == 0;
//                           req.header_mem.fmt == 0;
//                           req.header_mem.td == 0;
// //                           req.header_mem.requester_id==34;
//                           req.header_mem.first_dw==15;
//                           req.header_mem.last_dw==15;
//                           req.header_mem.address1 == 32'h0000_3000;
//                           req.header_mem.len ==1;
//                           req.payload_m.size() == req.header_mem.len;});
//       end
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory read to check 
                          req.header_mem.typef == 5'b01101;
                          req.header_mem.fmt == 2;
                          req.header_mem.td == 0;
//                           req.header_mem.requester_id==34;
                          req.header_mem.first_dw==15;
                          req.header_mem.last_dw==15;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.address == 32'h0000_1000;
                          req.header_mem.len ==3;
//                           req.payload_m[0]==32'h0022_3344;
                          req.payload_m.size() == req.header_mem.len;});
      end
    end
  endtask
endclass

//Compare and swap
class seq_compare_and_swap extends siv_pcie_tl_seq;
  `uvm_object_utils(seq_compare_and_swap)
  function new(string name="seq_compare_and_swap");
    super.new(name);
  endfunction
  task body();
    if(device_cfg.is_rc) begin
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory write
                          req.header_mem.typef == 0;
                          req.header_mem.fmt == 2;
                          req.header_mem.td == 0;
//                           req.header_mem.requester_id==34;
                          req.header_mem.first_dw== 4'b1111;
                          req.header_mem.last_dw== 4'b1111;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==1;
                          req.payload_m[0] == 32'h0011_2233;// a dummy write at address
                          req.payload_m.size() == req.header_mem.len;});
      end
//       repeat(1)begin
//         `uvm_do_with(req,{req.pkt_type == 2;             //memory read to check 
//                           req.header_mem.typef == 0;
//                           req.header_mem.fmt == 0;
//                           req.header_mem.td == 0;
// //                           req.header_mem.requester_id==34;
//                           req.header_mem.first_dw==15;
//                           req.header_mem.last_dw==15;
//                           req.header_mem.address1 == 32'h0000_3000;
//                           req.header_mem.len ==1;
//                           req.payload_m.size() == req.header_mem.len;});
//       end
      repeat(1)begin
        `uvm_do_with(req,{req.pkt_type == 2;             //memory read to check 
                          req.header_mem.typef == 5'b01110;
                          req.header_mem.fmt == 2;
                          req.header_mem.td == 0;
//                           req.header_mem.requester_id==34;
                          req.header_mem.first_dw==15;
                          req.header_mem.last_dw==15;
                          req.header_mem.address1 == 32'h0000_3000;
                          req.header_mem.len ==2;
                          req.payload_m[0]==32'h3322_1100;
                          req.payload_m[1]==32'h0022_3344;
                          req.payload_m.size() == req.header_mem.len;});
      end
    end
  endtask
endclass

//PTM Req message
class msg_ptm_req_seq extends siv_pcie_tl_seq;
  `uvm_object_utils(msg_ptm_req_seq)

  function new(string name="msg_ptm_req_seq");
    super.new(name);
  endfunction

  task body();
    if (device_cfg.is_rc) begin

      `uvm_do_with(req, {
        req.pkt_type == 5;
        req.header_msg.fmt  == 3'b001;
        req.header_msg.typef[4:3]==2'b10;
        req.header_msg.td   == 1;
        req.header_msg.at   == 2'b00;
        req.header_msg.msg_code == MSG_PTM_REQ;
      });
    end
  endtask
endclass
































