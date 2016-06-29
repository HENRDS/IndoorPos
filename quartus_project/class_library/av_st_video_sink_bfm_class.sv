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


//  The following must be defined before including this class :
// `SINK
// `SINK_HIERARCHY_NAME
// `BITS_PER_CHANNEL
// `CHANNELS_PER_PIXEL

`define CLASSNAME c_av_st_video_sink_bfm_`SINK

class `CLASSNAME extends c_av_st_video_source_sink_base;

t_packet_types current_video_item_type =   undefined;


// The constructor 'connects' the output mailbox to the object's mailbox :
function new(mailbox #(c_av_st_video_item) m_vid);
    super.new(m_vid);
endfunction

task start;

    wait (`SINK_HIERARCHY_NAME.reset == 0)
    receive_video;

endtask

task receive_video;

    // Local objects :
    c_av_st_video_item                                                       item_data;
    c_av_st_video_data        #(`BITS_PER_CHANNEL,  `CHANNELS_PER_PIXEL)    video_data;
    c_av_st_video_control     #(`BITS_PER_CHANNEL,  `CHANNELS_PER_PIXEL) video_control;
    c_av_st_video_user_packet #(`BITS_PER_CHANNEL,  `CHANNELS_PER_PIXEL)     user_data;
    c_pixel                   #(`BITS_PER_CHANNEL,  `CHANNELS_PER_PIXEL)    pixel_data;
    
    bit                    [`BITS_PER_CHANNEL * `CHANNELS_PER_PIXEL-1:0]          data;
    bit                    [`BITS_PER_CHANNEL -1:                     0]  channel_data;
    
    bit    [3 :0]    nibble_stack[$];
    bit    [3:0]        nibble = 'h0;
    bit    [15:0]       height = 'h0;
    bit    [15:0]        width = 'h0;
    bit    [3 :0]  interlacing = 'h0;    
    int        control_data_id =   0;
    int control_packet_garbage =   0;
    bit               eop_seen =   0;
    int                channel =   0;
    int                     nw =   0; // Warning prevention
    
    fork
    
    forever
    begin
  	@(posedge clk);
        if ($urandom_range(100000, 0) < (long_delay_probability*1000))
        begin
             nw = randomize(long_delay_duration);
            `SINK_HIERARCHY_NAME.set_ready(1'b0);
            repeat(long_delay_duration) @(posedge clk);                
            `SINK_HIERARCHY_NAME.set_ready(1'b1); 
        end
        else if ($urandom_range(100, 0) > readiness_probability) 
            `SINK_HIERARCHY_NAME.set_ready(1'b0);
        else
            `SINK_HIERARCHY_NAME.set_ready(1'b1); 
    end
   
    forever
    begin

        // Constructors :
        video_data             = new();
        user_data              = new();
        video_control          = new();    
        pixel_data             = new();
        control_data_id        =     0;
        control_packet_garbage =     0;
        eop_seen               =  1'b1;
        channel                =     0;
        
        do
        begin
            // Wait until we get a transaction
            @(`SINK_HIERARCHY_NAME.signal_transaction_received);

            // get the new transaction from the model
            `SINK_HIERARCHY_NAME.pop_transaction();

            // Pop the raw data from the Av-ST bus :
            data = `SINK_HIERARCHY_NAME.get_transaction_data();

            // The first beat of data is just used to identify the packet type :
            if (`SINK_HIERARCHY_NAME.get_transaction_sop() == 1'b1)
            begin            
                 
                if (!eop_seen)
                    $display("%t WARNING : %s missing an EOP from the previous packet.\n",$time,name); 
                           
                casez (data[3:0])
                    4'h0    : current_video_item_type = video_packet;
                    4'hf    : current_video_item_type = control_packet;  
                    default : current_video_item_type = user_packet;
                endcase
                
                nibble_stack = {}; // Empty the nibble stack
                $display("%t %s is processing a %s.",$time,name,display_video_item_type(current_video_item_type));                
               
                eop_seen = 1'b0;                            
                
            end
            
            // Subsequent beats are decoded according to type :
            else if (current_video_item_type == video_packet)
            begin
                            
                // Pack it into a pixel object :
                if (pixel_transport == parallel)
                begin
                    for (channel=0; channel<`CHANNELS_PER_PIXEL; pixel_data.set_data(channel++, channel_data) )        
                        for (int pixel_bit=0; pixel_bit<`BITS_PER_CHANNEL; pixel_bit++)
                            channel_data[pixel_bit] = data[channel*`BITS_PER_CHANNEL+pixel_bit];
                end
                
                else
                begin
                    pixel_data.set_data(channel, data);
                end
                     
                // If we have enough data, push the pixel into the video packet
                if ( channel == (`CHANNELS_PER_PIXEL - (pixel_transport == serial)) )
                begin
                    //$display("Sink BFM assembling vide packet. Pushed %0h %0h %0h to front of packet",pixel_data.get_data(2),pixel_data.get_data(1),pixel_data.get_data(0));
                    video_data.push_pixel(pixel_data);
                    channel = 0;
                    pixel_data = new();
                end
                else
                begin
                    channel = channel + 'h1;               
                end
                
                //$display("%t Sink pushed video pixel ch2=%h ch1=%h ch0=%h, length now %d",$time, pixel_data.get_data(2),pixel_data.get_data(1),pixel_data.get_data(0),video_data.get_length());
                
            end else if (current_video_item_type == user_packet)
            begin
                user_data.push_data(data);
                //$display("Sink pushed user data, now length %d",user_data.get_length());
                
            end else if (current_video_item_type == control_packet)
            begin
                
                // Non-garbage beat:                           
                if (control_data_id < 3)
                begin
                
                    for (channel=0; channel < ((pixel_transport == serial) ? 1 : `CHANNELS_PER_PIXEL); channel++ )        
                    begin

                        //$display("Sink - control packet data received of %h for channel %h",data,channel);

                        // Construct a nibble from the bus data :
                        for (int nibble_bit=0; nibble_bit<4; nibble_bit++)
                            nibble[nibble_bit] = data[ (channel*`BITS_PER_CHANNEL) + nibble_bit];

                        // Push the nibble onto nibble_stack :
                        nibble_stack.push_front(nibble);
                        //$display("Sink - pushed first nibble of %h",nibble);

                        // When 3 nibbles have been accumulated, interpret as height, width etc...
                        case (control_data_id)

                        0 :
                        begin
                            if (nibble_stack.size() == 4)
                            begin
                                for (int i=3; i>=0; i--)
                                    width = width | (nibble_stack.pop_back() << (i*4));
                                control_data_id++;
                                //$display("Sink - width = %h", width);
                            end
                        end

                        1 :
                        begin
                            if (nibble_stack.size() == 4)
                            begin
                                for (int i=3; i>=0; i--)
                                    height = height | (nibble_stack.pop_back() << (i*4));
                                 control_data_id++;
                                //$display("Sink - height = %h", height);
                            end
                        end


                        2 :
                        begin
                            if (nibble_stack.size() == 1)
                            begin
                                interlacing = nibble_stack.pop_back();
                                //$display("Sink - interlacing = %h", interlacing);
                                control_data_id++;
                            end
                        end

                        endcase 

                    end //for  
                
                end
                
                // Garbage beat :
                else
                begin
                    //$display("Sink - control_packet_garbage = %0d",control_packet_garbage);
                    control_packet_garbage = control_packet_garbage + 1;
                end
                
                //$display("Nibble stack has %d elements left", nibble_stack.size());
                
            end //else
            
        end //do
        while (!`SINK_HIERARCHY_NAME.get_transaction_eop()); 
 
        eop_seen = 1'b1;
        
        if (current_video_item_type == video_packet)
        begin
            m_video_items.put(video_data);
            $display("%t %s  sent video packet #%0d of length %0d to the mailbox",$time, name, ++video_packets_sent, video_data.get_length());
        end
            
        else if (current_video_item_type == user_packet)
        begin
            m_video_items.put(user_data);
            $display("%t %s sent user packet #%0d of length %0d to the mailbox",$time, name, ++user_packets_sent, user_data.get_length());
        end
        
        else if (current_video_item_type == control_packet)
        begin

            video_control.set_width(width);
            video_control.set_height(height);
            video_control.set_interlacing(interlacing);               
            m_video_items.put(video_control);
            
            //Reset these for next control packet :
            height = 'h0;
            width = 'h0;
            interlacing = 'h0; 
            if (control_packet_garbage == 0)
                $display("%t %s sent control packet #%0d (%s) to the mailbox",$time, name, ++control_packets_sent, video_control.info());
            else
                $display("%t %s sent control packet #%0d (%s with %0d garbage beats removed) to the mailbox",$time, name,++control_packets_sent, video_control.info(), control_packet_garbage);
               
         end
            
    end
    
    join

endtask

endclass
