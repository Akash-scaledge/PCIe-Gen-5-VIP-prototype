////////////////////////////////////////////////////
// Interface (32-bit)
////////////////////////////////////////////////////

interface dl_if(input logic clk, input logic rst);
  logic [31:0] tx_data;//changes to 32 bit from 8
  logic [31:0] rx_data;
endinterface