 class pcie_extnd_cpblty_reg extends uvm_reg;
  rand uvm_reg_field nxt_cpbl_offset;
  rand uvm_reg_field cpbl_ver;
  rand uvm_reg_field cpbl_id;
  `uvm_object_utils(pcie_extnd_cpblty_reg)
  
  function new(string name="pcie_extnd_cpblty_reg");
    super.new(name,32,UVM_NO_COVERAGE);
  endfunction
  
  virtual function void build();
    // Create object instance for each field
    nxt_cpbl_offset=uvm_reg_field::type_id::create("nxt_cpbl_offset");
    cpbl_ver=uvm_reg_field::type_id::create("cpbl_ver");
    cpbl_id=uvm_reg_field::type_id::create("cpbl_id");

    // Configure each field
    nxt_cpbl_offset.configure(this,12,20,"RO",0,12'h25,0,1,0);
    cpbl_ver.configure(this,4,16,"RO",0,4'h1,0,1,0);
    cpbl_id.configure(this,16,0,"RO",0,16'h0,0,1,0);
  endfunction
endclass

class dlf_cpblties_reg extends uvm_reg;
  rand uvm_reg_field dlf_enable;
  rand uvm_reg_field rsvdp;
  rand uvm_reg_field lf_support;
  `uvm_object_utils(dlf_cpblties_reg)
  
  function new(string name="dlf_cpblties_reg");
    super.new(name,32,UVM_NO_COVERAGE);
  endfunction
  
  virtual function void build();
    // Create object instance for each field
    dlf_enable=uvm_reg_field::type_id::create("dlf_enable");
    rsvdp=uvm_reg_field::type_id::create("rsvdp");
    lf_support=uvm_reg_field::type_id::create("lf_support");

    // Configure each field
    dlf_enable.configure(this,1,31,"RW",0,1'b1,0,1,1);
    rsvdp.configure(this,8,23,"RW",0,0,0,0,1);
    lf_support.configure(this,23,0,"RW",0,16'h0,0,1,1);
  endfunction
  
endclass

class dlf_status_reg extends uvm_reg;
  rand uvm_reg_field dlf_enable;
  rand uvm_reg_field rsvdp;
  rand uvm_reg_field rm_support;
  `uvm_object_utils(dlf_status_reg)
  
  function new(string name="dlf_cpblties_reg");
    super.new(name,32,UVM_NO_COVERAGE);
  endfunction
  
  virtual function void build();
    // Create object instance for each field
    dlf_enable=uvm_reg_field::type_id::create("dlf_enable");
    rsvdp=uvm_reg_field::type_id::create("rsvdp");
    rm_support=uvm_reg_field::type_id::create("rm_support");

    // Configure each field
    dlf_enable.configure(this,1,31,"RW",0,1'b1,0,1,1);
    rsvdp.configure(this,8,23,"RW",0,0,0,0,1);
    rm_support.configure(this,23,0,"RW",0,16'h0,0,1,1);
  endfunction
endclass

class dlf_ext_cpb extends uvm_reg_block;
  rand pcie_extnd_cpblty_reg header_reg;
  rand dlf_cpblties_reg local_f_reg;
  rand dlf_status_reg remote_f_reg;
  `uvm_object_utils(dlf_ext_cpb)
  
  function new(string name="dlf_ext_cpb");
    super.new(name,UVM_NO_COVERAGE);
  endfunction
  
  virtual function void build();
    header_reg=pcie_extnd_cpblty_reg::type_id::create("header_reg");
    header_reg.configure(this);
    header_reg.build();
    local_f_reg=dlf_cpblties_reg::type_id::create("local_f_reg");
    local_f_reg.configure(this);
    local_f_reg.build();
    remote_f_reg=dlf_status_reg::type_id::create("remote_f_reg");
    remote_f_reg.configure(this);
    remote_f_reg.build();
    
    default_map=create_map("default_map",'h0,4,UVM_LITTLE_ENDIAN);
    
    default_map.add_reg(header_reg,'h00,"RO");
    default_map.add_reg(local_f_reg,'h04,"RW");
    default_map.add_reg(remote_f_reg,'h08,"RW");
    
    
    
  endfunction
  
endclass