`default_nettype none
// PSRAM interface module
// TEST8 2024.08.31 4MB RAM

module ram (
    output wire [1:0] O_psram_ck,
    output wire [1:0] O_psram_ck_n,
    inout wire [15:0] IO_psram_dq,
    inout wire [1:0] IO_psram_rwds,
    output wire [1:0] O_psram_cs_n,
    output wire [1:0] O_psram_reset_n,
    input wire ram_read,
    input wire ram_write,
    input wire ram_byte,
    input wire [21:0] ram_addr,
    output reg [15:0] ram_rdata,
    input wire [15:0] ram_wdata,
    input wire mclk
);

Gowin_rPLL_ram pll_ram(
    .clkout(memory_clk), //output clkout
    .lock(pll_lock), //output lock
    .clkoutp(memory_clk_p), //output clkoutp
    .clkoutd(clk_d), //output clkoutd
    .clkin(mclk) //input clkin
);

logic clk_d;
logic rst_n;
logic memory_clk;
logic memory_clk_p;
logic pll_lock;
logic init_calib0;
logic init_calib1;
logic clk_out;
logic cmd0;
logic cmd1;
logic cmd_en0;
logic cmd_en1;
logic [20:0] addr0;
logic [20:0] addr1;
logic [31:0] wr_data0;
logic [31:0] wr_data1;
logic [31:0] rd_data0;
logic [31:0] rd_data1;
logic rd_data_valid0;
logic rd_data_valid1;
logic [3:0] data_mask0;
logic [3:0] data_mask1;

assign rst_n = 1'b1;
assign cmd1 = 1'b0;
assign cmd_en1 = 1'b0;
assign addr1 = 21'b0;
assign wr_data1 = 32'b0;
assign data_mask1 = 4'b0;

PSRAM_Memory_Interface_HS_2CH_V2_Top psram(
    .clk_d(clk_d), //input clk_d
    .rst_n(rst_n), //input rst_n
    .memory_clk(memory_clk), //input memory_clk
    .memory_clk_p(memory_clk_p), //input memory_clk_p
    .pll_lock(pll_lock), //input pll_lock
    .O_psram_ck(O_psram_ck), //output [1:0] O_psram_ck
    .O_psram_ck_n(O_psram_ck_n), //output [1:0] O_psram_ck_n
    .IO_psram_rwds(IO_psram_rwds), //inout [1:0] IO_psram_rwds
    .O_psram_reset_n(O_psram_reset_n), //output [1:0] O_psram_reset_n
    .IO_psram_dq(IO_psram_dq), //inout [15:0] IO_psram_dq
    .O_psram_cs_n(O_psram_cs_n), //output [1:0] O_psram_cs_n
    .init_calib0(init_calib0), //output init_calib0
    .init_calib1(init_calib1), //output init_calib1
    .clk_out(clk_out), //output clk_out
    .cmd0(cmd0), //input cmd0
    .cmd1(cmd1), //input cmd1
    .cmd_en0(cmd_en0), //input cmd_en0
    .cmd_en1(cmd_en1), //input cmd_en1
    .addr0(addr0), //input [20:0] addr0
    .addr1(addr1), //input [20:0] addr1
    .wr_data0(wr_data0), //input [31:0] wr_data0
    .wr_data1(wr_data1), //input [31:0] wr_data1
    .rd_data0(rd_data0), //output [31:0] rd_data0
    .rd_data1(rd_data1), //output [31:0] rd_data1
    .rd_data_valid0(rd_data_valid0), //output rd_data_valid0
    .rd_data_valid1(rd_data_valid1), //output rd_data_valid1
    .data_mask0(data_mask0), //input [3:0] data_mask0
    .data_mask1(data_mask1) //input [3:0] data_mask1
);

logic rd0;
logic rd1;
logic wr0;
logic wr1;
always_ff@(posedge clk_out) begin
    rd0 <= ram_read;
    rd1 <= rd0;
    wr0 <= ram_write;
    wr1 <= wr0;
end

logic [5:0] mcycle;
always_ff@(posedge clk_out or negedge rst_n) begin
    if (!rst_n) begin
        mcycle <= 0;
        wr_data0 <= 32'b0;
        cmd_en0 <= 0;
        data_mask0 <= 4'b1111;
    end else if (init_calib0) begin
        if (mcycle == 0) begin
            if (rd1) begin
                addr0 <= ram_addr[21:1];
                cmd0 <= 0;   // READ
                cmd_en0 <= 1;
                mcycle <= 1;
            end else if (wr1) begin
                if (ram_byte) begin
                    data_mask0 <= {ram_addr[0], !ram_addr[0], 2'b11};
                end else begin
                    data_mask0 <= 4'b0011;
                end
                wr_data0[31:16] <= ram_wdata;
                addr0 <= ram_addr[21:1];
                cmd0 <= 1;   // WRITE
                cmd_en0 <= 1;
                mcycle <= 15;
            end
        end else if (mcycle == 1) begin
            cmd_en0 <= 0;
            mcycle <= 2;
        end else if (mcycle < 14) begin
            mcycle <= mcycle + 1'b1;
        end else if (mcycle == 14) begin
            if (!rd1) begin
                mcycle <= 0;
            end
        end else if (mcycle == 15) begin
            cmd_en0 <= 0;
            data_mask0 <= 4'b1111;
            mcycle <= 16;
        end else if (mcycle < 28) begin
            mcycle <= mcycle + 1'b1;
        end else if (mcycle == 28) begin
            if (!wr1) begin
                mcycle <= 0;
            end
        end
    end
end

always_ff@(posedge clk_out) begin
    if (rd1) begin
        if (rd_data_valid0 && (rcycle == 1'b0)) begin
            ram_rdata <= rd_data0[31:16];
        end
    end else begin
        ram_rdata <= 16'bz;
    end
end

logic [1:0] rcycle;
always_ff@(posedge clk_out) begin
    if (mcycle == 1) begin
        rcycle <= 0;
    end else if (rd_data_valid0) begin
        rcycle <= rcycle + 1'b1;
    end
end

endmodule

`default_nettype wire
