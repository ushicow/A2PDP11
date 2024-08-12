// DCJ11 TangNano interface
// TEST2 2024.07.28 Bus read, nanja.info
// TSET3 2024.08.03 Start-Up config, nanja.info
// TEST4 2024.08.07 NXM abort signal
// TEST5 2024.08.12 Console ODT output
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
    input wire rrdy,        // Ready to read from DJC11's ODT data
    output reg rstb,        // Strobe for read from DJC11's ODT data
    input wire wrdy,        // Ready to write to DJC11's ODT data
    output reg wstb,        // Strobe for write to DJC11's ODT data
    output wire nxm_n
);

logic sclk;
Gowin_rPLL u_rpll(
    .clkout(sclk),  //output clkout  54MHz
    .clkin(clk)     //input clkin    18MHz
);

// AIO CODE
parameter NIO           = 4'b1111;  // internal operation only, no I/O
parameter GP_READ       = 4'b1110;  // General-Purpose read
parameter INTERRUPT_ACK = 4'b1101;  // Interrupt acknowledge, vector read
parameter REQEST_READ   = 4'b1100;  // Instruction-stream request read
parameter RMW_NOLOCK    = 4'b1011;  // Read/Modify/Write - no bus lock
parameter RMW_BUSLOCK   = 4'b1010;  // Read/Modify/Write - bus lock
parameter DATA_READ     = 4'b1001;  // Data-stream read
parameter DEMAND_READ   = 4'b1000;  // Instruction-stream demand read
parameter GP_WRITE      = 4'b0101;  // General-Purpose word write
parameter BYTE_WRITE    = 4'b0011;  // Bus byte write
parameter WORD_WRITE    = 4'b0001;  // Bus word write

// BANK SELECT
parameter BS_MEM        = 2'b00;    // Memory
parameter BS_SYS        = 2'b01;    // System register
parameter BS_EXT        = 2'b10;    // Extarnal I/O
parameter BS_INT        = 2'b11;    // Internal register

// GP CODE
parameter POWER_UP0     = 8'o000;   // Reads the power-up mode
parameter POWER_UP2     = 8'o002;   // Reads the power-up mode, clears the FPA’s FPS

// DLART
parameter DLART         = 19'o1777756;  // DLART registers
parameter RCSR          = 22'o17777560; // Receiver Control and Status Register
parameter RBUF          = 22'o17777562; // Receiver Buffer Register
parameter XCSR          = 22'o17777564; // Transmitter Control And Status Register
parameter XBUF          = 22'o17777566; // Transmitter Buffer Register

logic [7:0] gp_code;
always_ff@(negedge ale_n) begin
    if ((aio == GP_READ) || (aio == GP_WRITE)) begin
        gp_code <= dal_lo[7:0];
    end else begin
        gp_code <= 8'b11111111;
    end
end

logic [21:0] mdal;
logic [3:0] maio;
logic [1:0] mbs;
always_ff@(negedge ale_n) begin
    mdal <= {dal_hi, dal_lo};
    maio <= aio;
    mbs <= bs;
end

always_ff@(negedge bufctl_n) begin
    if ((gp_code == POWER_UP0) || (gp_code == POWER_UP2)) begin
        dal_out <= 16'b0000000_0_0000_0_01_1;
                // BOOT_ADDRESS, FPE, UNUSED, HALT, MODE, POK
    end else begin
        dal_out <= 0;
    end
end

logic nxm;
assign nxm_n = sctl_n ? 1'b1 : ~nxm;
always_ff@(negedge ale_n) begin
    if ((aio[3:2] == 2'b10) || (aio[3:2] == 2'b00)) begin
        // RMW_BUSLOCK, RMW_NOLOCK, DATA_READ, DEMAND_READ, WORD_WRITE, BYTE_WRITE
        if (bs == BS_MEM) begin
            if (dal_lo > 16'o157777) begin
                nxm <= 1'b1;
            end
        end
        if (bs == BS_EXT) begin
            if ({dal_hi, dal_lo[15:3]} == DLART) begin
                nxm <= 1'b0;
            end else begin
                nxm <= 1'b1;
            end
        end
    end else begin
        nxm <= 1'b0;
    end
end

logic rxrdy = 1'b1;
logic rrdy1;
logic rrdy0;
always_ff@(negedge clk) begin
    rrdy0 <= rrdy;
    rrdy1 <= rrdy0;
end

always_ff@(negedge clk) begin
    if ((sctl_n == 0) && (mdal == XBUF)) begin
        rstb <= 1'b1;
        rxrdy <= 1'b0;
    end else if (!rrdy1) begin
        rstb <= 1'b0;
    end else if (!rstb) begin
        rxrdy <= 1'b1;
    end
end

logic [15:0] dal;
logic [15:0] dal_out;
logic [15:0] odt_out;
assign dal_lo = bufctl_n ? 16'bz : dal_out | odt_out;

always_ff@(negedge bufctl_n) begin
    if ((maio == DATA_READ) && (mbs == BS_EXT)) begin
        if (mdal == RCSR) begin 
            odt_out <= {8'b0, wrdy, 7'b0};
        end
        if (mdal == RBUF) begin
            wstb <= 1'b1;
        end
        if (mdal == XCSR) begin
            odt_out <= {8'b0, rxrdy, 7'b0};
        end
    end else begin
        odt_out <= 16'bz;
        wstb <= 1'b0;
    end
end


endmodule

`default_nettype wire
