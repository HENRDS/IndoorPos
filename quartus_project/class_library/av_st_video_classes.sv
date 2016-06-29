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


`ifndef _ALT_VIP_VID_CLASSES_
`define _ALT_VIP_VID_CLASSES_

package av_st_video_classes;

typedef enum {video_packet, control_packet, user_packet, generic_packet, undefined} t_packet_types;
typedef enum {parallel, serial}                                                     t_pixel_format;
typedef enum {on, off, random}                                                      t_packet_control;
typedef enum {read, write}                                                          t_rw;
typedef enum {normal, inverse}                                                      t_ycbcr_order;
typedef enum {big, little}                                                          t_endianism;

function string display_video_item_type (t_packet_types t);
begin

    case (t) 
    video_packet    : return      "video_packet";
    control_packet  : return    "control_packet";
    user_packet     : return       "user_packet";
    generic_packet  : return    "generic_packet";
    undefined       : return         "undefined";
    endcase

end
endfunction : display_video_item_type


// The mailboxes which source/sink video packets hold 'queue items'
// which may be Av-st video packets, control packets or user packets :
class c_av_st_video_item  ;

    t_packet_types packet_type;
    
    function new();
       packet_type = generic_packet;
    endfunction : new;
    
    function compare(c_av_st_video_item c);
    endfunction : compare;
    
    function void copy(c_av_st_video_item c);
       this.packet_type = c.packet_type;
    endfunction : copy;

    // Getters and setters :
    function void set_packet_type(t_packet_types ptype);
        packet_type = ptype;
    endfunction : set_packet_type 

    function t_packet_types get_packet_type ();
        return packet_type;
    endfunction : get_packet_type 
   
endclass


class c_pixel #(parameter BITS_PER_CHANNEL = 8, CHANNELS_PER_PIXEL = 3) ;
    
    // Each pixel is an array of CHANNELS_PER_PIXEL channels, each channel of BITS_PER_CHANNEL precision :
    rand bit  [0:CHANNELS_PER_PIXEL-1] [BITS_PER_CHANNEL-1:0]channel ;
        
    // Default constructor :
    function new();
        for (int i=0; i<CHANNELS_PER_PIXEL; i++ )
            channel[i] = 'hx;
       //$display("c_pixel NEW called with CHANNELS_PER_PIXEL=",CHANNELS_PER_PIXEL);
    endfunction : new;

    // Copy constructor :
    function void copy(c_pixel #(BITS_PER_CHANNEL,CHANNELS_PER_PIXEL) pix);
        for (int i=0; i<CHANNELS_PER_PIXEL; i++ )
            this.channel[i] = pix.get_data(i);
    endfunction : copy
    
    // Pixel channel "Getters" and "Setters" :
    function bit[BITS_PER_CHANNEL-1:0] get_data(int id);
        return channel[id];
    endfunction : get_data
    
    // Setter :
    function void set_data(int id, bit [BITS_PER_CHANNEL-1:0] data);
        channel[id] = data;
    endfunction : set_data 
        
endclass



class c_av_st_video_data #(parameter BITS_PER_CHANNEL = 8, CHANNELS_PER_PIXEL = 3) extends c_av_st_video_item ;

    // Create a queue of pixel objects from class c_pixel.  A queue is used instead
    // of an array.  This denies random access, but improves simulation speed :    
    c_pixel #(BITS_PER_CHANNEL,CHANNELS_PER_PIXEL) pixels [$];
    c_pixel #(BITS_PER_CHANNEL,CHANNELS_PER_PIXEL) pixel,new_pixel,r_pixel;
        
    rand int       video_length;
    int            video_max_length = 10;
    
    // Default constructor :
    function new();
        super.new();
        packet_type = video_packet;
        pixels = new[video_length];
       //$display("c_av_st_video_data NEW called with CHANNELS_PER_PIXEL=",CHANNELS_PER_PIXEL);
    endfunction : new;
    
    // Copy constructor :
    function void copy(c_av_st_video_data #(BITS_PER_CHANNEL,CHANNELS_PER_PIXEL) c);
        super.copy(c_av_st_video_item'(c));
        packet_type = video_packet;
        pixels = new[video_length];

        for (int i=0; i<c.get_length(); i++ )
        begin
            new_pixel = new();            
            pixel = c.query_pixel(i);
            new_pixel.copy(pixel);
            pixels.push_front(new_pixel);   
        end        
           
    endfunction : copy;
    
    function bit compare (c_av_st_video_data #(BITS_PER_CHANNEL,CHANNELS_PER_PIXEL) r);
    begin
        
        for (int j=0; j< r.get_length(); j++)
        begin
        
            r_pixel = r.query_pixel(j);            
            for (int i=0; i< CHANNELS_PER_PIXEL; i++)            
                if ( r_pixel.get_data(i) != pixels[r.get_length()-1-j].get_data(i))
                    return 1'b0;
            
        end
        return 1'b1;
        
     end
     endfunction    
    // Getters and setters 
    
    //set_max_length sets the maximum length of video packet that could be held by the object :
    function void set_max_length(int length);
        video_max_length = length;
    endfunction : set_max_length
    
    //get_length returns the length of the video data packet :
    function int get_length();
        return pixels.size();
    endfunction : get_length
    
    // Populate fills the video data packet with random pixels :    
    function void post_randomize();
    
        c_pixel #(BITS_PER_CHANNEL,CHANNELS_PER_PIXEL) pixel, pixel_template;
        pixel_template = new();
        
        for (int i=0; i<video_length; i++ )
        begin
            // Here the randomize is performed on one object, which is then copied, in order to
            // improve simulation speed :
            pixel_template.randomize();
            pixel = new();
            pixel.copy(pixel_template);
            pixels.push_front(pixel);   
        end           
        
    endfunction : post_randomize;    
    
    // pop_pixel returns an object of class c_pixel :
    function c_pixel #(BITS_PER_CHANNEL,CHANNELS_PER_PIXEL) pop_pixel();
        c_pixel #(BITS_PER_CHANNEL,CHANNELS_PER_PIXEL) pixel;
        pixel = new();
        pixel = pixels.pop_back();    
        return pixel;
    endfunction : pop_pixel
    
    // query_pixel returns an object of class c_pixel :
    function c_pixel #(BITS_PER_CHANNEL,CHANNELS_PER_PIXEL) query_pixel(int i);
        c_pixel #(BITS_PER_CHANNEL,CHANNELS_PER_PIXEL) pixel;
        pixel = new();
        pixel = pixels[i];    
        return pixel;
    endfunction : query_pixel

    // Unpopulate pops each pixel off the stream, optionaly displaying them :
    function void unpopulate(bit display);
        c_pixel #(BITS_PER_CHANNEL,CHANNELS_PER_PIXEL) pixel;
        pixel = new();
        while (pixels.size() > 0)
        begin
            pixel = pixels.pop_back();
            if (display) $display("Unpopulate : %3h%3h%3h",pixel.get_data(0),pixel.get_data(1),pixel.get_data(2));
        end
    endfunction : unpopulate
    
    //push_pixel pushes a pixel to the front of the queue :
    function void push_pixel(c_pixel #(BITS_PER_CHANNEL,CHANNELS_PER_PIXEL) pixel);
        pixels.push_front(pixel);
    endfunction : push_pixel
   
    constraint c1 { video_length > 0; video_length < video_max_length;}

endclass



class c_av_st_video_control #(parameter BITS_PER_CHANNEL = 8, CHANNELS_PER_PIXEL = 3) extends c_av_st_video_item ;

    rand bit [15:0] width;
    rand bit [15:0] height;
    rand bit [3:0]  interlace;
    
    // Control packets may append any number of garbage beats after the last beat.
    rand t_packet_control      append_garbage = off;
    rand int              garbage_probability = 50;
    
    function new();
        super.new();
        packet_type = control_packet;
        this.width = 'hx;
        this.height = 'hx;
        this.interlace = 'hx;
       //$display("c_av_st_video_control NEW called with CHANNELS_PER_PIXEL=",CHANNELS_PER_PIXEL);
    endfunction
   
    
    function bit compare (c_av_st_video_control r);
    begin

        if (this.width != r.get_width())
            return 1'b0;
        if (this.height != r.get_height())
            return 1'b0;
        if (this.interlace != r.get_interlacing())
            return 1'b0;          
        
        return 1'b1;
        
    end
    endfunction  
      
    
    // Getters :
    function bit [15:0] get_width ();
        return this.width;
    endfunction :  get_width
    
    function bit [15:0] get_height ();
        return this.height;
    endfunction :  get_height
    
    function bit [3:0] get_interlacing ();
        return this.interlace;
    endfunction :  get_interlacing
    
    function t_packet_control get_append_garbage ();
        return this.append_garbage;
    endfunction :  get_append_garbage
     
    function int get_garbage_probability ();
        return this.garbage_probability;
    endfunction :  get_garbage_probability
   
    // Setters :
    function void set_width (bit [15:0] w);
        this.width = w;
    endfunction :  set_width
     
    function void set_height (bit [15:0] h);
        this.height = h;
    endfunction :  set_height
     
    function void set_interlacing (bit [3:0] i);
        this.interlace = i;
    endfunction :  set_interlacing
     
    function void set_append_garbage (t_packet_control i);
        this.append_garbage = i;
    endfunction :  set_append_garbage
      
    function void set_garbage_probability (int i);
        this.garbage_probability = i;
    endfunction :  set_garbage_probability
    
    function string info();
        string s;
        $sformat(s, "width = %0d, height = %0d, interlacing = 0x%0h", width, height, interlace);
        return s;    
    endfunction
  
endclass



class c_av_st_video_user_packet #(parameter BITS_PER_CHANNEL = 8, CHANNELS_PER_PIXEL = 3) extends c_av_st_video_item;

    rand bit [BITS_PER_CHANNEL*CHANNELS_PER_PIXEL-1:0] data [$];
    rand bit[3:0]  identifier;
    int            max_length = 10;
    
    rand bit [BITS_PER_CHANNEL*CHANNELS_PER_PIXEL-1:0] datum ;

    function new();
        super.new();
        packet_type = user_packet;
        data = {};
        //$display("c_av_st_video_user_packet NEW called with CHANNELS_PER_PIXEL=",CHANNELS_PER_PIXEL);
    endfunction
    
    // Copy constructor :
    function void copy(c_av_st_video_user_packet c);
        super.copy(c_av_st_video_item'(c));
        packet_type = user_packet;
        data = {};

        for (int i=0; i<c.get_length(); i++ )
        begin
            data.push_front(c.query_data(i));   
        end        
           
    endfunction : copy;
    
    function bit compare (c_av_st_video_user_packet r);
    begin
            
        for (int j=0; j< r.get_length(); j++)                    
            if ( r.query_data(j) != data[r.get_length()-1-j])
                return 1'b0;
            
        return 1'b1;
        
     end
     endfunction : compare 
    
    //set_max_length sets the maximum length of video packet that could be held by the object :
    function void set_max_length(int l);
        max_length = l;
    endfunction : set_max_length
    
    function int get_length();
        return data.size();
    endfunction : get_length
     
    function bit[3:0] get_identifier();
        return identifier;
    endfunction : get_identifier
   
    function bit [BITS_PER_CHANNEL*CHANNELS_PER_PIXEL-1:0] pop_data();
        return data.pop_back();    
    endfunction : pop_data
   
    function bit [BITS_PER_CHANNEL*CHANNELS_PER_PIXEL-1:0] query_data(int i);
        return data[i];    
    endfunction : query_data
    
    function void push_data(bit [BITS_PER_CHANNEL*CHANNELS_PER_PIXEL-1:0] d);
        data.push_front(d);
    endfunction : push_data 
    
    constraint c1 { data.size() inside {[1:max_length]};} 
    constraint c2 { identifier inside {[4:14]};} 
       
endclass



// This package also includes a base class for the source and sink file BFMs
// which provides the various statistical metrics :
class c_av_st_video_source_sink_base;

    // The class receives video items and outputs through this mailbox :
    mailbox #(c_av_st_video_item) m_video_items = new(0);

    t_pixel_format              pixel_transport = parallel;
    string                                 name = "undefined";

    int                      video_packets_sent =    0;
    int                    control_packets_sent =    0;
    int                       user_packets_sent =    0;

    int                   readiness_probability =   80;
    real                 long_delay_probability = 0.01;

    rand int      long_delay_duration_min_beats =  100;
    rand int      long_delay_duration_max_beats = 1000;
    rand int      long_delay_duration           =   80;

    // The constructor 'connects' the output mailbox to the object's mailbox :
    function new(mailbox #(c_av_st_video_item) m_vid);
        this.m_video_items = m_vid;
    endfunction

    function void set_readiness_probability(int percentage);
        this.readiness_probability = percentage;
    endfunction

    function int get_readiness_probability();
        return this.readiness_probability;
    endfunction



    function void set_long_delay_probability(real percentage);
        this.long_delay_probability = percentage;
    endfunction : set_long_delay_probability

    function real get_long_delay_probability();
        return this.long_delay_probability;
    endfunction : get_long_delay_probability



    function void set_long_delay_duration_min_beats(int percentage);
        this.long_delay_duration_min_beats = percentage;
    endfunction : set_long_delay_duration_min_beats

    function int get_long_delay_duration_min_beats();
        return this.long_delay_duration_min_beats;
    endfunction : get_long_delay_duration_min_beats



    function void set_long_delay_duration_max_beats(int percentage);
        this.long_delay_duration_max_beats = percentage;
    endfunction : set_long_delay_duration_max_beats

    function int get_long_delay_duration_max_beats();
        return this.long_delay_duration_max_beats;
    endfunction : get_long_delay_duration_max_beats



    function void set_pixel_transport(t_pixel_format in_parallel);
        this.pixel_transport = in_parallel;
    endfunction : set_pixel_transport

    function t_pixel_format get_pixel_transport();
        return this.pixel_transport;
    endfunction : get_pixel_transport



    function void set_name(string s);
        this.name = s;
    endfunction : set_name

    function string get_name();
        return name;
    endfunction : get_name


    constraint c1 { long_delay_duration inside {[long_delay_duration_min_beats:long_delay_duration_max_beats]};}

endclass


endpackage : av_st_video_classes
`endif
