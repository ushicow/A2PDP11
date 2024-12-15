//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10.03 (64-bit) 
//Created Time: 2024-11-24 15:33:19
//create_clock -name mclk -period 37.037 -waveform {0 18.518} [get_ports {mclk}]
create_clock -name clk -period 55.556 -waveform {0 27.778} [get_ports {clk}]
create_generated_clock -name clk_d -source [get_ports {clk}] -master_clock clk -divide_by 4 -multiply_by 9 [get_nets {clk_d}]
create_generated_clock -name memory_clk -source [get_ports {clk}] -master_clock clk -multiply_by 9 [get_nets {u_ram/memory_clk}]
create_generated_clock -name clk_out -source [get_ports {clk}] -master_clock clk -divide_by 2 -multiply_by 9 [get_nets {u_ram/clk_out}]
create_generated_clock -name clk_x3 -source [get_ports {clk}] -master_clock clk -divide_by 3 -multiply_by 9 -duty_cycle 33 [get_nets {clk_x3}]
//create_generated_clock -name clk_x2p -source [get_ports {clk}] -master_clock clk -divide_by 2 -multiply_by 9 [get_nets {u_ram/psram/clk_x2p}]
set_false_path -from [get_clocks {clk_x3}] -to [get_clocks {clk_d}] 
set_false_path -from [get_clocks {clk_out}] -to [get_clocks {clk_x3}] 
//set_false_path -from [get_clocks {clk_x2p}] -to [get_clocks {memory_clk}] 
//set_false_path -from [get_clocks {clk_x3}] -to [get_clocks {clk_out}] 
//set_false_path -from [get_clocks {clk_out}] -to [get_clocks {memory_clk}] 
set_false_path -from [get_clocks {clk_d}] -to [get_clocks {memory_clk}] 
set_multicycle_path -from [get_clocks {clk_out}] -to [get_clocks {memory_clk}]  -setup -end 2
set_multicycle_path -from [get_clocks {clk_d}] -to [get_clocks {clk_out}]  -setup -end 4
set_multicycle_path -from [get_clocks {clk_d}] -to [get_clocks {clk_out}]  -hold -end 4
//set_multicycle_path -from [get_clocks {clk_d}] -to [get_clocks {clk_x2p}]  -setup -end 4
//set_multicycle_path -from [get_clocks {clk_d}] -to [get_clocks {clk_x2p}]  -hold -end 4
