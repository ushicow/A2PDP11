// DCJ11 TangNano interface
// TEST2 2024.07.28 Bus read, nanja.info
// TSET3 2024.08.03 Start-Up config, nanja.info
// 
`default_nettype none

module top ( 
    input wire [3:0] aio,
    input wire [1:0] bs,
    input wire [5:0] dal_hi,    // DAL<21:16>
    inout wire [15:0] dal_lo,   // DAL<15:0>
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

logic sclk;
Gowin_rPLL u_rpll(
    .clkout(sclk),  //output clkout  54MHz
    .clkin(clk)     //input clkin    18MHz
);

// AIO CODE
parameter NIO           = 4'b1111;
parameter GP_READ       = 4'b1110;
parameter INTERRUPT_ACK = 4'b1101;
parameter REQEST_READ   = 4'b1100;
parameter RMW_NOLOCK    = 4'b1011;
parameter RMW_BUSLOCK   = 4'b1010;
parameter DATA_READ     = 4'b0111;
parameter DEMAND_READ   = 4'b0110;
parameter GP_WRITE      = 4'b0101;
parameter BYTE_WRITE    = 4'b0011;
parameter WORD_WRITE    = 4'b0001;

// GP CODE
parameter POWER_UP0     = 8'o000;
parameter POWER_UP2     = 8'o002;

logic [7:0] gp_code;
always_ff@(negedge ale_n) begin
    if ((aio == GP_READ) || (aio == GP_WRITE)) begin
        gp_code <= dal_lo[7:0];
    end else begin
        gp_code <= 8'b11111111;
    end
end

assign dir = ~bufctl_n;

logic [15:0] dal_out;
assign dal_lo = bufctl_n ? 16'bz: dal_out;

always_ff@(negedge bufctl_n) begin
    if ((gp_code == POWER_UP0) || (gp_code == POWER_UP2)) begin
        dal_out <= 16'b1000001_0_0000_0_11_1;
                // BOOT_ADDRESS, FPE, UNUSED, HALT, MODE, POK
    end else begin
        dal_out <= 0;
    end
end


endmodule

`default_nettype wire
