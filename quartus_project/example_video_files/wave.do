# (C) 2001-2016 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License Subscription 
# Agreement, Altera MegaCore Function License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Source bus functional model}
add wave -noupdate /tb_test/netlist/source_0_sop
add wave -noupdate /tb_test/netlist/source_0_eop
add wave -noupdate -radix hexadecimal /tb_test/netlist/source_0_data
add wave -noupdate /tb_test/netlist/source_0_valid
add wave -noupdate /tb_test/netlist/source_0_ready
add wave -noupdate -divider {Sink bus functional model}
add wave -noupdate /tb_test/netlist/sink_0_sop
add wave -noupdate /tb_test/netlist/sink_0_eop
add wave -noupdate -radix hexadecimal /tb_test/netlist/sink_0_data
add wave -noupdate /tb_test/netlist/sink_0_valid
add wave -noupdate /tb_test/netlist/sink_0_ready
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {85 ns} 0}
configure wave -namecolwidth 214
configure wave -valuecolwidth 62
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {39 ns} {176 ns}
