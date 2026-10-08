//--------------------------------------------------------------
// SIV PCIe Configuration Object (siv_pl_cfg)
//--------------------------------------------------------------
// Used by both Root Complex and Endpoint components
class siv_tl_cfg extends uvm_object;
  `uvm_object_utils(siv_tl_cfg) 
  // Device Configuration
  bit         is_rc;           // 1=RC, 0=EP
  bit         is_active;       // 1=Active link 
  string      inst_name;       // Instance identifier string
  bit[9:0]    reg_no;
  bit[2:0]    mps;
  bit[2:0]    mrrs;
  bit[0:0]    rcb;
  bit[2:0]    vc_count;
  
  // Constructor
  function new(string name = "siv_tl_cfg");
    super.new(name);
  endfunction
  
  virtual function bit[2:0] get_vc();
    reg_no = 'h80;
    vc_count=$root.top.dut.mem[reg_no][2:0];
    $display("Value of extended_vc_count is = %0h", vc_count);
   return vc_count;
  endfunction
  
  virtual function bit[2:0] get_mps();
    reg_no = 'h48;
   // $display("Value of max_payload_size is = %0h", $root.top.dut.mem[reg_no]);
    mps=$root.top.dut.mem[reg_no][7:5];
    $display("Value of max_payload_size is = %0h", mps);
   return mps;
  endfunction
  
  virtual function bit[2:0] get_mrrs();
    reg_no = 'h48;
    mrrs=$root.top.dut.mem[reg_no][14:12];
    $display("Value of max_read_request_size is = %0h", mrrs);
   return mrrs;
  endfunction
  
  virtual function bit[0:0] get_rcb();
    reg_no = 'h50;
    rcb=$root.top.dut.mem[reg_no][3];
    $display("Value of rcb_value is = %0h", rcb);
   return rcb;
  endfunction
endclass