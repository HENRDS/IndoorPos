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
// `SOURCE
// `SOURCE_HIERARCHY_NAME
// `BITS_PER_CHANNEL
// `CHANNELS_PER_PIXEL

`define CLASSNAME c_av_st_video_source_bfm_`SOURCE

class `CLASSNAME extends c_av_st_video_source_sink_base;

rand bit [`BITS_PER_CHANNEL*`CHANNELS_PER_PIXEL-1:0] garbage_data; 

typedef c_av_st_video_data #(.BITS_PER_CHANNEL(`BITS_PER_CHANNEL), .CHANNELS_PER_PIXEL(`CHANNELS_PER_PIXEL)) video_t;


// The constructor 'connects' the output mailbox to the object's mailbox :
function new(mailbox #(c_av_st_video_item) m_vid);
    super.new(m_vid);
endfunction


task start;

    wait (`SOURCE_HIERARCHY_NAME.reset == 0)
    forever 
       send_video;

endtask



task send_video;

    bit [`BITS_PER_CHANNEL*`CHANNELS_PER_PIXEL-1:0] transaction_data;
    int channel = 0;
    int  length = 0;
    int      nw = 0;// Warning prevention
    
    // Local objects :
    c_av_st_video_item                                                                                             item_data;
    c_av_st_video_data        #(.BITS_PER_CHANNEL(`BITS_PER_CHANNEL), .CHANNELS_PER_PIXEL(`CHANNELS_PER_PIXEL))   video_data;
    c_av_st_video_control     #(.BITS_PER_CHANNEL(`BITS_PER_CHANNEL), .CHANNELS_PER_PIXEL(`CHANNELS_PER_PIXEL)) control_data;
    c_av_st_video_user_packet #(.BITS_PER_CHANNEL(`BITS_PER_CHANNEL), .CHANNELS_PER_PIXEL(`CHANNELS_PER_PIXEL))    user_data;

    c_pixel                   #(.BITS_PER_CHANNEL(`BITS_PER_CHANNEL), .CHANNELS_PER_PIXEL(`CHANNELS_PER_PIXEL) )   pixel_data;

    pixel_data = new();
    // Pull a video item out of the mailbox  :
    this.m_video_items.get(item_data);

    `SOURCE_HIERARCHY_NAME.set_transaction_sop(1'b1);
    `SOURCE_HIERARCHY_NAME.set_transaction_eop(1'b0); 
       
     if ($urandom_range(100, 0) < readiness_probability) 
         `SOURCE_HIERARCHY_NAME.set_transaction_idles(0); 
     else
         `SOURCE_HIERARCHY_NAME.set_transaction_idles(1);
    
    if (item_data.get_packet_type() == video_packet)
    begin

        // Av-ST Video format requires a 4'h0 on the LSB of the first beat for video packets
        `SOURCE_HIERARCHY_NAME.set_transaction_data({{`BITS_PER_CHANNEL*`CHANNELS_PER_PIXEL-4{1'bx}},4'h0}); 
        `SOURCE_HIERARCHY_NAME.push_transaction();
        
        // Reset SOP for rest of packet :
        `SOURCE_HIERARCHY_NAME.set_transaction_sop(1'b0);

        //Cast the video item to a video packet :
        video_data = video_t'(item_data);
        //$display("%t Source - Video packet transmission of length %d started.", $time, video_data.get_length());
    
        // iteratively put all pixels of the video onto the bus...
        while (video_data.get_length() != 0)
        begin
        
            if (`SOURCE_HIERARCHY_NAME.reset == 0)
            begin 

                pixel_data = video_data.pop_pixel();
                
                do
                begin
                

                    //$display("%t Source pushed video pixel ch1=%h ch0=%h, length now %d",$time, pixel_data.get_data(1),pixel_data.get_data(0),video_data.get_length());
                    transaction_data = 'h0;
                    if (pixel_transport == parallel)
                    begin
                        for (int i=0; i< `CHANNELS_PER_PIXEL; i++)
                            transaction_data = transaction_data | (pixel_data.get_data(i) << `BITS_PER_CHANNEL*i) ;
                    end
                    else
                    begin
                        transaction_data = pixel_data.get_data(channel);
                    end
                        
                    //$display("%t j=%0d, transaction_data = %h",$time, j, transaction_data);
                                        
                    `SOURCE_HIERARCHY_NAME.set_transaction_data(transaction_data);

                    if (video_data.get_length() == 0 &&  ( (pixel_transport == parallel) || (channel == `CHANNELS_PER_PIXEL-1) )  ) 
                        `SOURCE_HIERARCHY_NAME.set_transaction_eop(1'b1);   

                    `SOURCE_HIERARCHY_NAME.push_transaction();

                    if ($urandom_range(100000, 0) < (long_delay_probability*1000))
                    begin
                         nw = randomize(long_delay_duration);
                        `SOURCE_HIERARCHY_NAME.set_transaction_idles(long_delay_duration);                 
                    end
                    else if ($urandom_range(100, 0) < readiness_probability) 
                        `SOURCE_HIERARCHY_NAME.set_transaction_idles(0); 
                    else
                        `SOURCE_HIERARCHY_NAME.set_transaction_idles(1); 

                end    
                while ((pixel_transport == serial) && ++channel < `CHANNELS_PER_PIXEL);
                channel = 0;
            end

            else
            begin  // if in reset then we need to empty the input mailbox 
                 video_data.pop_pixel();
            end 
            
        length++;

        end
        
        $display("%t %s sent   video packet #%0d of length %0d to the BFM.", $time, name, ++video_packets_sent,length );        
        
    end 
    
    else if (item_data.get_packet_type() == control_packet)
    begin
    
        bit [15:0]                                      width;
        bit [15:0]                                      height;
        bit [3 :0]                                      interlacing;
        bit [`BITS_PER_CHANNEL*`CHANNELS_PER_PIXEL-1:0] transmit_symbol = 'h0;
        
        t_packet_control                                  append_garbage = off;
        
        int                                               garbage_probability = 0;
        bit                                               garbage_being_generated = 1'b0;
        int                                               garbage_beats_generated = 0;
         
        // Av-ST Video format requires a 4'h0 on the LSB of the first beat for video packets
        `SOURCE_HIERARCHY_NAME.set_transaction_data({{`BITS_PER_CHANNEL*`CHANNELS_PER_PIXEL-4{1'bx}},4'hf}); 
        `SOURCE_HIERARCHY_NAME.push_transaction();
        
        // Reset SOP for rest of packet :
        `SOURCE_HIERARCHY_NAME.set_transaction_sop(1'b0);

        //Cast the video item to a video control packet :
        control_data = c_av_st_video_control'(item_data); 
           
        width               = control_data.get_width();
        height              = control_data.get_height();
        interlacing         = control_data.get_interlacing();
        append_garbage      = control_data.get_append_garbage();
        garbage_probability = control_data.get_garbage_probability();
                
        if (append_garbage == random)
        begin
            if ($urandom_range(100, 0) < garbage_probability)
                append_garbage = on;
            else      
                append_garbage = off;
        end
            
        for (int nibble_number = 1; nibble_number<10; nibble_number++)
        begin
        
            bit [3:0] transmit_nibble = 'h0;
                       
            // As per table 4-5 in Video and Image Processing User Guide
            case (nibble_number)
            1 : transmit_nibble =  width[15:12];
            2 : transmit_nibble =  width[11: 8];
            3 : transmit_nibble =  width[ 7: 4];
            4 : transmit_nibble =  width[ 3: 0];
            5 : transmit_nibble = height[15:12];
            6 : transmit_nibble = height[11: 8];
            7 : transmit_nibble = height[ 7: 4];
            8 : transmit_nibble = height[ 3: 0];
            9 : transmit_nibble = interlacing;
            endcase
            
            // NB. A whole pixel is represented by 'transmit_symbol' bits, yet we may be transmitting in series in which
            // case we only use `BITS_PER_CHANNEL bits of it :            
            if (pixel_transport == parallel)
                transmit_symbol = transmit_symbol | (transmit_nibble << (`BITS_PER_CHANNEL*((nibble_number-1)%`CHANNELS_PER_PIXEL)));
            else
                transmit_symbol = transmit_symbol | transmit_nibble;
            
            //$display("nibble: %d transmit_nibble = %0h. transmit_symbol = %0h",nibble_number, transmit_nibble, transmit_symbol);
            
            if ( (nibble_number%`CHANNELS_PER_PIXEL == 0) || (nibble_number == 9) || (pixel_transport == serial))
            begin
                               
                //$display("nibble_number == %d. Transmitting transmit_symbol = %h",nibble_number, transmit_symbol);            
                `SOURCE_HIERARCHY_NAME.set_transaction_data(transmit_symbol);
            
                // An idle cycle is inserted (where valid->0) 100-readiness_probability times every 100 cycles :
                if ($urandom_range(100, 0) < readiness_probability) 
                    `SOURCE_HIERARCHY_NAME.set_transaction_idles(0); 
                else
                    `SOURCE_HIERARCHY_NAME.set_transaction_idles(1); 

                if ((nibble_number == 9) && (append_garbage == off))
                    `SOURCE_HIERARCHY_NAME.set_transaction_eop(1'b1); 
                   
                `SOURCE_HIERARCHY_NAME.push_transaction();
                 
                // Reset symbol for next time :
                transmit_symbol = 'h0;
                
            end //if
           
        end //for
        
        // Control packet has been sent, now optionally append some garbage :
        if (append_garbage == on)
        begin
        
            garbage_beats_generated = 0;
            garbage_being_generated = 1'b1;
            
            do
            begin
            
                // Probability of terminating garbage fixed at 10%
                if ($urandom_range(100, 0) < 10)
                    garbage_being_generated = 1'b0;
                    
                nw = randomize(garbage_data);
                
                `SOURCE_HIERARCHY_NAME.set_transaction_data(garbage_data); 

                if ($urandom_range(100, 0) < readiness_probability) 
                    `SOURCE_HIERARCHY_NAME.set_transaction_idles(0); 
                else
                    `SOURCE_HIERARCHY_NAME.set_transaction_idles(1); 

                if (!garbage_being_generated)
                    `SOURCE_HIERARCHY_NAME.set_transaction_eop(1'b1); 

                `SOURCE_HIERARCHY_NAME.push_transaction();

                garbage_beats_generated++;
                
            end
            while (garbage_being_generated); 
            
            $display("%t %s sent control packet #%0d (%s) with %0d garbage beats to the BFM", $time, name, ++control_packets_sent, control_data.info(), garbage_beats_generated );        
        
        end //if (append_garbage == on)
        
        else
        begin
            $display("%t %s sent control packet #%0d (%s) to the BFM", $time, name, ++control_packets_sent, control_data.info() );                
        end
        
     end // else-if
    
    else if (item_data.get_packet_type() == user_packet)
    begin

         //Cast the video item to a video packet :
        user_data = c_av_st_video_user_packet'(item_data);
        
        // Av-ST Video format requires a 4'h0 on the LSB of the first beat for video packets
        `SOURCE_HIERARCHY_NAME.set_transaction_data({{`BITS_PER_CHANNEL*`CHANNELS_PER_PIXEL-4{1'bx}},user_data.get_identifier()}); 
        `SOURCE_HIERARCHY_NAME.push_transaction();
        
        // Reset SOP for rest of packet :
        `SOURCE_HIERARCHY_NAME.set_transaction_sop(1'b0);

        //$display("%t Source - User packet transmission of length %d started.", $time, user_data.get_length());
    
        // iteratively put all pixels of the video onto the bus...
        while (user_data.get_length() != 0)
        begin
        //$display("%t Source - User packet transmission beat %d.", $time, user_data.get_length());

            if (`SOURCE_HIERARCHY_NAME.reset == 0)
            begin 

                `SOURCE_HIERARCHY_NAME.set_transaction_data(user_data.pop_data());

                if (user_data.get_length() == 0) 
                    `SOURCE_HIERARCHY_NAME.set_transaction_eop(1'b1);   

                `SOURCE_HIERARCHY_NAME.push_transaction();

                // An idle cycle is inserted (where valid->0) 100-readiness_probability times every 100 cycles :
                if ($urandom_range(100, 0) < readiness_probability) 
                    `SOURCE_HIERARCHY_NAME.set_transaction_idles(0); 
                else
                    `SOURCE_HIERARCHY_NAME.set_transaction_idles(1); 

            end

            else
            begin  // if in reset then we need to empty the input mailbox 
                user_data.pop_data();
            end 

        length++;
        
        end
        
        $display("%t %s sent    user packet #%0d of length %0d to the BFM",$time, name, ++user_packets_sent, length);
        
    end 
    
    else
    begin
        $display("Error : Unrecognised packet type detected.");
        $finish;
    end
   

endtask

endclass
