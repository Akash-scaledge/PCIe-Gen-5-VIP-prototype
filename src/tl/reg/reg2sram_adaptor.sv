// Define a register-to-memory adapter class extending from uvm_reg_adapter
class reg_sram_adapter extends uvm_reg_adapter;

  // Register the adapter with the UVM factory
  `uvm_object_utils(reg_sram_adapter)

  // Constructor
  function new(string name = "reg_axi_adapter");
    super.new(name);
  endfunction

  // Convert a register operation into a memory bus transaction
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    // Create a memory transaction item
    mem_tx bus_item = mem_tx::type_id::create("bus_item");

    // Map register operation fields to memory transaction
    bus_item.addr_i = rw.addr;
    bus_item.data   = rw.data;
    bus_item.write_i = (rw.kind == UVM_WRITE) ? 1 : 0;

    // Optional debug message for write operations
    if (bus_item.write_i == 1)
      `uvm_info(get_type_name, $sformatf("reg2bus: addr = %0h, data = %0h, write_i = %0h",
                                         bus_item.addr_i, bus_item.data, bus_item.write_i), UVM_LOW);

    return bus_item;
  endfunction

  // Convert a memory bus transaction back into a register operation
  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    mem_tx bus_pkt;

    // Safely cast the generic sequence item to mem_tx
    if (!$cast(bus_pkt, bus_item))
      `uvm_fatal(get_type_name(), "Failed to cast bus_item transaction")

    // Map memory transaction fields back to register operation
    rw.addr = bus_pkt.addr_i;
    rw.data = bus_pkt.data;
    rw.kind = (bus_pkt.write_i) ? UVM_WRITE : UVM_READ;

    // Optional debug message for read operations
    if (rw.kind == UVM_READ)
      `uvm_info(get_type_name, $sformatf("bus2reg: addr = %0h, rdata = %0h, kind = %0h",
                                         rw.addr, rw.data, rw.kind), UVM_LOW);
  endfunction

endclass
