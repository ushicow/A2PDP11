`default_nettype none
// DCJ11 TangNano interface by nanja.info
// TEST2 2024.07.28 Bus read
// TSET3 2024.08.03 Start-Up config
// TEST4 2024.08.07 NXM abort signal
// TEST5 2024.08.12 Console ODT output
// TEST6 2024.08.25 Console ODT input
// TEST7 2024.08.26 2KB RAM
// TEST8 2024.08.31 4MB RAM
// TEST9 2024.09.03 Byte Data Write

module top ( 
    inout wire [15:0] dal,      // DAL<21:0>, BS<1:0>
    input wire [3:0] aio,       // AIO<3:0>
    input wire bufctl_n,
    input wire ale_n,
    output wire nxm_n,
    input wire sctl_n,
    input wire clk,
    output reg dv,
    output reg miss_n,
    output reg dallo_oe_n,
    output reg dalhi_oe_n,
    input wire rrdy,            // Ready to read from DCJ11's ODT data
    output reg rstb,            // Strobe for read from DCJ11's ODT data
    input wire wrdy,            // Ready to write to DCJ11's ODT data
    output reg wstb,            // Strobe for write to DCJ11's ODT data
    inout wire [7:0] ad,        // ODT data
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

logic sclk;
Gowin_OSC osc(
    .oscout(sclk) //output oscout
);

logic clk_x4;   // clk x 4 = 72MHz
logic clk_x2;   // clk x 2 = 36MHz
Gowin_rPLL rpll(
    .clkout(clk_x4), //output clkout
    .clkoutd(clk_x2), //output clkoutd
    .clkin(clk) //input clkin
);

logic [7:0] count;
logic [15:0] mdallo;
logic [21:0] mdal;
logic [3:0] maio;
logic [1:0] mbs;
logic [7:0] gp_code;
//always_ff@(negedge clk_x2) begin
//    if (ale_n) begin
//        count <= 0;
//    end else begin
//        if (count == 8'd0) begin
//            dallo_oe_n <= 1'b1;
//            dalhi_oe_n <= 1'b0;
//            if ((aio == GP_READ) || (aio == GP_WRITE)) begin
//                gp_code <= dal[7:0];
//            end else begin
//                gp_code <= 8'b11111111;
//            end
//            mdallo <= dal;
//        end else if (count == 8'd1) begin
//            maio <= aio;
//            mbs[0] <= dal[6];
//            mbs[1] <= dal[7];
//            mdal[21] <= dal[8];
//            mdal[20] <= dal[0];
//            mdal[19] <= dal[9];
//            mdal[18] <= dal[10];
//            mdal[17] <= dal[11];
//            mdal[16] <= dal[12];
//            mdal[15:0] <= mdallo;
//            dallo_oe_n <= 1'b0;
//            dalhi_oe_n <= 1'b1;
//        end
//        count <= count + 1'b1;
//    end
//end

always_ff@(posedge clk_x2) begin
    if (ale_n) begin
        count <= 0;
    end else begin
        count <= count + 1'b1;
    end
end

always_ff@(negedge clk_x2) begin
    if (count == 8'd1) begin
        dallo_oe_n <= 1'b1;
        dalhi_oe_n <= 1'b0;
        if ((aio == GP_READ) || (aio == GP_WRITE)) begin
            gp_code <= dal[7:0];
        end else begin
            gp_code <= 8'b11111111;
        end
        mdallo <= dal;
    end else if (count == 8'd2) begin
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
        dallo_oe_n <= 1'b0;
        dalhi_oe_n <= 1'b1;
    end
end

always_ff@(negedge bufctl_n) begin
    if ((gp_code == POWER_UP0) || (gp_code == POWER_UP2)) begin
        dal_out <= 16'b0000000_0_0000_0_01_1;
                // BOOT_ADDRESS, FPE, UNUSED, HALT, MODE, POK
    end else begin
        dal_out <= 0;
    end
end

assign nxm_n = sctl_n ? 1'b1 : !nxm;
logic nxm;
always_ff@(negedge sctl_n) begin
    if ((maio[3:2] == 2'b10) || (maio[3:2] == 2'b00)) begin
//         RMW_BUSLOCK, RMW_NOLOCK, DATA_READ, DEMAND_READ, WORD_WRITE, BYTE_WRITE
        if (mbs == BS_MEM) begin
            if (mdal >= 22'o17760000) begin
                nxm <= 1'b1;
            end
        end
        if (mbs == BS_EXT) begin
            if ((mdal[21:3] == DLART) || (mdal[21:3] == PC11)) begin
                nxm <= 1'b0;
            end else begin
                nxm <= 1'b1;
            end
        end
    end else begin
        nxm <= 1'b0;
    end
end

logic rxrdy;
logic rrdy1;
logic rrdy0;
logic [7:0] rdata;
always_ff@(negedge clk) begin
    rrdy0 <= rrdy;
    rrdy1 <= rrdy0;
end

always_ff@(negedge clk) begin
    if ((sctl_n == 0) && (mdal == XBUF)) begin
        rstb <= 1'b1;
        rxrdy <= 1'b0;
        rdata <= dal[7:0];
    end else if (!rrdy1) begin
        rstb <= 1'b0;
    end else if (!rstb) begin
        rxrdy <= 1'b1;
    end
    if (gp_code == 8'o014) begin
        rxrdy <= 1'b1;
        rstb <= 1'b0;
    end
end

assign ad = rstb ? rdata : 8'bz;

logic wxrdy;
logic wrdy1;
logic wrdy0;
logic [7:0] wdata;
always_ff@(negedge clk) begin
    wrdy0 <= wrdy;
    wrdy1 <= wrdy0;
end

always_ff@(negedge clk) begin
    if (wrdy1) begin
        wstb <= 1'b1;
    end else if (wstb) begin
        wdata <= ad;
        wstb <= 1'b0;
        wxrdy <= 1'b1;
    end else if ((mdal == RBUF) && (!sctl_n)) begin
        wxrdy <= 1'b0;
    end
    if (gp_code == 8'o014) begin
        wxrdy <= 1'b0;
        wstb <= 1'b0;
    end
end

logic [15:0] dal_out;
logic [15:0] odt_out;
logic [15:0] mem_out;
assign dal = bufctl_n ? 16'bz : dal_out | odt_out | mem_out;

always_ff@(negedge bufctl_n) begin
    if ((maio == DATA_READ) && (mbs == BS_EXT)) begin
        case (mdal)
            RCSR : odt_out <= {8'b0, wxrdy, 7'b0};
            XCSR : odt_out <= {8'b0, rxrdy, 7'b0};
            RBUF : odt_out <= wdata;
            PRS  : odt_out <= 16'b1000_0000_0000_0000;
            PRB  : odt_out <= 16'b0;
            PPS  : odt_out <= 16'b0000_0000_1000_0000;
            default : odt_out <= 16'bz;
        endcase
    end else begin
        odt_out <= 16'bz;
    end
end

logic init;
assign led1 = init;
ram u_ram(
    .*
);

assign dv = 1'b1;
logic [21:0] ram_addr;
logic [15:0] ram_rdata;
logic [15:0] ram_wdata;
logic ram_read;
logic ram_write;
logic ram_byte;
always_ff@(posedge clk) begin
    if (mbs == BS_MEM) begin
        ram_addr <= mdal;
        if ((maio[3:2] == 2'b10) || (maio == REQUEST_READ)) begin
            miss_n <= (!ale_n && !bufctl_n) ? 1'b0 : 1'b1;
            ram_read <= (!ale_n && !bufctl_n) ? 1'b1 : 1'b0;
            mem_out <= (ale_n && !bufctl_n) ? ram_rdata : 16'bz;
        end
    end
end

always_ff@(posedge clk) begin
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
