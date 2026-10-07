// Define a memory transaction class extending from uvm_sequence_item
class mem_tx extends uvm_sequence_item;

    // Declare randomized fields for address, data, and operation type
    rand bit [ADDR_SIZE-1:0] addr_i;   // Address input (based on DEPTH)
    rand bit [WIDTH-1:0] data;         // Data for read/write
    rand bit write_i;                  // Write control (1 = write, 0 = read)

    // Register fields for automation (copy, compare, print, etc.)
    `uvm_object_utils_begin(mem_tx)
        `uvm_field_int(addr_i, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(write_i, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor macro for UVM objects
    `NEWOBJ;

endclass
