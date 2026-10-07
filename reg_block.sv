`include "reg_pkg.sv"
`include "reg_pkg_2.sv"
// Top-level register block class representing a module's configuration space
class module_reg extends uvm_reg_block;

  // Declare all registers in the block
  rand vendor_id_reg cfg_reg;
  rand device_id_reg dfg_reg;
  rand command_reg cmd_reg;
  rand status_reg sts_reg;
  rand revision_id_reg rev_id_reg;
  rand class_code_reg clc_reg;
  rand cache_line_size_reg cache_reg;
  rand latency_timer_reg ltr_reg;
  rand header_type_reg hdr_reg;
  rand bist_reg bist;
  rand base_address_reg0 bar0;
  rand base_address_reg1 bar1;
  rand base_address_reg2 bar2;
  rand base_address_reg3 bar3;
  rand base_address_reg4 bar4;
  rand base_address_reg5 bar5;
  rand cardbus_cis_pointer_reg cis_ptr;
  rand subsystem_vendor_id_reg sub_vendor_id_reg;
  rand subsystem_id_reg sub_id_reg;
  rand expansion_rom_base_addr_reg exp_rom_base_addr_reg;
  rand capabilities_pointer_reg cap_pointer_reg;
  rand reserved_reg reserved_register;
  rand reserved2_reg reserved2_register;
  rand interrupt_line_reg intr_line_reg;
  rand interrupt_pin_reg intr_pin_reg;
  rand min_gnt_reg min_gnt_register;
  rand max_lat_reg max_lat_register;

  // Register the block with the UVM factory
  `uvm_object_utils(module_reg)

  // Constructor
  function new(string name = "module_reg");
    super.new(name);
  endfunction

  // Build method: create, configure, and build all registers
  virtual function void build();

    // Create and configure each register
    cfg_reg = vendor_id_reg::type_id::create("vendor_id_reg");
    cfg_reg.configure(this, null);
    cfg_reg.build();

    dfg_reg = device_id_reg::type_id::create("device_id_reg");
    dfg_reg.configure(this, null);
    dfg_reg.build();

    cmd_reg = command_reg::type_id::create("command_reg");
    cmd_reg.configure(this, null);
    cmd_reg.build();

    sts_reg = status_reg::type_id::create("sts_reg");
    sts_reg.configure(this, null);
    sts_reg.build();

    rev_id_reg = revision_id_reg::type_id::create("rev_id_reg");
    rev_id_reg.configure(this, null);
    rev_id_reg.build();

    clc_reg = class_code_reg::type_id::create("clc_reg");
    clc_reg.configure(this, null);
    clc_reg.build();

    cache_reg = cache_line_size_reg::type_id::create("cache_reg");
    cache_reg.configure(this, null);
    cache_reg.build();

    ltr_reg = latency_timer_reg::type_id::create("ltr_reg");
    ltr_reg.configure(this, null);
    ltr_reg.build();

    hdr_reg = header_type_reg::type_id::create("hdr_reg");
    hdr_reg.configure(this, null);
    hdr_reg.build();

    bist = bist_reg::type_id::create("bist");
    bist.configure(this, null);
    bist.build();

    // Base address registers
    bar0 = base_address_reg0::type_id::create("bar0");
    bar0.configure(this, null);
    bar0.build();

    bar1 = base_address_reg1::type_id::create("bar1");
    bar1.configure(this, null);
    bar1.build();

    bar2 = base_address_reg2::type_id::create("bar2");
    bar2.configure(this, null);
    bar2.build();

    bar3 = base_address_reg3::type_id::create("bar3");
    bar3.configure(this, null);
    bar3.build();

    bar4 = base_address_reg4::type_id::create("bar4");
    bar4.configure(this, null);
    bar4.build();

    bar5 = base_address_reg5::type_id::create("bar5");
    bar5.configure(this, null);
    bar5.build();

    // Other configuration registers
    cis_ptr = cardbus_cis_pointer_reg::type_id::create("cis_ptr");
    cis_ptr.configure(this, null);
    cis_ptr.build();

    sub_vendor_id_reg = subsystem_vendor_id_reg::type_id::create("sub_vendor_id_reg");
    sub_vendor_id_reg.configure(this, null);
    sub_vendor_id_reg.build();

    sub_id_reg = subsystem_id_reg::type_id::create("sub_id_reg");
    sub_id_reg.configure(this, null);
    sub_id_reg.build();

    exp_rom_base_addr_reg = expansion_rom_base_addr_reg::type_id::create("exp_rom_base_addr_reg");
    exp_rom_base_addr_reg.configure(this, null);
    exp_rom_base_addr_reg.build();

    cap_pointer_reg = capabilities_pointer_reg::type_id::create("cap_pointer_reg");
    cap_pointer_reg.configure(this, null);
    cap_pointer_reg.build();

    reserved_register = reserved_reg::type_id::create("reserved_register");
    reserved_register.configure(this, null);
    reserved_register.build();

    reserved2_register = reserved2_reg::type_id::create("reserved2_register");
    reserved2_register.configure(this, null);
    reserved2_register.build();

    intr_line_reg = interrupt_line_reg::type_id::create("intr_line_reg");
    intr_line_reg.configure(this, null);
    intr_line_reg.build();

    intr_pin_reg = interrupt_pin_reg::type_id::create("intr_pin_reg");
    intr_pin_reg.configure(this, null);
    intr_pin_reg.build();

    min_gnt_register = min_gnt_reg::type_id::create("min_gnt_register");
    min_gnt_register.configure(this, null);
    min_gnt_register.build();

    max_lat_register = max_lat_reg::type_id::create("max_lat_register");
    max_lat_register.configure(this, null);
    max_lat_register.build();

  // Create the default register map
    default_map = create_map("sram_map", `UVM_REG_ADDR_WIDTH'h0, 4, UVM_LITTLE_ENDIAN, 1);

   // PCIe Configuration Space Type 0 Header (correct addressing)
    default_map.add_reg(cfg_reg, 10'h00, "RO");           // 0x00: Vendor ID [15:0]
    default_map.add_reg(dfg_reg, 10'h02, "RO");           // 0x02: Device ID [31:16]
    default_map.add_reg(cmd_reg, 10'h04, "RW");           // 0x04: Command [15:0]
    default_map.add_reg(sts_reg, 10'h06, "RO");           // 0x06: Status [31:16]
    default_map.add_reg(rev_id_reg, 10'h08, "RO");        // 0x08: Revision ID [7:0]
    default_map.add_reg(clc_reg, 10'h09, "RO");           // 0x09: Class Code [31:8]
    default_map.add_reg(cache_reg, 10'h0C, "RW");         // 0x0C: Cache Line Size [7:0]
    default_map.add_reg(ltr_reg, 10'h0D, "RW");           // 0x0D: Latency Timer [15:8]
    default_map.add_reg(hdr_reg, 10'h0E, "RO");           // 0x0E: Header Type [23:16]
    default_map.add_reg(bist, 10'h0F, "RW");              // 0x0F: BIST [31:24]

    // Base Address Registers
    default_map.add_reg(bar0, 10'h10, "RW");              // 0x10: BAR0
    default_map.add_reg(bar1, 10'h14, "RW");              // 0x14: BAR1
    default_map.add_reg(bar2, 10'h18, "RW");              // 0x18: BAR2
    default_map.add_reg(bar3, 10'h1C, "RW");              // 0x1C: BAR3
    default_map.add_reg(bar4, 10'h20, "RW");              // 0x20: BAR4
    default_map.add_reg(bar5, 10'h24, "RW");              // 0x24: BAR5

    // Other registers
    default_map.add_reg(cis_ptr, 10'h28, "RO");           // 0x28: Cardbus CIS Pointer
    default_map.add_reg(sub_vendor_id_reg, 10'h2C, "RO"); // 0x2C: Subsystem Vendor ID [15:0]
    default_map.add_reg(sub_id_reg, 10'h2E, "RO");        // 0x2E: Subsystem ID [31:16]
    default_map.add_reg(exp_rom_base_addr_reg, 10'h30, "RW"); // 0x30: Expansion ROM Base
    default_map.add_reg(cap_pointer_reg, 10'h34, "RO");   // 0x34: Capabilities Pointer [7:0]
    default_map.add_reg(reserved_register, 10'h35, "RO"); // 0x35: Reserved [31:8]
    default_map.add_reg(reserved2_register, 10'h38, "RO");// 0x38: Reserved
    default_map.add_reg(intr_line_reg, 10'h3C, "RW");     // 0x3C: Interrupt Line [7:0]
    default_map.add_reg(intr_pin_reg, 10'h3D, "RO");      // 0x3D: Interrupt Pin [15:8]
    default_map.add_reg(min_gnt_register, 10'h3E, "RO");  // 0x3E: Min_Gnt [23:16]
    default_map.add_reg(max_lat_register, 10'h3F, "RO");  // 0x3F: Max_Lat [31:24]

  endfunction

endclass

//----------------------------------------------------------------------
//----------------------------------------------------------------------

//PCIe capability structure

class pcie_cap_reg_model extends uvm_reg_block;
  `uvm_object_utils(pcie_cap_reg_model)

  // Declare all registers
  rand pcie_capability_list_reg       pcie_cap_list_reg;    
  rand pcie_capabilities_reg          pcie_cap_reg;         
  rand device_capabilities_reg        dev_cap_reg;    
  rand device_control_reg             dev_ctrl_reg;        
  rand device_status_reg              dev_sts_reg;        
  rand link_capabilites_reg           link_cap_reg;    
  rand link_control_reg               link_ctrl_reg;    
  rand link_status_reg                link_status;
  rand slot_capabilities_reg          slot_capabilities;
  rand slot_control_reg               slot_control;
  rand slot_status_reg                slot_status;
  rand root_control_reg               root_control;
  rand root_capabilities_reg          root_capabilities;
  rand root_status_reg                root_status;
  rand device_capabilities_2_reg      device_capabilities_2;
  rand device_control_2_reg           device_control_2;
  rand device_status_2_reg            device_status_2;
  rand link_capabilities_2_reg        link_capabilities_2;
  rand link_control_2_reg             link_control_2;
  rand link_status_2_reg              link_status_2;
  rand slot_capabilities_2_reg        slot_capabilities_2;
  rand slot_control_2_reg             slot_control_2;
  rand slot_status_2_reg              slot_status_2;
  
  function new(string name = "pcie_cap_reg_model");
    super.new(name);
  endfunction

  // Build method: create, configure, and build all registers
  virtual function void build();

    // Create and configure each register
    pcie_cap_list_reg = pcie_capability_list_reg::type_id::create("pcie_cap_list_reg");
    pcie_cap_list_reg.configure(this, null);
    pcie_cap_list_reg.build();

    pcie_cap_reg = pcie_capabilities_reg::type_id::create("pcie_cap_reg");
    pcie_cap_reg.configure(this, null);
    pcie_cap_reg.build();

    dev_cap_reg = device_capabilities_reg::type_id::create("dev_cap_reg");
    dev_cap_reg.configure(this, null);
    dev_cap_reg.build();

    dev_ctrl_reg = device_control_reg::type_id::create("dev_ctrl_reg");
    dev_ctrl_reg.configure(this, null);
    dev_ctrl_reg.build();

    dev_sts_reg = device_status_reg::type_id::create("dev_sts_reg");
    dev_sts_reg.configure(this, null);
    dev_sts_reg.build();
  
    link_cap_reg = link_capabilites_reg::type_id::create("link_cap_reg");
    link_cap_reg.configure(this, null);
    link_cap_reg.build();

    link_ctrl_reg = link_control_reg::type_id::create("link_ctrl_reg");
    link_ctrl_reg.configure(this, null);
    link_ctrl_reg.build();

    // Continue with remaining registers from previous conversation
    link_status = link_status_reg::type_id::create("link_status");
    link_status.configure(this, null);
    link_status.build();

    slot_capabilities = slot_capabilities_reg::type_id::create("slot_capabilities");
    slot_capabilities.configure(this, null);
    slot_capabilities.build();

    slot_control = slot_control_reg::type_id::create("slot_control");
    slot_control.configure(this, null);
    slot_control.build();

    slot_status = slot_status_reg::type_id::create("slot_status");
    slot_status.configure(this, null);
    slot_status.build();

    root_control = root_control_reg::type_id::create("root_control");
    root_control.configure(this, null);
    root_control.build();

    root_capabilities = root_capabilities_reg::type_id::create("root_capabilities");
    root_capabilities.configure(this, null);
    root_capabilities.build();

    root_status = root_status_reg::type_id::create("root_status");
    root_status.configure(this, null);
    root_status.build();

    device_capabilities_2 = device_capabilities_2_reg::type_id::create("device_capabilities_2");
    device_capabilities_2.configure(this, null);
    device_capabilities_2.build();

    device_control_2 = device_control_2_reg::type_id::create("device_control_2");
    device_control_2.configure(this, null);
    device_control_2.build();

    device_status_2 = device_status_2_reg::type_id::create("device_status_2");
    device_status_2.configure(this, null);
    device_status_2.build();

    link_capabilities_2 = link_capabilities_2_reg::type_id::create("link_capabilities_2");
    link_capabilities_2.configure(this, null);
    link_capabilities_2.build();

    link_control_2 = link_control_2_reg::type_id::create("link_control_2");
    link_control_2.configure(this, null);
    link_control_2.build();

    link_status_2 = link_status_2_reg::type_id::create("link_status_2");
    link_status_2.configure(this, null);
    link_status_2.build();

    slot_capabilities_2 = slot_capabilities_2_reg::type_id::create("slot_capabilities_2");
    slot_capabilities_2.configure(this, null);
    slot_capabilities_2.build();

    slot_control_2 = slot_control_2_reg::type_id::create("slot_control_2");
    slot_control_2.configure(this, null);
    slot_control_2.build();

    slot_status_2 = slot_status_2_reg::type_id::create("slot_status_2");
    slot_status_2.configure(this, null);
    slot_status_2.build();

    // Create the default register map
    default_map = create_map("sram_map", `UVM_REG_ADDR_WIDTH'h0, 4, UVM_LITTLE_ENDIAN, 1);

    // Add registers to the map with address and access type
    default_map.add_reg(pcie_cap_list_reg, 10'h0, "RO");
    default_map.add_reg(pcie_cap_reg, 10'h2, "RO");
    default_map.add_reg(dev_cap_reg, 10'h4, "RO");
    default_map.add_reg(dev_ctrl_reg, 10'h8, "RW");
    default_map.add_reg(dev_sts_reg, 10'hA, "RO");
    default_map.add_reg(link_cap_reg, 10'hC, "RO");
    default_map.add_reg(link_ctrl_reg, 10'h10, "RW");
    default_map.add_reg(link_status, 10'h12, "RO");
    default_map.add_reg(slot_capabilities, 10'h14, "RO");
    default_map.add_reg(slot_control, 10'h18, "RW");
    default_map.add_reg(slot_status, 10'h1A, "RW");
    default_map.add_reg(root_control, 10'h1C, "RW");
    default_map.add_reg(root_capabilities, 10'h1E, "RO");
    default_map.add_reg(root_status, 10'h20, "RW");
    default_map.add_reg(device_capabilities_2, 10'h24, "RO");
    default_map.add_reg(device_control_2, 10'h28, "RW");
    default_map.add_reg(device_status_2, 10'h2A, "RO");
    default_map.add_reg(link_capabilities_2, 10'h2C, "RO");
    default_map.add_reg(link_control_2, 10'h30, "RW");
    default_map.add_reg(link_status_2, 10'h32, "RW");
    default_map.add_reg(slot_capabilities_2, 10'h34, "RO");
    default_map.add_reg(slot_control_2, 10'h38, "RO");
    default_map.add_reg(slot_status_2, 10'h3A, "RO");

  endfunction

endclass


//----------------------------------------------------------------------
//----------------------------------------------------------------------

class virtual_channel_reg_block extends uvm_reg_block;
  `uvm_object_utils(virtual_channel_reg_block)

  // Declare all registers
  rand virtual_channel_extended_capability_header_reg    vc_ext_cap_header;
  rand port_vc_capability_register_1_reg                 port_vc_cap_1;
  rand port_vc_capability_register_2_reg                 port_vc_cap_2;
  rand port_vc_control_reg                               port_vc_control;
  rand port_vc_status_reg                                port_vc_status;
  
  // VC Resource 0 Registers
  rand vc_resource_capability_reg_0                      vc_resource_0_cap;
  rand vc_resource_control_reg_0                         vc_resource_0_ctrl;
  rand vc_resource_status_reg_0                          vc_resource_0_status;
  
  // VC Resource 1 Registers
  rand vc_resource_capability_reg_1                      vc_resource_1_cap;
  rand vc_resource_control_reg_1                         vc_resource_1_ctrl;
  rand vc_resource_status_reg_1                          vc_resource_1_status;
  
  // VC Resource 2 Registers
  rand vc_resource_capability_reg_2                      vc_resource_2_cap;
  rand vc_resource_control_reg_2                         vc_resource_2_ctrl;
  rand vc_resource_status_reg_2                          vc_resource_2_status;
  
  // VC Resource 3 Registers
  rand vc_resource_capability_reg_3                      vc_resource_3_cap;
  rand vc_resource_control_reg_3                         vc_resource_3_ctrl;
  rand vc_resource_status_reg_3                          vc_resource_3_status;
  
  // VC Resource 4 Registers
  rand vc_resource_capability_reg_4                      vc_resource_4_cap;
  rand vc_resource_control_reg_4                         vc_resource_4_ctrl;
  rand vc_resource_status_reg_4                          vc_resource_4_status;
  
  // VC Resource 5 Registers
  rand vc_resource_capability_reg_5                      vc_resource_5_cap;
  rand vc_resource_control_reg_5                         vc_resource_5_ctrl;
  rand vc_resource_status_reg_5                          vc_resource_5_status;
  
  // VC Resource 6 Registers
  rand vc_resource_capability_reg_6                      vc_resource_6_cap;
  rand vc_resource_control_reg_6                         vc_resource_6_ctrl;
  rand vc_resource_status_reg_6                          vc_resource_6_status;
  
  // VC Resource 7 Registers
  rand vc_resource_capability_reg_7                      vc_resource_7_cap;
  rand vc_resource_control_reg_7                         vc_resource_7_ctrl;
  rand vc_resource_status_reg_7                          vc_resource_7_status;

  function new(string name = "virtual_channel_reg_block");
    super.new(name);
  endfunction

  // Build method: create, configure, and build all registers
  virtual function void build();

    // Create and configure Virtual Channel Extended Capability Header
    vc_ext_cap_header = virtual_channel_extended_capability_header_reg::type_id::create("vc_ext_cap_header");
    vc_ext_cap_header.configure(this, null);
    vc_ext_cap_header.build();

    // Create and configure Port VC Capability Register 1
    port_vc_cap_1 = port_vc_capability_register_1_reg::type_id::create("port_vc_cap_1");
    port_vc_cap_1.configure(this, null);
    port_vc_cap_1.build();

    // Create and configure Port VC Capability Register 2
    port_vc_cap_2 = port_vc_capability_register_2_reg::type_id::create("port_vc_cap_2");
    port_vc_cap_2.configure(this, null);
    port_vc_cap_2.build();

    // Create and configure Port VC Control Register
    port_vc_control = port_vc_control_reg::type_id::create("port_vc_control");
    port_vc_control.configure(this, null);
    port_vc_control.build();

    // Create and configure Port VC Status Register
    port_vc_status = port_vc_status_reg::type_id::create("port_vc_status");
    port_vc_status.configure(this, null);
    port_vc_status.build();

    // Create and configure VC Resource 0 Registers
    vc_resource_0_cap = vc_resource_capability_reg_0::type_id::create("vc_resource_0_cap");
    vc_resource_0_cap.configure(this, null);
    vc_resource_0_cap.build();

    vc_resource_0_ctrl = vc_resource_control_reg_0::type_id::create("vc_resource_0_ctrl");
    vc_resource_0_ctrl.configure(this, null);
    vc_resource_0_ctrl.build();

    vc_resource_0_status = vc_resource_status_reg_0::type_id::create("vc_resource_0_status");
    vc_resource_0_status.configure(this, null);
    vc_resource_0_status.build();

    // Create and configure VC Resource 1 Registers
    vc_resource_1_cap = vc_resource_capability_reg_1::type_id::create("vc_resource_1_cap");
    vc_resource_1_cap.configure(this, null);
    vc_resource_1_cap.build();

    vc_resource_1_ctrl = vc_resource_control_reg_1::type_id::create("vc_resource_1_ctrl");
    vc_resource_1_ctrl.configure(this, null);
    vc_resource_1_ctrl.build();

    vc_resource_1_status = vc_resource_status_reg_1::type_id::create("vc_resource_1_status");
    vc_resource_1_status.configure(this, null);
    vc_resource_1_status.build();

    // Create and configure VC Resource 2 Registers
    vc_resource_2_cap = vc_resource_capability_reg_2::type_id::create("vc_resource_2_cap");
    vc_resource_2_cap.configure(this, null);
    vc_resource_2_cap.build();

    vc_resource_2_ctrl = vc_resource_control_reg_2::type_id::create("vc_resource_2_ctrl");
    vc_resource_2_ctrl.configure(this, null);
    vc_resource_2_ctrl.build();

    vc_resource_2_status = vc_resource_status_reg_2::type_id::create("vc_resource_2_status");
    vc_resource_2_status.configure(this, null);
    vc_resource_2_status.build();

    // Create and configure VC Resource 3 Registers
    vc_resource_3_cap = vc_resource_capability_reg_3::type_id::create("vc_resource_3_cap");
    vc_resource_3_cap.configure(this, null);
    vc_resource_3_cap.build();

    vc_resource_3_ctrl = vc_resource_control_reg_3::type_id::create("vc_resource_3_ctrl");
    vc_resource_3_ctrl.configure(this, null);
    vc_resource_3_ctrl.build();

    vc_resource_3_status = vc_resource_status_reg_3::type_id::create("vc_resource_3_status");
    vc_resource_3_status.configure(this, null);
    vc_resource_3_status.build();

    // Create and configure VC Resource 4 Registers
    vc_resource_4_cap = vc_resource_capability_reg_4::type_id::create("vc_resource_4_cap");
    vc_resource_4_cap.configure(this, null);
    vc_resource_4_cap.build();

    vc_resource_4_ctrl = vc_resource_control_reg_4::type_id::create("vc_resource_4_ctrl");
    vc_resource_4_ctrl.configure(this, null);
    vc_resource_4_ctrl.build();

    vc_resource_4_status = vc_resource_status_reg_4::type_id::create("vc_resource_4_status");
    vc_resource_4_status.configure(this, null);
    vc_resource_4_status.build();

    // Create and configure VC Resource 5 Registers
    vc_resource_5_cap = vc_resource_capability_reg_5::type_id::create("vc_resource_5_cap");
    vc_resource_5_cap.configure(this, null);
    vc_resource_5_cap.build();

    vc_resource_5_ctrl = vc_resource_control_reg_5::type_id::create("vc_resource_5_ctrl");
    vc_resource_5_ctrl.configure(this, null);
    vc_resource_5_ctrl.build();

    vc_resource_5_status = vc_resource_status_reg_5::type_id::create("vc_resource_5_status");
    vc_resource_5_status.configure(this, null);
    vc_resource_5_status.build();

    // Create and configure VC Resource 6 Registers
    vc_resource_6_cap = vc_resource_capability_reg_6::type_id::create("vc_resource_6_cap");
    vc_resource_6_cap.configure(this, null);
    vc_resource_6_cap.build();

    vc_resource_6_ctrl = vc_resource_control_reg_6::type_id::create("vc_resource_6_ctrl");
    vc_resource_6_ctrl.configure(this, null);
    vc_resource_6_ctrl.build();

    vc_resource_6_status = vc_resource_status_reg_6::type_id::create("vc_resource_6_status");
    vc_resource_6_status.configure(this, null);
    vc_resource_6_status.build();

    // Create and configure VC Resource 7 Registers
    vc_resource_7_cap = vc_resource_capability_reg_7::type_id::create("vc_resource_7_cap");
    vc_resource_7_cap.configure(this, null);
    vc_resource_7_cap.build();

    vc_resource_7_ctrl = vc_resource_control_reg_7::type_id::create("vc_resource_7_ctrl");
    vc_resource_7_ctrl.configure(this, null);
    vc_resource_7_ctrl.build();

    vc_resource_7_status = vc_resource_status_reg_7::type_id::create("vc_resource_7_status");
    vc_resource_7_status.configure(this, null);
    vc_resource_7_status.build();

    // Create the default register map
    default_map = create_map("sram_map", `UVM_REG_ADDR_WIDTH'h0, 4, UVM_LITTLE_ENDIAN, 1);

    // Add registers to the map with address and access type
    // Virtual Channel Extended Capability Header
    default_map.add_reg(vc_ext_cap_header, 10'h0, "RO");

    // Port VC Registers
    default_map.add_reg(port_vc_cap_1, 10'h4, "RO");
    default_map.add_reg(port_vc_cap_2, 10'h8, "RO");
    default_map.add_reg(port_vc_control, 10'hC, "RW");
    default_map.add_reg(port_vc_status, 10'hE, "RO");

     // VC Resource 0 Registers
    default_map.add_reg(vc_resource_0_cap, 10'h10, "RO");
    default_map.add_reg(vc_resource_0_ctrl, 10'h14, "RW");
    default_map.add_reg(vc_resource_0_status, 10'h18, "RO");

    // VC Resource 1 Registers
    default_map.add_reg(vc_resource_1_cap, 10'h1C, "RO");
    default_map.add_reg(vc_resource_1_ctrl, 10'h20, "RW");
    default_map.add_reg(vc_resource_1_status, 10'h24, "RO");

    // VC Resource 2 Registers
    default_map.add_reg(vc_resource_2_cap, 10'h28, "RO");
    default_map.add_reg(vc_resource_2_ctrl, 10'h2C, "RW");
    default_map.add_reg(vc_resource_2_status, 10'h30, "RO");

    // VC Resource 3 Registers
    default_map.add_reg(vc_resource_3_cap, 10'h34, "RO");
    default_map.add_reg(vc_resource_3_ctrl, 10'h38, "RW");
    default_map.add_reg(vc_resource_3_status, 10'h3C, "RO");

    // VC Resource 4 Registers
    default_map.add_reg(vc_resource_4_cap, 10'h40, "RO");
    default_map.add_reg(vc_resource_4_ctrl, 10'h44, "RW");
    default_map.add_reg(vc_resource_4_status, 10'h48, "RO");

    // VC Resource 5 Registers
    default_map.add_reg(vc_resource_5_cap, 10'h4C, "RO");
    default_map.add_reg(vc_resource_5_ctrl, 10'h50, "RW");
    default_map.add_reg(vc_resource_5_status, 10'h54, "RO");

    // VC Resource 6 Registers
    default_map.add_reg(vc_resource_6_cap, 10'h58, "RO");
    default_map.add_reg(vc_resource_6_ctrl, 10'h5C, "RW");
    default_map.add_reg(vc_resource_6_status, 10'h60, "RO");

    // VC Resource 7 Registers
    default_map.add_reg(vc_resource_7_cap, 10'h64, "RO");
    default_map.add_reg(vc_resource_7_ctrl, 10'h68, "RW");
    default_map.add_reg(vc_resource_7_status, 10'h6C, "RO");


  endfunction

endclass

//----------------------------------------------------------------------
//----------------------------------------------------------------------

// Top Level class: SFR Reg Model
// Define the top-level register model class
class RegModel_SFR extends uvm_reg_block;

  // Declare a handle to the module-level register block
  rand module_reg mod_reg;
  rand pcie_cap_reg_model mod_pcie_cap_reg;
  rand virtual_channel_reg_block vc_reg_block;
  
  // Optional named register map (not used directly here but declared for clarity)
  uvm_reg_map sram_map;

  // Register the class with the UVM factory
  `uvm_object_utils(RegModel_SFR)

  // Constructor: initialize the register block with no coverage
  function new(string name = "RegModel_SFR");
    super.new(name, .has_coverage(UVM_NO_COVERAGE));
  endfunction

  // Build method: create and configure the register block and its map
  virtual function void build();

    // Create the default map named "sram_map"
    // Base address: 0x0
    // Bus width: 4 bytes
    // Endianness: Little-endian
    // Byte-addressing: disabled (0)
    default_map = create_map("sram_map", 'h0, 4, UVM_LITTLE_ENDIAN, 0);

    // Create and build the module-level register block
    mod_reg = module_reg::type_id::create("mod_reg");
    mod_reg.configure(this);  // Set this block as the parent
    mod_reg.build();          // Build all registers inside module_reg
    //this.add_block(mod_reg);
    // Add the module_reg's default map as a submap to this block's default map
    default_map.add_submap(this.mod_reg.default_map, 0);
    
    mod_pcie_cap_reg=pcie_cap_reg_model::type_id::create("mod_pcie_cap_reg"); 
    mod_pcie_cap_reg.configure(this);
    mod_pcie_cap_reg.build();
    default_map.add_submap(this.mod_pcie_cap_reg.default_map, 10'h40);
    
    vc_reg_block=virtual_channel_reg_block::type_id::create("vc_reg_block"); 
    vc_reg_block.configure(this);
    vc_reg_block.build();
    default_map.add_submap(this.vc_reg_block.default_map, 10'h7c);
  
  endfunction

endclass
