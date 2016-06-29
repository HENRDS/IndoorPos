module abs_filter_core
#(
	parameter BITS_PER_SYMBOL = 8,
	parameter SYMBOLS_PER_BEAT = 3 // only 1 symbol used as black/white
)
(	
	input	clk,
	input	rst,
		
	// interface to VIP control packet decoder via VIP flow control wrapper	
	input	stall_in,
	output	read,
	input	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_A_in,
	input	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_B_in,
	input	end_of_video,
		
	input	[15:0] width_in,
	input	[15:0] height_in,
	input	[3:0] interlaced_in,
	input	vip_ctrl_valid_in,
		
	// interface to VIP control packet encoder via VIP flow control wrapper	
	input	stall_out,		
	output	write,
	output	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_out,
	output	end_of_video_out,		
		
	output	[15:0] width_out,
	output	[15:0] height_out,
	output	[3:0] interlaced_out,		
	output	vip_ctrl_valid_out);
		
// internal flow controlled signals				
wire [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT : 0] data_A_int;
wire [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT : 0] data_B_int;
wire input_valid;
reg data_available;
reg [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT : 0] data_A_int_reg;
reg [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT : 0] data_B_int_reg;
reg [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT : 0] data_out_reg;
		
/******************************************************************************/
/* Data processing of user algorithm starts here                              */
/******************************************************************************/

// color components input A data
wire [BITS_PER_SYMBOL - 1:0] red_A;
wire [BITS_PER_SYMBOL - 1:0] green_A;
wire [BITS_PER_SYMBOL - 1:0] blue_A;

wire [BITS_PER_SYMBOL - 1:0] red_B;
wire [BITS_PER_SYMBOL - 1:0] green_B;
wire [BITS_PER_SYMBOL - 1:0] blue_B;

// LSBs = blue, MSBs = red (new since 8.1)
assign blue_A = data_A_int[BITS_PER_SYMBOL - 1:0];
assign green_A = data_A_int[2*BITS_PER_SYMBOL - 1:BITS_PER_SYMBOL];
assign red_A = data_A_int[3*BITS_PER_SYMBOL - 1:2*BITS_PER_SYMBOL];

assign blue_B = data_B_int[BITS_PER_SYMBOL - 1:0];
assign green_B = data_B_int[2*BITS_PER_SYMBOL - 1:BITS_PER_SYMBOL];
assign red_B = data_B_int[3*BITS_PER_SYMBOL - 1:2*BITS_PER_SYMBOL];

// calculate results
wire [BITS_PER_SYMBOL - 1:0] result_B;
wire [BITS_PER_SYMBOL - 1:0] result_G;
wire [BITS_PER_SYMBOL - 1:0] result_R;

assign result_B = (blue_A > blue_B) ? (blue_A - blue_B) : (blue_B - blue_A);
assign result_G = (green_A > green_B) ? (green_A - green_B) : (green_B - green_A); 
assign result_R = (red_A > red_B) ? (red_A - red_B) : (red_B - red_A); 

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
		output_data <= input_valid ? {result_R, result_G, result_B} : output_data;
		output_valid <= input_valid; // one clock cycle latency in this algorithm
	  output_end_of_video <= input_valid ? data_A_int[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT] : output_end_of_video;
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
assign data_A_int = (input_valid) ? {end_of_video, data_A_in} : data_A_int_reg;
assign data_B_int = (input_valid) ? {end_of_video, data_B_in} : data_B_int_reg;

// hold data if not writing or output stalled, otherwise assign internal data
assign data_out = (output_valid | data_available) ? output_data : data_out_reg[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0];
assign end_of_video_out = (output_valid | data_available) ? output_end_of_video : data_out_reg[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT];

// register internal flow controlled signals	
always @(posedge clk or posedge rst)
	if (rst) begin
		data_A_int_reg <= {(BITS_PER_SYMBOL * SYMBOLS_PER_BEAT + 1){1'b0}};
		data_B_int_reg <= {(BITS_PER_SYMBOL * SYMBOLS_PER_BEAT + 1){1'b0}};
		data_out_reg <= {(BITS_PER_SYMBOL * SYMBOLS_PER_BEAT + 1){1'b0}};
		data_available <= 1'b0;
	end
	else begin
		data_A_int_reg <= data_A_int;
		data_B_int_reg <= data_B_int;
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