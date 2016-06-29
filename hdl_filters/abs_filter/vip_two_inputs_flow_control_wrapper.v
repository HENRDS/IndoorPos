/* VIP flow control wrapper of HDL template */
module vip_two_inputs_flow_control_wrapper
#(
	parameter BITS_PER_SYMBOL = 8,
	parameter SYMBOLS_PER_BEAT = 3
)
(	
	input	clk,
	input	rst,
	
	// interface to decoder A
	output	din_A_ready,
	input	din_A_valid,
	input	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] din_A_data,
	input	[15:0] decoder_A_width,
	input	[15:0] decoder_A_height,
	input	[3:0] decoder_A_interlaced,
	input	decoder_A_end_of_video,
	input	decoder_A_is_video,
	input	decoder_A_vip_ctrl_valid,

	// interface to decoder B
	output	din_B_ready,
	input	din_B_valid,
	input	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] din_B_data,
	input	[15:0] decoder_B_width,
	input	[15:0] decoder_B_height,
	input	[3:0] decoder_B_interlaced,
	input	decoder_B_end_of_video,
	input	decoder_B_is_video,
	input	decoder_B_vip_ctrl_valid,
	
	// algorithm inputs from decoder
	output	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_A_in,
	output	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_B_in,
	output	[15:0] width_in,
	output	[15:0] height_in,
	output	[3:0] interlaced_in,
	output	end_of_video_in,
	output	vip_ctrl_valid_in,
	
	// algorithm outputs to encoder
	input	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_out,
	input	[15:0] width_out,
	input	[15:0] height_out,
	input	[3:0] interlaced_out,
	input	vip_ctrl_valid_out,
	input	end_of_video_out,
	
	// interface to encoder
	input	dout_ready,
	output	dout_valid,
	output	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] dout_data,
	output	[15:0] encoder_width,
	output	[15:0] encoder_height,
	output	[3:0] encoder_interlaced,
	output	encoder_vip_ctrl_send,
	input	encoder_vip_ctrl_busy,
	output	encoder_end_of_video,

	// flow control signals
	input	read,
	input	write,
	output	stall_in,
	output	stall_out
	);

// conversion ready/valid to stall/read interface and filtering of active video		
assign data_A_in = din_A_data;
assign data_B_in = din_B_data;

assign end_of_video_in = decoder_A_end_of_video;

assign din_A_ready = ~decoder_A_is_video | read;
assign din_B_ready = ~decoder_B_is_video | read;

assign stall_in = ~(din_A_valid & decoder_A_is_video & din_B_valid & decoder_B_is_video);
		
// conversion stall/write to ready/valid interface
assign dout_data = data_out;
assign encoder_end_of_video = end_of_video_out;
assign dout_valid = write;
assign stall_out = ~dout_ready;

// decoder control signals
assign width_in = decoder_A_width;
assign height_in = decoder_A_height;
assign interlaced_in = decoder_A_interlaced;
assign vip_ctrl_valid_in = decoder_A_vip_ctrl_valid;

reg [15:0] width_reg, height_reg;
reg [3:0] interlaced_reg;
reg vip_ctrl_valid_reg;
wire vip_ctrl_send_internal;

// encoder control signals
assign encoder_vip_ctrl_send = (vip_ctrl_valid_reg || vip_ctrl_valid_out) & ~encoder_vip_ctrl_busy;
assign encoder_width = vip_ctrl_valid_out ? width_out : width_reg;
assign encoder_height = vip_ctrl_valid_out ? height_out : height_reg;
assign encoder_interlaced = vip_ctrl_valid_out ? interlaced_out : interlaced_reg;

// connect control signals	
always @(posedge clk or posedge rst)
	if (rst) begin
		width_reg <= 16'd640;
		height_reg <= 16'd480;
		interlaced_reg <= 4'd0;
		vip_ctrl_valid_reg <= 1'b0;
	end
	else begin
		width_reg <= encoder_width;
		height_reg <= encoder_height;
		interlaced_reg <= encoder_interlaced;
		if (vip_ctrl_valid_out || !encoder_vip_ctrl_busy) begin
		   vip_ctrl_valid_reg <= vip_ctrl_valid_out && encoder_vip_ctrl_busy;
		end
	end	
	
endmodule
		
					
			