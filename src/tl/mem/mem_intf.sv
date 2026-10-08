// Define a SystemVerilog interface for memory communication
interface mem_intf(input clk_i, rst_i);

  // Declare interface signals
  bit [9:0] addr_i;       // Address input (10-bit for 1024-depth memory)
  bit [31:0] rdata_o;     // Read data output
  bit [31:0] wdata_i;     // Write data input
  bit ready_o;            // Ready signal from DUT
  bit enable_i;           // Enable signal to initiate transaction
  bit write_i;            // Write control signal (1 = write, 0 = read)

  // Clocking block for monitor (passive observation)
  clocking mon_cb @(posedge clk_i);
    default input #0;
    input addr_i, wdata_i, rdata_o, write_i, enable_i, ready_o;
  endclocking

  // Clocking block for driver/BFM (active driving)
  clocking bfm_cb @(posedge clk_i);
    default input #0 output #1;
    input ready_o, rdata_o;
    output addr_i, wdata_i, write_i, enable_i;
  endclocking

endinterface
