class timer_uvm_dl extends uvm_object;
  `uvm_object_utils(timer_uvm_dl)
  virtual dl_if vif;
  bit done_flag;
  string key;
  bit is_running;
  bit stop_requested = 0;  

  function new(string name = "timer_uvm");
    super.new(name);
  endfunction
  
  // Set the vif from outside
  function void set_vif(virtual dl_if vif_in);
    this.vif = vif_in;
  endfunction

  //NEW METHOD
  function void stop_timer();
    if (is_running) begin
      stop_requested = 1;
      `uvm_info("TIMER", $sformatf("Timer [%s] stop requested", key), UVM_LOW);
    end
  endfunction

 // start_timer METHOD
 task start_timer(int delay_cycles, string user_key);
  if (is_running)
    return;

  is_running = 1;
  done_flag = 0;
  stop_requested = 0;
  key = user_key;

  `uvm_info("TIMER", $sformatf("Starting timer [%s] for %0d cycles", key, delay_cycles), UVM_LOW)
  fork
    automatic int local_delay = delay_cycles;
    begin
      repeat (local_delay) @(posedge vif.clk);
      // Only set done_flag if not stopped
      if (!stop_requested) begin
        done_flag = 1;
        `uvm_info("TIMER", $sformatf("Timer expired after %0d cycles for key = %s", local_delay, key), UVM_LOW)
      end
      is_running = 0;
    end
  join_none
endtask

endclass
