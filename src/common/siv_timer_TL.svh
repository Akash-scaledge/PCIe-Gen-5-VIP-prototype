class timer_uvm_tl extends uvm_object;
  `uvm_object_utils(timer_uvm_tl)
  virtual siv_tl_if vif;
  bit done_flag;
  string key;

  function new(string name = "timer_uvm");
    super.new(name);
  endfunction
  // Set the vif from outside
  function void set_vif(virtual siv_tl_if vif_in);
    this.vif = vif_in;
  endfunction

  // Task to start the timer
  task start_timer(int delay_cycles, string user_key);
    done_flag = 0;
    key=user_key;
    `uvm_info("TIMER", $sformatf("Starting timer [%s] for %0d cycles", key, delay_cycles), UVM_LOW)
    fork
      automatic int local_delay = delay_cycles;
      begin
        //$display($time," in FORK, local_delay=%0d", local_delay);
        repeat (local_delay) begin
          @(posedge vif.clk);
        end
        done_flag = 1;
        `uvm_info("TIMER", $sformatf("Timer expired after %0d cycles for key = %s", local_delay, key), UVM_LOW)
      end
    join_none
  endtask
endclass