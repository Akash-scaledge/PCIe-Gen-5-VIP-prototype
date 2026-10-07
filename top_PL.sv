module top;
  // Clock and reset generation
  bit clk = 0;
  bit rst_n = 1;
  
  // Interface instantiation
//   siv_ltssm_intf pl_intf(clk, rst_n);
   // Interface instantiation
  siv_ltssm_intf pl_rc_intf(clk, rst_n);
  siv_ltssm_intf pl_ep_intf(clk, rst_n);
  
  // Clock generation
  initial begin
    forever #5 clk = ~clk;
  end
  
  // Reset generation
  initial begin
    rst_n = 1;
    #100 rst_n = 0;
  end
  
  // Waveform dumping
  initial begin
    $dumpfile("ltssm_waves.vcd");
    $dumpvars(0, top);
  end
  
  // UVM test startup
  initial begin
    // Set virtual interface
    uvm_config_db#(virtual siv_ltssm_intf)::set(null, "*", "rc_vif", pl_rc_intf);
    uvm_config_db#(virtual siv_ltssm_intf)::set(null, "*", "ep_vif", pl_ep_intf);
    // Run test
    run_test("reject_coeff_test");
  end
  
  // Simple loopback for testing
//   assign pl_intf.rx_data = pl_intf.tx_data;
   // Simple loopback for testing
  assign pl_rc_intf.rx_data = pl_ep_intf.tx_data;
  assign pl_ep_intf.rx_data = pl_rc_intf.tx_data;
endmodule
