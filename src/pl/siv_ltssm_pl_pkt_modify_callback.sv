/**
 * Callback class for modifying PCIe Physical Layer packet sequence items.
 * This callback provides a hook to modify packet contents before they are driven
 * onto the interface. Can be used for error injection.
 */
class siv_ltssm_ts_pkt_modify_callback extends uvm_callback;
  `uvm_object_utils(siv_ltssm_ts_pkt_modify_callback)
  
  // Counter to track callback invocations
  int callback_count = 0;
  
  /**
   * Constructor for the callback class
   * @param name Instance name for the callback object
   */
  function new(string name = "siv_ltssm_pl_pkt_modify_callback");
    super.new(name);
    `uvm_info("CB_INIT", $sformatf("Callback instance '%s' created", name), UVM_HIGH)
  endfunction
  
  /**
   * Packet modification method - called before packet is driven
   * @param item Reference to the sequence item being processed
   * 
   * Current implementation:
   * - Modifies the data rate ID symbol (position 4) to 0xAA on 6th invocation
   */
  virtual function void modify_item(ref siv_ltssm_seq_item item);
    `uvm_info("CB_EXEC", 
             $sformatf("Modifying packet (Callback count: %0d)", callback_count), 
             UVM_MEDIUM)
    
    // Inject modification on 6th packet (count starts at 0)
    if (callback_count == 5) begin
      item.symbols[4] = 8'hAA;
      `uvm_info("CB_MODIFY", 
               "Injected special pattern (0xAA) at symbol position 4", 
               UVM_LOW)
    end
    
    callback_count++;
  endfunction
endclass



//----------------------------------------------------
// USER DEFINED CALLBACKS TO MODIFY SEQUENCE ITEMS
//----------------------------------------------------

// 1. modifies the OS's first symbol to some random values
class modify_symbol_0_cb extends siv_ltssm_ts_pkt_modify_callback;
  `uvm_object_utils(modify_symbol_0_cb)

  function new(string name = "modify_symbol_0_cb");
    super.new(name);
  endfunction

  virtual function void modify_item(ref siv_ltssm_seq_item item);
    bit[7:0] rvalue = $random;
    item.symbols[0] = rvalue;
    `uvm_info("CB_MODIFY",$sformatf("Injected special pattern (%h) at symbol position 0",rvalue),UVM_LOW)
  endfunction
endclass