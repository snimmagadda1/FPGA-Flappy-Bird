module vga_controller(iRST_n,
                      iVGA_CLK,
                      oBLANK_n,
                      oHS,
                      oVS,
                      b_data,
                      g_data,
                      r_data,
							 bird_y_long,
							 pipe1_x_long,
							 pipe1_y_long,
							 pipe2_x_long,
							 pipe2_y_long,
							 gameover_flag);
input iRST_n;
input iVGA_CLK;
output reg oBLANK_n;
output reg oHS;
output reg oVS;
output [7:0] b_data;
output [7:0] g_data;  
output [7:0] r_data;                        
///////// ////                     
reg [23:0] bgr_data;
wire VGA_CLK_n;
wire [7:0] index;
wire [23:0] bgr_data_raw;
wire cBLANK_n,cHS,cVS,rst;
////


//// ANIMATION

reg [18:0] bird_x = 19'd320;
input [31:0] bird_y_long, pipe1_x_long, pipe1_y_long, pipe2_x_long, pipe2_y_long;
input gameover_flag;


wire [18:0] bird_y;
assign bird_y = bird_y_long[18:0];

wire [18:0] pipe_x;
assign pipe_x = pipe1_x_long[18:0];

wire [18:0] pipe_y;
assign pipe_y = pipe1_y_long[18:0];

wire [18:0] pipe2_x;
assign pipe2_x = pipe2_x_long[18:0];

wire [18:0] pipe2_y;
assign pipe2_y = pipe2_y_long[18:0];

reg [18:0] gap_width = 19'd150;



wire [18:0] screen_width = 19'd640;
wire [18:0] screen_height = 19'd480;

wire [18:0] bird_width = 19'd45;
wire [18:0] bird_height = 19'd35;
wire [16:0] bird_static_start = 17'd0;
reg [16:0] bird_static_curr = 17'd0;

wire [18:0] lower_pipe_width = 19'd54;
wire [18:0] lower_pipe_height = 19'd120;
wire [16:0] lower_pipe_static_start = 17'd82;
reg [16:0] lower_pipe_static_curr = 17'd82;

wire [18:0] upper_pipe_width = 19'd54;
wire [18:0] upper_pipe_height = 19'd120;
wire [16:0] upper_pipe_static_start = 17'd82;
reg [16:0] upper_pipe_static_curr = 17'd82;

wire [18:0] lower_pipe2_width = 19'd54;
wire [18:0] lower_pipe2_height = 19'd120;
wire [16:0] lower_pipe2_static_start = 17'd82;
reg [16:0] lower_pipe2_static_curr = 17'd82;

wire [18:0] upper_pipe2_width = 19'd54;
wire [18:0] upper_pipe2_height = 19'd120;
wire [16:0] upper_pipe2_static_start = 17'd82;
reg [16:0] upper_pipe2_static_curr = 17'd82;

wire [18:0] gameover_width = 19'd330;
wire [18:0] gameover_height = 19'd60;
wire [16:0] gameover_static_start = 17'd160;
reg [16:0] gameover_static_curr = 17'd160;



reg [18:0] bird_left = 19'd0;
reg [18:0] bird_right = 19'd0;
reg [18:0] bird_top = 19'd0;
reg [18:0] bird_bottom = 19'd0;

reg [18:0] bird_pixels_drawn = 19'd0;

reg [18:0] lower_pipe_left = 19'd0;
reg [18:0] lower_pipe_right = 19'd0;
reg [18:0] lower_pipe_top = 19'd0;
reg [18:0] lower_pipe_bottom = 19'd0;

reg [18:0] upper_pipe_left = 19'd0;
reg [18:0] upper_pipe_right = 19'd0;
reg [18:0] upper_pipe_top = 19'd0;
reg [18:0] upper_pipe_bottom = 19'd0;

reg [18:0] lower_pipe2_left = 19'd0;
reg [18:0] lower_pipe2_right = 19'd0;
reg [18:0] lower_pipe2_top = 19'd0;
reg [18:0] lower_pipe2_bottom = 19'd0;

reg [18:0] upper_pipe2_left = 19'd0;
reg [18:0] upper_pipe2_right = 19'd0;
reg [18:0] upper_pipe2_top = 19'd0;
reg [18:0] upper_pipe2_bottom = 19'd0;

reg [18:0] lower_pipe_pixels_drawn = 19'd0;

reg [18:0] upper_pipe_pixels_drawn = 19'd0;

reg [18:0] lower_pipe2_pixels_drawn = 19'd0;

reg [18:0] upper_pipe2_pixels_drawn = 19'd0;


reg [18:0] gameover_left = 19'd0;
reg [18:0] gameover_right = 19'd0;
reg [18:0] gameover_top = 19'd0;
reg [18:0] gameover_bottom = 19'd0;

reg [18:0] gameover_pixels_drawn = 19'd0;

reg [16:0] static_ADDR;
wire [7:0] static_output;
reg [18:0] dynamic_ADDR;

reg drawing_bird = 1'b0;
reg drawing_lower_pipe = 1'b0;
reg drawing_upper_pipe = 1'b0;
reg drawing_lower_pipe2 = 1'b0;
reg drawing_upper_pipe2 = 1'b0;
reg drawing_gameover = 1'b0;

////

wire [18:0] lower_pipe_x;
assign lower_pipe_x = pipe_x - lower_pipe_width/2;
wire [18:0] lower_pipe_y;
assign lower_pipe_y = pipe_y + gap_width/2;

wire [18:0] upper_pipe_x;
assign upper_pipe_x = pipe_x - upper_pipe_width/2;
wire [18:0] upper_pipe_y;
assign upper_pipe_y = 19'd0;

wire [18:0] lower_pipe2_x;
assign lower_pipe2_x = pipe2_x - lower_pipe2_width/2;
wire [18:0] lower_pipe2_y;
assign lower_pipe2_y = pipe2_y + gap_width/2;

wire [18:0] upper_pipe2_x;
assign upper_pipe2_x = pipe2_x - upper_pipe2_width/2;
wire [18:0] upper_pipe2_y;
assign upper2_pipe_y = 19'd0;


////
reg [4:0] animation_count = 5'd0;



////
assign rst = ~iRST_n;
video_sync_generator LTM_ins (.vga_clk(iVGA_CLK),
                              .reset(rst),
                              .blank_n(cBLANK_n),
                              .HS(cHS),
                              .VS(cVS));
										
										


////Address generator
always@(posedge iVGA_CLK,negedge iRST_n)
begin
  if (!iRST_n)
  begin
     dynamic_ADDR=19'd0;
	  static_ADDR=17'd0;
	  
	  bird_pixels_drawn=19'd0;
	  lower_pipe_pixels_drawn=19'd0;
	  upper_pipe_pixels_drawn=19'd0;
	  lower_pipe2_pixels_drawn=19'd0;
	  upper_pipe2_pixels_drawn=19'd0;
	  gameover_pixels_drawn = 19'd0;
	  
	  bird_static_curr=bird_static_start;
	  lower_pipe_static_curr=lower_pipe_static_start;
	  upper_pipe_static_curr=upper_pipe_static_start;
	  lower_pipe2_static_curr=lower_pipe2_static_start;
	  upper_pipe2_static_curr=upper_pipe2_static_start;
	  gameover_static_curr = gameover_static_start;
	  
	  drawing_bird=1'b0;
	  drawing_lower_pipe=1'b0;
	  drawing_upper_pipe=1'b0;
	  drawing_lower_pipe2=1'b0;
	  drawing_upper_pipe2=1'b0;
	  drawing_gameover = 1'b0;
	  
	  animation_count = animation_count + 1;
	  
	  if (animation_count == 5'd30) // BLACK FUCKING MAGIC
		begin
			animation_count = 6'd0;	
			
			bird_left <= bird_x;
			bird_right <= (bird_x + bird_width);
			bird_top <= bird_y;
			bird_bottom <= (bird_y + bird_height);
			
			lower_pipe_left <= lower_pipe_x;
			lower_pipe_right <= (lower_pipe_x + lower_pipe_width);
			lower_pipe_top <= lower_pipe_y;
			lower_pipe_bottom <= screen_height;
		
			upper_pipe_left <= upper_pipe_x;
			upper_pipe_right <= (upper_pipe_x + upper_pipe_width);
			upper_pipe_top <= upper_pipe_y;
			upper_pipe_bottom <= pipe_y-gap_width/2;
			
			lower_pipe2_left <= lower_pipe2_x;
			lower_pipe2_right <= (lower_pipe2_x + lower_pipe2_width);
			lower_pipe2_top <= lower_pipe2_y;
			lower_pipe2_bottom <= screen_height;
		
			upper_pipe2_left <= upper_pipe2_x;
			upper_pipe2_right <= (upper_pipe2_x + upper_pipe2_width);
			upper_pipe2_top <= upper_pipe2_y;
			upper_pipe2_bottom <= pipe2_y-gap_width/2;
			
			gameover_left <= 19'd155;
			gameover_right <= 19'd155 + gameover_width;
			gameover_top <= 19'd175;
			gameover_bottom <= 19'd175 + gameover_height;
			
		end
	
  end
  else if (cHS==1'b0 && cVS==1'b0)
  begin
     dynamic_ADDR=19'd0;
	  static_ADDR=17'd0;
	  
	  bird_pixels_drawn=19'd0;
	  lower_pipe_pixels_drawn=19'd0;
	  upper_pipe_pixels_drawn=19'd0;
	  lower_pipe2_pixels_drawn=19'd0;
	  upper_pipe2_pixels_drawn=19'd0;
	  gameover_pixels_drawn = 19'd0;
	  
	  bird_static_curr=bird_static_start;
	  lower_pipe_static_curr=lower_pipe_static_start;
	  upper_pipe_static_curr=upper_pipe_static_start;
	  lower_pipe2_static_curr=lower_pipe2_static_start;
	  upper_pipe2_static_curr=upper_pipe2_static_start;
	  gameover_static_curr = gameover_static_start;
	  
	  drawing_bird=1'b0;
	  drawing_lower_pipe=1'b0;
	  drawing_upper_pipe=1'b0;
	  drawing_lower_pipe2=1'b0;
	  drawing_upper_pipe2=1'b0;
	  drawing_gameover = 1'b0;
	  
	  animation_count = animation_count + 1;
	  
	  if (animation_count == 5'd30)
		begin
			animation_count = 6'd0;
			
			bird_left <= bird_x;
			bird_right <= (bird_x + bird_width);
			bird_top <= bird_y;
			bird_bottom <= (bird_y + bird_height);
			
			lower_pipe_left <= lower_pipe_x;
			lower_pipe_right <= (lower_pipe_x + lower_pipe_width);
			lower_pipe_top <= lower_pipe_y;
			lower_pipe_bottom <= screen_height;
		
			upper_pipe_left <= upper_pipe_x;
			upper_pipe_right <= (upper_pipe_x + upper_pipe_width);
			upper_pipe_top <= upper_pipe_y;
			upper_pipe_bottom <= pipe_y-gap_width/2;
			
			lower_pipe2_left <= lower_pipe2_x;
			lower_pipe2_right <= (lower_pipe2_x + lower_pipe2_width);
			lower_pipe2_top <= lower_pipe2_y;
			lower_pipe2_bottom <= screen_height;
		
			upper_pipe2_left <= upper_pipe2_x;
			upper_pipe2_right <= (upper_pipe2_x + upper_pipe2_width);
			upper_pipe2_top <= upper_pipe2_y;
			upper_pipe2_bottom <= pipe2_y-gap_width/2;
			
			gameover_left <= 19'd155;
			gameover_right <= 19'd155 + gameover_width;
			gameover_top <= 19'd175;
			gameover_bottom <= 19'd175 + gameover_height;
		end
		
  end
  else if (cBLANK_n==1'b1)
  begin
     dynamic_ADDR=dynamic_ADDR+1;
	  
	  if (gameover_flag == 1'b0)
	  begin
	  
	  if (dynamic_ADDR % screen_width >= bird_left && dynamic_ADDR % screen_width <= bird_right
	      && (dynamic_ADDR/640) % screen_height >= bird_top && (dynamic_ADDR/640) % screen_height <= bird_bottom)
	  begin
	     if (~drawing_bird)
		  begin
		     drawing_bird=1'b1;
			  static_ADDR=bird_static_curr;
		  end
	     static_ADDR=static_ADDR+1;
		  bird_pixels_drawn=bird_pixels_drawn+1;
		  if (bird_pixels_drawn == bird_width+1)
		  begin
		     bird_pixels_drawn=19'd0;
		     static_ADDR=static_ADDR+(screen_width-bird_width)-1;
		  end
	  end
	  else
	  begin
	     if (drawing_bird)
		  begin
		     drawing_bird=1'b0;
			  bird_static_curr=static_ADDR;
		  end
	  end
	  
	  if (dynamic_ADDR % screen_width >= lower_pipe_left && dynamic_ADDR % screen_width <= lower_pipe_right
	      && (dynamic_ADDR/640) % screen_height >= lower_pipe_top && (dynamic_ADDR/640) % screen_height <= lower_pipe_bottom)
	  begin
	     if (~drawing_lower_pipe)
		  begin
		     drawing_lower_pipe=1'b1;
			  static_ADDR=lower_pipe_static_curr;
		  end
		  if (static_ADDR >= 640*120)
		  begin
		     static_ADDR=lower_pipe_static_start;
		  end
	     static_ADDR=static_ADDR+1;
		  lower_pipe_pixels_drawn=lower_pipe_pixels_drawn+1;
		  if (lower_pipe_pixels_drawn == lower_pipe_width+1)
		  begin
		     lower_pipe_pixels_drawn=19'd0;
		     static_ADDR=static_ADDR+(screen_width-lower_pipe_width)-1;
		  end
	  end
	  else
	  begin
	     if (drawing_lower_pipe)
		  begin
		     drawing_lower_pipe=1'b0;
			  lower_pipe_static_curr=static_ADDR;
		  end
	  end
	  
	  if (dynamic_ADDR % screen_width >= upper_pipe_left && dynamic_ADDR % screen_width <= upper_pipe_right
	      && (dynamic_ADDR/640) % screen_height >= upper_pipe_top && (dynamic_ADDR/640) % screen_height <= upper_pipe_bottom)
	  begin
	     if (~drawing_upper_pipe)
		  begin
		     drawing_upper_pipe=1'b1;
			  static_ADDR=upper_pipe_static_curr;
		  end
		  if (static_ADDR >= 640*120)
		  begin
		     static_ADDR=upper_pipe_static_start;
		  end
	     static_ADDR=static_ADDR+1;
		  upper_pipe_pixels_drawn=upper_pipe_pixels_drawn+1;
		  if (upper_pipe_pixels_drawn == upper_pipe_width+1)
		  begin
		     upper_pipe_pixels_drawn=19'd0;
		     static_ADDR=static_ADDR+(screen_width-upper_pipe_width)-1;
		  end
	  end
	  else
	  begin
	     if (drawing_upper_pipe)
		  begin
		     drawing_upper_pipe=1'b0;
			  upper_pipe_static_curr=static_ADDR;
		  end
	  end
	  
	  
	  
	  
	   if (dynamic_ADDR % screen_width >= lower_pipe2_left && dynamic_ADDR % screen_width <= lower_pipe2_right
	      && (dynamic_ADDR/640) % screen_height >= lower_pipe2_top && (dynamic_ADDR/640) % screen_height <= lower_pipe2_bottom)
	  begin
	     if (~drawing_lower_pipe2)
		  begin
		     drawing_lower_pipe2=1'b1;
			  static_ADDR=lower_pipe2_static_curr;
		  end
		  if (static_ADDR >= 640*120)
		  begin
		     static_ADDR=lower_pipe2_static_start;
		  end
	     static_ADDR=static_ADDR+1;
		  lower_pipe2_pixels_drawn=lower_pipe2_pixels_drawn+1;
		  if (lower_pipe2_pixels_drawn == lower_pipe2_width+1)
		  begin
		     lower_pipe2_pixels_drawn=19'd0;
		     static_ADDR=static_ADDR+(screen_width-lower_pipe2_width)-1;
		  end
	  end
	  else
	  begin
	     if (drawing_lower_pipe2)
		  begin
		     drawing_lower_pipe2=1'b0;
			  lower_pipe2_static_curr=static_ADDR;
		  end
	  end
	  
	  if (dynamic_ADDR % screen_width >= upper_pipe2_left && dynamic_ADDR % screen_width <= upper_pipe2_right
	      && (dynamic_ADDR/640) % screen_height >= upper_pipe2_top && (dynamic_ADDR/640) % screen_height <= upper_pipe2_bottom)
	  begin
	     if (~drawing_upper_pipe2)
		  begin
		     drawing_upper_pipe2=1'b1;
			  static_ADDR=upper_pipe2_static_curr;
		  end
		  if (static_ADDR >= 640*120)
		  begin
		     static_ADDR=upper_pipe2_static_start;
		  end
	     static_ADDR=static_ADDR+1;
		  upper_pipe2_pixels_drawn=upper_pipe2_pixels_drawn+1;
		  if (upper_pipe2_pixels_drawn == upper_pipe2_width+1)
		  begin
		     upper_pipe2_pixels_drawn=19'd0;
		     static_ADDR=static_ADDR+(screen_width-upper_pipe2_width)-1;
		  end
	  end
	  else
	  begin
	     if (drawing_upper_pipe2)
		  begin
		     drawing_upper_pipe2=1'b0;
			  upper_pipe2_static_curr=static_ADDR;
		  end
	  end
	  
	  end
	  
	  else
	  begin
	  
	  if (dynamic_ADDR % screen_width >= gameover_left && dynamic_ADDR % screen_width <= gameover_right
	      && (dynamic_ADDR/640) % screen_height >= gameover_top && (dynamic_ADDR/640) % screen_height <= gameover_bottom)
	  begin
	     if (~drawing_gameover)
		  begin
		     drawing_gameover=1'b1;
			  static_ADDR=gameover_static_curr;
		  end
		  if (static_ADDR >= 640*120)
		  begin
		     static_ADDR=gameover_static_start;
		  end
	     static_ADDR=static_ADDR+1;
		  gameover_pixels_drawn=gameover_pixels_drawn+1;
		  if (gameover_pixels_drawn == gameover_width+1)
		  begin
		     gameover_pixels_drawn=19'd0;
		     static_ADDR=static_ADDR+(screen_width-gameover_width)-1;
		  end
	  end
	  else
	  begin
	     if (drawing_gameover)
		  begin
		     drawing_gameover=1'b0;
			  gameover_static_curr=static_ADDR;
		  end
	  end
	  
	  end
	  
  end
	  
end
//////////////////////////
//////INDEX addr.
assign VGA_CLK_n = ~iVGA_CLK;

img_data static_data(
	.address( static_ADDR ),
	.clock( VGA_CLK_n ),
	.q( static_output )
	);

vga_data	vga_display (
	.address ( dynamic_ADDR ),
	.data( static_output ), 
	.aclr(1'b0),
	.clock ( VGA_CLK_n ),
	.wren(1'b1),
	.q ( index )
	);
//////Color table output
img_index	img_index_inst (
	.address ( index ),
	.clock ( iVGA_CLK ),
	.q ( bgr_data_raw)
	);	
//////
//////latch valid data at falling edge;
always@(posedge VGA_CLK_n) bgr_data <= bgr_data_raw;
assign b_data = bgr_data[23:16];
assign g_data = bgr_data[15:8];
assign r_data = bgr_data[7:0];
///////////////////
//////Delay the iHD, iVD,iDEN for one clock cycle;
always@(negedge iVGA_CLK)
begin
  oHS<=cHS;
  oVS<=cVS;
  oBLANK_n<=cBLANK_n;
end

endmodule
 	















