//--------------------------------------------------------------
// SIV UVM Timer (siv_uvm_timer)
//--------------------------------------------------------------
// Features:
// - Configurable delay in clock cycles
// - Interface-aware (requires virtual interface with clock)
// - Fork/join_none based non-blocking implementation
// - Debug logging with UVM messaging
// import uvm_pkg::*;

class siv_uvm_timer_pl extends uvm_object;
  `uvm_object_utils(siv_uvm_timer_pl)

  // Interface and Control Variables
  virtual siv_ltssm_intf      timer_interface;  // Virtual interface with clock
  bit                    timer_expired;    // Timer flag
  string                 timer_id;         // Identifier 

  // Constructor
  //   name - Instance name for UVM hierarchy
  function new(string name = "siv_uvm_timer");
    super.new(name);
    this.timer_expired = 0;
    this.timer_id = "";
  endfunction

  // Set Virtual Interface
  function void set_vif(virtual siv_ltssm_intf vif);
    this.timer_interface = vif;
    `uvm_info("TIMER_INIT", 
             $sformatf("Virtual interface set for timer: %s", 
             this.get_name()), 
             UVM_HIGH)
  endfunction

  // Start Timer Task
  //   delay_cycles - Number of clock cycles to wait
  //   timer_name   - Identifier 
  //
  // Description:
  //   Starts non-blocking timer that will set done_flag after
  //   specified number of clock cycles
  task start_timer(int delay_cycles, string timer_name);
    // Initialize timer state
    this.timer_expired = 0;
    this.timer_id = timer_name;
    
    `uvm_info("TIMER_START", 
             $sformatf("[%s] Starting %0d cycle timer", 
             timer_id, delay_cycles), 
             UVM_MEDIUM)

    fork
      begin
        automatic int cycles_remaining = delay_cycles;
        
        // Count down clock cycles
        while (cycles_remaining > 0) begin
          @(posedge timer_interface.clk);
          cycles_remaining--;
        end
        
        // Timer completion
        this.timer_expired = 1;
        `uvm_info("TIMER_DONE", 
                 $sformatf("[%s] Timer completed after %0d cycles", 
                 timer_id, delay_cycles), 
                 UVM_MEDIUM)
      end
    join_none
  endtask

  //   Current expiration status of the timer
  function bit is_done();
    return timer_expired;
  endfunction

endclass