// Define a 16-bit vendor ID register class
class vendor_id_reg extends uvm_reg;

  // Declare a field to hold the vendor ID
  rand uvm_reg_field vendor_id_fields;

  // Register the class with the UVM factory for factory-based creation
  `uvm_object_utils(vendor_id_reg)

  // Constructor: initialize the register with name and size (16 bits), no coverage
  function new(string name = "vendor_id_reg");
    super.new(name, 16, build_coverage(UVM_NO_COVERAGE));
  endfunction

  // Build method: create and configure the field
  virtual function void build();

    // Create the field instance
    vendor_id_fields = uvm_reg_field::type_id::create("vendor_id_fields");

    // Configure the field with the following properties:
    // - parent: this register
    // - size: 16 bits
    // - lsb_pos: starting at bit 0
    // - access: "RO" (read-only)
    // - volatile: 0 (not volatile)
    // - reset: 0xFFFF
    // - has_reset: 1 (reset value is defined)
    // - is_rand: 0 (not randomizable)
    // - individually_accessible: 0 (not accessed independently)
    vendor_id_fields.configure(
      .parent(this), .size(16), .lsb_pos(0), .access("RO"),
      .volatile(0), .reset(16'h8086), .has_reset(1),
      .is_rand(0), .individually_accessible(0)
    );

  endfunction

endclass



// Define a 16-bit device ID register class
class device_id_reg extends uvm_reg;

  // Declare a field to hold the device ID
  rand uvm_reg_field device_id_fields;

  // Register the class with the UVM factory
  `uvm_object_utils(device_id_reg)

  // Constructor: define register name and size (16 bits), no coverage
  function new(string name = "device_id_reg");
    super.new(name, 16, build_coverage(UVM_NO_COVERAGE));
  endfunction

  // Build method: create and configure the field
  virtual function void build();
    // Create the field instance
    device_id_fields = uvm_reg_field::type_id::create("device_id_fields");

    // Configure the field with:
    // - parent register
    // - size: 16 bits
    // - lsb_pos: starting at bit 16 (suggests shared address with another field)
    // - access: read/write
    // - volatile: 0 (not volatile)
    // - reset: default value 0xFFFF
    // - has_reset: true
    // - is_rand: true (can be randomized)
    // - individually_accessible: true (can be accessed independently)
    device_id_fields.configure(
      .parent(this), .size(16), .lsb_pos(0), .access("RW"),
      .volatile(0), .reset(16'h10d3), .has_reset(1),
      .is_rand(1), .individually_accessible(1)
    );
  endfunction

endclass


// Define a 16-bit command register class
class command_reg extends uvm_reg;

  // Declare individual control fields representing various command bits
  rand uvm_reg_field io_space_enable;
  rand uvm_reg_field memory_space_enable;
  rand uvm_reg_field bus_master_enable;
  rand uvm_reg_field special_cycle_enable;
  rand uvm_reg_field VGS_palette_snoop;
  rand uvm_reg_field memory_write_and_invalidate;
  rand uvm_reg_field parity_error_response;
  rand uvm_reg_field idsel_stepping_cycle_control;
  rand uvm_reg_field SERR_enable;
  rand uvm_reg_field fast_back_to_back_transactions_enable;
  rand uvm_reg_field interrupt_disable;
  rand uvm_reg_field reserved;

  // Register the class with the UVM factory
  `uvm_object_utils(command_reg)

  // Constructor: define register name and size (16 bits), no coverage
  function new(string name = "command_reg");
    super.new(name, 16, build_coverage(UVM_NO_COVERAGE));
  endfunction

  // Build method: create and configure each field
  virtual function void build();

    // Create each field instance
    io_space_enable = uvm_reg_field::type_id::create("io_space_enable");
    memory_space_enable = uvm_reg_field::type_id::create("memory_space_enable");
    bus_master_enable = uvm_reg_field::type_id::create("bus_master_enable");
    special_cycle_enable = uvm_reg_field::type_id::create("special_cycle_enable");
    memory_write_and_invalidate = uvm_reg_field::type_id::create("memory_write_and_invalidate");
    VGS_palette_snoop = uvm_reg_field::type_id::create("VGS_palette_snoop");
    parity_error_response = uvm_reg_field::type_id::create("parity_error_response");
    idsel_stepping_cycle_control = uvm_reg_field::type_id::create("idsel_stepping_cycle_control");
    SERR_enable = uvm_reg_field::type_id::create("SERR_enable");
    fast_back_to_back_transactions_enable = uvm_reg_field::type_id::create("fast_back_to_back_transactions_enable");
    interrupt_disable = uvm_reg_field::type_id::create("interrupt_disable");
    reserved = uvm_reg_field::type_id::create("reserved");

    // Configure each field with:
    // - parent register
    // - bit width
    // - bit position
    // - access type (RW or RO)
    // - volatility
    // - reset value
    // - has_reset
    // - is_rand
    // - individually_accessible

    io_space_enable.configure(this, 1, 0, "RW", 0, 0, 1, 1, 1);
    memory_space_enable.configure(this, 1, 1, "RW", 0, 0, 1, 1, 1);
    bus_master_enable.configure(this, 1, 2, "RW", 0, 0, 1, 1, 1);
    special_cycle_enable.configure(this, 1, 3, "RO", 0, 0, 1, 0, 1);
    memory_write_and_invalidate.configure(this, 1, 4, "RO", 0, 0, 1, 0, 1);
    VGS_palette_snoop.configure(this, 1, 5, "RO", 0, 0, 1, 0, 1);
    parity_error_response.configure(this, 1, 6, "RW", 0, 0, 1, 1, 1);
    idsel_stepping_cycle_control.configure(this, 1, 7, "RO", 0, 0, 1, 0, 1);
    SERR_enable.configure(this, 1, 8, "RW", 0, 0, 1, 1, 1);
    fast_back_to_back_transactions_enable.configure(this, 1, 9, "RO", 0, 0, 1, 0, 1);
    interrupt_disable.configure(this, 1, 10, "RW", 0, 0, 1, 1, 1);
    reserved.configure(this, 5, 11, "RO", 0, 0, 1, 0, 1); // Bits 11–15 reserved

  endfunction

endclass


// Define a 32-bit status register class
class status_reg extends uvm_reg;

  // Declare all fields within the status register
  rand uvm_reg_field immediate_readiness;
  rand uvm_reg_field reserved_bit1_2;
  rand uvm_reg_field interrupt_status;
  rand uvm_reg_field capabilities_list;
  rand uvm_reg_field mhz_66_capable;
  rand uvm_reg_field reserved_bit6;
  rand uvm_reg_field back_to_back_transaction_capable;
  rand uvm_reg_field master_data_parity_error;
  rand uvm_reg_field devsel_timing;
  rand uvm_reg_field signaled_target_abort;
  rand uvm_reg_field received_target_abort;
  rand uvm_reg_field received_master_abort;
  rand uvm_reg_field signaled_system_error;
  rand uvm_reg_field detected_parity_error;

  // Register the class with the UVM factory
  `uvm_object_utils(status_reg)

  // Constructor: define register name and size (32 bits), no coverage
  function new(string name = "status_reg");
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build method: create and configure each field
  virtual function void build();

    // Bit 16: Indicates device is ready
    immediate_readiness = uvm_reg_field::type_id::create("immediate_readiness");
    immediate_readiness.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);

    // Bits 17-18: Reserved
    reserved_bit1_2 = uvm_reg_field::type_id::create("reserved_bit1_2");
    reserved_bit1_2.configure(this, 2, 1, "RO", 0, 0, 1, 0, 1);

    // Bit 19: Interrupt status flag
    interrupt_status = uvm_reg_field::type_id::create("interrupt_status");
    interrupt_status.configure(this, 1, 3, "RO", 0, 0, 1, 0, 1);

    // Bit 20: Indicates presence of capabilities list
    capabilities_list = uvm_reg_field::type_id::create("capabilities_list");
    capabilities_list.configure(this, 1, 4, "RO", 0, 0, 1, 0, 1);

    // Bit 21: 66 MHz capable flag
    mhz_66_capable = uvm_reg_field::type_id::create("mhz_66_capable");
    mhz_66_capable.configure(this, 1, 5, "RO", 0, 0, 1, 0, 1);

    // Bit 22: Reserved
    reserved_bit6 = uvm_reg_field::type_id::create("reserved_bit6");
    reserved_bit6.configure(this, 1, 6, "RO", 0, 0, 1, 0, 1);

    // Bit 23: Back-to-back transaction capability
    back_to_back_transaction_capable = uvm_reg_field::type_id::create("back_to_back_transaction_capable");
    back_to_back_transaction_capable.configure(this, 1, 7, "RO", 0, 0, 1, 0, 1);

    // Bit 24: Master data parity error detected
    master_data_parity_error = uvm_reg_field::type_id::create("master_data_parity_error");
    master_data_parity_error.configure(this, 1, 8, "RO", 0, 0, 1, 0, 1);

    // Bits 25-26: DEVSEL timing encoding
    devsel_timing = uvm_reg_field::type_id::create("devsel_timing");
    devsel_timing.configure(this, 2, 9, "RO", 0, 0, 1, 0, 1);

    // Bit 27: Signaled target abort
    signaled_target_abort = uvm_reg_field::type_id::create("signaled_target_abort");
    signaled_target_abort.configure(this, 1, 11, "RO", 0, 0, 1, 0, 1);

    // Bit 28: Received target abort
    received_target_abort = uvm_reg_field::type_id::create("received_target_abort");
    received_target_abort.configure(this, 1, 12, "RO", 0, 0, 1, 0, 1);

    // Bit 29: Received master abort
    received_master_abort = uvm_reg_field::type_id::create("received_master_abort");
    received_master_abort.configure(this, 1, 13, "RO", 0, 0, 1, 0, 1);

    // Bit 30: Signaled system error
    signaled_system_error = uvm_reg_field::type_id::create("signaled_system_error");
    signaled_system_error.configure(this, 1, 14, "RO", 0, 0, 1, 0, 1);

    // Bit 31: Detected parity error
    detected_parity_error = uvm_reg_field::type_id::create("detected_parity_error");
    detected_parity_error.configure(this, 1, 15, "RO", 0, 0, 1, 0, 1);

  endfunction

endclass

// Define an 8-bit revision ID register class
class revision_id_reg extends uvm_reg;

  // Declare a field to hold the revision ID
  rand uvm_reg_field revision_id_fields;

  // Register the class with the UVM factory for dynamic creation
  `uvm_object_utils(revision_id_reg)

  // Constructor: initialize the register with name and size (8 bits), no coverage
  function new(string name = "revision_id_reg");
    super.new(name, 8, build_coverage(UVM_NO_COVERAGE));
  endfunction

  // Build method: create and configure the field
  virtual function void build();

    // Create the field instance
    revision_id_fields = uvm_reg_field::type_id::create("revision_id_fields");

    // Configure the field with:
    // - parent: this register
    // - size: 8 bits
    // - lsb_pos: starting at bit 0
    // - access: "RO" (read-only)
    // - volatile: 0 (not volatile)
    // - reset: 0 (default value)
    // - has_reset: 1 (reset value is defined)
    // - is_rand: 0 (not randomizable)
    // - individually_accessible: 0 (accessed as part of the whole register)
    revision_id_fields.configure(
      .parent(this), .size(8), .lsb_pos(0), .access("RO"),
      .volatile(0), .reset(0), .has_reset(1),
      .is_rand(0), .individually_accessible(0)
    );

  endfunction

endclass


// Define a 24-bit class code register class
class class_code_reg extends uvm_reg;

  // Declare fields representing class code components
  uvm_reg_field base_class_code;         
  uvm_reg_field sub_class_code;          
  uvm_reg_field programming_interface;   

  // Register the class with the UVM factory
  `uvm_object_utils(class_code_reg)

  // Constructor: initialize the register with name and size (24 bits), no coverage
  function new(string name = "class_code_reg");
    super.new(name, 24, UVM_NO_COVERAGE);
  endfunction

  // Build method: create and configure each field
  virtual function void build();

    // Bits 8–15: Programming interface field
    programming_interface = uvm_reg_field::type_id::create("programming_interface");
    programming_interface.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);

    // Bits 16–23: Subclass code field
    sub_class_code = uvm_reg_field::type_id::create("sub_class_code");
    sub_class_code.configure(this, 8, 8, "RO", 0, 0, 1, 0, 1);

    // Bits 24–31: Base class code field
    base_class_code = uvm_reg_field::type_id::create("base_class_code");
    base_class_code.configure(this, 8, 16, "RO", 0, 0, 1, 0, 1);

  endfunction

endclass

// Define an 8-bit cache line size register class
class cache_line_size_reg extends uvm_reg;

  // Declare a field to hold the cache line size value
  rand uvm_reg_field cache_line_size_fields;

  // Register the class with the UVM factory for dynamic creation
  `uvm_object_utils(cache_line_size_reg)

  // Constructor: initialize the register with name and size (8 bits), no coverage
  function new(string name = "cache_line_size_reg");
    super.new(name, 8, build_coverage(UVM_NO_COVERAGE));
  endfunction

  // Build method: create and configure the field
  virtual function void build();

    // Create the field instance
    cache_line_size_fields = uvm_reg_field::type_id::create("cache_line_size_fields");

    // Configure the field with:
    // - parent: this register
    // - size: 8 bits
    // - lsb_pos: starting at bit 0
    // - access: "RW" (read/write)
    // - volatile: 0 (not volatile)
    // - reset: 0 (default value)
    // - has_reset: 1 (reset value is defined)
    // - is_rand: 1 (can be randomized)
    // - individually_accessible: 1 (can be accessed independently)
    cache_line_size_fields.configure(
      .parent(this), .size(8), .lsb_pos(0), .access("RW"),
      .volatile(0), .reset(0), .has_reset(1),
      .is_rand(1), .individually_accessible(1)
    );

  endfunction

endclass

// Define an 8-bit latency timer register class
class latency_timer_reg extends uvm_reg;

  // Declare a field to hold the latency timer value
  rand uvm_reg_field latency_timer_fields;

  // Register the class with the UVM factory for dynamic creation
  `uvm_object_utils(latency_timer_reg)

  // Constructor: initialize the register with name and size (8 bits), no coverage
  function new(string name = "latency_timer_reg");
    super.new(name, 8, build_coverage(UVM_NO_COVERAGE));
  endfunction

  // Build method: create and configure the field
  virtual function void build();

    // Create the field instance
    latency_timer_fields = uvm_reg_field::type_id::create("latency_timer_fields");

    // Configure the field with:
    // - parent: this register
    // - size: 8 bits
    // - lsb_pos: starting at bit 8 (suggests shared address with another field)
    // - access: "RO" (read-only)
    // - volatile: 0 (not volatile)
    // - reset: 0 (default value)
    // - has_reset: 1 (reset value is defined)
    // - is_rand: 0 (not randomizable)
    // - individually_accessible: 1 (can be accessed independently)
    latency_timer_fields.configure(
      .parent(this), .size(8), .lsb_pos(0), .access("RO"),
      .volatile(0), .reset(0), .has_reset(1),
      .is_rand(0), .individually_accessible(1)
    );

  endfunction

endclass


// Define an 8-bit header type register class
class header_type_reg extends uvm_reg;

  // Declare fields representing header layout and multifunction device flag
  rand uvm_reg_field multi_function_device;
  rand uvm_reg_field header_layout;

  // Register the class with the UVM factory
  `uvm_object_utils(header_type_reg)

  // Constructor: initialize the register with name and size (8 bits), no coverage
  function new(string name = "header_type_reg");
    super.new(name, 8, UVM_NO_COVERAGE);
  endfunction

  // Build method: create and configure the fields
  virtual function void build();

    // Create and configure the header layout field
    // - size: 7 bits
    // - lsb_pos: 16 
    // - access: read-only
    header_layout = uvm_reg_field::type_id::create("header_layout");
    header_layout.configure(this, 7, 0, "RO", 0, 0, 1, 0, 1);

    // Create and configure the multifunction device field
    // - size: 1 bit
    // - lsb_pos: 23
    multi_function_device = uvm_reg_field::type_id::create("multi_function_device");
    multi_function_device.configure(this, 1, 7, "RO", 0, 0, 1, 0, 1);

  endfunction

endclass


// Define a register class extending from uvm_reg
class bist_reg extends uvm_reg;

  // Declare register fields as randomizable
  rand uvm_reg_field completion_code;
  rand uvm_reg_field rsvdP;
  rand uvm_reg_field start_bist;
  rand uvm_reg_field bist_capable;

  // Register the class with the UVM factory
  `uvm_object_utils(bist_reg)

  // Constructor: initialize the register with name and size
  function new(string name = "bist_reg");
    // Set register size to 32 bits (corrected from 8)
    super.new(name, 8, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure bist_capable field
    // 1-bit field at bit position 31, Read-Only
    bist_capable = uvm_reg_field::type_id::create("bist_capable");
    bist_capable.configure(this, 1, 7, "RO", 0, 0, 1, 0, 1);

    // Create and configure start_bist field
    // 1-bit field at bit position 30, Read-Write
    start_bist = uvm_reg_field::type_id::create("start_bist");
    start_bist.configure(this, 1, 6, "RW", 0, 0, 1, 1, 1);

    // Create and configure rsvdP field
    // 2-bit field at bit position 28, Read-Only
    rsvdP = uvm_reg_field::type_id::create("rsvdP");
    rsvdP.configure(this, 2, 4, "RO", 0, 0, 1, 0, 1);

    // Create and configure completion_code field
    // 4-bit field at bit position 24, Read-Only
    completion_code = uvm_reg_field::type_id::create("completion_code");
    completion_code.configure(this, 4, 0, "RO", 0, 0, 1, 0, 1);

  endfunction

endclass

// Define a register class extending from uvm_reg
class base_address_reg0 extends uvm_reg;

  // Declare register fields as randomizable
  rand uvm_reg_field base_addr;
  rand uvm_reg_field mem_or_io_space;//io or mem
  rand uvm_reg_field mem_type;//32 or 64
  rand uvm_reg_field prefetchable;
  rand uvm_reg_field request_size; 

  // Register the class with the UVM factory
  `uvm_object_utils(base_address_reg0)

  // Constructor: initialize the register with name and size
  function new(string name = "base_address_reg0");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Bit 0 - Memory Space Indicator
    // 1-bit field at bit position 0, 
    mem_or_io_space = uvm_reg_field::type_id::create("mem_or_io_space");
    mem_or_io_space.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);

    // Bits 2:1 - Memory Type
    // 2-bit field starting at bit position 1, 
    mem_type = uvm_reg_field::type_id::create("mem_type"); //32 bit "00"
    mem_type.configure(this, 2, 1, "RO", 0, 2'b0, 1, 0, 1);

    // Bit 3 - Prefetchable
    // 1-bit field at bit position 3, 
    prefetchable = uvm_reg_field::type_id::create("prefetchable"); //prefetchable "0" non pre "1"
    prefetchable.configure(this, 1, 3, "RO", 0, 0, 1, 0, 1);
    
    
    request_size = uvm_reg_field::type_id::create("request_size");
    request_size.configure(this,8,4,"RO",0,8'h0,1,0,1);

    // Bits 31:4 - Base Address
    // 28-bit field starting at bit position 4, 
    base_addr = uvm_reg_field::type_id::create("base_addr");//mem sizw 2**12
    base_addr.configure(this,20 , 12, "RW", 0, 0, 1, 1, 1);

  endfunction

endclass

// Define a register class extending from uvm_reg
class base_address_reg1 extends uvm_reg;

  // Declare register fields as randomizable
  rand uvm_reg_field base_addr;
  rand uvm_reg_field mem_or_io_space;//io or mem
  rand uvm_reg_field reserved;
  rand uvm_reg_field request_size; 

  // Register the class with the UVM factory
  `uvm_object_utils(base_address_reg1)

  // Constructor: initialize the register with name and size
  function new(string name = "base_address_reg0");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Bit 0 - Memory Space Indicator
    // 1-bit field at bit position 0, 
    mem_or_io_space = uvm_reg_field::type_id::create("mem_or_io_space");
    mem_or_io_space.configure(this, 1, 0, "RO", 0, 1, 1, 0, 1);// if this bit is 1 ,io space is enabled


    // Bit 3 - Prefetchable
    // 1-bit field at bit position 3, 
    reserved = uvm_reg_field::type_id::create("reserved"); //prefetchable "0" non prefechable "1"
    reserved.configure(this, 1, 1, "RO", 0, 0, 1, 0, 1);
    
    
    request_size = uvm_reg_field::type_id::create("request_size");
    request_size.configure(this,6,2,"RO",0,8'h0,1,0,1);

    // Bits 31:4 - Base Address
    // 28-bit field starting at bit position 4, 
    base_addr = uvm_reg_field::type_id::create("base_addr");//io sizw 2**8
    base_addr.configure(this,24 , 8, "RW", 0, 0, 1, 1, 1);

  endfunction
 
endclass


// Define a register class extending from uvm_reg
class base_address_reg2 extends uvm_reg;

  // Declare a register field
  uvm_reg_field base_address_2;

  // Register the class with the UVM factory
  `uvm_object_utils(base_address_reg2)

  // Constructor: initialize the register with name and size
  function new(string name = "base_address_reg2");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Bits 31:0 - Base Address 2
    // 32-bit field starting at bit position 0, Read-Write
    base_address_2 = uvm_reg_field::type_id::create("base_address_2");
    base_address_2.configure(this, 32, 0, "RW", 0, 0, 1, 1, 1);

  endfunction

endclass

// Define a register class extending from uvm_reg
class base_address_reg3 extends uvm_reg;

  // Declare a register field
  uvm_reg_field base_address_3;

  // Register the class with the UVM factory
  `uvm_object_utils(base_address_reg3)

  // Constructor: initialize the register with name and size
  function new(string name = "base_address_reg3");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Bits 31:0 - Base Address 3
    // 32-bit field starting at bit position 0, Read-Write
    base_address_3 = uvm_reg_field::type_id::create("base_address_3");
    base_address_3.configure(this, 32, 0, "RW", 0, 0, 1, 1, 1);

  endfunction

endclass

// Define a register class extending from uvm_reg
class base_address_reg4 extends uvm_reg;

  // Declare a register field
  uvm_reg_field base_address_4;

  // Register the class with the UVM factory
  `uvm_object_utils(base_address_reg4)

  // Constructor: initialize the register with name and size
  function new(string name = "base_address_reg4");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Bits 31:0 - Base Address 4
    // 32-bit field starting at bit position 0, Read-Only
    base_address_4 = uvm_reg_field::type_id::create("base_address_4");
    base_address_4.configure(this, 32, 0, "RO", 0, 0, 1, 0, 1);

  endfunction

endclass

// Define a register class extending from uvm_reg
class base_address_reg5 extends uvm_reg;

  // Declare a register field
  uvm_reg_field base_address_5;

  // Register the class with the UVM factory
  `uvm_object_utils(base_address_reg5)

  // Constructor: initialize the register with name and size
  function new(string name = "base_address_reg5");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Bits 31:0 - Base Address 5
    // 32-bit field starting at bit position 0, Read-Only
    base_address_5 = uvm_reg_field::type_id::create("base_address_5");
    base_address_5.configure(this, 32, 0, "RO", 0, 0, 1, 0, 1);

  endfunction

endclass


// Define a register class extending from uvm_reg
class cardbus_cis_pointer_reg extends uvm_reg;

  // Declare a register field
  uvm_reg_field cardbus_cis_pointer;

  // Register the class with the UVM factory
  `uvm_object_utils(cardbus_cis_pointer_reg)

  // Constructor: initialize the register with name and size
  function new(string name = "cardbus_cis_pointer_reg");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Bits 31:0 - CardBus CIS Pointer
    // 32-bit field starting at bit position 0, Read-Only
    cardbus_cis_pointer = uvm_reg_field::type_id::create("cardbus_cis_pointer");
    cardbus_cis_pointer.configure(this, 32, 0, "RO", 0, 0, 1, 0, 1);

  endfunction

endclass

// Define a register class extending from uvm_reg
class subsystem_vendor_id_reg extends uvm_reg;

  // Declare a register field
  rand uvm_reg_field subsystem_vendor_id_fields;

  // Register the class with the UVM factory
  `uvm_object_utils(subsystem_vendor_id_reg)

  // Constructor: initialize the register with name and size
  function new(string name = "subsystem_vendor_id_reg");
    // Set register size to 16 bits and disable functional coverage
    super.new(name, 16, build_coverage(UVM_NO_COVERAGE));
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Bits 15:0 - Subsystem Vendor ID
    // 16-bit field starting at bit position 0, Read-Write
    subsystem_vendor_id_fields = uvm_reg_field::type_id::create("subsystem_vendor_id_fields");
    subsystem_vendor_id_fields.configure(
      .parent(this),               // Parent register
      .size(16),                   // Field size: 16 bits
      .lsb_pos(0),                 // Starting bit position: 0
      .access("RW"),              // Read-Write access
      .volatile(0),                // Non-volatile
      .reset(16'h0),               // Reset value: 0
      .has_reset(1),               // Reset value is valid
      .is_rand(0),                 // Not randomized
      .individually_accessible(0)  // Not individually accessible
    );

  endfunction

endclass

// Define a register class extending from uvm_reg
class subsystem_id_reg extends uvm_reg;

  // Declare a register field
  rand uvm_reg_field subsystem_id_fields;

  // Register the class with the UVM factory
  `uvm_object_utils(subsystem_id_reg)

  // Constructor: initialize the register with name and size
  function new(string name = "subsystem_id_reg");
    // Set register size to 16 bits and disable functional coverage
    super.new(name, 16, build_coverage(UVM_NO_COVERAGE));
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Create and configure the subsystem_id_fields field
    // Field configuration:
    // - parent: this register
    // - size: 16 bits
    // - lsb_pos: 16 (starting bit position)
    // - access: "RW" (Read-Write)
    // - volatile: 0 (non-volatile)
    // - reset: 16'h0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 1 (field is randomized)
    // - individually_accessible: 1 (can be accessed independently)
    subsystem_id_fields = uvm_reg_field::type_id::create("subsystem_id_fields");
    subsystem_id_fields.configure(
      .parent(this),
      .size(16),
      .lsb_pos(0),
      .access("RW"),
      .volatile(0),
      .reset(16'h0),
      .has_reset(1),
      .is_rand(1),
      .individually_accessible(1)
    );

  endfunction

endclass

class expansion_rom_base_addr_reg extends uvm_reg;

  // Declare fields
  uvm_reg_field base_addr;
  uvm_reg_field rsvdp;
  uvm_reg_field rom_enable;
  uvm_reg_field rom_valid_status;
  uvm_reg_field rom_valid_details;

  // Factory registration
  `uvm_object_utils(expansion_rom_base_addr_reg)

  // Constructor
  function new(string name = "expansion_rom_base_addr_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to configure fields
  virtual function void build();

    // ROM Enable: bit [7]
    rom_enable = uvm_reg_field::type_id::create("rom_enable",,get_full_name());
    rom_enable.configure(this, 1, 0, "RW", 0,0,1,1,1);
    
    // ROM Validation Status: bit [6]
    rom_valid_status = uvm_reg_field::type_id::create("rom_valid_status",,get_full_name());
    rom_valid_status.configure(this, 3, 1, "RO",0,0,1,0,1);

    // ROM Validation Details: bits [5:0]
    rom_valid_details = uvm_reg_field::type_id::create("rom_valid_details",,get_full_name());
    rom_valid_details.configure(this, 4, 4, "RO",0,0,1,0,1);
     // Reserved: bits [10:8]
    rsvdp = uvm_reg_field::type_id::create("rsvdp",,get_full_name());
    rsvdp.configure(this, 3, 8, "RO", 0,0,1,0,1);
    // Base Address: bits [31:11]
    base_addr = uvm_reg_field::type_id::create("base_addr",,get_full_name());
    base_addr.configure(this, 21, 11, "RW", 0,0,1,1,1);

  endfunction

endclass

// Define a register class extending from uvm_reg
class capabilities_pointer_reg extends uvm_reg;

  // Declare a register field
  rand uvm_reg_field capabilities_pointer_fields;

  // Register the class with the UVM factory
  `uvm_object_utils(capabilities_pointer_reg)

  // Constructor: initialize the register with name and size
  function new(string name = "capabilities_pointer_reg");
    // Set register size to 8 bits and disable functional coverage
    super.new(name, 8, build_coverage(UVM_NO_COVERAGE));
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Create and configure the capabilities_pointer_fields field
    // Field configuration:
    // - parent: this register
    // - size: 8 bits
    // - lsb_pos: 0 (starting bit position)
    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 16'hffff (reset value, though it's wider than 8 bits)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 0 (not individually accessible)
    capabilities_pointer_fields = uvm_reg_field::type_id::create("capabilities_pointer_fields");
    capabilities_pointer_fields.configure(
      .parent(this),
      .size(8),
      .lsb_pos(0),
      .access("RO"),
      .volatile(0),
      .reset(16'hffff),
      .has_reset(1),
      .is_rand(0),
      .individually_accessible(0)
    );

  endfunction

endclass

// Define a register class extending from uvm_reg
class reserved_reg extends uvm_reg;

  // Declare a register field
  uvm_reg_field reserved_fields;

  // Register the class with the UVM factory
  `uvm_object_utils(reserved_reg)

  // Constructor: initialize the register with name and size
  function new(string name = "reserved_reg");
    // Set register size to 24 bits
    super.new(name, 24, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Create and configure the reserved_fields field
    // Field configuration:
    // - parent: this register
    // - size: 24 bits
    // - lsb_pos: 8 (starting bit position)
    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    reserved_fields = uvm_reg_field::type_id::create("reserved_fields");
    reserved_fields.configure(this, 24, 0, "RO", 0, 0, 1, 0, 1);

  endfunction

endclass

// Define a register class extending from uvm_reg
class reserved2_reg extends uvm_reg;

  // Declare a register field
  uvm_reg_field reserved_fields;

  // Register the class with the UVM factory
  `uvm_object_utils(reserved2_reg)

  // Constructor: initialize the register with name and size
  function new(string name = "reserved2_reg");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Create and configure the reserved_fields field
    // Field configuration:
    // - parent: this register
    // - size: 32 bits
    // - lsb_pos: 0 (starting bit position)
    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    reserved_fields = uvm_reg_field::type_id::create("reserved_fields");
    reserved_fields.configure(this, 32, 0, "RO", 0, 0, 1, 0, 1);

  endfunction

endclass

// Define a register class extending from uvm_reg
class interrupt_line_reg extends uvm_reg;

  // Declare a register field
  rand uvm_reg_field interrupt_line_fields;

  // Register the class with the UVM factory
  `uvm_object_utils(interrupt_line_reg)

  // Constructor: initialize the register with name and size
  function new(string name = "interrupt_line_reg");
    // Set register size to 8 bits and disable functional coverage
    super.new(name, 8, build_coverage(UVM_NO_COVERAGE));
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Create and configure the interrupt_line_fields field
    // Field configuration:
    // - parent: this register
    // - size: 8 bits
    // - lsb_pos: 0 (starting bit position)
    // - access: "RW" (Read-Write)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 1 (field is randomized)
    // - individually_accessible: 1 (can be accessed independently)
    interrupt_line_fields = uvm_reg_field::type_id::create("interrupt_line_fields");
    interrupt_line_fields.configure(
      .parent(this),
      .size(8),
      .lsb_pos(0),
      .access("RW"),
      .volatile(0),
      .reset(0),
      .has_reset(1),
      .is_rand(1),
      .individually_accessible(1)
    );

  endfunction

endclass

// Define a register class extending from uvm_reg
class interrupt_pin_reg extends uvm_reg;

  // Declare a register field
  rand uvm_reg_field interrupt_pin_fields;

  // Register the class with the UVM factory
  `uvm_object_utils(interrupt_pin_reg)

  // Constructor: initialize the register with name and size
  function new(string name = "interrupt_pin_reg");
    // Set register size to 8 bits and disable functional coverage
    super.new(name, 8, build_coverage(UVM_NO_COVERAGE));
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Create and configure the interrupt_pin_fields field
    // Field configuration:
    // - parent: this register
    // - size: 8 bits
    // - lsb_pos: 8 (starting bit position — note: this is outside the 8-bit range)
    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    interrupt_pin_fields = uvm_reg_field::type_id::create("interrupt_pin_fields");
    interrupt_pin_fields.configure(
      .parent(this),
      .size(8),
      .lsb_pos(0),
      .access("RO"),
      .volatile(0),
      .reset(0),
      .has_reset(1),
      .is_rand(0),
      .individually_accessible(1)
    );

  endfunction

endclass

// Define a register class extending from uvm_reg
class min_gnt_reg extends uvm_reg;

  // Declare a register field
  rand uvm_reg_field min_gnt_fields;

  // Register the class with the UVM factory
  `uvm_object_utils(min_gnt_reg)

  // Constructor: initialize the register with name and size
  function new(string name = "min_gnt_reg");
    // Set register size to 8 bits
    super.new(name, 8, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Create and configure the min_gnt_fields field
    // Field configuration:
    // - parent: this register
    // - size: 8 bits
    // - lsb_pos: 16 (starting bit position — note: this is outside the 8-bit range)
    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    min_gnt_fields = uvm_reg_field::type_id::create("min_gnt_fields");
    min_gnt_fields.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);

  endfunction

endclass

// Define a register class extending from uvm_reg
class max_lat_reg extends uvm_reg;

  // Declare a register field
  rand uvm_reg_field max_lat_fields;

  // Register the class with the UVM factory
  `uvm_object_utils(max_lat_reg)

  // Constructor: initialize the register with name and size
  function new(string name = "max_lat_reg");
    // Set register size to 8 bits
    super.new(name, 8, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the field
  virtual function void build();

    // Create and configure the max_lat_fields field
    // Field configuration:
    // - parent: this register
    // - size: 8 bits
    // - lsb_pos: 24 (starting bit position — note: this is outside the 8-bit range)
    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    max_lat_fields = uvm_reg_field::type_id::create("max_lat_fields");
    max_lat_fields.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);

  endfunction

endclass
/************************************************************************************************************************************************************PCIe_capability_register********************************************************************************************************/


class pcie_capability_list_reg extends uvm_reg;

  rand uvm_reg_field capabilty_id;
  rand uvm_reg_field next_capability_ptr;

  `uvm_object_utils(pcie_capability_list_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "pcie_capability_list_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

   // Build function to define and configure the field
  virtual function void build();

    // Create and configure the max_lat_fields field
    // Field configuration:
    // - parent: this register
    // - size: 16 bits
    // - lsb_pos: 0    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    capabilty_id = uvm_reg_field::type_id::create("capabilty_id");
    capabilty_id.configure(this, 8, 0, "RO", 0, 0, 1, 0, 1);

    next_capability_ptr = uvm_reg_field::type_id::create("next_capability_ptr");
    next_capability_ptr.configure(this, 8, 8, "RO", 0, 0, 1, 0, 1);
  
  endfunction

endclass


class pcie_capabilities_reg extends uvm_reg;

  rand uvm_reg_field capability_ver;
  rand uvm_reg_field device_or_port_type;
  rand uvm_reg_field slot_implemented;
  rand uvm_reg_field interrupt_msg_num;
  rand uvm_reg_field undefined;

  `uvm_object_utils(pcie_capabilities_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "pcie_capabilities_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

   // Build function to define and configure the field
  virtual function void build();

    // Create and configure the max_lat_fields field
    // Field configuration:
    // - parent: this register
    // - size: 4 bits
    // - lsb_pos: 0    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    capability_ver = uvm_reg_field::type_id::create("capability_ver");
    capability_ver.configure(this, 4, 0, "RO", 0, 0, 1, 0, 1);

    device_or_port_type = uvm_reg_field::type_id::create("device_or_port_type");
    device_or_port_type.configure(this, 4, 4, "RO", 0, 0, 1, 0, 1);

////
    slot_implemented = uvm_reg_field::type_id::create("slot_implemented");
    slot_implemented.configure(this, 1, 8, "RO", 0, 0, 1, 0, 1);

    interrupt_msg_num = uvm_reg_field::type_id::create("interrupt_msg_num");
    interrupt_msg_num.configure(this, 5, 9, "RO", 0, 0, 1, 0, 1);

    undefined = uvm_reg_field::type_id::create("undefined");
    undefined.configure(this, 1, 14, "RO", 0, 0, 1, 0, 1);

  
  endfunction

endclass
class device_capabilities_reg extends uvm_reg;

  rand uvm_reg_field max_payload_supported;
  rand uvm_reg_field phantom_function_supported;
  rand uvm_reg_field extended_tag_field_supported; 
  rand uvm_reg_field endpoint_L0s_acceptable_latency; 
  rand uvm_reg_field endpoint_L1s_acceptable_latency; 
  rand uvm_reg_field undefined; 
  rand uvm_reg_field role_based_error_reporting; 
  rand uvm_reg_field err_cor_subclass_capable; 
  rand uvm_reg_field captured_slot_power_limit_val; 
  rand uvm_reg_field captured_slot_power_limit_scale; 
  rand uvm_reg_field function_level_reset_capability;  


  `uvm_object_utils(device_capabilities_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "device_capabilities_reg");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

   // Build function to define and configure the field
  virtual function void build();

    // Create and configure the max_lat_fields field
    // Field configuration:
    // - parent: this register
    // - size: 8 bits
    // - lsb_pos: 0    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    max_payload_supported = uvm_reg_field::type_id::create("max_payload_supported");
    max_payload_supported.configure(this, 2, 0, "RO", 0, 0, 1, 0, 1);

    phantom_function_supported = uvm_reg_field::type_id::create("phantom_function_supported");
    phantom_function_supported.configure(this, 2, 3, "RO", 0, 0, 1, 0, 1);
 
    extended_tag_field_supported = uvm_reg_field::type_id::create("extended_tag_field_supported");
    extended_tag_field_supported.configure(this, 1, 5, "RO", 0, 0, 1, 0, 1);

    endpoint_L0s_acceptable_latency = uvm_reg_field::type_id::create("endpoint_L0s_acceptable_latency");
    endpoint_L0s_acceptable_latency.configure(this, 3, 6, "RO", 0, 0, 1, 0, 1);

    endpoint_L1s_acceptable_latency = uvm_reg_field::type_id::create("endpoint_L1s_acceptable_latency");
    endpoint_L1s_acceptable_latency.configure(this, 3, 9, "RO", 0, 0, 1, 0, 1);
 
    undefined = uvm_reg_field::type_id::create("undefined");
    undefined.configure(this, 3, 12, "RO", 0, 0, 1, 0, 1);

    role_based_error_reporting = uvm_reg_field::type_id::create("role_based_error_reporting");
    role_based_error_reporting.configure(this, 1, 15, "RO", 0, 0, 1, 0, 1);

    err_cor_subclass_capable = uvm_reg_field::type_id::create("err_cor_subclass_capable");
    err_cor_subclass_capable.configure(this, 1, 16, "RO", 0, 0, 1, 0, 1);

    captured_slot_power_limit_val = uvm_reg_field::type_id::create("captured_slot_power_limit_val");
    captured_slot_power_limit_val.configure(this, 8, 18, "RO", 0, 0, 1, 0, 1);

    captured_slot_power_limit_scale = uvm_reg_field::type_id::create("captured_slot_power_limit_scale");
    captured_slot_power_limit_scale.configure(this, 2, 26, "RO", 0, 0, 1, 0, 1);


    function_level_reset_capability = uvm_reg_field::type_id::create("function_level_reset_capability");
    function_level_reset_capability.configure(this, 1, 28, "RO", 0, 0, 1, 0, 1);

  endfunction

endclass

class device_control_reg extends uvm_reg;

  rand uvm_reg_field correctable_err_reporting_en;
  rand uvm_reg_field non_fatal_err_reporting_en;
  rand uvm_reg_field fatal_err_reporting_en;
  rand uvm_reg_field unsupported_req_reporting_en;
  rand uvm_reg_field relaxed_ordering_en;
  rand uvm_reg_field max_payload_size;
  rand uvm_reg_field extended_tag_field_en;
  rand uvm_reg_field phantom_functions_en;
  rand uvm_reg_field aux_power_pm_en;
  rand uvm_reg_field enable_no_snoop;
  rand uvm_reg_field max_read_request_size;
  rand uvm_reg_field bridge_config_retry_status;

  `uvm_object_utils(device_control_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "device_control_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

   // Build function to define and configure the field
  virtual function void build();

    // Create and configure the max_lat_fields field
    // Field configuration:
    // - parent: this register
    // - size: 8 bits
    // - lsb_pos: 0    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    correctable_err_reporting_en = uvm_reg_field::type_id::create("correctable_err_reporting_en");
    correctable_err_reporting_en.configure(this, 1, 0, "RW", 0, 0, 1, 0, 1);
 
    non_fatal_err_reporting_en = uvm_reg_field::type_id::create("non_fatal_err_reporting_en");
    non_fatal_err_reporting_en.configure(this, 1, 1, "RW", 0, 0, 1, 0, 1);

    fatal_err_reporting_en = uvm_reg_field::type_id::create("fatal_err_reporting_en");
    fatal_err_reporting_en.configure(this, 1, 2, "RW", 0, 0, 1, 0, 1);

    unsupported_req_reporting_en = uvm_reg_field::type_id::create("unsupported_req_reporting_en");
    unsupported_req_reporting_en.configure(this, 1, 3, "RW", 0, 0, 1, 0, 1);

    relaxed_ordering_en = uvm_reg_field::type_id::create("relaxed_ordering_en");
    relaxed_ordering_en.configure(this, 1, 4, "RW", 0, 1, 1, 0, 1); 

    max_payload_size = uvm_reg_field::type_id::create("max_payload_size");
    max_payload_size.configure(this, 3, 5, "RW", 0, 0, 1, 0, 1); 

    extended_tag_field_en = uvm_reg_field::type_id::create("extended_tag_field_en");
    extended_tag_field_en.configure(this, 1, 8, "RW", 0, 0, 1, 0, 1); 

    phantom_functions_en = uvm_reg_field::type_id::create("phantom_functions_en");
    phantom_functions_en.configure(this, 1, 9, "RW", 0, 0, 1, 0, 1);

    aux_power_pm_en = uvm_reg_field::type_id::create("aux_power_pm_en");
    aux_power_pm_en.configure(this, 1, 10, "RW", 0, 0, 1, 0, 1);

    enable_no_snoop = uvm_reg_field::type_id::create("enable_no_snoop");
    enable_no_snoop.configure(this, 1, 11, "RW", 0, 1, 1, 0, 1);
//
    max_read_request_size = uvm_reg_field::type_id::create("max_read_request_size");
    max_read_request_size.configure(this, 3, 12, "RW", 0, 0, 1, 0, 1);
 
    bridge_config_retry_status = uvm_reg_field::type_id::create("bridge_config_retry_status");
    bridge_config_retry_status.configure(this, 1, 15, "RW", 0, 0, 1, 0, 1);
 
  endfunction

endclass
class device_status_reg extends uvm_reg;

  rand uvm_reg_field correctable_err_detected;
  rand uvm_reg_field non_fatal_err_detected;
  rand uvm_reg_field fatal_err_detected;
  rand uvm_reg_field unsupported_req_detected;
  rand uvm_reg_field aux_power_detected;
  rand uvm_reg_field txns_pending; 

  `uvm_object_utils(device_status_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "device_status_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

   // Build function to define and configure the field
  virtual function void build();

    // Create and configure the max_lat_fields field
    // Field configuration:
    // - parent: this register
    // - size: 16bits
    // - lsb_pos: 0    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    correctable_err_detected = uvm_reg_field::type_id::create("correctable_err_detected");
    correctable_err_detected.configure(this, 1, 0, "RW", 0, 0, 1, 0, 1);

    non_fatal_err_detected = uvm_reg_field::type_id::create("non_fatal_err_detected");
    non_fatal_err_detected.configure(this, 1, 1, "RW", 0, 0, 1, 0, 1);

    fatal_err_detected = uvm_reg_field::type_id::create("fatal_err_detected");
    fatal_err_detected.configure(this, 1, 2, "RW", 0, 0, 1, 0, 1);

    unsupported_req_detected = uvm_reg_field::type_id::create("unsupported_req_detected");
    unsupported_req_detected.configure(this, 1, 3, "RW", 0, 0, 1, 0, 1);

    aux_power_detected = uvm_reg_field::type_id::create("aux_power_detected");
    aux_power_detected.configure(this, 1, 4, "RO", 0, 0, 1, 0, 1);
 
    txns_pending = uvm_reg_field::type_id::create("txns_pending");
    txns_pending.configure(this, 1, 5, "RO", 0, 0, 1, 0, 1);
  
  endfunction

endclass


class link_capabilites_reg extends uvm_reg;

  rand uvm_reg_field max_link_speed;
  rand uvm_reg_field max_link_width;
  rand uvm_reg_field aspm_support;
  rand uvm_reg_field L0s_exit_latency;
  rand uvm_reg_field L1_exit_latency;
  rand uvm_reg_field clk_power_mangmnt;
  rand uvm_reg_field surprise_down_reporting_cap;
  rand uvm_reg_field dll_link_active_reporting_cap;
  rand uvm_reg_field link_bandwidth_notify_cap;
  rand uvm_reg_field aspm_optionality_compliance;
  rand uvm_reg_field port_number;
  
  `uvm_object_utils(link_capabilites_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "link_capabilites_reg");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

   // Build function to define and configure the field
  virtual function void build();

    // Create and configure the max_lat_fields field
    // Field configuration:
    // - parent: this register
    // - size: 16bits
    // - lsb_pos: 0    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    max_link_speed = uvm_reg_field::type_id::create("max_link_speed");
    max_link_speed.configure(this, 3, 0, "RO", 0, 0, 1, 0, 1);
    
    max_link_width = uvm_reg_field::type_id::create("max_link_width");
    max_link_width.configure(this, 6, 4, "RO", 0, 0, 1, 0, 1);
    aspm_support = uvm_reg_field::type_id::create("aspm_support");
    aspm_support.configure(this, 2, 10, "RO", 0, 0, 1, 0, 1);
 
    L0s_exit_latency = uvm_reg_field::type_id::create("L0s_exit_latency");
    L0s_exit_latency.configure(this, 3, 12, "RO", 0, 0, 1, 0, 1);
    
    L1_exit_latency = uvm_reg_field::type_id::create("L1_exit_latency");
    L1_exit_latency.configure(this, 3, 15, "RO", 0, 0, 1, 0, 1);
    
    clk_power_mangmnt = uvm_reg_field::type_id::create("clk_power_mangmnt");
    clk_power_mangmnt.configure(this, 1, 18, "RO", 0, 0, 1, 0, 1);
    
    surprise_down_reporting_cap = uvm_reg_field::type_id::create("surprise_down_reporting_cap");
    surprise_down_reporting_cap.configure(this, 1, 19, "RO", 0, 0, 1, 0, 1);
    
     dll_link_active_reporting_cap = uvm_reg_field::type_id::create("dll_link_active_reporting_cap");
    dll_link_active_reporting_cap.configure(this, 1, 20, "RO", 0, 0, 1, 0, 1);
    
     link_bandwidth_notify_cap = uvm_reg_field::type_id::create("link_bandwidth_notify_cap");
    link_bandwidth_notify_cap.configure(this, 1, 21, "RO", 0, 0, 1, 0, 1);
    
     aspm_optionality_compliance = uvm_reg_field::type_id::create("aspm_optionality_compliance");
    aspm_optionality_compliance.configure(this, 1, 22, "RO", 0, 0, 1, 0, 1);
    
    port_number = uvm_reg_field::type_id::create("port_number");
    port_number.configure(this, 8, 24, "RO", 0, 0, 1, 0, 1);
    
  endfunction

endclass


class link_control_reg extends uvm_reg;

  rand uvm_reg_field aspm_ctrl;
  rand uvm_reg_field rd_compl_boundary;
  rand uvm_reg_field link_disable;
  rand uvm_reg_field retrain_link;
  rand uvm_reg_field com_clk_config;
  rand uvm_reg_field extended_synch;
  rand uvm_reg_field en_clk_power_mngmnt;
  rand uvm_reg_field hw_auto_width_disable;
  rand uvm_reg_field link_bdwdth_mngmnt_interrupt_en;
  rand uvm_reg_field link_auto_bdwdth_interrupt_en;
  rand uvm_reg_field DRS_signaling_control;
  
  `uvm_object_utils(link_control_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "link_control_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

   // Build function to define and configure the field
  virtual function void build();

    // Create and configure the max_lat_fields field
    // Field configuration:
    // - parent: this register
    // - size: 16bits
    // - lsb_pos: 0    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    aspm_ctrl = uvm_reg_field::type_id::create("aspm_ctrl");
    aspm_ctrl.configure(this, 2, 0, "RW", 0, 0, 1, 0, 1);
    
    rd_compl_boundary = uvm_reg_field::type_id::create("rd_compl_boundary");
    rd_compl_boundary.configure(this, 1, 3, "RW", 0, 0, 1, 0, 1);
    
    link_disable = uvm_reg_field::type_id::create("link_disable");
    link_disable.configure(this, 1, 4, "RW", 0, 0, 1, 0, 1);
 
    retrain_link = uvm_reg_field::type_id::create("retrain_link");
    retrain_link.configure(this, 1, 5, "RW", 0, 0, 1, 0, 1);
    
    com_clk_config = uvm_reg_field::type_id::create("com_clk_config");
    com_clk_config.configure(this, 1, 6, "RW", 0, 0, 1, 0, 1);
    
    extended_synch = uvm_reg_field::type_id::create("extended_synch");
    extended_synch.configure(this, 1, 7, "RW", 0, 0, 1, 0, 1);
    
    en_clk_power_mngmnt = uvm_reg_field::type_id::create("en_clk_power_mngmnt");
    en_clk_power_mngmnt.configure(this, 1, 8, "RW", 0, 0, 1, 0, 1);
    
    hw_auto_width_disable = uvm_reg_field::type_id::create("hw_auto_width_disable");
    hw_auto_width_disable.configure(this, 1, 9, "RW", 0, 0, 1, 0, 1);
    
    link_bdwdth_mngmnt_interrupt_en = uvm_reg_field::type_id::create("link_bdwdth_mngmnt_interrupt_en");
    link_bdwdth_mngmnt_interrupt_en.configure(this, 1, 10, "RW", 0, 0, 1, 0, 1);
    
    link_auto_bdwdth_interrupt_en = uvm_reg_field::type_id::create("link_auto_bdwdth_interrupt_en");
    link_auto_bdwdth_interrupt_en.configure(this, 1, 11, "RW", 0, 0, 1, 0, 1);
    
    DRS_signaling_control = uvm_reg_field::type_id::create("DRS_signaling_control");
    DRS_signaling_control.configure(this, 2, 14, "RW", 0, 0, 1, 0, 1);
       
  endfunction
endclass

class link_status_reg extends uvm_reg;

  rand uvm_reg_field current_link_speed;
  rand uvm_reg_field negotiated_link_width;
  rand uvm_reg_field undefined;
  rand uvm_reg_field link_training;
  rand uvm_reg_field slot_clock_configuration;
  rand uvm_reg_field data_link_layer_active;
  rand uvm_reg_field link_bandwidth_managment_status;
  rand uvm_reg_field link_autonomous_bandwidth_status;
  
  `uvm_object_utils(link_status_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "link_status_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

   // Build function to define and configure the field
  virtual function void build();

    // Create and configure the max_lat_fields field
    // Field configuration:
    // - parent: this register
    // - size: 16bits
    // - lsb_pos: 0    // - access: "RO" (Read-Only)
    // - volatile: 0 (non-volatile)
    // - reset: 0 (reset value)
    // - has_reset: 1 (reset value is valid)
    // - is_rand: 0 (not randomized)
    // - individually_accessible: 1 (can be accessed independently)
    current_link_speed = uvm_reg_field::type_id::create("current_link_speed");
    current_link_speed.configure(this, 4, 0, "RO", 0, 0, 1, 0, 1);
    
    negotiated_link_width = uvm_reg_field::type_id::create("negotiated_link_width");
    negotiated_link_width.configure(this, 6, 4, "RO", 0, 0, 1, 0, 1);
    
    undefined = uvm_reg_field::type_id::create("undefined");
    undefined.configure(this, 1, 10, "RO", 0, 0, 1, 0, 1);
 
    link_training = uvm_reg_field::type_id::create("link_training");
    link_training.configure(this, 1, 11, "RO", 0, 0, 1, 0, 1);
    
    slot_clock_configuration = uvm_reg_field::type_id::create("slot_clock_configuration");
    slot_clock_configuration.configure(this, 1, 12, "RO", 0, 0, 1, 0, 1);
    
    data_link_layer_active = uvm_reg_field::type_id::create("data_link_layer_active");
    data_link_layer_active.configure(this, 1, 13, "RO", 0, 0, 1, 0, 1);
    
    link_bandwidth_managment_status = uvm_reg_field::type_id::create("link_bandwidth_managment_status");
    link_bandwidth_managment_status.configure(this, 1, 14, "RW", 0, 0, 1, 0, 1);
    
    link_autonomous_bandwidth_status = uvm_reg_field::type_id::create("link_autonomous_bandwidth_status");
    link_autonomous_bandwidth_status.configure(this, 1, 15, "RW", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class slot_capabilities_reg extends uvm_reg;

  rand uvm_reg_field attention_button_present;
  rand uvm_reg_field power_controller_present;
  rand uvm_reg_field mrl_sensor_present;
  rand uvm_reg_field attention_indicator_present;
  rand uvm_reg_field power_indicator_present;
  rand uvm_reg_field hot_plug_surprise;
  rand uvm_reg_field hot_plug_capable;
  rand uvm_reg_field slot_power_limit_value;
  rand uvm_reg_field slot_power_limit_scale;
  rand uvm_reg_field electromechanical_interlock_present;
  rand uvm_reg_field no_command_completed_support;
  rand uvm_reg_field physical_slot_number;
  
  `uvm_object_utils(slot_capabilities_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "slot_capabilities_reg");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Attention Button Present
    attention_button_present = uvm_reg_field::type_id::create("attention_button_present");
    attention_button_present.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 1: Power Controller Present
    power_controller_present = uvm_reg_field::type_id::create("power_controller_present");
    power_controller_present.configure(this, 1, 1, "RO", 0, 0, 1, 0, 1);
    
    // Bit 2: MRL Sensor Present
    mrl_sensor_present = uvm_reg_field::type_id::create("mrl_sensor_present");
    mrl_sensor_present.configure(this, 1, 2, "RO", 0, 0, 1, 0, 1);
    
    // Bit 3: Attention Indicator Present
    attention_indicator_present = uvm_reg_field::type_id::create("attention_indicator_present");
    attention_indicator_present.configure(this, 1, 3, "RO", 0, 0, 1, 0, 1);
    
    // Bit 4: Power Indicator Present
    power_indicator_present = uvm_reg_field::type_id::create("power_indicator_present");
    power_indicator_present.configure(this, 1, 4, "RO", 0, 0, 1, 0, 1);
    
    // Bit 5: Hot-Plug Surprise
    hot_plug_surprise = uvm_reg_field::type_id::create("hot_plug_surprise");
    hot_plug_surprise.configure(this, 1, 5, "RO", 0, 0, 1, 0, 1);
    
    // Bit 6: Hot-Plug Capable
    hot_plug_capable = uvm_reg_field::type_id::create("hot_plug_capable");
    hot_plug_capable.configure(this, 1, 6, "RO", 0, 0, 1, 0, 1);
    
    // Bits 7-14: Slot Power Limit Value (8 bits)
    slot_power_limit_value = uvm_reg_field::type_id::create("slot_power_limit_value");
    slot_power_limit_value.configure(this, 8, 7, "RO", 0, 0, 1, 0, 1);
    
    // Bits 15-16: Slot Power Limit Scale (2 bits)
    slot_power_limit_scale = uvm_reg_field::type_id::create("slot_power_limit_scale");
    slot_power_limit_scale.configure(this, 2, 15, "RO", 0, 0, 1, 0, 1);
    
    // Bit 17: Electromechanical Interlock Present
    electromechanical_interlock_present = uvm_reg_field::type_id::create("electromechanical_interlock_present");
    electromechanical_interlock_present.configure(this, 1, 17, "RO", 0, 0, 1, 0, 1);
    
    // Bit 18: No Command Completed Support
    no_command_completed_support = uvm_reg_field::type_id::create("no_command_completed_support");
    no_command_completed_support.configure(this, 1, 18, "RO", 0, 0, 1, 0, 1);
    
    // Bits 19-31: Physical Slot Number (13 bits)
    physical_slot_number = uvm_reg_field::type_id::create("physical_slot_number");
    physical_slot_number.configure(this, 13, 19, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class slot_control_reg extends uvm_reg;

  rand uvm_reg_field attention_button_pressed_enable;
  rand uvm_reg_field power_fault_detected_enable;
  rand uvm_reg_field mrl_sensor_changed_enable;
  rand uvm_reg_field presence_detect_changed_enable;
  rand uvm_reg_field command_completed_interrupt_enable;
  rand uvm_reg_field hot_plug_interrupt_enable;
  rand uvm_reg_field attention_indicator_control;
  rand uvm_reg_field power_indicator_control;
  rand uvm_reg_field power_controller_control;
  rand uvm_reg_field electromechanical_interlock_control;
  rand uvm_reg_field data_link_layer_state_changed_enable;
  rand uvm_reg_field auto_slot_power_limit_disable;
  rand uvm_reg_field in_band_pd_disable;
  rand uvm_reg_field rsvdp;
  
  `uvm_object_utils(slot_control_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "slot_control_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Attention Button Pressed Enable
    attention_button_pressed_enable = uvm_reg_field::type_id::create("attention_button_pressed_enable");
    attention_button_pressed_enable.configure(this, 1, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bit 1: Power Fault Detected Enable
    power_fault_detected_enable = uvm_reg_field::type_id::create("power_fault_detected_enable");
    power_fault_detected_enable.configure(this, 1, 1, "RW", 0, 0, 1, 0, 1);
    
    // Bit 2: MRL Sensor Changed Enable
    mrl_sensor_changed_enable = uvm_reg_field::type_id::create("mrl_sensor_changed_enable");
    mrl_sensor_changed_enable.configure(this, 1, 2, "RW", 0, 0, 1, 0, 1);
    
    // Bit 3: Presence Detect Changed Enable
    presence_detect_changed_enable = uvm_reg_field::type_id::create("presence_detect_changed_enable");
    presence_detect_changed_enable.configure(this, 1, 3, "RW", 0, 0, 1, 0, 1);
    
    // Bit 4: Command Completed Interrupt Enable
    command_completed_interrupt_enable = uvm_reg_field::type_id::create("command_completed_interrupt_enable");
    command_completed_interrupt_enable.configure(this, 1, 4, "RW", 0, 0, 1, 0, 1);
    
    // Bit 5: Hot-Plug Interrupt Enable
    hot_plug_interrupt_enable = uvm_reg_field::type_id::create("hot_plug_interrupt_enable");
    hot_plug_interrupt_enable.configure(this, 1, 5, "RW", 0, 0, 1, 0, 1);
    
    // Bits 6-7: Attention Indicator Control (2 bits)
    attention_indicator_control = uvm_reg_field::type_id::create("attention_indicator_control");
    attention_indicator_control.configure(this, 2, 6, "RW", 0, 0, 1, 0, 1);
    
    // Bits 8-9: Power Indicator Control (2 bits)
    power_indicator_control = uvm_reg_field::type_id::create("power_indicator_control");
    power_indicator_control.configure(this, 2, 8, "RW", 0, 0, 1, 0, 1);
    
    // Bit 10: Power Controller Control
    power_controller_control = uvm_reg_field::type_id::create("power_controller_control");
    power_controller_control.configure(this, 1, 10, "RW", 0, 0, 1, 0, 1);
    
    // Bit 11: Electromechanical Interlock Control
    electromechanical_interlock_control = uvm_reg_field::type_id::create("electromechanical_interlock_control");
    electromechanical_interlock_control.configure(this, 1, 11, "RW", 0, 0, 1, 0, 1);
    
    // Bit 12: Data Link Layer State Changed Enable
    data_link_layer_state_changed_enable = uvm_reg_field::type_id::create("data_link_layer_state_changed_enable");
    data_link_layer_state_changed_enable.configure(this, 1, 12, "RW", 0, 0, 1, 0, 1);
    
    // Bit 13: Auto Slot Power Limit Disable
    auto_slot_power_limit_disable = uvm_reg_field::type_id::create("auto_slot_power_limit_disable");
    auto_slot_power_limit_disable.configure(this, 1, 13, "RW", 0, 0, 1, 0, 1);
    
    // Bit 14: In-Band PD Disable
    in_band_pd_disable = uvm_reg_field::type_id::create("in_band_pd_disable");
    in_band_pd_disable.configure(this, 1, 14, "RW", 0, 0, 1, 0, 1);
    
    // Bit 15: RsvdP (Reserved and Preserved)
    rsvdp = uvm_reg_field::type_id::create("rsvdp");
    rsvdp.configure(this, 1, 15, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class slot_status_reg extends uvm_reg;

  rand uvm_reg_field attention_button_pressed;
  rand uvm_reg_field power_fault_detected;
  rand uvm_reg_field mrl_sensor_changed;
  rand uvm_reg_field presence_detect_changed;
  rand uvm_reg_field command_completed;
  rand uvm_reg_field mrl_sensor_state;
  rand uvm_reg_field presence_detect_state;
  rand uvm_reg_field electromechanical_interlock_status;
  rand uvm_reg_field data_link_layer_state_changed;
  rand uvm_reg_field rsvdp;
  
  `uvm_object_utils(slot_status_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "slot_status_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Attention Button Pressed
    attention_button_pressed = uvm_reg_field::type_id::create("attention_button_pressed");
    attention_button_pressed.configure(this, 1, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bit 1: Power Fault Detected  
    power_fault_detected = uvm_reg_field::type_id::create("power_fault_detected");
    power_fault_detected.configure(this, 1, 1, "RW", 0, 0, 1, 0, 1);
    
    // Bit 2: MRL Sensor Changed
    mrl_sensor_changed = uvm_reg_field::type_id::create("mrl_sensor_changed");
    mrl_sensor_changed.configure(this, 1, 2, "RW", 0, 0, 1, 0, 1);
    
    // Bit 3: Presence Detect Changed
    presence_detect_changed = uvm_reg_field::type_id::create("presence_detect_changed");
    presence_detect_changed.configure(this, 1, 3, "RW", 0, 0, 1, 0, 1);
    
    // Bit 4: Command Completed
    command_completed = uvm_reg_field::type_id::create("command_completed");
    command_completed.configure(this, 1, 4, "RW", 0, 0, 1, 0, 1);
    
    // Bit 5: MRL Sensor State
    mrl_sensor_state = uvm_reg_field::type_id::create("mrl_sensor_state");
    mrl_sensor_state.configure(this, 1, 5, "RO", 0, 0, 1, 0, 1);
    
    // Bit 6: Presence Detect State
    presence_detect_state = uvm_reg_field::type_id::create("presence_detect_state");
    presence_detect_state.configure(this, 1, 6, "RO", 0, 0, 1, 0, 1);
    
    // Bit 7: Electromechanical Interlock Status
    electromechanical_interlock_status = uvm_reg_field::type_id::create("electromechanical_interlock_status");
    electromechanical_interlock_status.configure(this, 1, 7, "RO", 0, 0, 1, 0, 1);
    
    // Bit 8: Data Link Layer State Changed
    data_link_layer_state_changed = uvm_reg_field::type_id::create("data_link_layer_state_changed");
    data_link_layer_state_changed.configure(this, 1, 8, "RW", 0, 0, 1, 0, 1);
    
    // Bits 9-15: RsvdP (Reserved and Preserved)
    rsvdp = uvm_reg_field::type_id::create("rsvdp");
    rsvdp.configure(this, 7, 9, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class root_control_reg extends uvm_reg;

  rand uvm_reg_field system_error_on_correctable_error_enable;
  rand uvm_reg_field system_error_on_non_fatal_error_enable;
  rand uvm_reg_field system_error_on_fatal_error_enable;
  rand uvm_reg_field pme_interrupt_enable;
  rand uvm_reg_field crs_software_visibility_enable;
  rand uvm_reg_field rsvdp;
  
  `uvm_object_utils(root_control_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "root_control_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: System Error on Correctable Error Enable
    system_error_on_correctable_error_enable = uvm_reg_field::type_id::create("system_error_on_correctable_error_enable");
    system_error_on_correctable_error_enable.configure(this, 1, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bit 1: System Error on Non-Fatal Error Enable
    system_error_on_non_fatal_error_enable = uvm_reg_field::type_id::create("system_error_on_non_fatal_error_enable");
    system_error_on_non_fatal_error_enable.configure(this, 1, 1, "RW", 0, 0, 1, 0, 1);
    
    // Bit 2: System Error on Fatal Error Enable
    system_error_on_fatal_error_enable = uvm_reg_field::type_id::create("system_error_on_fatal_error_enable");
    system_error_on_fatal_error_enable.configure(this, 1, 2, "RW", 0, 0, 1, 0, 1);
    
    // Bit 3: PME Interrupt Enable
    pme_interrupt_enable = uvm_reg_field::type_id::create("pme_interrupt_enable");
    pme_interrupt_enable.configure(this, 1, 3, "RW", 0, 0, 1, 0, 1);
    
    // Bit 4: CRS Software Visibility Enable
    crs_software_visibility_enable = uvm_reg_field::type_id::create("crs_software_visibility_enable");
    crs_software_visibility_enable.configure(this, 1, 4, "RW", 0, 0, 1, 0, 1);
    
    // Bits 5-15: RsvdP (Reserved and Preserved)
    rsvdp = uvm_reg_field::type_id::create("rsvdp");
    rsvdp.configure(this, 11, 5, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class root_capabilities_reg extends uvm_reg;

  rand uvm_reg_field crs_software_visibility;
  rand uvm_reg_field rsvdp;
  
  `uvm_object_utils(root_capabilities_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "root_capabilities_reg");
    // Set register size to 16 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: CRS Software Visibility
    crs_software_visibility = uvm_reg_field::type_id::create("crs_software_visibility");
    crs_software_visibility.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bits 1-15: RsvdP (Reserved and Preserved)
    rsvdp = uvm_reg_field::type_id::create("rsvdp");
    rsvdp.configure(this, 30, 1, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class root_status_reg extends uvm_reg;

  rand uvm_reg_field pme_requester_id;
  rand uvm_reg_field pme_status;
  rand uvm_reg_field pme_pending;
  rand uvm_reg_field rsvdz;
  
  `uvm_object_utils(root_status_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "root_status_reg");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-15: PME Requester ID
    pme_requester_id = uvm_reg_field::type_id::create("pme_requester_id");
    pme_requester_id.configure(this, 16, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 16: PME Status
    pme_status = uvm_reg_field::type_id::create("pme_status");
    pme_status.configure(this, 1, 16, "RW", 0, 0, 1, 0, 1);
    
    // Bit 17: PME Pending
    pme_pending = uvm_reg_field::type_id::create("pme_pending");
    pme_pending.configure(this, 1, 17, "RO", 0, 0, 1, 0, 1);
    
    // Bits 18-31: RsvdZ (Reserved and Zero)
    rsvdz = uvm_reg_field::type_id::create("rsvdp");
    rsvdz.configure(this, 14, 18, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class device_capabilities_2_reg extends uvm_reg;

  rand uvm_reg_field completion_timeout_ranges_supported;
  rand uvm_reg_field completion_timeout_disable_supported;
  rand uvm_reg_field ari_forwarding_supported;
  rand uvm_reg_field atomicop_routing_supported;
  rand uvm_reg_field atomicop_completer_32bit_supported;
  rand uvm_reg_field atomicop_completer_64bit_supported;
  rand uvm_reg_field cas_completer_128bit_supported;
  rand uvm_reg_field no_ro_enabled_pr_pr_passing;
  rand uvm_reg_field ltr_mechanism_supported;
  rand uvm_reg_field tph_completer_supported;
  rand uvm_reg_field ln_system_cls;
  rand uvm_reg_field tag_completer_10bit_supported;
  rand uvm_reg_field tag_requester_10bit_supported;
  rand uvm_reg_field obff_supported;
  rand uvm_reg_field extended_fmt_field_supported;
  rand uvm_reg_field end_end_tlp_prefix_supported;
  rand uvm_reg_field max_end_end_tlp_prefixes;
  rand uvm_reg_field emergency_power_reduction_supported;
  rand uvm_reg_field emergency_power_reduction_initialization_required;
  rand uvm_reg_field rsvdp;
  rand uvm_reg_field frs_supported;
  
  `uvm_object_utils(device_capabilities_2_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "device_capabilities_2_reg");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-3: Completion Timeout Ranges Supported (4 bits)
    completion_timeout_ranges_supported = uvm_reg_field::type_id::create("completion_timeout_ranges_supported");
    completion_timeout_ranges_supported.configure(this, 4, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 4: Completion Timeout Disable Supported
    completion_timeout_disable_supported = uvm_reg_field::type_id::create("completion_timeout_disable_supported");
    completion_timeout_disable_supported.configure(this, 1, 4, "RO", 0, 0, 1, 0, 1);
    
    // Bit 5: ARI Forwarding Supported
    ari_forwarding_supported = uvm_reg_field::type_id::create("ari_forwarding_supported");
    ari_forwarding_supported.configure(this, 1, 5, "RO", 0, 0, 1, 0, 1);
    
    // Bit 6: AtomicOp Routing Supported
    atomicop_routing_supported = uvm_reg_field::type_id::create("atomicop_routing_supported");
    atomicop_routing_supported.configure(this, 1, 6, "RO", 0, 0, 1, 0, 1);
    
    // Bit 7: 32-bit AtomicOp Completer Supported
    atomicop_completer_32bit_supported = uvm_reg_field::type_id::create("atomicop_completer_32bit_supported");
    atomicop_completer_32bit_supported.configure(this, 1, 7, "RO", 0, 0, 1, 0, 1);
    
    // Bit 8: 64-bit AtomicOp Completer Supported
    atomicop_completer_64bit_supported = uvm_reg_field::type_id::create("atomicop_completer_64bit_supported");
    atomicop_completer_64bit_supported.configure(this, 1, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bit 9: 128-bit CAS Completer Supported
    cas_completer_128bit_supported = uvm_reg_field::type_id::create("cas_completer_128bit_supported");
    cas_completer_128bit_supported.configure(this, 1, 9, "RO", 0, 0, 1, 0, 1);
    
    // Bit 10: No RO-enabled PR-PR Passing
    no_ro_enabled_pr_pr_passing = uvm_reg_field::type_id::create("no_ro_enabled_pr_pr_passing");
    no_ro_enabled_pr_pr_passing.configure(this, 1, 10, "RO", 0, 0, 1, 0, 1);
    
    // Bit 11: LTR Mechanism Supported
    ltr_mechanism_supported = uvm_reg_field::type_id::create("ltr_mechanism_supported");
    ltr_mechanism_supported.configure(this, 1, 11, "RO", 0, 0, 1, 0, 1);
    
    // Bits 12-13: TPH Completer Supported (2 bits)
    tph_completer_supported = uvm_reg_field::type_id::create("tph_completer_supported");
    tph_completer_supported.configure(this, 2, 12, "RO", 0, 0, 1, 0, 1);
    
    // Bits 14-15: LN System CLS (2 bits)
    ln_system_cls = uvm_reg_field::type_id::create("ln_system_cls");
    ln_system_cls.configure(this, 2, 14, "RO", 0, 0, 1, 0, 1);
    
    // Bit 16: 10-Bit Tag Completer Supported
    tag_completer_10bit_supported = uvm_reg_field::type_id::create("tag_completer_10bit_supported");
    tag_completer_10bit_supported.configure(this, 1, 16, "RO", 0, 0, 1, 0, 1);
    
    // Bit 17: 10-Bit Tag Requester Supported
    tag_requester_10bit_supported = uvm_reg_field::type_id::create("tag_requester_10bit_supported");
    tag_requester_10bit_supported.configure(this, 1, 17, "RO", 0, 0, 1, 0, 1);
    
    // Bits 18-19: OBFF Supported (2 bits)
    obff_supported = uvm_reg_field::type_id::create("obff_supported");
    obff_supported.configure(this, 2, 18, "RO", 0, 0, 1, 0, 1);
    
    // Bit 20: Extended Fmt Field Supported
    extended_fmt_field_supported = uvm_reg_field::type_id::create("extended_fmt_field_supported");
    extended_fmt_field_supported.configure(this, 1, 20, "RO", 0, 0, 1, 0, 1);
    
    // Bit 21: End-End TLP Prefix Supported
    end_end_tlp_prefix_supported = uvm_reg_field::type_id::create("end_end_tlp_prefix_supported");
    end_end_tlp_prefix_supported.configure(this, 1, 21, "RO", 0, 0, 1, 0, 1);
    
    // Bits 22-23: Max End-End TLP Prefixes (2 bits)
    max_end_end_tlp_prefixes = uvm_reg_field::type_id::create("max_end_end_tlp_prefixes");
    max_end_end_tlp_prefixes.configure(this, 2, 22, "RO", 0, 0, 1, 0, 1);
    
    // Bit 24: Emergency Power Reduction Supported
    emergency_power_reduction_supported = uvm_reg_field::type_id::create("emergency_power_reduction_supported");
    emergency_power_reduction_supported.configure(this, 2, 24, "RO", 0, 0, 1, 0, 1);
    
    // Bit 25: Emergency Power Reduction Initialization Required
    emergency_power_reduction_initialization_required = uvm_reg_field::type_id::create("emergency_power_reduction_initialization_required");
    emergency_power_reduction_initialization_required.configure(this, 1, 26, "RO", 0, 0, 1, 0, 1);
    
    // Bits 26-30: RsvdP (Reserved and Preserved) (5 bits)
    rsvdp = uvm_reg_field::type_id::create("rsvdp");
    rsvdp.configure(this, 4, 27, "RO", 0, 0, 1, 0, 1);
    
    // Bit 31: FRS Supported
    frs_supported = uvm_reg_field::type_id::create("frs_supported");
    frs_supported.configure(this, 1, 31, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class device_control_2_reg extends uvm_reg;

  rand uvm_reg_field completion_timeout_value;
  rand uvm_reg_field completion_timeout_disable;
  rand uvm_reg_field ari_forwarding_enable;
  rand uvm_reg_field atomicop_requester_enable;
  rand uvm_reg_field atomicop_egress_blocking;
  rand uvm_reg_field ido_request_enable;
  rand uvm_reg_field ido_completion_enable;
  rand uvm_reg_field ltr_mechanism_enable;
  rand uvm_reg_field emergency_power_reduction_request;
  rand uvm_reg_field tag_requester_10bit_enable;
  rand uvm_reg_field obff_enable;
  rand uvm_reg_field end_end_tlp_prefix_blocking;
  
  `uvm_object_utils(device_control_2_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "device_control_2_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-3: Completion Timeout Value (4 bits)
    completion_timeout_value = uvm_reg_field::type_id::create("completion_timeout_value");
    completion_timeout_value.configure(this, 4, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bit 4: Completion Timeout Disable
    completion_timeout_disable = uvm_reg_field::type_id::create("completion_timeout_disable");
    completion_timeout_disable.configure(this, 1, 4, "RW", 0, 0, 1, 0, 1);
    
    // Bit 5: ARI Forwarding Enable
    ari_forwarding_enable = uvm_reg_field::type_id::create("ari_forwarding_enable");
    ari_forwarding_enable.configure(this, 1, 5, "RW", 0, 0, 1, 0, 1);
    
    // Bit 6: AtomicOp Requester Enable
    atomicop_requester_enable = uvm_reg_field::type_id::create("atomicop_requester_enable");
    atomicop_requester_enable.configure(this, 1, 6, "RW", 0, 0, 1, 0, 1);
    
    // Bit 7: AtomicOp Egress Blocking
    atomicop_egress_blocking = uvm_reg_field::type_id::create("atomicop_egress_blocking");
    atomicop_egress_blocking.configure(this, 1, 7, "RW", 0, 0, 1, 0, 1);
    
    // Bit 8: IDO Request Enable
    ido_request_enable = uvm_reg_field::type_id::create("ido_request_enable");
    ido_request_enable.configure(this, 1, 8, "RW", 0, 0, 1, 0, 1);
    
    // Bit 9: IDO Completion Enable
    ido_completion_enable = uvm_reg_field::type_id::create("ido_completion_enable");
    ido_completion_enable.configure(this, 1, 9, "RW", 0, 0, 1, 0, 1);
    
    // Bit 10: LTR Mechanism Enable
    ltr_mechanism_enable = uvm_reg_field::type_id::create("ltr_mechanism_enable");
    ltr_mechanism_enable.configure(this, 1, 10, "RW", 0, 0, 1, 0, 1);
    
    // Bit 11: Emergency Power Reduction Request
    emergency_power_reduction_request = uvm_reg_field::type_id::create("emergency_power_reduction_request");
    emergency_power_reduction_request.configure(this, 1, 11, "RW", 0, 0, 1, 0, 1);
    
    // Bit 12: 10-Bit Tag Requester Enable
    tag_requester_10bit_enable = uvm_reg_field::type_id::create("tag_requester_10bit_enable");
    tag_requester_10bit_enable.configure(this, 1, 12, "RW", 0, 0, 1, 0, 1);
    
    // Bits 13-14: OBFF Enable (2 bits)
    obff_enable = uvm_reg_field::type_id::create("obff_enable");
    obff_enable.configure(this, 2, 13, "RW", 0, 0, 1, 0, 1);
    
    // Bit 15: End-End TLP Prefix Blocking
    end_end_tlp_prefix_blocking = uvm_reg_field::type_id::create("end_end_tlp_prefix_blocking");
    end_end_tlp_prefix_blocking.configure(this, 1, 15, "RW", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class device_status_2_reg extends uvm_reg;

  rand uvm_reg_field rsvdz;
  
  `uvm_object_utils(device_status_2_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "device_status_2_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure the field based on the register being RsvdZ
    
    // Bits 0-15: RsvdZ (Reserved and Zero) - entire register
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 16, 0, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class link_capabilities_2_reg extends uvm_reg;

  rand uvm_reg_field rsvdp_1;
  rand uvm_reg_field supported_link_speeds_vector;
  rand uvm_reg_field crosslink_supported;
  rand uvm_reg_field lower_skp_os_generation_supported_speeds_vector;
  rand uvm_reg_field lower_skp_os_reception_supported_speeds_vector;
  rand uvm_reg_field retimer_presence_detect_supported;
  rand uvm_reg_field two_retimers_presence_detect_supported;
  rand uvm_reg_field drs_supported;
  rand uvm_reg_field rsvdp;
  
  `uvm_object_utils(link_capabilities_2_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "link_capabilities_2_reg");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    rsvdp_1 = uvm_reg_field::type_id::create("rsvdp_1");
    rsvdp_1.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bits 1-6: Supported Link Speeds Vector (7 bits)
    supported_link_speeds_vector = uvm_reg_field::type_id::create("supported_link_speeds_vector");
    supported_link_speeds_vector.configure(this, 7, 1, "RO", 0, 0, 1, 0, 1);
    
    // Bit 8: Crosslink Supported
    crosslink_supported = uvm_reg_field::type_id::create("crosslink_supported");
    crosslink_supported.configure(this, 1, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bits 9-15: Lower SKP OS Generation Supported Speeds Vector (7 bits)
    lower_skp_os_generation_supported_speeds_vector = uvm_reg_field::type_id::create("lower_skp_os_generation_supported_speeds_vector");
    lower_skp_os_generation_supported_speeds_vector.configure(this, 7, 9, "RO", 0, 0, 1, 0, 1);
    
    // Bits 15-21: Lower SKP OS Reception Supported Speeds Vector (7 bits)
    lower_skp_os_reception_supported_speeds_vector = uvm_reg_field::type_id::create("lower_skp_os_reception_supported_speeds_vector");
    lower_skp_os_reception_supported_speeds_vector.configure(this, 7, 16, "RO", 0, 0, 1, 0, 1);
    
    // Bit 22: Retimer Presence Detect Supported
    retimer_presence_detect_supported = uvm_reg_field::type_id::create("retimer_presence_detect_supported");
    retimer_presence_detect_supported.configure(this, 1, 23, "RO", 0, 0, 1, 0, 1);
    
    // Bit 23: Two Retimers Presence Detect Supported
    two_retimers_presence_detect_supported = uvm_reg_field::type_id::create("two_retimers_presence_detect_supported");
    two_retimers_presence_detect_supported.configure(this, 1, 24, "RO", 0, 0, 1, 0, 1);
    
    // Bits 24-30: RsvdP (Reserved and Preserved) (7 bits)
    rsvdp = uvm_reg_field::type_id::create("rsvdp");
    rsvdp.configure(this, 6, 25, "RO", 0, 0, 1, 0, 1);
    
    // Bit 31: DRS Supported
    drs_supported = uvm_reg_field::type_id::create("drs_supported");
    drs_supported.configure(this, 1, 31, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class link_control_2_reg extends uvm_reg;

  rand uvm_reg_field target_link_speed;
  rand uvm_reg_field enter_compliance;
  rand uvm_reg_field hardware_autonomous_speed_disable;
  rand uvm_reg_field selectable_de_emphasis;
  rand uvm_reg_field transmit_margin;
  rand uvm_reg_field enter_modified_compliance;
  rand uvm_reg_field compliance_sos;
  rand uvm_reg_field compliance_preset_de_emphasis;
  
  `uvm_object_utils(link_control_2_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "link_control_2_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 0-3: Target Link Speed (4 bits)
    target_link_speed = uvm_reg_field::type_id::create("target_link_speed");
    target_link_speed.configure(this, 4, 0, "RW", 0, 0, 1, 0, 1);
    
    // Bit 4: Enter Compliance
    enter_compliance = uvm_reg_field::type_id::create("enter_compliance");
    enter_compliance.configure(this, 1, 4, "RW", 0, 0, 1, 0, 1);
    
    // Bit 5: Hardware Autonomous Speed Disable
    hardware_autonomous_speed_disable = uvm_reg_field::type_id::create("hardware_autonomous_speed_disable");
    hardware_autonomous_speed_disable.configure(this, 1, 5, "RW", 0, 0, 1, 0, 1);
    
    // Bit 6: Selectable De-emphasis
    selectable_de_emphasis = uvm_reg_field::type_id::create("selectable_de_emphasis");
    selectable_de_emphasis.configure(this, 1, 6, "RO", 0, 0, 1, 0, 1);
    
    // Bits 7-9: Transmit Margin (3 bits)
    transmit_margin = uvm_reg_field::type_id::create("transmit_margin");
    transmit_margin.configure(this, 3, 7, "RW", 0, 0, 1, 0, 1);
    
    // Bit 10: Enter Modified Compliance
    enter_modified_compliance = uvm_reg_field::type_id::create("enter_modified_compliance");
    enter_modified_compliance.configure(this, 1, 10, "RW", 0, 0, 1, 0, 1);
    
    // Bit 11: Compliance SOS
    compliance_sos = uvm_reg_field::type_id::create("compliance_sos");
    compliance_sos.configure(this, 1, 11, "RW", 0, 0, 1, 0, 1);
    
    // Bits 12-15: Compliance Preset/De-emphasis (4 bits)
    compliance_preset_de_emphasis = uvm_reg_field::type_id::create("compliance_preset_de_emphasis");
    compliance_preset_de_emphasis.configure(this, 4, 12, "RW", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class link_status_2_reg extends uvm_reg;

  rand uvm_reg_field current_de_emphasis_level;
  rand uvm_reg_field equalization_8_0_gt_s_complete;
  rand uvm_reg_field equalization_8_0_gt_s_phase_1_successful;
  rand uvm_reg_field equalization_8_0_gt_s_phase_2_successful;
  rand uvm_reg_field equalization_8_0_gt_s_phase_3_successful;
  rand uvm_reg_field link_equalization_request_8_0_gt_s;
  rand uvm_reg_field retimer_presence_detected;
  rand uvm_reg_field two_retimers_presence_detected;
  rand uvm_reg_field crosslink_resolution;
  rand uvm_reg_field rsvdz;
  rand uvm_reg_field downstream_component_presence;
  rand uvm_reg_field drs_message_received;
  
  `uvm_object_utils(link_status_2_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "link_status_2_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bit 0: Current De-emphasis Level
    current_de_emphasis_level = uvm_reg_field::type_id::create("current_de_emphasis_level");
    current_de_emphasis_level.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
    // Bit 1: Equalization 8.0 GT/s Complete
    equalization_8_0_gt_s_complete = uvm_reg_field::type_id::create("equalization_8_0_gt_s_complete");
    equalization_8_0_gt_s_complete.configure(this, 1, 1, "RO", 0, 0, 1, 0, 1);
    
    // Bit 2: Equalization 8.0 GT/s Phase 1 Successful
    equalization_8_0_gt_s_phase_1_successful = uvm_reg_field::type_id::create("equalization_8_0_gt_s_phase_1_successful");
    equalization_8_0_gt_s_phase_1_successful.configure(this, 1, 2, "RO", 0, 0, 1, 0, 1);
    
    // Bit 3: Equalization 8.0 GT/s Phase 2 Successful
    equalization_8_0_gt_s_phase_2_successful = uvm_reg_field::type_id::create("equalization_8_0_gt_s_phase_2_successful");
    equalization_8_0_gt_s_phase_2_successful.configure(this, 1, 3, "RO", 0, 0, 1, 0, 1);
    
    // Bit 4: Equalization 8.0 GT/s Phase 3 Successful
    equalization_8_0_gt_s_phase_3_successful = uvm_reg_field::type_id::create("equalization_8_0_gt_s_phase_3_successful");
    equalization_8_0_gt_s_phase_3_successful.configure(this, 1, 4, "RO", 0, 0, 1, 0, 1);
    
    // Bit 5: Link Equalization Request 8.0 GT/s
    link_equalization_request_8_0_gt_s = uvm_reg_field::type_id::create("link_equalization_request_8_0_gt_s");
    link_equalization_request_8_0_gt_s.configure(this, 1, 5, "RW", 0, 0, 1, 0, 1);
    
    // Bit 6: Retimer Presence Detected
    retimer_presence_detected = uvm_reg_field::type_id::create("retimer_presence_detected");
    retimer_presence_detected.configure(this, 1, 6, "RO", 0, 0, 1, 0, 1);
    
    // Bit 7: Two Retimers Presence Detected
    two_retimers_presence_detected = uvm_reg_field::type_id::create("two_retimers_presence_detected");
    two_retimers_presence_detected.configure(this, 1, 7, "RO", 0, 0, 1, 0, 1);
    
    // Bit 8: Crosslink Resolution
    crosslink_resolution = uvm_reg_field::type_id::create("crosslink_resolution");
    crosslink_resolution.configure(this, 2, 8, "RO", 0, 0, 1, 0, 1);
    
    // Bit 9: RsvdZ (Reserved and Zero)
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 2, 10, "RO", 0, 0, 1, 0, 1);
    
    // Bit 10: Downstream Component Presence
    downstream_component_presence = uvm_reg_field::type_id::create("downstream_component_presence");
    downstream_component_presence.configure(this, 3, 12, "RO", 0, 0, 1, 0, 1);
    
    // Bit 11: DRS Message Received
    drs_message_received = uvm_reg_field::type_id::create("drs_message_received");
    drs_message_received.configure(this, 1, 15, "RW", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class slot_capabilities_2_reg extends uvm_reg;

  rand uvm_reg_field rsvdp;
  rand uvm_reg_field in_band_pd_disable_supported;
  
  `uvm_object_utils(slot_capabilities_2_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "slot_capabilities_2_reg");
    // Set register size to 32 bits
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure each field based on the register diagram
    
    // Bits 1-31: RsvdP (Reserved and Preserved) (31 bits)
    rsvdp = uvm_reg_field::type_id::create("rsvdp");
    rsvdp.configure(this, 31, 1, "RO", 0, 0, 1, 0, 1);
    
    // Bit 0: In-Band PD Disable Supported
    in_band_pd_disable_supported = uvm_reg_field::type_id::create("in_band_pd_disable_supported");
    in_band_pd_disable_supported.configure(this, 1, 0, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class slot_control_2_reg extends uvm_reg;

  rand uvm_reg_field rsvdp;
  
  `uvm_object_utils(slot_control_2_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "slot_control_2_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure the field based on the register being RsvdP
    
    // Bits 0-15: RsvdP (Reserved and Preserved) - entire register
    rsvdp = uvm_reg_field::type_id::create("rsvdp");
    rsvdp.configure(this, 16, 0, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

class slot_status_2_reg extends uvm_reg;

  rand uvm_reg_field rsvdz;
  
  `uvm_object_utils(slot_status_2_reg);

  // Constructor: initialize the register with name and size
  function new(string name = "slot_status_2_reg");
    // Set register size to 16 bits
    super.new(name, 16, UVM_NO_COVERAGE);
  endfunction

  // Build function to define and configure the fields
  virtual function void build();

    // Create and configure the field based on the register being RsvdZ
    
    // Bits 0-15: RsvdZ (Reserved and Zero) - entire register
    rsvdz = uvm_reg_field::type_id::create("rsvdz");
    rsvdz.configure(this, 16, 0, "RO", 0, 0, 1, 0, 1);
    
  endfunction
endclass

