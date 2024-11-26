`default_nettype none
// DCJ11 TangNano interface by nanja.info
// TEST18 2024.11.24 Use Extarnal clock

module top ( 
    inout wire [15:0] dal,          // DAL<21:0>, BS<1:0>
    input wire [3:0] aio,           // AIO<3:0>
    inout wire [7:0] d,             // Apple II Data D<7:0>
    input wire devsel_n,            // Apple II /DEVSEL
    input wire rw,                  // Apple II R/W
    input wire bufctl_n,
    input wire ale_n,
    output wire nxm_n,
    input wire sctl_n,
    input wire clk,
    output reg cont_n,
    output reg miss_n,
    output reg dallo_oe_n,
    output reg event_n,
    output reg irq0,
    output reg irq1,
    output wire [1:0] O_psram_ck,
    output wire [1:0] O_psram_ck_n,
    inout wire [15:0] IO_psram_dq,
    inout wire [1:0] IO_psram_rwds,
    output wire [1:0] O_psram_cs_n,
    output wire [1:0] O_psram_reset_n,
    input wire mclk,
    input wire rst_n,
    output wire led1
);

// AIO CODE
parameter NIO           = 4'b1111;  // internal operation only, no I/O
parameter GP_READ       = 4'b1110;  // General-Purpose read
parameter INTERRUPT_ACK = 4'b1101;  // Interrupt acknowledge, vector read
parameter REQUEST_READ  = 4'b1100;  // Instruction-stream request read
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

// PC11 Paper Tape Reader/Punch
parameter PC11          = 19'o1777755;  // PC11 registers
parameter PRS           = 22'o17777550; // Paper Tape Reader Status Register
parameter PRB           = 22'o17777552; // Paper Tape Reader Buffer Register
parameter PPS           = 22'o17777554; // Paper Tape Punch Status Register
parameter PPB           = 22'o17777556; // Paper Tape Punch Buffer Register

parameter HIMEM         = 22'o17757777; // End of RAM

// Apple II Register
parameter A2RCSR        = 8'h00;         // Console out status; Read = rstb, Write = rrdy
parameter A2RBUF        = 8'h01;         // Cousole out data
parameter A2XCSR        = 8'h02;         // Console in status; Read = xstb, Write = xrdy  
parameter A2XBUF        = 8'h03;         // Console in data

logic clk_x3;   // clk x 3 = 54 MHz
//Gowin_rPLL rpll(
//    .clkout(clk_x3), //output clkout
//    .clkin(clk) //input clkin
//);

assign event_n = 1'b1;
assign irq0 = 1'b0;
assign irq1 = 1'b0;

logic [4:0] count;
logic [15:0] mdallo;
logic [21:0] mdal;
logic [3:0] maio;
logic [1:0] mbs;
logic [7:0] gp_code;
logic [7:0] a;              // Apple II Address

always_ff@(posedge clk_x3) begin
    if (ale_n) begin
        count <= 0;
    end else begin
        if (count == 0) begin
            dallo_oe_n <= 1'b1;
            mdallo <= dal;
        end else if (count == 2) begin
            if ((aio == GP_READ) || (aio == GP_WRITE)) begin
                gp_code <= mdallo[7:0];
            end else begin
                gp_code <= 8'b11111111;
            end
            maio <= aio;
            mbs[0] <= dal[6];
            mbs[1] <= dal[7];
            mdal[21] <= dal[8];
            mdal[20] <= dal[0];
            mdal[19] <= dal[9];
            mdal[18] <= dal[10];
            mdal[17] <= dal[11];
            mdal[16] <= dal[12];
            mdal[15:0] <= mdallo;
            a[0] <= dal[5];
            a[1] <= dal[4];
            a[2] <= dal[3];
            a[3] <= dal[2];
            a[4] <= dal[1];
            a[5] <= dal[15];
            a[6] <= dal[14];
            a[7] <= dal[13];
            dallo_oe_n <= 1'b0;
        end
        count <= count + 1'b1;
    end
end

assign nxm_n = sctl_n ? 1'b1 :
    ((maio[2] == 0) && (mbs == BS_MEM) && (mdal > HIMEM)) ? 1'b0 :
    ((maio[2] == 0) && (mbs == BS_EXT) && 
        ((mdal[21:3] != DLART) && (mdal[21:3] != PC11))) ? 1'b0 :
    1'b1;

logic [7:0] xbuf;
logic [7:0] rbuf;
logic xrdy;
logic rrdy;
logic [7:0] d0;
assign d = rw ? d0 : 8'bz;

logic devsel0;
logic devsel1;
//always_ff@(posedge clk) begin
always_ff@(posedge clk_x3) begin
      devsel0 <= !devsel_n;
    devsel1 <= devsel0;
end

logic dev_done;
logic error;
//always_ff@(posedge clk) begin
always_ff@(posedge clk_x3) begin
    if (devsel1) begin
        if (dev_done) begin;
            if (rw) begin
                case (a[3:0])
                    A2RCSR : d0 <= {rstb, 7'b0};
                    A2XCSR : d0 <= {xstb, 7'b0};
                    A2XBUF : d0 <= xbuf;
                endcase
            end else begin
                case (a[3:0])
                    A2RCSR : rrdy <= d[7];
                    A2RBUF : rbuf <= d;
                    A2XCSR : xrdy <= d[7];
                    8'h0f  : error <= 1'b1;
                endcase
            end
            dev_done <= 1'b0;
        end
    end else begin
        dev_done <= 1'b1;
        error <= 1'b0;
    end
end

logic xdone;
logic xstb;
//always_ff@(posedge clk) begin
always_ff@(posedge clk_x3) begin
    if (gp_code == 8'o014) begin
        xdone <= 1'b1;
        xstb <= 1'b0;
    end else if ((sctl_n == 0) && (mdal == XBUF)) begin
        xstb <= 1'b1;
        xdone <= 1'b0;
        xbuf <= dal[7:0];
    end else if (xstb & !xrdy) begin
        xstb <= 1'b0;
    end else if (!xstb & xrdy) begin
        xdone <= 1'b1;
    end
end

logic rdone;
logic rstb;
//always_ff@(posedge clk) begin
always_ff@(posedge clk_x3) begin
    if (gp_code == 8'o014) begin
        rdone <= 1'b0;
        rstb <= 1'b0;
    end else if (rrdy) begin
        rstb <= 1'b1;
    end else if (rstb) begin
        rstb <= 1'b0;
        rdone <= 1'b1;
    end else if (mdal == RBUF) begin
        rdone <= 1'b0;
    end
end

assign dal = bufctl_n ? 16'bz : 
    (mdal == RCSR) ? {8'b0, rdone, 7'b0} :
    (mdal == XCSR) ? {8'b0, xdone, 7'b0} :
    (mdal == RBUF) ? {8'b0, rbuf} :
    (mdal == PRS) ? 16'b1000_0000_0000_0000 :
    (mdal == PRB) ? 16'b0 :
    (mdal == PPS) ? 16'b0000_0000_1000_0000 :
    (gp_code == POWER_UP0) ? 16'b0000000_0_0000_0_01_1 :
    (gp_code == POWER_UP2) ? 16'b0000000_0_0000_0_01_1 :
    (mdal <= HIMEM) ? ram_rdata : 16'bz;

logic init;
assign led1 = init;
ram u_ram(
    .*
);

assign cont_n = 1'b0;
logic [21:0] ram_addr;
logic [15:0] ram_rdata;
logic [15:0] ram_wdata;
logic ram_read;
logic ram_write;
logic ram_byte;
always_ff@(posedge clk_x3) begin
    if ((mbs == BS_MEM) && (count == 3)) begin
        ram_addr <= mdal;
        if ((maio[3:2] == 2'b10) || (maio == REQUEST_READ)) begin
            miss_n <= 1'b0;
            ram_read <= 1'b1;
        end
    end else if (count == 0) begin
        miss_n <= 1'b1;
        ram_read <= 1'b0;
    end
end

//always_ff@(posedge clk) begin
always_ff@(posedge clk_x3) begin
    if ((mbs == BS_MEM) && (maio[3:2] == 2'b00) && (!sctl_n)) begin
        if (maio == BYTE_WRITE) begin
            ram_byte <= 1'b1;
        end
        ram_write <= 1'b1;
        ram_wdata <= dal[15:0];
    end else begin
        ram_write <= 1'b0;
        ram_byte <= 1'b0;
    end
end

endmodule

`default_nettype wire
