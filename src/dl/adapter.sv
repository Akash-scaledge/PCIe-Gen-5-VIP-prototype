class dlf_reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(dlf_reg_adapter)
  function new(string name = "dlf_reg_adapter");
    super.new(name);
  endfunction
  // Generic RAL -> Bus Transaction
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    pcie_dl_seq_item bus_item=pcie_dl_seq_item::type_id::create("bus_item");
    bus_item.addr_reg = rw.addr;
    bus_item.data_reg = rw.data;
    bus_item.rd_or_wr = (rw.kind == UVM_READ) ? 1: 0;
    
    `uvm_info(get_type_name, $sformatf("reg2bus: addr = %0h, data = %0h, rd_or_wr = %0h", bus_item.addr_reg, bus_item.data_reg, bus_item.rd_or_wr), UVM_LOW);
    return bus_item;
  endfunction

  // Bus Transaction -> Generic RAL
  virtual function void bus2reg (uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    pcie_dl_seq_item bus_pkt;
    if(!$cast(bus_pkt, bus_item))
      `uvm_fatal(get_type_name(), "Failed to cast bus_item transaction")

    rw.addr = bus_pkt.addr_reg;
    rw.data = bus_pkt.data_reg;
    rw.kind = (bus_pkt.rd_or_wr) ? UVM_READ: UVM_WRITE;
  endfunction
endclass