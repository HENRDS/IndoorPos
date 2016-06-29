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


// top-level module of user algorithm and wrappers which is instantiated in SOPC Builder
module alt_vip_rgb2grey

	#(parameter BITS_PER_SYMBOL = 8,
		parameter SYMBOLS_PER_BEAT = 3) 
		
	(	input		clk,
		input		rst,
	
		// Avalon-ST sink interface
		output	din_ready,
		input		din_valid,
		input		din_sop,
		input		din_eop,
		input		[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] din_data, 
		
		// Avalon-ST source interface
		input		dout_ready,
		output	dout_valid,
		output	dout_sop,
		output	dout_eop,
		output	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] dout_data);
		
// Avalon Stream Input internal signals
		wire		input_ready;
		wire		input_valid;
		wire		input_sop;
		wire		input_eop;
		wire		[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] input_data;
		
// VIP Avalon Stream Input
alt_vip_common_stream_input
	#(.DATA_WIDTH (BITS_PER_SYMBOL * SYMBOLS_PER_BEAT))
	avalon_st_input
	(	.clk (clk),		
	  .rst (rst),
		.din_ready (din_ready),
		.din_valid (din_valid),
		.din_data (din_data),
		.din_sop (din_sop),
		.din_eop (din_eop),
		.int_ready (input_ready),
		.int_valid (input_valid),
		.int_data (input_data),
		.int_sop (input_sop),
		.int_eop (input_eop));				
						
// VIP_Control_Packet_decoder signals
wire		decoder_ready;
wire 		decoder_valid;
wire 		[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] decoder_data;

wire		[15:0] decoder_width;
wire		[15:0] decoder_height;
wire		[3:0] decoder_interlaced;

wire		decoder_vip_ctrl_valid;
wire		decoder_end_of_video;
wire		decoder_is_video;
						
// VIP_Control_Packet_decoder instantiation		
alt_vip_common_control_packet_decoder
	#(.BITS_PER_SYMBOL (BITS_PER_SYMBOL),
		.SYMBOLS_PER_BEAT (SYMBOLS_PER_BEAT))
	decoder	
	(	.clk (clk),
		.rst (rst),
		// Avalon-ST sink interface
		.din_ready (input_ready),
		.din_valid (input_valid),
		.din_sop (input_sop),
		.din_eop (input_eop),
		.din_data (input_data),
		// interface to user algorithm
		.dout_ready (decoder_ready),
		.dout_valid (decoder_valid),
		.dout_data (decoder_data),
		.width (decoder_width),
		.height (decoder_height),
		.interlaced (decoder_interlaced),
		.is_video (decoder_is_video),
		.end_of_video (decoder_end_of_video),
		.vip_ctrl_valid (decoder_vip_ctrl_valid)
	);
	
// VIP_Control_Packet_encoder signals
wire		encoder_ready;
wire		encoder_valid;
wire		[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] encoder_data;

wire		[15:0] encoder_width;
wire		[15:0] encoder_height;
wire		[3:0] encoder_interlaced;

wire		encoder_vip_ctrl_send;
wire		encoder_vip_ctrl_busy;
wire		encoder_end_of_video;
				
// VIP_Flow_Control and user algorithm signals
wire		[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_in;

wire 		[15:0] width_in;
wire 		[15:0] height_in;
wire 		[3:0] interlaced_in;
wire 		end_of_video;
wire 		vip_ctrl_valid;

wire		[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_out;
						
wire 		[15:0] width_out;
wire 		[15:0] height_out;
wire 		[3:0] interlaced_out;
wire		vip_ctrl_send;
wire		vip_ctrl_busy;
wire		end_of_video_out;

wire		read;
wire		write;
wire		stall_in;
wire		stall_out;
		
// VIP_Flow_Control wrapper instantiation		
alt_vip_common_flow_control_wrapper
	#(.BITS_PER_SYMBOL (BITS_PER_SYMBOL),
		.SYMBOLS_PER_BEAT (SYMBOLS_PER_BEAT))
	flow_control_wrapper
	(	.clk (clk),
		.rst (rst),
		// interface to VIP control packet decoder
		.din_ready (decoder_ready),
		.din_valid (decoder_valid),
		.din_data (decoder_data),
		.decoder_width (decoder_width),
		.decoder_height (decoder_height),
		.decoder_interlaced (decoder_interlaced),
		.decoder_end_of_video (decoder_end_of_video),
		.decoder_is_video (decoder_is_video),
		.decoder_vip_ctrl_valid (decoder_vip_ctrl_valid),
		// interfaces to user algorithm on input and output side
		.stall_in (stall_in),
		.stall_out (stall_out),
		.read (read),
		.write (write),	
		.data_in (data_in),
		.width_in (width_in),
		.height_in (height_in),
		.interlaced_in (interlaced_in),
		.end_of_video_in (end_of_video),
		.vip_ctrl_valid_in (vip_ctrl_valid),
		.data_out (data_out),
		.width_out (width_out),
		.height_out (height_out),
		.interlaced_out (interlaced_out),
		.vip_ctrl_valid_out (vip_ctrl_send),
		.end_of_video_out (end_of_video_out),
		// interface to VIP control packet encoder
		.dout_ready (encoder_ready),
		.dout_valid (encoder_valid),
		.dout_data (encoder_data),
		.encoder_width (encoder_width),
		.encoder_height (encoder_height),
		.encoder_interlaced (encoder_interlaced),
		.encoder_vip_ctrl_send (encoder_vip_ctrl_send),
		.encoder_vip_ctrl_busy (encoder_vip_ctrl_busy),
		.encoder_end_of_video (encoder_end_of_video)
	);

// Avalon Stream Output internal signals
		wire		output_ready;
		wire		output_valid;
		wire		output_sop;
		wire		output_eop;
		wire		[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] output_data;
		
// VIP_Control_Packet_encoder instantiation
alt_vip_common_control_packet_encoder
	#(.BITS_PER_SYMBOL (BITS_PER_SYMBOL),
		.SYMBOLS_PER_BEAT (SYMBOLS_PER_BEAT))
	encoder	
	(	.clk (clk),
		.rst (rst),
		// interface to user algorithm
		.din_ready (encoder_ready),
		.din_valid (encoder_valid),
		.din_data (encoder_data),
		.width (encoder_width),
		.height (encoder_height),
		.interlaced (encoder_interlaced),
		.end_of_video (encoder_end_of_video),
		.vip_ctrl_send (encoder_vip_ctrl_send),
		.vip_ctrl_busy (encoder_vip_ctrl_busy),
		// Avalon-ST source interface
		.dout_ready (output_ready),
		.dout_valid (output_valid),
		.dout_sop (output_sop),
		.dout_eop (output_eop),
		.dout_data (output_data)
	);
	
// VIP Avalon Stream Output
alt_vip_common_stream_output
	#(.DATA_WIDTH (BITS_PER_SYMBOL * SYMBOLS_PER_BEAT))
	avalon_st_output
	(	.clk (clk),
		.rst (rst),
		.dout_ready (dout_ready),
		.dout_valid (dout_valid),
		.dout_data (dout_data),
		.dout_sop (dout_sop),
		.dout_eop (dout_eop),
		.int_ready (output_ready),
		.int_valid (output_valid),
		.int_data (output_data),
		.int_sop (output_sop),
		.int_eop (output_eop),
		.enable (1'b1),
		.synced ());				
							
// algorithm core instantiation - to be replaced by the user
alt_vip_rgb2grey_core
	#(.BITS_PER_SYMBOL (BITS_PER_SYMBOL),
		.SYMBOLS_PER_BEAT (SYMBOLS_PER_BEAT))
	algorithm	
	(	.clk (clk),
		.rst (rst),	
		// flow control signals
		.stall_in (stall_in),
		.stall_out (stall_out),
		.read (read),
		.write (write),
		// algorithm interface to VIP control packet decoder via VIP flow control wrapper
		.data_in (data_in),
		.width_in (width_in),
		.height_in (height_in),
		.interlaced_in (interlaced_in),		
		.end_of_video (end_of_video),		
		.vip_ctrl_valid_in (vip_ctrl_valid),		
		// algorithm interface to VIP control packet encoder via VIP flow control wrapper
		.data_out (data_out),
		.width_out (width_out),
		.height_out (height_out),
		.interlaced_out (interlaced_out),		
		.end_of_video_out (end_of_video_out),		
		.vip_ctrl_valid_out (vip_ctrl_send)
		);

endmodule
		
					
			