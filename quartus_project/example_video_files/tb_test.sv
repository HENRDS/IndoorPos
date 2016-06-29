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


`timescale 1ns / 1ns

module tb_test;

// These must be set to match the equivalent values in the netlist and the video file.
// Eg. RGB32 is CHANNELS_PER_PIXEL = 3, BITS_PER_CHANNEL = 8

`define CHANNELS_PER_PIXEL  3
`define BITS_PER_CHANNEL    8

import av_st_video_classes::*;
import av_st_video_file_io_class::*;
 
// Create clock and reset:
logic clk, reset;

initial
    clk <= 1'b0;
   
always
    #2.5 clk <= ~clk; //200 MHz


initial
begin
    reset <= 1'b1;
    #10 @(posedge clk) reset <= 1'b0;
end


// Instantiate "netlist" :
`define NETLIST netlist
tb `NETLIST (.reset_reset_n(~reset),.clk_clk(clk));

// Create some useful objects from our defined classes :
c_av_st_video_item         video_item_pkt_sink  ;

c_av_st_video_data         #(`BITS_PER_CHANNEL, `CHANNELS_PER_PIXEL) video_data_pkt  ;
c_av_st_video_control      #(`BITS_PER_CHANNEL, `CHANNELS_PER_PIXEL) video_control_pkt  ;
c_av_st_video_user_packet  #(`BITS_PER_CHANNEL, `CHANNELS_PER_PIXEL) user_pkt  ;

c_av_st_video_data         #(`BITS_PER_CHANNEL, `CHANNELS_PER_PIXEL) video_data_pkt_sink  ;
c_av_st_video_user_packet  #(`BITS_PER_CHANNEL, `CHANNELS_PER_PIXEL) video_user_pkt_sink  ;
c_av_st_video_control      #(`BITS_PER_CHANNEL, `CHANNELS_PER_PIXEL) video_control_pkt_sink  ;


// The following code creates a class with a name specific to `SOURCE, which is needed because the
// class calls functions for that specific `SOURCE.  A class is used so that individual mailboxes
// can be easily associated with individual sources/sinks :

// This names MUST match the instance name of the source in the netlist :
`define SOURCE st_source_bfm_0 
`define SOURCE_STR "st_source_bfm_0"
`define SOURCE_HIERARCHY_NAME `NETLIST.`SOURCE
`include "../class_library/av_st_video_source_bfm_class.sv"

// Create an object of name `SOURCE of class av_st_video_source_bfm_`SOURCE :
`define CLASSNAME c_av_st_video_source_bfm_`SOURCE
`CLASSNAME `SOURCE;   
`undef CLASSNAME

// Create mailboxes to transfer video packets and control packets :
mailbox #(c_av_st_video_item) m_video_items_for_src_bfm = new(0);
mailbox #(c_av_st_video_item) m_video_items_for_sink_bfm = new(0);


// This names MUST match the instance name of the sink in tb.v :
`define SINK st_sink_bfm_0 
`define SINK_STR "st_sink_bfm_0"
`define SINK_HIERARCHY_NAME `NETLIST.`SINK
`include "../class_library/av_st_video_sink_bfm_class.sv"

// Create an object of name `SINK of class av_st_video_sink_bfm_`SINK :
`define CLASSNAME c_av_st_video_sink_bfm_`SINK
`CLASSNAME `SINK;
`undef CLASSNAME

// Now create file I/O objects to read and write :
c_av_st_video_file_io #(`BITS_PER_CHANNEL, `CHANNELS_PER_PIXEL) video_file_reader;
c_av_st_video_file_io #(`BITS_PER_CHANNEL, `CHANNELS_PER_PIXEL) video_file_writer;

bit [15:0] height, width;
int fields_read, r;
string video_format;

initial
begin
    
    wait (reset == 1'b0)
    repeat (4) @ (posedge (clk));
 
    video_data_pkt    = new();    
    video_control_pkt = new();
    user_pkt          = new();

    // Associate the mailboxes with the source and sink classes via their constructors :
    `SOURCE = new(m_video_items_for_src_bfm);
    `SINK   = new(m_video_items_for_sink_bfm);
    
    // Avaon-ST video packets should be sent with pixels in parallel :
    `SOURCE.set_pixel_transport(parallel);
      `SINK.set_pixel_transport(parallel);
    
    `SOURCE.set_name(`SOURCE_STR);
      `SINK.set_name(  `SINK_STR);
    
    `SOURCE.set_readiness_probability(90);
      `SINK.set_readiness_probability(90); 
      
    `SOURCE.set_long_delay_probability(0.01);
      `SINK.set_long_delay_probability(0.01);       
    
    fork    
    
        `SOURCE.start();
        `SINK.start();

        begin

            // File reader :

            // Associate the source BFM's video in mailbox with the video file reader object via the file reader's constructor :
            video_file_reader = new(m_video_items_for_src_bfm);   
            video_file_reader.set_object_name("file_reader_0");
            
            // Arguments are : (File name, read/write)
            video_file_reader.open_file("vip_car.raw", read);  
            
            // Get the video details from the input file, as we shall re-use these
            // when generating the output file :
            video_format = video_file_reader.get_video_data_type();  
            height       = video_file_reader.get_image_height();  
            width        = video_file_reader.get_image_width();  

            // Set some of the stress test components :
            video_file_reader.set_send_control_packets(off);            
            video_file_reader.set_send_user_packets(off);
            video_file_reader.set_send_garbage_after_control_packets(off);     
                
            // Fine-tune statistics of generation :   
            //video_file_reader.set_control_packet_probability(80);                                                 
            //video_file_reader.set_user_packet_probability(30);                                                 
            //video_file_reader.set_early_eop_probability(30);                                                 
            //video_file_reader.set_late_eop_probability(50);                                     
            
            // Read and send file :
            video_file_reader.read_file();
            video_file_reader.close_file();     

            fields_read = 10; //video_file_reader.get_video_packets_handled();

            // File writer :
            
            video_file_writer = new(m_video_items_for_sink_bfm);   
            video_file_writer.set_object_name("file_writer_0");
            
            // Set the file format to be the same as for the input file :
            video_file_writer.set_video_data_type(video_format);       
            video_file_writer.set_image_height(height);
            video_file_writer.set_image_width(width);
            
            // Open the file, reading for writing :
            video_file_writer.open_file("vip_car_out.raw", write);       

            // Now wait for and write the video output packets to the file as they arrive :
            do
            begin  
                video_file_writer.wait_for_and_write_video_packet_to_file();    
            end        
            while ( video_file_writer.get_video_packets_handled() < fields_read );
            
            video_file_writer.close_file();
            
            $display("Simulation complete. To view resultant video, now run the windows raw2avi application :\n   >raw2avi.exe %s video.avi\n\n",video_file_writer.get_filename());        

            $finish;
            
        end
        
    join   
         
end       

endmodule
