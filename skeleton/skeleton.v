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
	button_pressed);  											// KEY 1		
		
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
//	
//	lfsr_32bit PRNG1(clock, resetn, pipe1randout, 32'hf0f0f0f0);
//	lfsr_32bit PRNG2(clock, resetn, pipe2randout, 32'hffffffff);
//	lfsr_32bit PRNG3(clock, resetn, pipe3randout, 32'h00000000);
//	assign pipe1_y = pipe1randout % 200 + 240;
//	assign pipe2_y = pipe2randout % 200 + 240;
//	assign pipe3_y = pipe3randout % 200 + 240;
	
	// your processor
	processor myprocessor(clock, ~resetn, butt_pressed, bird_y, pipe1_x, pipe1_y, pipe2_x, pipe2_y, pipe3_x, pipe3_y, gameover_flag, game_score, collision_flag);
	
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
	assign leds = 8'b00010100;
		
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
								 .game_score_disp(game_score_disp));
	
	
endmodule
