// DCJ11 TangNano interface
// 2024.07.28 nanja.info

`default_nettype none

module top ( 
    input wire [3:0] aio,
    input wire [1:0] bs,
    input wire [21:0] dal,
    input wire proc_n,
    input wire bufctl_n,
    input wire ale_n,
    input wire strb_n,
    input wire sctl_n,
    input wire map_n,
    input wire abort_n,
    input wire clk,
    output wire dir
);

assign dir = 1'b0;  // Read from DCJ11 DAL

logic sclk;
Gowin_rPLL u_rpll(
    .clkout(sclk),  //output clkout  36MHz
    .clkin(clk)     //input clkin    18MHz
);

endmodule

`default_nettype wire
