// Code your design here
module memory(clk_i,rst_i,addr_i,write_i,wdata_i,rdata_o,enable_i,ready_o);
parameter WIDTH=32;
parameter DEPTH=1024;
parameter ADDR_SIZE=$clog2(DEPTH);

input clk_i,rst_i,write_i,enable_i;
input [ADDR_SIZE-1:0]addr_i;
input [WIDTH-1:0]wdata_i;

output reg [WIDTH-1:0]rdata_o;
output reg ready_o;

reg [WIDTH-1:0] mem[DEPTH-1:0];
  always @(posedge clk_i)begin
	if(rst_i==1)begin
		ready_o=0;
		rdata_o=0;
		for(int i=0;i<DEPTH;i++)begin
          mem[i]=0;
		end
	end
	else begin
		if(enable_i==1)begin
			ready_o=1;
          if(write_i==1)begin 
            mem[addr_i]=wdata_i;
          end
			else begin
              rdata_o=mem[addr_i];
            end
           // $display("dut mem[%0h]=%0h",addr_i,mem[addr_i]);
		end
		else ready_o<=0;
	end
end
endmodule
