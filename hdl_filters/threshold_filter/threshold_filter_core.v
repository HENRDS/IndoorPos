module threshold_filter_core

	#(parameter BITS_PER_SYMBOL = 8,
		parameter SYMBOLS_PER_BEAT = 3, // only 1 symbol used as black/white
		parameter THRESHOLD_VALUE = 50
		)
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

// color components input data
wire [BITS_PER_SYMBOL - 1:0] pixel;
	
// LSBs = blue, MSBs = red (new since 8.1)
assign pixel = data_int[3*BITS_PER_SYMBOL - 1:2*BITS_PER_SYMBOL];

// calculate results
wire [BITS_PER_SYMBOL - 1:0] result;

assign result = (pixel > THRESHOLD_VALUE) ? 255 : 0;

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
		output_data <= input_valid ? {result, result, result} : output_data;
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
		
					
			