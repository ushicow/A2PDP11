//Copyright (C)2014-2024 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//Tool Version: V1.9.10.01 (64-bit)
//Part Number: GW1NR-LV9QN88PC6/I5
//Device: GW1NR-9
//Device Version: C
//Created Time: Sun Aug 25 17:23:05 2024

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_RAM16S your_instance_name(
        .dout(dout), //output [15:0] dout
        .wre(wre), //input wre
        .ad(ad), //input [9:0] ad
        .di(di), //input [15:0] di
        .clk(clk) //input clk
    );

//--------Copy end-------------------
