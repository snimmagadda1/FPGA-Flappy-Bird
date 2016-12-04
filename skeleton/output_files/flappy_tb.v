`timescale 1 ns / 100 ps
module flappy_tb();
	reg clock, reset;
	reg [31:0] clockcycle;

	wire ps2_key_pressed;
	wire [31:0] bird_y;
	processor p(clock, reset, ps2_key_pressed, bird_y);
	
	initial
	begin
		clock = 0;
		reset = 0;
		$display($time, " << Starting the Simulation >>");
		$monitor("Bird Y = %d\n", bird_y[18:0]);
		#200000
		$stop;
	end
	
	always
		#10 clock = ~clock;


endmodule
