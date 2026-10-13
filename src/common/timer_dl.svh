class timer_uvm_dl extends uvm_object;
  `uvm_object_utils(timer_uvm_dl)
  virtual dl_if vif;
  bit done_flag;
  string key;
  bit is_running;
  bit stop_requested = 0;  
  int unsigned gen = 0;    // countdown generation: stop_timer()/start_timer() invalidate an older countdown

  function new(string name = "timer_uvm");
    super.new(name);
  endfunction
  
  // Set the vif from outside
  function void set_vif(virtual dl_if vif_in);
    this.vif = vif_in;
  endfunction

  //NEW METHOD
  // The timer stops at once and can be started again right away. (Before,
  // is_running stayed 1 until the old countdown ran out, so a start_timer()
  // right after stop_timer() was ignored and the timer never expired.)
  function void stop_timer();
    if (is_running) begin
      stop_requested = 1;
      is_running = 0;
      gen++;
      `uvm_info("TIMER", $sformatf("Timer [%s] stopped", key), UVM_LOW);
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
  gen++;

  `uvm_info("TIMER", $sformatf("Starting timer [%s] for %0d cycles", key, delay_cycles), UVM_LOW)
  fork
    automatic int local_delay = delay_cycles;
    automatic int unsigned my_gen = gen;
    begin
      repeat (local_delay) @(posedge vif.clk);
      // Only expire if this countdown was not stopped or replaced meanwhile
      if (my_gen == gen) begin
        done_flag = 1;
        is_running = 0;
        `uvm_info("TIMER", $sformatf("Timer expired after %0d cycles for key = %s", local_delay, key), UVM_LOW)
      end
    end
  join_none
endtask

endclass
