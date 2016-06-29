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


/* VIP Control Packet Encoder for HDL template */
module alt_vip_common_control_packet_encoder

	#(parameter BITS_PER_SYMBOL = 8,
		parameter SYMBOLS_PER_BEAT = 3)
		
	(	input		clk,
		input		rst,
	
		// Avalon-ST sink interface (internal - from user algorithm)
		output	din_ready,
		input		din_valid,
		input		[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] din_data, // only video data
		
		// Avalon-ST source interface (external)
		input		dout_ready,
		output	dout_valid,
		output	dout_sop,
		output	dout_eop,
		output	[BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] dout_data,
		
		// encoder control signals
		input 	end_of_video,		
		input		[15:0] width,
		input		[15:0] height,
		input		[3:0] interlaced,
		input		vip_ctrl_send,
	 	output  reg vip_ctrl_busy);
		
// FSM states
localparam [3:0] IDLE            = 4'd15;
localparam [3:0] WAITING         = 4'd14;
localparam [3:0] WIDTH_3         = 4'd0;
localparam [3:0] WIDTH_2         = 4'd1;
localparam [3:0] WIDTH_1         = 4'd2;
localparam [3:0] WIDTH_0         = 4'd3;
localparam [3:0] HEIGHT_3        = 4'd4;
localparam [3:0] HEIGHT_2        = 4'd5;
localparam [3:0] HEIGHT_1        = 4'd6;
localparam [3:0] HEIGHT_0        = 4'd7;
localparam [3:0] INTERLACING     = 4'd8;
localparam [3:0] DUMMY_STATE     = 4'd9;
localparam [3:0] DUMMY_STATE2    = 4'd10;
localparam [3:0] WAIT_FOR_END    = 4'd11;

localparam PACKET_LENGTH = 10;

// internal signals
reg [3:0] state;

wire sop;
wire eop;
wire [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] data;
//reg control_valid;
wire control_valid;

reg end_of_video_valid;

reg write_control;

reg [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT * (PACKET_LENGTH - 1) - 1 : 0] control_data;
wire [3:0] control_header_state [PACKET_LENGTH - 2: 0];
wire [BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 1:0] control_header_data [(PACKET_LENGTH-2) : 0];

// register control data when vip_ctrl_send is high
always @(posedge clk or posedge rst)
	if (rst) begin
		control_data <= {(BITS_PER_SYMBOL * SYMBOLS_PER_BEAT * (PACKET_LENGTH - 1)){1'b0}};
	end
	else if (vip_ctrl_send) begin
		control_data [3: 0] <= width [15:12]; // w3
		control_data [BITS_PER_SYMBOL + 3: BITS_PER_SYMBOL] <= width [11:8]; // w2
		control_data [2 * BITS_PER_SYMBOL + 3: 2 * BITS_PER_SYMBOL] <= width [7:4]; // w1
		control_data [3 * BITS_PER_SYMBOL + 3: 3 * BITS_PER_SYMBOL] <= width [3:0]; // w0
		control_data [4 * BITS_PER_SYMBOL + 3: 4 * BITS_PER_SYMBOL] <= height[15:12]; // h3
		control_data [5 * BITS_PER_SYMBOL + 3: 5 * BITS_PER_SYMBOL] <= height [11:8]; // h2
		control_data [6 * BITS_PER_SYMBOL + 3: 6 * BITS_PER_SYMBOL] <= height [7:4]; // h1
		control_data [7 * BITS_PER_SYMBOL + 3: 7 * BITS_PER_SYMBOL] <= height [3:0]; // h0
		control_data [8 * BITS_PER_SYMBOL + 3: 8 * BITS_PER_SYMBOL] <= interlaced; // int
	end	

generate
	begin : generate_control_header
  	genvar symbol;
    for(symbol = 0; symbol < PACKET_LENGTH - 1; symbol = symbol + SYMBOLS_PER_BEAT) begin : control_header_states
			assign control_header_state [symbol] = symbol + SYMBOLS_PER_BEAT;
			assign control_header_data [symbol] = control_data [((symbol + SYMBOLS_PER_BEAT) * BITS_PER_SYMBOL - 1) : (symbol * BITS_PER_SYMBOL)];
		end
	end
endgenerate

// Finite State Machine to insert encoded VIP control packets into data stream
always @(posedge clk or posedge rst)
	if (rst) begin
		state <= IDLE;
		end_of_video_valid <= 1'b0;
		write_control <= 1'b1;
		vip_ctrl_busy <= 1'b0;
	end
	else begin
		end_of_video_valid <= din_valid & din_ready & end_of_video;
		vip_ctrl_busy <= (state == IDLE) ? vip_ctrl_send :	(state == WAIT_FOR_END) ? ~(din_valid & din_ready & end_of_video) : 1'b1;
		case (state)
			
			IDLE :	begin // wait for vip_ctrl_send
				state <= vip_ctrl_send ? (~dout_ready) ? WAITING : WIDTH_3 : IDLE;
				write_control <= vip_ctrl_send | write_control;
			end
			
			WAITING :	begin // wait for current video frame to finish
				state 			<= (dout_ready) ? WIDTH_3 : WAITING;
				write_control <= 1'b1;
			end
			
			WIDTH_3				: begin 
				state				<= dout_ready ? control_header_state [0] : WIDTH_3;
				write_control <= 1'b1;
			end
			
			WIDTH_2				: begin 
				state				<= dout_ready ? control_header_state [1] : WIDTH_2;
				write_control <= 1'b1;
			end
			
			WIDTH_1				: begin 
				state				<= dout_ready ? control_header_state [2] : WIDTH_1;
				write_control <= 1'b1;
			end
			
			WIDTH_0				: begin 
				state				<= dout_ready ? control_header_state [3] : WIDTH_0;
				write_control <= 1'b1;
			end
			
			HEIGHT_3			: begin 
				state				<= dout_ready ? control_header_state [4] : HEIGHT_3;
				write_control <= 1'b1;
			end
			
			HEIGHT_2			: begin 
				state				<= dout_ready ? control_header_state [5] : HEIGHT_2;
				write_control <= 1'b1;
			end
			
			HEIGHT_1			: begin 
				state				<= dout_ready ? control_header_state [6] : HEIGHT_1;
				write_control <= 1'b1;
			end
			
			HEIGHT_0			: begin 
				state				<= dout_ready ? control_header_state [7] : HEIGHT_0;
				write_control <= 1'b1;
			end
			
			INTERLACING		: begin 
				state				<= dout_ready ? control_header_state [8] : INTERLACING;
				write_control <= 1'b1;
			end
			
			DUMMY_STATE		: begin 
				state 			<= dout_ready ? WAIT_FOR_END : DUMMY_STATE;
				write_control <= 1'b1;
			end
			
			DUMMY_STATE2	: begin 
				state 			<= dout_ready ? WAIT_FOR_END : DUMMY_STATE2;
				write_control <= 1'b1;
			end
			
			WAIT_FOR_END	: begin // wait for current video packet to end before accepting another vip_ctrl_send
				state <= (din_valid & din_ready & end_of_video) ? IDLE : WAIT_FOR_END;
				write_control <= 1'b0;
			end
		endcase
	end	
	
assign control_valid = (state == IDLE) ? (vip_ctrl_send & dout_ready) :
											 (state == WAIT_FOR_END) ? 1'b0 : dout_ready;
assign data = (state == IDLE) ? {{(BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 4) {1'b0}}, 4'hf} :
							(state == WAITING) ? {{(BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 4) {1'b0}}, 4'hf} :
							(state == WIDTH_3) ? control_header_data [0] :
							(state == WIDTH_2) ? control_header_data [1] :
							(state == WIDTH_1) ? control_header_data [2] :
							(state == WIDTH_0) ? control_header_data [3] :
							(state == HEIGHT_3) ? control_header_data [4] :
							(state == HEIGHT_2) ? control_header_data [5] :
							(state == HEIGHT_1) ? control_header_data [6] :
							(state == HEIGHT_0) ? control_header_data [7] :
							(state == INTERLACING) ? control_header_data [8] :
							(state == DUMMY_STATE) ? {{(BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 4) {1'b0}}, 4'h0} :
							(state == DUMMY_STATE2) ? {{(BITS_PER_SYMBOL * SYMBOLS_PER_BEAT - 4) {1'b0}}, 4'h0} : din_data;
assign sop = ((state == IDLE) || (state == WAITING) || (state == DUMMY_STATE) || (state == DUMMY_STATE2)) ? 1'b1 : 1'b0;
assign eop = (state <= INTERLACING) ? (state == ((PACKET_LENGTH-2)/SYMBOLS_PER_BEAT * SYMBOLS_PER_BEAT)) : 1'b0;						
				
// combinatorial assignments of Avalon-ST signals	
assign din_ready = ~(vip_ctrl_send | write_control) & dout_ready;
assign dout_valid = control_valid ? 1'b1 : din_valid & din_ready;
assign dout_data = control_valid ? data : din_data;
assign dout_sop = control_valid & sop;
assign dout_eop = control_valid ? eop : end_of_video & din_valid & din_ready;
	
endmodule
		
					
			