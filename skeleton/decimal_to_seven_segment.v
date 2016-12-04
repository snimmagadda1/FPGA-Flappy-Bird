module decimal_to_seven_segment (
	// Inputs
	digit,

	// Bidirectional

	// Outputs
	seven_seg_display
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input		[31:0]	digit;

// Bidirectional

// Outputs
output reg		[6:0]	seven_seg_display;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires

// Internal Registers

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/


/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/
always @(*)
begin
 case(digit)
   32'd0 : seven_seg_display = 7'b1000000; //0
   32'd1 : seven_seg_display = 7'b1111001; //1
   32'd2 : seven_seg_display = 7'b0100100; //2
   32'd3 : seven_seg_display = 7'b0110000; //3
   32'd4 : seven_seg_display = 7'b0011001; //4
   32'd5 : seven_seg_display = 7'b0010010; //5
   32'd6 : seven_seg_display = 7'b0000010; //6
   32'd7 : seven_seg_display = 7'b1111000; //7
   32'd8 : seven_seg_display = 7'b0000000; //8
   32'd9 : seven_seg_display = 7'b0010000; //9
   default : seven_seg_display = 7'b0111111; //dash
  endcase
end


/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/


endmodule

