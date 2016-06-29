//TOP LEVEL MODULE
module abs_filter
#(
	parameter BITS_PER_SYMBOL = 8,
	parameter SYMBOLS_PER_BEAT = 3
) 		
(	
	input	clk,
	input	reset,
	
	// Avalon-ST sink interface A
	output	asi_dinA_ready,
	input	asi_dinA_valid,
	input	asi_dinA_startofpacket,
	input	asi_dinA_endofpacket,
	input	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] asi_dinA_data,

	// Avalos-ST sink interface B
	output	asi_dinB_ready,
	input	asi_dinB_valid,
	input	asi_dinB_startofpacket,
	input	asi_dinB_endofpacket,
	input	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] asi_dinB_data, 
		
	// Avalon-ST source interface
	input	aso_dout_ready,
	output	aso_dout_valid,
	output	aso_dout_startofpacket,
	output	aso_dout_endofpacket,
	output	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] aso_dout_data
);
		
// Avalon Stream Input A internal signals
wire	input_A_ready;
wire	input_A_valid;
wire	input_A_sop;
wire	input_A_eop;
wire	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] input_A_data;
		
// VIP Avalon Stream Input
alt_vip_common_stream_input
	#(
		.DATA_WIDTH (BITS_PER_SYMBOL * SYMBOLS_PER_BEAT)
	)
	avalon_st_input_A
	(	
		.clk (clk),
		.rst (reset),
		.din_ready (asi_dinA_ready),
		.din_valid (asi_dinA_valid),
		.din_data (asi_dinA_data),
		.din_sop (asi_dinA_startofpacket),
		.din_eop (asi_dinA_endofpacket),
		.int_ready (input_A_ready),
		.int_valid (input_A_valid),
		.int_data (input_A_data),
		.int_sop (input_A_sop),
		.int_eop (input_A_eop)
	);

// Avalon Stream Input B internal signals
wire	input_B_ready;
wire	input_B_valid;
wire	input_B_sop;
wire	input_B_eop;
wire	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] input_B_data;

alt_vip_common_stream_input
	#(
		.DATA_WIDTH (BITS_PER_SYMBOL * SYMBOLS_PER_BEAT)
	)
	avalon_st_input_B
	(	
		.clk (clk),
		.rst (reset),
		.din_ready (asi_dinB_ready),
		.din_valid (asi_dinB_valid),
		.din_data (asi_dinB_data),
		.din_sop (asi_dinB_startofpacket),
		.din_eop (asi_dinB_endofpacket),
		.int_ready (input_B_ready),
		.int_valid (input_B_valid),
		.int_data (input_B_data),
		.int_sop (input_B_sop),
		.int_eop (input_B_eop)
	);			
						
// VIP_Control_Packet_decoder A signals
wire	decoder_A_ready;
wire	decoder_A_valid;
wire	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] decoder_A_data;
wire	[15:0] decoder_A_width;
wire	[15:0] decoder_A_height;
wire	[3:0] decoder_A_interlaced;
wire	decoder_A_vip_ctrl_valid;
wire	decoder_A_end_of_video;
wire	decoder_A_is_video;
						
// VIP_Control_Packet_decoder instantiation		
alt_vip_common_control_packet_decoder
	#(
		.BITS_PER_SYMBOL (BITS_PER_SYMBOL),
		.SYMBOLS_PER_BEAT (SYMBOLS_PER_BEAT)
	)
	decoder_A	
	(	
		.clk (clk),
		.rst (reset),
		// Avalon-ST sink interface
		.din_ready (input_A_ready),
		.din_valid (input_A_valid),
		.din_sop (input_A_sop),
		.din_eop (input_A_eop),
		.din_data (input_A_data),
		// interface to user algorithm
		.dout_ready (decoder_A_ready),
		.dout_valid (decoder_A_valid),
		.dout_data (decoder_A_data),
		.width (decoder_A_width),
		.height (decoder_A_height),
		.interlaced (decoder_A_interlaced),
		.is_video (decoder_A_is_video),
		.end_of_video (decoder_A_end_of_video),
		.vip_ctrl_valid (decoder_A_vip_ctrl_valid)
	);

// VIP_Control_Packet_decoder A signals
wire	decoder_B_ready;
wire	decoder_B_valid;
wire	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] decoder_B_data;
wire	[15:0] decoder_B_width;
wire	[15:0] decoder_B_height;
wire	[3:0] decoder_B_interlaced;
wire	decoder_B_vip_ctrl_valid;
wire	decoder_B_end_of_video;
wire	decoder_B_is_video;
						
// VIP_Control_Packet_decoder instantiation		
alt_vip_common_control_packet_decoder
	#(
		.BITS_PER_SYMBOL (BITS_PER_SYMBOL),
		.SYMBOLS_PER_BEAT (SYMBOLS_PER_BEAT)
	)
	decoder_B	
	(	
		.clk (clk),
		.rst (reset),
		// Avalon-ST sink interface
		.din_ready (input_B_ready),
		.din_valid (input_B_valid),
		.din_sop (input_B_sop),
		.din_eop (input_B_eop),
		.din_data (input_B_data),
		// interface to user algorithm
		.dout_ready (decoder_B_ready),
		.dout_valid (decoder_B_valid),
		.dout_data (decoder_B_data),
		.width (decoder_B_width),
		.height (decoder_B_height),
		.interlaced (decoder_B_interlaced),
		.is_video (decoder_B_is_video),
		.end_of_video (decoder_B_end_of_video),
		.vip_ctrl_valid (decoder_B_vip_ctrl_valid)
	);
	
// VIP_Control_Packet_encoder signals
wire	encoder_ready;
wire	encoder_valid;
wire	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] encoder_data;

wire	[15:0] encoder_width;
wire	[15:0] encoder_height;
wire	[3:0] encoder_interlaced;

wire	encoder_vip_ctrl_send;
wire	encoder_vip_ctrl_busy;
wire	encoder_end_of_video;
				
// VIP_Flow_Control and user algorithm signals
wire	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_A_in;
wire	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_B_in;

wire 	[15:0] width_in;
wire 	[15:0] height_in;
wire 	[3:0] interlaced_in;
wire 	end_of_video;
wire 	vip_ctrl_valid;

wire	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data_out;
						
wire 	[15:0] width_out;
wire 	[15:0] height_out;
wire 	[3:0] interlaced_out;
wire	vip_ctrl_send;
wire	vip_ctrl_busy;
wire	end_of_video_out;

wire	read;
wire	write;
wire	stall_in;
wire	stall_out;
		
// VIP_Flow_Control wrapper instantiation		
vip_two_inputs_flow_control_wrapper
	#(
		.BITS_PER_SYMBOL (BITS_PER_SYMBOL),
		.SYMBOLS_PER_BEAT (SYMBOLS_PER_BEAT)
	)
	flow_control_wrapper
	(	
		.clk (clk),
		.rst (reset),
		// interface to VIP control packet decoder A
		.din_A_ready (decoder_A_ready),
		.din_A_valid (decoder_A_valid),
		.din_A_data (decoder_A_data),
		.decoder_A_width (decoder_A_width),
		.decoder_A_height (decoder_A_height),
		.decoder_A_interlaced (decoder_A_interlaced),
		.decoder_A_end_of_video (decoder_A_end_of_video),
		.decoder_A_is_video (decoder_A_is_video),
		.decoder_A_vip_ctrl_valid (decoder_A_vip_ctrl_valid),
		// interface to VIP control packet decoder B
		.din_B_ready (decoder_B_ready),
		.din_B_valid (decoder_B_valid),
		.din_B_data (decoder_B_data),
		.decoder_B_width (decoder_B_width),
		.decoder_B_height (decoder_B_height),
		.decoder_B_interlaced (decoder_B_interlaced),
		.decoder_B_end_of_video (decoder_B_end_of_video),
		.decoder_B_is_video (decoder_B_is_video),
		.decoder_B_vip_ctrl_valid (decoder_B_vip_ctrl_valid),
		// interfaces to user algorithm on input and output side
		.stall_in (stall_in),
		.stall_out (stall_out),
		.read (read),
		.write (write),	
		.data_A_in (data_A_in),
		.data_B_in (data_B_in),
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
wire	output_ready;
wire	output_valid;
wire	output_sop;
wire	output_eop;
wire	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] output_data;
		
// VIP_Control_Packet_encoder instantiation
alt_vip_common_control_packet_encoder
	#(
		.BITS_PER_SYMBOL (BITS_PER_SYMBOL),
		.SYMBOLS_PER_BEAT (SYMBOLS_PER_BEAT)
	)
	encoder	
	(	
		.clk (clk),
		.rst (reset),
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
	#(
		.DATA_WIDTH (BITS_PER_SYMBOL * SYMBOLS_PER_BEAT)
	)
	avalon_st_output
	(	
		.clk (clk),
		.rst (reset),
		.dout_ready (aso_dout_ready),
		.dout_valid (aso_dout_valid),
		.dout_data (aso_dout_data),
		.dout_sop (aso_dout_startofpacket),
		.dout_eop (aso_dout_endofpacket),
		.int_ready (output_ready),
		.int_valid (output_valid),
		.int_data (output_data),
		.int_sop (output_sop),
		.int_eop (output_eop),
		.enable (1'b1),
		.synced ()
	);				
							
// algorithm core instantiation - to be replaced by the user
abs_filter_core
	#(
		.BITS_PER_SYMBOL (BITS_PER_SYMBOL),
		.SYMBOLS_PER_BEAT (SYMBOLS_PER_BEAT)
	)
	algorithm	
	(	
		.clk (clk),
		.rst (reset),	
		// flow control signals
		.stall_in (stall_in),
		.stall_out (stall_out),
		.read (read),
		.write (write),
		// algorithm interface to VIP control packet decoder via VIP flow control wrapper
		.data_A_in (data_A_in),
		.data_B_in (data_B_in),
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
		
					
			