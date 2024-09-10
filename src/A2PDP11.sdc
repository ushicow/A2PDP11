//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.10.01 (64-bit) 
//Created Time: 2024-09-09 21:49:12
create_clock -name mclk -period 37.037 -waveform {0 18.518} [get_ports {mclk}]
create_clock -name sctl_n -period 222.222 -waveform {0 111.111} [get_ports {sctl_n}]
create_clock -name clk -period 55.556 -waveform {0 27.778} [get_ports {clk}]
create_clock -name bufctl_n -period 222.222 -waveform {0 111.111} [get_ports {bufctl_n}]
//create_generated_clock -name clk_out -source [get_ports {mclk}] -master_clock mclk -divide_by 9 -multiply_by 25 [get_nets {u_ram/clk_out}]
//create_generated_clock -name memory_clk -source [get_ports {mclk}] -master_clock mclk -divide_by 9 -multiply_by 50 [get_nets {u_ram/memory_clk}]
create_generated_clock -name clk_d -source [get_ports {mclk}] -master_clock mclk -divide_by 18 -multiply_by 25 [get_nets {u_ram/clk_d}]
