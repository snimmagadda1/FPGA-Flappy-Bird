module lfsr_32bit(clk, rst_n, data, seed);

input clk, rst_n;
input [31:0] seed;
output reg [31:0] data;
wire feedback;
assign feedback = data[31] ^ data[1];
initial
begin
	data <= seed;
end

always @(posedge clk or negedge rst_n)
begin
  if (~rst_n) 
  begin
    data <= seed;
	 end
  else
  begin
    data <= {data[30:0], feedback};
	 end
end

endmodule
