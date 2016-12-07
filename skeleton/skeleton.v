module skeleton(resetn, 
	ps2_clock, ps2_data, 										// ps2 related I/O
	debug_data_in, debug_addr, leds, 						// extra debugging ports
	lcd_data, lcd_rw, lcd_en, lcd_rs, lcd_on, lcd_blon,// LCD info
	seg1, seg2, seg3, seg4, seg5, seg6, seg7, seg8,		// seven segements
	VGA_CLK,   														//	VGA Clock
	VGA_HS,															//	VGA H_SYNC
	VGA_VS,															//	VGA V_SYNC
	VGA_BLANK,														//	VGA BLANK
	VGA_SYNC,														//	VGA SYNC
	VGA_R,   														//	VGA Red[9:0]
	VGA_G,	 														//	VGA Green[9:0]
	VGA_B,															//	VGA Blue[9:0]
	CLOCK_50,														// 50 MHz clock
	button_pressed,
	pick_board);  											// KEY 1		
		
	////////////////////////	VGA	////////////////////////////
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK;				//	VGA BLANK
	output			VGA_SYNC;				//	VGA SYNC
	output	[7:0]	VGA_R;   				//	VGA Red[9:0]
	output	[7:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[7:0]	VGA_B;   				//	VGA Blue[9:0]
	input				CLOCK_50;

	////////////////////////	PS2	////////////////////////////
	input 			resetn;
	inout 			ps2_data, ps2_clock;
	
	////////////////////////	LCD and Seven Segment	////////////////////////////
	output 			   lcd_rw, lcd_en, lcd_rs, lcd_on, lcd_blon;
	output 	[7:0] 	leds, lcd_data;
	output 	[6:0] 	seg1, seg2, seg3, seg4, seg5, seg6, seg7, seg8;
	output 	[31:0] 	debug_data_in;
	output   [11:0]   debug_addr;
	
	
	
	
	
	wire			 clock;
	wire			 lcd_write_en;
	wire 	[31:0] lcd_write_data;
	wire	[7:0]	 ps2_key_data;
	wire			 ps2_key_pressed;
	wire	[7:0]	 ps2_out;
	
	input button_pressed;
	input pick_board;
	
	wire butt_pressed;
	assign butt_pressed = ~button_pressed;

	
	
	wire [31:0] bird_y, pipe1_x, pipe1_y, pipe2_x, pipe2_y, pipe3_x, pipe3_y, game_score, game_score_disp;
	
	wire gameover_flag;
	
	wire collision_flag;
	
	wire [7:0] game_ascii;
	
	assign game_ascii = game_score[7:0] + 7'd48;



	
	// clock divider (by 20, i.e., 2.5 MHz)
	//pll div(.inclk0(CLOCK_50),.c0(inclock));
	assign clock = CLOCK_50;
	
	// UNCOMMENT FOLLOWING LINE AND COMMENT ABOVE LINE TO RUN AT 50 MHz
	//assign clock = inclock;
	wire [31:0] piperandout;
	lfsr_32bit PRNG1(clock, resetn, piperandout, 32'hf0f0f0f0);
	wire [31:0] pipe_y_rand;
	assign pipe_y_rand = piperandout % 50 + 190;
	
	
	wire butt_posedge, bex_return;
	rising_edge_detect(butt_pressed, ~resetn, clock, butt_posedge, reset_jump_flag);
	
	wire butt_posedge_synced;
	
	// your processor
	processor myprocessor(clock, ~resetn, butt_pressed, bird_y, pipe1_x, pipe1_y, pipe2_x, pipe2_y, pipe3_x, pipe3_y, pipe_y_rand, gameover_flag, game_score, collision_flag, bex_return);
	
	// keyboard controller
	PS2_Interface myps2(clock, resetn, ps2_clock, ps2_data, ps2_key_data, ps2_key_pressed, ps2_out);
	
	// lcd controller
	lcd mylcd(clock, ~resetn, 1'b0, game_ascii, lcd_data, lcd_rw, lcd_en, lcd_rs, lcd_on, lcd_blon);
	
	// example for sending ps2 data to the first two seven segment displays
	decimal_to_seven_segment dig1(game_score_disp % 10, seg1);
	decimal_to_seven_segment dig2((game_score_disp/10) % 10, seg2);
	decimal_to_seven_segment dig3((game_score_disp/100) % 10, seg3);
	Hexadecimal_To_Seven_Segment hex4(4'b0, seg4);
	Hexadecimal_To_Seven_Segment hex5(4'b0, seg5);
	Hexadecimal_To_Seven_Segment hex6(4'b0, seg6);
	Hexadecimal_To_Seven_Segment hex7(4'b0, seg7);
	Hexadecimal_To_Seven_Segment hex8(4'b0, seg8);
	
	// some LEDs that you could use for debugging if you wanted
	assign leds = {7'b0, butt_posedge};
		
	// VGA
	Reset_Delay			r0	(.iCLK(CLOCK_50),.oRESET(DLY_RST)	);
	VGA_Audio_PLL 		p1	(.areset(~DLY_RST),.inclk0(CLOCK_50),.c0(VGA_CTRL_CLK),.c1(AUD_CTRL_CLK),.c2(VGA_CLK)	);
	vga_controller vga_ins(.iRST_n(DLY_RST),
								 .iVGA_CLK(VGA_CLK),
								 .oBLANK_n(VGA_BLANK),
								 .oHS(VGA_HS),
								 .oVS(VGA_VS),
								 .b_data(VGA_B),
								 .g_data(VGA_G),
								 .r_data(VGA_R),
								 .bird_y_long(bird_y),
								 .pipe1_x_long(pipe1_x),
								 .pipe1_y_long(pipe1_y),
								 .pipe2_x_long(pipe2_x),
								 .pipe2_y_long(pipe2_y),
								 .pipe3_x_long(pipe3_x),
								 .pipe3_y_long(pipe3_y),
								 .gameover_flag(gameover_flag),
								 .collision_flag(collision_flag),
								 .game_score(game_score),
								 .game_score_disp(game_score_disp),
								 .pick_board(pick_board),
								 .butt_posedge_in(butt_posedge),
								 .butt_posedge_out(butt_posedge_synced));
	
	
endmodule

module rising_edge_detect(sig, rst, clk, sig_edge, bex_in);

	input sig, rst, clk, bex_in;
	wire sig_edge_in;
	wire dffout;
	output sig_edge;
	
	dffe d1(.d(~sig), .clk(clk), .ena(1'b1), .prn(1'b1), .clrn(1'b1), .q(dffout));

	
	dffe d2(.d(sig & dffout), .clk(clk), .ena(sig & dffout), .prn(1'b1), .clrn(~bex_in), .q(sig_edge));

endmodule
