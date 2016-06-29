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


/* VIP Control Packet Decoder for HDL template */
module alt_vip_common_control_packet_decoder

	#(parameter BITS_PER_SYMBOL = 8,
		parameter SYMBOLS_PER_BEAT = 3)
		
	(	input		clk,
		input		rst,
			
		// Avalon-ST sink interface (external)
		output	din_ready,
		input		din_valid,
		input		din_sop,
		input		din_eop,
		input		[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] din_data,
		
		// Avalon-ST source interface (internal - to user algorithm)
		input		dout_ready,
		output	dout_valid,
		output	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] dout_data,
		
		// decoded signals
		output	end_of_video,      // high during last active video pixel in video packet
		output  is_video,          // high during active video pixels in video packet
		output	[15:0] width,      // width of video field
		output	[15:0] height,     // heigth of video field
		output	[3:0] interlaced,	 // interlaced flags 	
		output	vip_ctrl_valid);   // high when width, height and interlaced are valid for next video packet
		
// Number of register stages depends on parameter #SYMBOLS_PER_BEAT (1, 2, 3, or 4)
localparam PACKET_LENGTH = 10;
localparam VALID_LATENCY = 	(SYMBOLS_PER_BEAT == 1) ? 10 : 
							(SYMBOLS_PER_BEAT == 2) ? 6 : 4;

// internal signals
reg [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT+1:0] register [(PACKET_LENGTH-2)/SYMBOLS_PER_BEAT:0]; //{sop, eop, data}
reg [15:0] width_reg;
reg [15:0] height_reg;
reg [3:0] interlaced_reg;
wire [15:0] width_out;
wire [15:0] height_out;
wire [3:0] interlaced_out;
reg is_video_reg;
reg vip_ctrl_valid_reg;
wire start_control_packet;

generate begin : generate_registers
	genvar i;
	for (i = 0; i <= (PACKET_LENGTH-2)/SYMBOLS_PER_BEAT; i = i + 1) begin : init_registers
	
		always @(posedge clk or posedge rst)
			if (rst) begin
				register [i] <= {(BITS_PER_SYMBOL * SYMBOLS_PER_BEAT + 2){1'b0}};
			end
			else begin
				register [i] <= (din_valid & din_ready) ? (i>0) ? register [i-1] : {din_sop, din_eop, din_data} : register [i];
			end
	end
end
endgenerate
		
// Extract control parameters from registers depending on #SYMBOLS_PER_BEAT (only 1, 2, 3, 4 possible)			
generate
	if (SYMBOLS_PER_BEAT == 1) begin // color planes in series
		assign start_control_packet = ((register [8] [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT+1] == 1'b1) && (register [8] [3:0] == 4'hF));
		assign width_out = start_control_packet ? {register [7] [3:0], register [6] [3:0], register [5] [3:0], register [4] [3:0]} : width_reg;
		assign height_out = start_control_packet ? {register [3] [3:0], register [2] [3:0], register [1] [3:0], register [0] [3:0]} : height_reg;
		assign interlaced_out = start_control_packet ? din_data [3:0] : interlaced_reg;
	end
	else if (SYMBOLS_PER_BEAT == 2) begin // two color planes in parallel, e.g. Y and C
		assign start_control_packet = ((register [4] [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT+1] == 1'b1) && (register [4] [3:0] == 4'hF));
		assign width_out = start_control_packet ? {register [3] [3:0], register [3] [BITS_PER_SYMBOL+3:BITS_PER_SYMBOL], register [2] [3:0], register [2] [BITS_PER_SYMBOL+3:BITS_PER_SYMBOL]} : width_reg;
		assign height_out = start_control_packet ? {register [1] [3:0], register [1] [BITS_PER_SYMBOL+3:BITS_PER_SYMBOL], register [0] [3:0], register [0] [BITS_PER_SYMBOL+3:BITS_PER_SYMBOL]} : height_reg;
		assign interlaced_out = start_control_packet ? din_data [3:0] : interlaced_reg;
	end
	else if (SYMBOLS_PER_BEAT == 3) begin // three color planes in parallel, e.g. R, G, B
		assign start_control_packet = ((register [2] [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT+1] == 1'b1) && (register [2] [3:0] == 4'hF)); 
		assign width_out = start_control_packet ? {register [1] [3:0], register [1] [BITS_PER_SYMBOL+3:BITS_PER_SYMBOL], register [1] [2*BITS_PER_SYMBOL+3:2*BITS_PER_SYMBOL], register [0] [3:0]} : width_reg;
		assign height_out = start_control_packet ? {register [0] [BITS_PER_SYMBOL+3:BITS_PER_SYMBOL], register [0] [2*BITS_PER_SYMBOL+3:2*BITS_PER_SYMBOL], din_data [3:0], din_data [BITS_PER_SYMBOL+3:BITS_PER_SYMBOL]} : height_reg;
		assign interlaced_out = start_control_packet ? din_data [2*BITS_PER_SYMBOL+3:2*BITS_PER_SYMBOL] : interlaced_reg;
	end
	else if (SYMBOLS_PER_BEAT == 4) begin // four color planes in parallel, e.g. R, G, B, alpha
		assign start_control_packet = ((register [2] [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT+1] == 1'b1) && (register [2] [3:0] == 4'hF)); 
		assign width_out = start_control_packet ? {register [1] [3:0], register [1] [BITS_PER_SYMBOL+3:BITS_PER_SYMBOL], register [1] [2*BITS_PER_SYMBOL+3:2*BITS_PER_SYMBOL],  register [1] [3*BITS_PER_SYMBOL+3:3*BITS_PER_SYMBOL]} : width_reg;
		assign height_out = start_control_packet ? {register [0] [3:0], register [0] [BITS_PER_SYMBOL+3:BITS_PER_SYMBOL], register [0] [2*BITS_PER_SYMBOL+3:2*BITS_PER_SYMBOL],  register [0] [3*BITS_PER_SYMBOL+3:3*BITS_PER_SYMBOL]} : height_reg;
		assign interlaced_out = start_control_packet ? din_data [3:0] : interlaced_reg;
	end
endgenerate
	
always @(posedge clk or posedge rst)
	if (rst) begin
		is_video_reg <= 1'b0;
		vip_ctrl_valid_reg <= 1'b0;
	end
	else begin
		if (din_valid && din_ready && din_sop && (din_data [3:0] == 4'h0)) begin // video frame packet start
			vip_ctrl_valid_reg <= 1'b1;
			is_video_reg <= 1'b1;
		end
		else if (din_valid && din_eop && din_ready) begin // end of packet
			is_video_reg <= 1'b0; 
		end
		if (vip_ctrl_valid_reg) begin
			vip_ctrl_valid_reg <= 1'b0;
		end
	end
										
// register internal signals						
always @(posedge clk or posedge rst)
	if (rst) begin
		width_reg <= 16'd640;
		height_reg <= 16'd480;
		interlaced_reg <= 4'd0;
	end
	else begin
		width_reg <= width_out;
		height_reg <= height_out;
		interlaced_reg <= interlaced_out;
	end

// assign output control signals			
assign width = width_reg;
assign height = height_reg;
assign interlaced = interlaced_reg;
assign vip_ctrl_valid = vip_ctrl_valid_reg;

assign end_of_video = din_eop & is_video_reg; // eop of video frame
assign is_video = is_video_reg;	// active video
		
// feed through Avalon-ST signals
assign din_ready = dout_ready;
assign dout_valid = din_valid & din_ready;
assign dout_data = din_data;

endmodule
		
					
			