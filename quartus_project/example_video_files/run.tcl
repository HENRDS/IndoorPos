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


set QSYS_SIMDIR ../testbench/tb/simulation
set TOP_LEVEL_NAME "tb_test"

source $QSYS_SIMDIR/mentor/msim_setup.tcl

# Compile all the project files :
com

# Compile class libraries and top level :
vlog -novopt -sv $QSYS_SIMDIR/submodules/verbosity_pkg.sv
vlog -novopt -sv $QSYS_SIMDIR/submodules/avalon_utilities_pkg.sv
vlog -novopt -sv ../class_library/av_st_video_classes.sv
vlog -novopt -sv ../class_library/av_st_video_file_io_class.sv
vlog -novopt -sv $TOP_LEVEL_NAME.sv

# Elaborate the top level :
elab_debug

# Simulate :
# run -all
