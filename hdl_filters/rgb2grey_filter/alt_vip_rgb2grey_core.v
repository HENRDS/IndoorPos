// (C) 2001-2016 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// example algorithm - to be replaced by user algorithm
// this algorithm turns RGB colors into greyscale
module alt_vip_rgb2grey_core

	#(parameter BITS_PER_SYMBOL = 8,
		parameter SYMBOLS_PER_BEAT = 3) // only 1 symbol used as black/white
		
	(	input		clk,
		input		rst,
		
		// interface to VIP control packet decoder via VIP flow control wrapper	
		input		stall_in,
		output	read,		
		input		[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_in, 		
		input		end_of_video,
		
		input		[15:0] width_in,
		input		[15:0] height_in,
		input		[3:0] interlaced_in,
		input		vip_ctrl_valid_in,
		
		// interface to VIP control packet encoder via VIP flow control wrapper	
		input		stall_out,		
		output	write,
		output [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_out,
		output	end_of_video_out,		
		
		output [15:0] width_out,
		output [15:0] height_out,
		output	[3:0] interlaced_out,		
		output vip_ctrl_valid_out);
		
// internal flow controlled signals				
wire [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT : 0] data_int;
wire input_valid;
reg data_available;
reg [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT : 0] data_int_reg;
reg [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT : 0] data_out_reg;
		
/******************************************************************************/
/* Data processing of user algorithm starts here                              */
/******************************************************************************/

/*********************************************/
/* this example: RGB to greyscale conversion */
/*********************************************/

// color constants
wire [7:0] red_factor;
wire [7:0] green_factor;
wire [7:0] blue_factor;

assign red_factor = 76; // 255 * 0.299
assign green_factor = 150; // 255 * 0.587;
assign blue_factor = 29; // 255 * 0.114;

// color components input data
wire [BITS_PER_SYMBOL - 1:0] red;
wire [BITS_PER_SYMBOL - 1:0] green;
wire [BITS_PER_SYMBOL - 1:0] blue;
	
// LSBs = blue, MSBs = red (new since 8.1)
assign blue = data_int[BITS_PER_SYMBOL - 1:0];
assign green = data_int[2*BITS_PER_SYMBOL - 1:BITS_PER_SYMBOL];
assign red = data_int[3*BITS_PER_SYMBOL - 1:2*BITS_PER_SYMBOL];

// calculate results
wire [BITS_PER_SYMBOL + 8 - 1:0] grey;
wire [BITS_PER_SYMBOL - 1:0] grey_result;

assign grey = (red_factor * red + green_factor * green + blue_factor * blue);
assign grey_result = grey[BITS_PER_SYMBOL+8 - 1:8];

// assign outputs
reg [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] output_data;  // algorithm output data
reg output_valid;
reg output_end_of_video;

always @(posedge clk or posedge rst)
	if (rst) begin
		output_data <= {(BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1){1'b0}};
		output_valid <= 1'b0;
	  output_end_of_video <= 1'b0;
	end else begin
		output_data <= input_valid ? {grey_result, grey_result, grey_result} : output_data;
		output_valid <= input_valid; // one clock cycle latency in this algorithm
	  output_end_of_video <= input_valid ? data_int[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT] : output_end_of_video;
	end	

/******************************************************************************/
/* End of user algorithm data processing                                      */
/******************************************************************************/

/******************************************************************************/
/* Start of flow control processing                                           */
/******************************************************************************/

// flow control access - algorithm dependent
assign read = ~stall_out; // try to read whenever data can be consumed (written out or buffered internally)
//assign read = ~stall_in | ~stall_out; // try to read whenever data can be consumed (written out or buffered internally)
assign write = ( output_valid | data_available); // write whenever output data valid
	
// only capture data if input valid (not stalled and reading)					
assign input_valid = (read & ~stall_in);
assign data_int = (input_valid) ? {end_of_video, data_in} : data_int_reg;

// hold data if not writing or output stalled, otherwise assign internal data
assign data_out = (output_valid | data_available) ? output_data : data_out_reg[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0];
assign end_of_video_out = (output_valid | data_available) ? output_end_of_video : data_out_reg[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT];

// register internal flow controlled signals	
always @(posedge clk or posedge rst)
	if (rst) begin
		data_int_reg <= {(BITS_PER_SYMBOL * SYMBOLS_PER_BEAT + 1){1'b0}};
		data_out_reg <= {(BITS_PER_SYMBOL * SYMBOLS_PER_BEAT + 1){1'b0}};
		data_available <= 1'b0;
	end
	else begin
		data_int_reg <= data_int;
		data_out_reg[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] <= data_out;
		data_out_reg[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT] <= end_of_video_out;
		data_available <= stall_out & (output_valid | data_available);
	end
			
/******************************************************************************/
/* End of flow control processing                                             */
/******************************************************************************/

assign vip_ctrl_valid_out = vip_ctrl_valid_in;
assign width_out = width_in;
assign height_out = height_in;
assign interlaced_out = interlaced_in;
		 	 	 	
endmodule
		
					
			