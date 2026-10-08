////////////////////////////////////////////////////
// TOP MODULE (32-bit cross-connect)
////////////////////////////////////////////////////

module top;
  bit clk = 0;
  bit rst = 1;
  dl_if dl_if_0(clk, rst); // RC
  dl_if dl_if_1(clk, rst); // EP
  always #5 clk = ~clk;
  initial begin
    rst = 1; #100 rst = 0;
  end
  assign dl_if_0.rx_data = dl_if_1.tx_data;
  assign dl_if_1.rx_data = dl_if_0.tx_data;
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, top);
    run_test("dlcmsm_scale_test");
//     run_test("dlcmsm_test");
  end
  initial begin
    uvm_config_db#(virtual dl_if)::set(null, "uvm_test_top.env.device_0.*", "vif", dl_if_0);
    uvm_config_db#(virtual dl_if)::set(null, "uvm_test_top.env.device_1.*", "vif", dl_if_1);
  end
endmodule