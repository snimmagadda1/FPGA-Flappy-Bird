module lfsr_32bit(clk, rst_n, data, seed);

input clk, rst_n;
input [31:0] seed;
output reg [31:0] data = seed;
wire feedback;
assign feedback = data[31] ^ data[1];


always @(posedge clk or negedge rst_n)
  if (~rst_n) 
    data <= seed;
  else
    data <= {data[30:0], feedback} ;

endmodule
