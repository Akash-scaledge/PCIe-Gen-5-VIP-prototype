
// `include "siv_tl_checker.sv"


//--------------------------------------------------------------
// Testbench Top Module
//--------------------------------------------------------------
module top;
  bit clk=0, rst=1;
  bit clk_i=0, rst_i=1;
  
 siv_tl_if rc_if(clk, rst);
  siv_tl_if ep_if(clk, rst);
   // Instantiate the memory interface
    mem_intf pif(clk_i, rst_i);
  
//     tl_checker dut1(.rc_tx_data(rc_if.tx_data),.rc_rx_data(rc_if.rx_data),.clk(clk),.rst(rst));
    // Instantiate the DUT and connect it to the interface
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
  
  initial begin
    forever #5 clk_i = ~clk_i;
  end
  
  initial begin
    rst_i=1;
    #10  rst_i=0;
  end
  initial begin
    forever #5 clk = ~clk;
  end
  
  initial begin
    rst=1;
    #10 rst=0;
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end

  initial begin
      // Set the virtual interface in the UVM configuration database
    uvm_config_db#(virtual siv_tl_if)::set(null, "uvm_test_top.pcieenv.rc_agent.*", "vif", rc_if);
    uvm_config_db#(virtual siv_tl_if)::set(null, "uvm_test_top.pcieenv.ep_agent.*", "vif", ep_if);
    uvm_config_db#(virtual mem_intf)::set(null, "*","vif",pif);
    run_test("mem_wr_rd_test");
//     run_test("mem_write_read_64");
//     run_test("config_wr_rd_test");
//     run_test("io_wr_rd_test");
//      run_test("mem_pcie_combined_test");
//         run_test("mem_wr_rd_BE_test"); 
//         run_test("mem_wr_zero_length_test");
    //     run_test("mem_wr_zero_rd_length_test");
    //     run_test("mem_wr_rd_ro_test"); 		//Bug is there
//     run_test("io_wr_rd_new_test");
//     run_test("mem_wr_rd_td_test");
//     run_test("mem_wr_rd_tc_vc_test");
//         run_test("config_wr_rd_td_test");
//     run_test("mem_wr_rd_rcb_test");
//         run_test("invalid_config_packet_test");
//     run_test("mem_wr_rd_invalid_at_test");
//     run_test("atomic_op_unc_swap_test");
//     run_test("atomic_op_unc_swap_64_bit_test");
//     run_test("atomic_op_compare_and_swap_test");
//     run_test("msg_ptm_req_test");
  end
  
  
  assign ep_if.rx_data = rc_if.tx_data; // RC drives → EP receives  
  assign rc_if.rx_data = ep_if.tx_data; // EP drives → RC receives

endmodule