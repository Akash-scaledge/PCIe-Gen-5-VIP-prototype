module top;
  // Clock and reset generation
  bit clk = 0;
  bit rst_n = 1;
  

  siv_ltssm_intf pl_rc_intf(clk, rst_n);
  siv_ltssm_intf pl_ep_intf(clk, rst_n);
  dl_if dl_if_0(clk, rst_n); // RC
  dl_if dl_if_1(clk, rst_n); // EP
  siv_tl_if rc_if(clk, rst_n);
  siv_tl_if ep_if(clk, rst_n);
  // Instantiate the memory interface
  mem_intf pif(clk, rst_n);
  memory dut(
    .clk_i(pif.clk_i),
    .rst_i(pif.rst_i),
        .addr_i(pif.addr_i),
        .wdata_i(pif.wdata_i),
        .write_i(pif.write_i),
        .rdata_o(pif.rdata_o),
        .enable_i(pif.enable_i),
        .ready_o(pif.ready_o)
    );
  // Clock generation
  initial begin
    forever #5 clk = ~clk;
  end
  assign pl_rc_intf.rx_data = pl_ep_intf.tx_data;
  assign pl_ep_intf.rx_data = pl_rc_intf.tx_data;
  assign dl_if_0.rx_data = dl_if_1.tx_data;
  assign dl_if_1.rx_data = dl_if_0.tx_data;
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
  initial begin
    uvm_config_db#(virtual dl_if)::set(null, "*", "vif", dl_if_0);
    uvm_config_db#(virtual dl_if)::set(null, "*", "vif", dl_if_1);
  end
  // UVM test startup
  initial begin
    // Set virtual interface
    uvm_config_db#(virtual siv_ltssm_intf)::set(null, "*", "rc_vif", pl_rc_intf);
    uvm_config_db#(virtual siv_ltssm_intf)::set(null, "*", "ep_vif", pl_ep_intf);
    uvm_config_db#(virtual siv_tl_if)::set(null, "*", "vif", rc_if);
    uvm_config_db#(virtual siv_tl_if)::set(null, "*", "vif", ep_if);
    uvm_config_db#(virtual mem_intf)::set(null, "*","vif",pif);
    
  end
  initial begin
    run_test("siv_pcie_base_test");
//      run_test("siv_L0s_base_test");
  end
  
  
  
endmodule