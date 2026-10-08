/************************************************************************************************************************************************************PCIe_extended_capability_register********************************************************************************************************/

class virtual_channel_extended_capability_header_reg extends uvm_reg;

  rand uvm_reg_field pci_express_extended_capability_id;
  rand uvm_reg_field capability_version;
  rand uvm_reg_field next_capability_offset;
  
  `uvm_object_utils(virtual_channel_extended_capability_header_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "virtual_channel_extended_capability_header_reg");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-15: PCI Express Extended Capability ID (16 bits)
    pci_express_extended_capability_id = uvm_reg_field::type_id::create("pci_express_extended_capability_id");
    pci_express_extended_capability_id.configure(this, 16, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bits 16-19: Capability Version (4 bits)
    capability_version = uvm_reg_field::type_id::create("capability_version");
    capability_version.configure(this, 4, 16, "RO", 0, 0, 1, 0, 1);
    
    // Bits 20-31: Next Capability Offset (12 bits)
    next_capability_offset = uvm_reg_field::type_id::create("next_capability_offset");
    next_capability_offset.configure(this, 12, 20, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class port_vc_capability_register_1_reg extends uvm_reg;

  rand uvm_reg_field extended_vc_count;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field low_priority_extended_vc_count;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field reference_clock;
  rand uvm_reg_field port_arbitration_table_entry_size;
  rand uvm_reg_field rsvdp_3;
  
  `uvm_object_utils(port_vc_capability_register_1_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "port_vc_capability_register_1_reg");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-2: Extended VC Count (3 bits)
    extended_vc_count = uvm_reg_field::type_id::create("extended_vc_count");
    extended_vc_count.configure(this, 3, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 3: RsvdP
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 1, 3, "RO", 0, 0, 1, 0, 1);
    
    // Bits 4-6: Low Priority Extended VC Count (3 bits)
    low_priority_extended_vc_count = uvm_reg_field::type_id::create("low_priority_extended_vc_count");
    low_priority_extended_vc_count.configure(this, 3, 4, "RO", 0, 0, 1, 0, 1);
    
    // Bit 7: RsvdP
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 1, 7, "RO", 0, 0, 1, 0, 1);
    
    // Bits 8-9: Reference Clock (2 bits)
    reference_clock = uvm_reg_field::type_id::create("reference_clock");
    reference_clock.configure(this, 2, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bits 10-11: Port Arbitration Table Entry Size (2 bits)
    port_arbitration_table_entry_size = uvm_reg_field::type_id::create("port_arbitration_table_entry_size");
    port_arbitration_table_entry_size.configure(this, 2, 10, "RO", 0, 0, 1, 0, 1);
    
    // Bits 12-31: RsvdP (20 bits) - handled implicitly as the remaining bits
     rsvdp_3 = uvm_reg_field::type_id::create("rsvdp_3");
     rsvdp_3.configure(this, 20, 12, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class port_vc_capability_register_2_reg extends uvm_reg;

  rand uvm_reg_field vc_arbitration_capability;
  rand uvm_reg_field rsvdp;
  rand uvm_reg_field vc_arbitration_table_offset;
  
  `uvm_object_utils(port_vc_capability_register_2_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "port_vc_capability_register_2_reg");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: VC Arbitration Capability (8 bits)
    vc_arbitration_capability = uvm_reg_field::type_id::create("vc_arbitration_capability");
    vc_arbitration_capability.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bits 8-23: RsvdP (Reserved and Preserved) (16 bits)
    rsvdp = uvm_reg_field::type_id::create("rsvdp");
    rsvdp.configure(this, 16, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-31: VC Arbitration Table Offset (8 bits)
    vc_arbitration_table_offset = uvm_reg_field::type_id::create("vc_arbitration_table_offset");
    vc_arbitration_table_offset.configure(this, 8, 24, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class port_vc_control_reg extends uvm_reg;

  rand uvm_reg_field load_vc_arbitration_table;
  rand uvm_reg_field vc_arbitration_select;
  rand uvm_reg_field rsvdp;
  
  `uvm_object_utils(port_vc_control_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "port_vc_control_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Load VC Arbitration Table
    load_vc_arbitration_table = uvm_reg_field::type_id::create("load_vc_arbitration_table");
    load_vc_arbitration_table.configure(this, 1, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bits 0-3: VC Arbitration Select (4 bits)
    vc_arbitration_select = uvm_reg_field::type_id::create("vc_arbitration_select");
    vc_arbitration_select.configure(this, 3, 1, "RW", 0, 0, 1, 0, 1);
    
    // Bits 4-15: RsvdP (Reserved and Preserved) (12 bits)
    rsvdp = uvm_reg_field::type_id::create("rsvdp");
    rsvdp.configure(this, 12, 4, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class port_vc_status_reg extends uvm_reg;

  rand uvm_reg_field vc_arbitration_table_status;
  rand uvm_reg_field rsvdz;
  
  `uvm_object_utils(port_vc_status_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "port_vc_status_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: VC Arbitration Table Status
    vc_arbitration_table_status = uvm_reg_field::type_id::create("vc_arbitration_table_status");
    vc_arbitration_table_status.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bits 1-15: RsvdZ (Reserved and Zero) (15 bits)
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 15, 1, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

// Base class for VC Resource Capability Register
class vc_resource_capability_reg_base extends uvm_reg;
  
  rand uvm_reg_field port_arbitration_capability;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field undefined;
  rand uvm_reg_field reject_snoop_transactions;
  rand uvm_reg_field maximum_time_slots;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field port_arbitration_table_offset;
  
  // ADD THIS: UVM factory registration
  `uvm_object_utils(vc_resource_capability_reg_base)
  
  function new(string name = "vc_resource_capability_reg_base");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    port_arbitration_capability = uvm_reg_field::type_id::create("port_arbitration_capability");
    port_arbitration_capability.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);
    
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 6, 8, "RO", 0, 0, 1, 0, 1);
    
    undefined = uvm_reg_field::type_id::create("undefined");
    undefined.configure(this, 1, 14, "RO", 0, 0, 1, 0, 1);
    
    reject_snoop_transactions = uvm_reg_field::type_id::create("reject_snoop_transactions");
    reject_snoop_transactions.configure(this, 1, 15, "RO", 0, 0, 1, 0, 1);
    
    maximum_time_slots = uvm_reg_field::type_id::create("maximum_time_slots");
    maximum_time_slots.configure(this, 7, 16, "RO", 0, 0, 1, 0, 1);
    
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 1, 23, "RO", 0, 0, 1, 0, 1);
    
    port_arbitration_table_offset = uvm_reg_field::type_id::create("port_arbitration_table_offset");
    port_arbitration_table_offset.configure(this, 8, 24, "RO", 0, 0, 1, 0, 1);
  endfunction
endclass

// Base class for VC Resource Control Register
/*class vc_resource_control_reg_base extends uvm_reg;
  
  rand uvm_reg_field tc_vc_map;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field load_port_arbitration_table;
  rand uvm_reg_field port_arbitration_select;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field vc_id;
  rand uvm_reg_field rsvdp_3;
  rand uvm_reg_field vc_enable;
  
  // ADD THIS: UVM factory registration
  `uvm_object_utils(vc_resource_control_reg_base)
  
  function new(string name = "vc_resource_control_reg_base");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    tc_vc_map = uvm_reg_field::type_id::create("tc_vc_map");
    tc_vc_map.configure(this, 8, 0, "RW", 0, 0, 1, 0, 1);
    
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 8, 8, "RO", 0, 0, 1, 0, 1);
    
    load_port_arbitration_table = uvm_reg_field::type_id::create("load_port_arbitration_table");
    load_port_arbitration_table.configure(this, 1, 16, "RW", 0, 0, 1, 0, 1);
    
    port_arbitration_select = uvm_reg_field::type_id::create("port_arbitration_select");
    port_arbitration_select.configure(this, 3, 17, "RW", 0, 0, 1, 0, 1);
    
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 4, 20, "RO", 0, 0, 1, 0, 1);
    
    vc_id = uvm_reg_field::type_id::create("vc_id");
    vc_id.configure(this, 3, 24, "RW", 0, 0, 1, 0, 1);
    
    rsvdp_3 = uvm_reg_field::type_id::create("rsvdp_3");
    rsvdp_3.configure(this, 4, 27, "RO", 0, 0, 1, 0, 1);
    
    vc_enable = uvm_reg_field::type_id::create("vc_enable");
    vc_enable.configure(this, 1, 31, "RW", 0, 0, 1, 0, 1);
  endfunction
endclass

// Base class for VC Resource Status Register
class vc_resource_status_reg_base extends uvm_reg;
  
  rand uvm_reg_field port_arbitration_table_status;
  rand uvm_reg_field vc_negotiation_pending;
  rand uvm_reg_field rsvdz;
  
  // ADD THIS: UVM factory registration
  `uvm_object_utils(vc_resource_status_reg_base)
  
  function new(string name = "vc_resource_status_reg_base");
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    port_arbitration_table_status = uvm_reg_field::type_id::create("port_arbitration_table_status");
    port_arbitration_table_status.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    vc_negotiation_pending = uvm_reg_field::type_id::create("vc_negotiation_pending");
    vc_negotiation_pending.configure(this, 1, 1, "RO", 0, 0, 1, 0, 1);
    
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 14, 2, "RO", 0, 0, 1, 0, 1);
  endfunction
endclass*/


class vc_resource_capability_reg_0 extends uvm_reg;

  rand uvm_reg_field port_arbitration_capability;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field undefined;
  rand uvm_reg_field reject_snoop_transactions;
  rand uvm_reg_field maximum_time_slots;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field port_arbitration_table_offset;
  
  `uvm_object_utils(vc_resource_capability_reg_0);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_capability_reg_0");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: Port Arbitration Capability (8 bits)
    port_arbitration_capability = uvm_reg_field::type_id::create("port_arbitration_capability");
    port_arbitration_capability.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 8-13: RsvdP (Reserved and Preserved)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 6, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bits 14: Undefined (6 bits)
    undefined = uvm_reg_field::type_id::create("undefined");
    undefined.configure(this, 1, 14, "RO", 0, 0, 1, 0, 1);
    
    // Bit 15: Reject Snoop Transactions
    reject_snoop_transactions = uvm_reg_field::type_id::create("reject_snoop_transactions");
    reject_snoop_transactions.configure(this, 1, 15, "RO", 0, 0, 1, 0, 1);
    
    // Bits 16-22: Maximum Time Slots (8 bits)
    maximum_time_slots = uvm_reg_field::type_id::create("maximum_time_slots");
    maximum_time_slots.configure(this, 7, 16, "RO", 0, 0, 1, 0, 1);
    
    // Bit 23: RsvdP (Reserved and Preserved)
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 1, 23, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-31: Port Arbitration Table Offset (8 bits)
    port_arbitration_table_offset = uvm_reg_field::type_id::create("port_arbitration_table_offset");
    port_arbitration_table_offset.configure(this, 8, 24, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_control_reg_0 extends uvm_reg;

  rand uvm_reg_field tc_vc_map;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field load_port_arbitration_table;
  rand uvm_reg_field port_arbitration_select;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field vc_id;
  rand uvm_reg_field rsvdp_3;
  rand uvm_reg_field vc_enable;
  
  `uvm_object_utils(vc_resource_control_reg_0);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_control_reg_0");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: TC/VC Map (8 bits)
    tc_vc_map = uvm_reg_field::type_id::create("tc_vc_map");
    tc_vc_map.configure(this, 8, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bits 8-15: RsvdP (Reserved and Preserved) (8 bits)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 8, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bit 16: Load Port Arbitration Table
    load_port_arbitration_table = uvm_reg_field::type_id::create("load_port_arbitration_table");
    load_port_arbitration_table.configure(this, 1, 16, "RW", 0, 0, 1, 0, 1);
    
    // Bits 17-19: Port Arbitration Select (3 bits)
    port_arbitration_select = uvm_reg_field::type_id::create("port_arbitration_select");
    port_arbitration_select.configure(this, 3, 17, "RW", 0, 0, 1, 0, 1);
    
    // Bits 20-23: RsvdP (Reserved and Preserved) (4 bits) - part of the larger RsvdP field
    // This is handled by extending the VC ID field or creating separate RsvdP fields
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 4, 20, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-26: VC ID (3 bits)
    vc_id = uvm_reg_field::type_id::create("vc_id");
    vc_id.configure(this, 3, 24, "RW", 0, 0, 1, 0, 1);
    
    // Bit 27-30: RsvdP (Reserved and Preserved) (4 bits)
    // Combined with the VC ID field spacing
    rsvdp_3 = uvm_reg_field::type_id::create("rsvdp_3");
    rsvdp_3.configure(this, 4, 27, "RO", 0, 0, 1, 0, 1);
    
    // Bit 31: VC Enable
    vc_enable = uvm_reg_field::type_id::create("vc_enable");
    vc_enable.configure(this, 1, 31, "RW", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_status_reg_0 extends uvm_reg;

  rand uvm_reg_field port_arbitration_table_status;
  rand uvm_reg_field vc_negotiation_pending;
  rand uvm_reg_field rsvdz;
  
  `uvm_object_utils(vc_resource_status_reg_0);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_status_reg_0");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Port Arbitration Table Status
    port_arbitration_table_status = uvm_reg_field::type_id::create("port_arbitration_table_status");
    port_arbitration_table_status.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 1: VC Negotiation Pending
    vc_negotiation_pending = uvm_reg_field::type_id::create("vc_negotiation_pending");
    vc_negotiation_pending.configure(this, 1, 1, "RO", 0, 0, 1, 0, 1);
    
    // Bits 2-15: RsvdZ (Reserved and Zero) (14 bits)
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 14, 2, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_capability_reg_1 extends uvm_reg;

  rand uvm_reg_field port_arbitration_capability;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field undefined;
  rand uvm_reg_field reject_snoop_transactions;
  rand uvm_reg_field maximum_time_slots;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field port_arbitration_table_offset;
  
  `uvm_object_utils(vc_resource_capability_reg_1);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_capability_reg_1");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: Port Arbitration Capability (8 bits)
    port_arbitration_capability = uvm_reg_field::type_id::create("port_arbitration_capability");
    port_arbitration_capability.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 8-13: RsvdP (Reserved and Preserved)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 6, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bits 14: Undefined (6 bits)
    undefined = uvm_reg_field::type_id::create("undefined");
    undefined.configure(this, 1, 14, "RO", 0, 0, 1, 0, 1);
    
    // Bit 15: Reject Snoop Transactions
    reject_snoop_transactions = uvm_reg_field::type_id::create("reject_snoop_transactions");
    reject_snoop_transactions.configure(this, 1, 15, "RO", 0, 0, 1, 0, 1);
    
    // Bits 16-22: Maximum Time Slots (8 bits)
    maximum_time_slots = uvm_reg_field::type_id::create("maximum_time_slots");
    maximum_time_slots.configure(this, 7, 16, "RO", 0, 0, 1, 0, 1);
    
    // Bit 23: RsvdP (Reserved and Preserved)
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 1, 23, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-31: Port Arbitration Table Offset (8 bits)
    port_arbitration_table_offset = uvm_reg_field::type_id::create("port_arbitration_table_offset");
    port_arbitration_table_offset.configure(this, 8, 24, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_control_reg_1 extends uvm_reg;

  rand uvm_reg_field tc_vc_map;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field load_port_arbitration_table;
  rand uvm_reg_field port_arbitration_select;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field vc_id;
  rand uvm_reg_field rsvdp_3;
  rand uvm_reg_field vc_enable;
  
  `uvm_object_utils(vc_resource_control_reg_1);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_control_reg_1");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: TC/VC Map (8 bits)
    tc_vc_map = uvm_reg_field::type_id::create("tc_vc_map");
    tc_vc_map.configure(this, 8, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bits 8-15: RsvdP (Reserved and Preserved) (8 bits)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 8, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bit 16: Load Port Arbitration Table
    load_port_arbitration_table = uvm_reg_field::type_id::create("load_port_arbitration_table");
    load_port_arbitration_table.configure(this, 1, 16, "RW", 0, 0, 1, 0, 1);
    
    // Bits 17-19: Port Arbitration Select (3 bits)
    port_arbitration_select = uvm_reg_field::type_id::create("port_arbitration_select");
    port_arbitration_select.configure(this, 3, 17, "RW", 0, 0, 1, 0, 1);
    
    // Bits 20-23: RsvdP (Reserved and Preserved) (4 bits) - part of the larger RsvdP field
    // This is handled by extending the VC ID field or creating separate RsvdP fields
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 4, 20, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-26: VC ID (3 bits)
    vc_id = uvm_reg_field::type_id::create("vc_id");
    vc_id.configure(this, 3, 24, "RW", 0, 0, 1, 0, 1);
    
    // Bit 27-30: RsvdP (Reserved and Preserved) (4 bits)
    // Combined with the VC ID field spacing
    rsvdp_3 = uvm_reg_field::type_id::create("rsvdp_3");
    rsvdp_3.configure(this, 4, 27, "RO", 0, 0, 1, 0, 1);
    
    // Bit 31: VC Enable
    vc_enable = uvm_reg_field::type_id::create("vc_enable");
    vc_enable.configure(this, 1, 31, "RW", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_status_reg_1 extends uvm_reg;

  rand uvm_reg_field port_arbitration_table_status;
  rand uvm_reg_field vc_negotiation_pending;
  rand uvm_reg_field rsvdz;
  
  `uvm_object_utils(vc_resource_status_reg_1);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_status_reg_1");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Port Arbitration Table Status
    port_arbitration_table_status = uvm_reg_field::type_id::create("port_arbitration_table_status");
    port_arbitration_table_status.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 1: VC Negotiation Pending
    vc_negotiation_pending = uvm_reg_field::type_id::create("vc_negotiation_pending");
    vc_negotiation_pending.configure(this, 1, 1, "RO", 0, 0, 1, 0, 1);
    
    // Bits 2-15: RsvdZ (Reserved and Zero) (14 bits)
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 14, 2, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_capability_reg_2 extends uvm_reg;

  rand uvm_reg_field port_arbitration_capability;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field undefined;
  rand uvm_reg_field reject_snoop_transactions;
  rand uvm_reg_field maximum_time_slots;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field port_arbitration_table_offset;
  
  `uvm_object_utils(vc_resource_capability_reg_2);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_capability_reg_2");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: Port Arbitration Capability (8 bits)
    port_arbitration_capability = uvm_reg_field::type_id::create("port_arbitration_capability");
    port_arbitration_capability.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 8-13: RsvdP (Reserved and Preserved)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 6, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bits 14: Undefined (6 bits)
    undefined = uvm_reg_field::type_id::create("undefined");
    undefined.configure(this, 1, 14, "RO", 0, 0, 1, 0, 1);
    
    // Bit 15: Reject Snoop Transactions
    reject_snoop_transactions = uvm_reg_field::type_id::create("reject_snoop_transactions");
    reject_snoop_transactions.configure(this, 1, 15, "RO", 0, 0, 1, 0, 1);
    
    // Bits 16-22: Maximum Time Slots (8 bits)
    maximum_time_slots = uvm_reg_field::type_id::create("maximum_time_slots");
    maximum_time_slots.configure(this, 7, 16, "RO", 0, 0, 1, 0, 1);
    
    // Bit 23: RsvdP (Reserved and Preserved)
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 1, 23, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-31: Port Arbitration Table Offset (8 bits)
    port_arbitration_table_offset = uvm_reg_field::type_id::create("port_arbitration_table_offset");
    port_arbitration_table_offset.configure(this, 8, 24, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_control_reg_2 extends uvm_reg;

  rand uvm_reg_field tc_vc_map;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field load_port_arbitration_table;
  rand uvm_reg_field port_arbitration_select;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field vc_id;
  rand uvm_reg_field rsvdp_3;
  rand uvm_reg_field vc_enable;
  
  `uvm_object_utils(vc_resource_control_reg_2);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_control_reg_2");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: TC/VC Map (8 bits)
    tc_vc_map = uvm_reg_field::type_id::create("tc_vc_map");
    tc_vc_map.configure(this, 8, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bits 8-15: RsvdP (Reserved and Preserved) (8 bits)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 8, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bit 16: Load Port Arbitration Table
    load_port_arbitration_table = uvm_reg_field::type_id::create("load_port_arbitration_table");
    load_port_arbitration_table.configure(this, 1, 16, "RW", 0, 0, 1, 0, 1);
    
    // Bits 17-19: Port Arbitration Select (3 bits)
    port_arbitration_select = uvm_reg_field::type_id::create("port_arbitration_select");
    port_arbitration_select.configure(this, 3, 17, "RW", 0, 0, 1, 0, 1);
    
    // Bits 20-23: RsvdP (Reserved and Preserved) (4 bits) - part of the larger RsvdP field
    // This is handled by extending the VC ID field or creating separate RsvdP fields
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 4, 20, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-26: VC ID (3 bits)
    vc_id = uvm_reg_field::type_id::create("vc_id");
    vc_id.configure(this, 3, 24, "RW", 0, 0, 1, 0, 1);
    
    // Bit 27-30: RsvdP (Reserved and Preserved) (4 bits)
    // Combined with the VC ID field spacing
    rsvdp_3 = uvm_reg_field::type_id::create("rsvdp_3");
    rsvdp_3.configure(this, 4, 27, "RO", 0, 0, 1, 0, 1);
    
    // Bit 31: VC Enable
    vc_enable = uvm_reg_field::type_id::create("vc_enable");
    vc_enable.configure(this, 1, 31, "RW", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_status_reg_2 extends uvm_reg;

  rand uvm_reg_field port_arbitration_table_status;
  rand uvm_reg_field vc_negotiation_pending;
  rand uvm_reg_field rsvdz;
  
  `uvm_object_utils(vc_resource_status_reg_2);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_status_reg_2");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Port Arbitration Table Status
    port_arbitration_table_status = uvm_reg_field::type_id::create("port_arbitration_table_status");
    port_arbitration_table_status.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 1: VC Negotiation Pending
    vc_negotiation_pending = uvm_reg_field::type_id::create("vc_negotiation_pending");
    vc_negotiation_pending.configure(this, 1, 1, "RO", 0, 0, 1, 0, 1);
    
    // Bits 2-15: RsvdZ (Reserved and Zero) (14 bits)
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 14, 2, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_capability_reg_3 extends uvm_reg;

  rand uvm_reg_field port_arbitration_capability;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field undefined;
  rand uvm_reg_field reject_snoop_transactions;
  rand uvm_reg_field maximum_time_slots;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field port_arbitration_table_offset;
  
  `uvm_object_utils(vc_resource_capability_reg_3);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_capability_reg_3");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: Port Arbitration Capability (8 bits)
    port_arbitration_capability = uvm_reg_field::type_id::create("port_arbitration_capability");
    port_arbitration_capability.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 8-13: RsvdP (Reserved and Preserved)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 6, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bits 14: Undefined (6 bits)
    undefined = uvm_reg_field::type_id::create("undefined");
    undefined.configure(this, 1, 14, "RO", 0, 0, 1, 0, 1);
    
    // Bit 15: Reject Snoop Transactions
    reject_snoop_transactions = uvm_reg_field::type_id::create("reject_snoop_transactions");
    reject_snoop_transactions.configure(this, 1, 15, "RO", 0, 0, 1, 0, 1);
    
    // Bits 16-22: Maximum Time Slots (8 bits)
    maximum_time_slots = uvm_reg_field::type_id::create("maximum_time_slots");
    maximum_time_slots.configure(this, 7, 16, "RO", 0, 0, 1, 0, 1);
    
    // Bit 23: RsvdP (Reserved and Preserved)
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 1, 23, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-31: Port Arbitration Table Offset (8 bits)
    port_arbitration_table_offset = uvm_reg_field::type_id::create("port_arbitration_table_offset");
    port_arbitration_table_offset.configure(this, 8, 24, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_control_reg_3 extends uvm_reg;

  rand uvm_reg_field tc_vc_map;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field load_port_arbitration_table;
  rand uvm_reg_field port_arbitration_select;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field vc_id;
  rand uvm_reg_field rsvdp_3;
  rand uvm_reg_field vc_enable;
  
  `uvm_object_utils(vc_resource_control_reg_3);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_control_reg_3");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: TC/VC Map (8 bits)
    tc_vc_map = uvm_reg_field::type_id::create("tc_vc_map");
    tc_vc_map.configure(this, 8, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bits 8-15: RsvdP (Reserved and Preserved) (8 bits)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 8, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bit 16: Load Port Arbitration Table
    load_port_arbitration_table = uvm_reg_field::type_id::create("load_port_arbitration_table");
    load_port_arbitration_table.configure(this, 1, 16, "RW", 0, 0, 1, 0, 1);
    
    // Bits 17-19: Port Arbitration Select (3 bits)
    port_arbitration_select = uvm_reg_field::type_id::create("port_arbitration_select");
    port_arbitration_select.configure(this, 3, 17, "RW", 0, 0, 1, 0, 1);
    
    // Bits 20-23: RsvdP (Reserved and Preserved) (4 bits) - part of the larger RsvdP field
    // This is handled by extending the VC ID field or creating separate RsvdP fields
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 4, 20, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-26: VC ID (3 bits)
    vc_id = uvm_reg_field::type_id::create("vc_id");
    vc_id.configure(this, 3, 24, "RW", 0, 0, 1, 0, 1);
    
    // Bit 27-30: RsvdP (Reserved and Preserved) (4 bits)
    // Combined with the VC ID field spacing
    rsvdp_3 = uvm_reg_field::type_id::create("rsvdp_3");
    rsvdp_3.configure(this, 4, 27, "RO", 0, 0, 1, 0, 1);
    
    // Bit 31: VC Enable
    vc_enable = uvm_reg_field::type_id::create("vc_enable");
    vc_enable.configure(this, 1, 31, "RW", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_status_reg_3 extends uvm_reg;

  rand uvm_reg_field port_arbitration_table_status;
  rand uvm_reg_field vc_negotiation_pending;
  rand uvm_reg_field rsvdz;
  
  `uvm_object_utils(vc_resource_status_reg_3);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_status_reg_3");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Port Arbitration Table Status
    port_arbitration_table_status = uvm_reg_field::type_id::create("port_arbitration_table_status");
    port_arbitration_table_status.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 1: VC Negotiation Pending
    vc_negotiation_pending = uvm_reg_field::type_id::create("vc_negotiation_pending");
    vc_negotiation_pending.configure(this, 1, 1, "RO", 0, 0, 1, 0, 1);
    
    // Bits 2-15: RsvdZ (Reserved and Zero) (14 bits)
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 14, 2, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_capability_reg_4 extends uvm_reg;

  rand uvm_reg_field port_arbitration_capability;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field undefined;
  rand uvm_reg_field reject_snoop_transactions;
  rand uvm_reg_field maximum_time_slots;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field port_arbitration_table_offset;
  
  `uvm_object_utils(vc_resource_capability_reg_4);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_capability_reg_4");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: Port Arbitration Capability (8 bits)
    port_arbitration_capability = uvm_reg_field::type_id::create("port_arbitration_capability");
    port_arbitration_capability.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 8-13: RsvdP (Reserved and Preserved)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 6, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bits 14: Undefined (6 bits)
    undefined = uvm_reg_field::type_id::create("undefined");
    undefined.configure(this, 1, 14, "RO", 0, 0, 1, 0, 1);
    
    // Bit 15: Reject Snoop Transactions
    reject_snoop_transactions = uvm_reg_field::type_id::create("reject_snoop_transactions");
    reject_snoop_transactions.configure(this, 1, 15, "RO", 0, 0, 1, 0, 1);
    
    // Bits 16-22: Maximum Time Slots (8 bits)
    maximum_time_slots = uvm_reg_field::type_id::create("maximum_time_slots");
    maximum_time_slots.configure(this, 7, 16, "RO", 0, 0, 1, 0, 1);
    
    // Bit 23: RsvdP (Reserved and Preserved)
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 1, 23, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-31: Port Arbitration Table Offset (8 bits)
    port_arbitration_table_offset = uvm_reg_field::type_id::create("port_arbitration_table_offset");
    port_arbitration_table_offset.configure(this, 8, 24, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_control_reg_4 extends uvm_reg;

  rand uvm_reg_field tc_vc_map;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field load_port_arbitration_table;
  rand uvm_reg_field port_arbitration_select;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field vc_id;
  rand uvm_reg_field rsvdp_3;
  rand uvm_reg_field vc_enable;
  
  `uvm_object_utils(vc_resource_control_reg_4);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_control_reg_4");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: TC/VC Map (8 bits)
    tc_vc_map = uvm_reg_field::type_id::create("tc_vc_map");
    tc_vc_map.configure(this, 8, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bits 8-15: RsvdP (Reserved and Preserved) (8 bits)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 8, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bit 16: Load Port Arbitration Table
    load_port_arbitration_table = uvm_reg_field::type_id::create("load_port_arbitration_table");
    load_port_arbitration_table.configure(this, 1, 16, "RW", 0, 0, 1, 0, 1);
    
    // Bits 17-19: Port Arbitration Select (3 bits)
    port_arbitration_select = uvm_reg_field::type_id::create("port_arbitration_select");
    port_arbitration_select.configure(this, 3, 17, "RW", 0, 0, 1, 0, 1);
    
    // Bits 20-23: RsvdP (Reserved and Preserved) (4 bits) - part of the larger RsvdP field
    // This is handled by extending the VC ID field or creating separate RsvdP fields
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 4, 20, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-26: VC ID (3 bits)
    vc_id = uvm_reg_field::type_id::create("vc_id");
    vc_id.configure(this, 3, 24, "RW", 0, 0, 1, 0, 1);
    
    // Bit 27-30: RsvdP (Reserved and Preserved) (4 bits)
    // Combined with the VC ID field spacing
    rsvdp_3 = uvm_reg_field::type_id::create("rsvdp_3");
    rsvdp_3.configure(this, 4, 27, "RO", 0, 0, 1, 0, 1);
    
    // Bit 31: VC Enable
    vc_enable = uvm_reg_field::type_id::create("vc_enable");
    vc_enable.configure(this, 1, 31, "RW", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_status_reg_4 extends uvm_reg;

  rand uvm_reg_field port_arbitration_table_status;
  rand uvm_reg_field vc_negotiation_pending;
  rand uvm_reg_field rsvdz;
  
  `uvm_object_utils(vc_resource_status_reg_4);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_status_reg_4");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Port Arbitration Table Status
    port_arbitration_table_status = uvm_reg_field::type_id::create("port_arbitration_table_status");
    port_arbitration_table_status.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 1: VC Negotiation Pending
    vc_negotiation_pending = uvm_reg_field::type_id::create("vc_negotiation_pending");
    vc_negotiation_pending.configure(this, 1, 1, "RO", 0, 0, 1, 0, 1);
    
    // Bits 2-15: RsvdZ (Reserved and Zero) (14 bits)
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 14, 2, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_capability_reg_5 extends uvm_reg;

  rand uvm_reg_field port_arbitration_capability;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field undefined;
  rand uvm_reg_field reject_snoop_transactions;
  rand uvm_reg_field maximum_time_slots;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field port_arbitration_table_offset;
  
  `uvm_object_utils(vc_resource_capability_reg_5);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_capability_reg_5");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: Port Arbitration Capability (8 bits)
    port_arbitration_capability = uvm_reg_field::type_id::create("port_arbitration_capability");
    port_arbitration_capability.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 8-13: RsvdP (Reserved and Preserved)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 6, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bits 14: Undefined (6 bits)
    undefined = uvm_reg_field::type_id::create("undefined");
    undefined.configure(this, 1, 14, "RO", 0, 0, 1, 0, 1);
    
    // Bit 15: Reject Snoop Transactions
    reject_snoop_transactions = uvm_reg_field::type_id::create("reject_snoop_transactions");
    reject_snoop_transactions.configure(this, 1, 15, "RO", 0, 0, 1, 0, 1);
    
    // Bits 16-22: Maximum Time Slots (8 bits)
    maximum_time_slots = uvm_reg_field::type_id::create("maximum_time_slots");
    maximum_time_slots.configure(this, 7, 16, "RO", 0, 0, 1, 0, 1);
    
    // Bit 23: RsvdP (Reserved and Preserved)
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 1, 23, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-31: Port Arbitration Table Offset (8 bits)
    port_arbitration_table_offset = uvm_reg_field::type_id::create("port_arbitration_table_offset");
    port_arbitration_table_offset.configure(this, 8, 24, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_control_reg_5 extends uvm_reg;

  rand uvm_reg_field tc_vc_map;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field load_port_arbitration_table;
  rand uvm_reg_field port_arbitration_select;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field vc_id;
  rand uvm_reg_field rsvdp_3;
  rand uvm_reg_field vc_enable;
  
  `uvm_object_utils(vc_resource_control_reg_5);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_control_reg_5");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: TC/VC Map (8 bits)
    tc_vc_map = uvm_reg_field::type_id::create("tc_vc_map");
    tc_vc_map.configure(this, 8, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bits 8-15: RsvdP (Reserved and Preserved) (8 bits)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 8, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bit 16: Load Port Arbitration Table
    load_port_arbitration_table = uvm_reg_field::type_id::create("load_port_arbitration_table");
    load_port_arbitration_table.configure(this, 1, 16, "RW", 0, 0, 1, 0, 1);
    
    // Bits 17-19: Port Arbitration Select (3 bits)
    port_arbitration_select = uvm_reg_field::type_id::create("port_arbitration_select");
    port_arbitration_select.configure(this, 3, 17, "RW", 0, 0, 1, 0, 1);
    
    // Bits 20-23: RsvdP (Reserved and Preserved) (4 bits) - part of the larger RsvdP field
    // This is handled by extending the VC ID field or creating separate RsvdP fields
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 4, 20, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-26: VC ID (3 bits)
    vc_id = uvm_reg_field::type_id::create("vc_id");
    vc_id.configure(this, 3, 24, "RW", 0, 0, 1, 0, 1);
    
    // Bit 27-30: RsvdP (Reserved and Preserved) (4 bits)
    // Combined with the VC ID field spacing
    rsvdp_3 = uvm_reg_field::type_id::create("rsvdp_3");
    rsvdp_3.configure(this, 4, 27, "RO", 0, 0, 1, 0, 1);
    
    // Bit 31: VC Enable
    vc_enable = uvm_reg_field::type_id::create("vc_enable");
    vc_enable.configure(this, 1, 31, "RW", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_status_reg_5 extends uvm_reg;

  rand uvm_reg_field port_arbitration_table_status;
  rand uvm_reg_field vc_negotiation_pending;
  rand uvm_reg_field rsvdz;
  
  `uvm_object_utils(vc_resource_status_reg_5);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_status_reg_5");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Port Arbitration Table Status
    port_arbitration_table_status = uvm_reg_field::type_id::create("port_arbitration_table_status");
    port_arbitration_table_status.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 1: VC Negotiation Pending
    vc_negotiation_pending = uvm_reg_field::type_id::create("vc_negotiation_pending");
    vc_negotiation_pending.configure(this, 1, 1, "RO", 0, 0, 1, 0, 1);
    
    // Bits 2-15: RsvdZ (Reserved and Zero) (14 bits)
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 14, 2, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_capability_reg_6 extends uvm_reg;

  rand uvm_reg_field port_arbitration_capability;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field undefined;
  rand uvm_reg_field reject_snoop_transactions;
  rand uvm_reg_field maximum_time_slots;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field port_arbitration_table_offset;
  
  `uvm_object_utils(vc_resource_capability_reg_6);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_capability_reg_6");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: Port Arbitration Capability (8 bits)
    port_arbitration_capability = uvm_reg_field::type_id::create("port_arbitration_capability");
    port_arbitration_capability.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 8-13: RsvdP (Reserved and Preserved)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 6, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bits 14: Undefined (6 bits)
    undefined = uvm_reg_field::type_id::create("undefined");
    undefined.configure(this, 1, 14, "RO", 0, 0, 1, 0, 1);
    
    // Bit 15: Reject Snoop Transactions
    reject_snoop_transactions = uvm_reg_field::type_id::create("reject_snoop_transactions");
    reject_snoop_transactions.configure(this, 1, 15, "RO", 0, 0, 1, 0, 1);
    
    // Bits 16-22: Maximum Time Slots (8 bits)
    maximum_time_slots = uvm_reg_field::type_id::create("maximum_time_slots");
    maximum_time_slots.configure(this, 7, 16, "RO", 0, 0, 1, 0, 1);
    
    // Bit 23: RsvdP (Reserved and Preserved)
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 1, 23, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-31: Port Arbitration Table Offset (8 bits)
    port_arbitration_table_offset = uvm_reg_field::type_id::create("port_arbitration_table_offset");
    port_arbitration_table_offset.configure(this, 8, 24, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_control_reg_6 extends uvm_reg;

  rand uvm_reg_field tc_vc_map;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field load_port_arbitration_table;
  rand uvm_reg_field port_arbitration_select;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field vc_id;
  rand uvm_reg_field rsvdp_3;
  rand uvm_reg_field vc_enable;
  
  `uvm_object_utils(vc_resource_control_reg_6);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_control_reg_6");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: TC/VC Map (8 bits)
    tc_vc_map = uvm_reg_field::type_id::create("tc_vc_map");
    tc_vc_map.configure(this, 8, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bits 8-15: RsvdP (Reserved and Preserved) (8 bits)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 8, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bit 16: Load Port Arbitration Table
    load_port_arbitration_table = uvm_reg_field::type_id::create("load_port_arbitration_table");
    load_port_arbitration_table.configure(this, 1, 16, "RW", 0, 0, 1, 0, 1);
    
    // Bits 17-19: Port Arbitration Select (3 bits)
    port_arbitration_select = uvm_reg_field::type_id::create("port_arbitration_select");
    port_arbitration_select.configure(this, 3, 17, "RW", 0, 0, 1, 0, 1);
    
    // Bits 20-23: RsvdP (Reserved and Preserved) (4 bits) - part of the larger RsvdP field
    // This is handled by extending the VC ID field or creating separate RsvdP fields
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 4, 20, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-26: VC ID (3 bits)
    vc_id = uvm_reg_field::type_id::create("vc_id");
    vc_id.configure(this, 3, 24, "RW", 0, 0, 1, 0, 1);
    
    // Bit 27-30: RsvdP (Reserved and Preserved) (4 bits)
    // Combined with the VC ID field spacing
    rsvdp_3 = uvm_reg_field::type_id::create("rsvdp_3");
    rsvdp_3.configure(this, 4, 27, "RO", 0, 0, 1, 0, 1);
    
    // Bit 31: VC Enable
    vc_enable = uvm_reg_field::type_id::create("vc_enable");
    vc_enable.configure(this, 1, 31, "RW", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_status_reg_6 extends uvm_reg;

  rand uvm_reg_field port_arbitration_table_status;
  rand uvm_reg_field vc_negotiation_pending;
  rand uvm_reg_field rsvdz;
  
  `uvm_object_utils(vc_resource_status_reg_6);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_status_reg_6");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Port Arbitration Table Status
    port_arbitration_table_status = uvm_reg_field::type_id::create("port_arbitration_table_status");
    port_arbitration_table_status.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 1: VC Negotiation Pending
    vc_negotiation_pending = uvm_reg_field::type_id::create("vc_negotiation_pending");
    vc_negotiation_pending.configure(this, 1, 1, "RO", 0, 0, 1, 0, 1);
    
    // Bits 2-15: RsvdZ (Reserved and Zero) (14 bits)
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 14, 2, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_capability_reg_7 extends uvm_reg;

  rand uvm_reg_field port_arbitration_capability;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field undefined;
  rand uvm_reg_field reject_snoop_transactions;
  rand uvm_reg_field maximum_time_slots;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field port_arbitration_table_offset;
  
  `uvm_object_utils(vc_resource_capability_reg_7);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_capability_reg_7");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: Port Arbitration Capability (8 bits)
    port_arbitration_capability = uvm_reg_field::type_id::create("port_arbitration_capability");
    port_arbitration_capability.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 8-13: RsvdP (Reserved and Preserved)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 6, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bits 14: Undefined (6 bits)
    undefined = uvm_reg_field::type_id::create("undefined");
    undefined.configure(this, 1, 14, "RO", 0, 0, 1, 0, 1);
    
    // Bit 15: Reject Snoop Transactions
    reject_snoop_transactions = uvm_reg_field::type_id::create("reject_snoop_transactions");
    reject_snoop_transactions.configure(this, 1, 15, "RO", 0, 0, 1, 0, 1);
    
    // Bits 16-22: Maximum Time Slots (8 bits)
    maximum_time_slots = uvm_reg_field::type_id::create("maximum_time_slots");
    maximum_time_slots.configure(this, 7, 16, "RO", 0, 0, 1, 0, 1);
    
    // Bit 23: RsvdP (Reserved and Preserved)
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 1, 23, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-31: Port Arbitration Table Offset (8 bits)
    port_arbitration_table_offset = uvm_reg_field::type_id::create("port_arbitration_table_offset");
    port_arbitration_table_offset.configure(this, 8, 24, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_control_reg_7 extends uvm_reg;

  rand uvm_reg_field tc_vc_map;
  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field load_port_arbitration_table;
  rand uvm_reg_field port_arbitration_select;
  rand uvm_reg_field rsvdp_2;
  rand uvm_reg_field vc_id;
  rand uvm_reg_field rsvdp_3;
  rand uvm_reg_field vc_enable;
  
  `uvm_object_utils(vc_resource_control_reg_7);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_control_reg_7");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-7: TC/VC Map (8 bits)
    tc_vc_map = uvm_reg_field::type_id::create("tc_vc_map");
    tc_vc_map.configure(this, 8, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bits 8-15: RsvdP (Reserved and Preserved) (8 bits)
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 8, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bit 16: Load Port Arbitration Table
    load_port_arbitration_table = uvm_reg_field::type_id::create("load_port_arbitration_table");
    load_port_arbitration_table.configure(this, 1, 16, "RW", 0, 0, 1, 0, 1);
    
    // Bits 17-19: Port Arbitration Select (3 bits)
    port_arbitration_select = uvm_reg_field::type_id::create("port_arbitration_select");
    port_arbitration_select.configure(this, 3, 17, "RW", 0, 0, 1, 0, 1);
    
    // Bits 20-23: RsvdP (Reserved and Preserved) (4 bits) - part of the larger RsvdP field
    // This is handled by extending the VC ID field or creating separate RsvdP fields
    rsvdp_2 = uvm_reg_field::type_id::create("rsvdp_2");
    rsvdp_2.configure(this, 4, 20, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-26: VC ID (3 bits)
    vc_id = uvm_reg_field::type_id::create("vc_id");
    vc_id.configure(this, 3, 24, "RW", 0, 0, 1, 0, 1);
    
    // Bit 27-30: RsvdP (Reserved and Preserved) (4 bits)
    // Combined with the VC ID field spacing
    rsvdp_3 = uvm_reg_field::type_id::create("rsvdp_3");
    rsvdp_3.configure(this, 4, 27, "RO", 0, 0, 1, 0, 1);
    
    // Bit 31: VC Enable
    vc_enable = uvm_reg_field::type_id::create("vc_enable");
    vc_enable.configure(this, 1, 31, "RW", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class vc_resource_status_reg_7 extends uvm_reg;

  rand uvm_reg_field port_arbitration_table_status;
  rand uvm_reg_field vc_negotiation_pending;
  rand uvm_reg_field rsvdz;
  
  `uvm_object_utils(vc_resource_status_reg_7);

  // Constructor: initialize the register with name and size
  function new(string name = "vc_resource_status_reg_7");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Port Arbitration Table Status
    port_arbitration_table_status = uvm_reg_field::type_id::create("port_arbitration_table_status");
    port_arbitration_table_status.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 1: VC Negotiation Pending
    vc_negotiation_pending = uvm_reg_field::type_id::create("vc_negotiation_pending");
    vc_negotiation_pending.configure(this, 1, 1, "RO", 0, 0, 1, 0, 1);
    
    // Bits 2-15: RsvdZ (Reserved and Zero) (14 bits)
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 14, 2, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass
