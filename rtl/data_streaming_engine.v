`timescale 1ns/1ps

// Shallow system-level DMA data streaming engine.
//
// Main functional path:
//   Descriptor Manager -> DMA Read -> AXI-Stream Register Slice
//   -> DMA Write -> Destination RAM
//
// The other AXI-Stream blocks in rtl/bus are kept as independent reusable
// building blocks and are not forced into this first integration.
module data_streaming_engine #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LEN_WIDTH  = 16,
    parameter MEM_DEPTH  = 1024
)(
    input wire clk,
    input wire rst_n,

    // Simple CPU-side descriptor input
    input wire [ADDR_WIDTH-1:0] src_addr,
    input wire [ADDR_WIDTH-1:0] dst_addr,
    input wire [LEN_WIDTH-1:0]  transfer_len,
    input wire                  descriptor_valid,

    output wire busy,
    output reg  done,

    // Source RAM preload interface (use only while idle)
    input wire [ADDR_WIDTH-1:0] src_mem_addr,
    input wire [DATA_WIDTH-1:0] src_mem_wdata,
    input wire                  src_mem_we,

    // Destination RAM readback interface
    input wire [ADDR_WIDTH-1:0] dst_mem_addr,
    output wire [DATA_WIDTH-1:0] dst_mem_rdata
);

    // -------------------------------------------------------------------------
    // Descriptor manager
    // -------------------------------------------------------------------------
    wire desc_valid;
    wire [ADDR_WIDTH-1:0] desc_src;
    wire [ADDR_WIDTH-1:0] desc_dst;
    wire [LEN_WIDTH-1:0]  desc_len;
    reg  desc_clear;

    dma_descriptor_manager #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .LEN_WIDTH(LEN_WIDTH)
    ) u_descriptor_manager (
        .clk(clk),
        .rst_n(rst_n),
        .descriptor_valid(descriptor_valid),
        .src_addr(src_addr),
        .dst_addr(dst_addr),
        .transfer_len(transfer_len),
        .descriptor_valid_out(desc_valid),
        .dma_src_addr(desc_src),
        .dma_dst_addr(desc_dst),
        .dma_transfer_len(desc_len),
        .descriptor_clear(desc_clear)
    );

    // -------------------------------------------------------------------------
    // Internal interconnect declarations
    // Keep all nets declared before they are used by instances.
    // -------------------------------------------------------------------------
    reg transfer_active;
    wire start_transfer;

    wire [ADDR_WIDTH-1:0] read_ram_addr;
    wire [DATA_WIDTH-1:0] read_ram_rdata;
    wire [DATA_WIDTH-1:0] read_axis_tdata;
    wire read_axis_tvalid;
    wire read_axis_tready;
    wire read_done;

    wire [DATA_WIDTH-1:0] stream_tdata;
    wire stream_tvalid;
    wire stream_tready;

    wire [ADDR_WIDTH-1:0] write_ram_addr;
    wire [DATA_WIDTH-1:0] write_ram_wdata;
    wire write_ram_we;
    wire write_done;

    wire [ADDR_WIDTH-1:0] src_ram_addr_i;
    wire src_ram_we_i;
    wire [DATA_WIDTH-1:0] src_ram_wdata_i;
    wire [ADDR_WIDTH-1:0] dst_ram_addr_i;
    wire [DATA_WIDTH-1:0] dst_ram_wdata_i;
    wire dst_ram_we_i;

    assign start_transfer = desc_valid && !transfer_active;
    assign busy = transfer_active;

    // -------------------------------------------------------------------------
    // DMA read engine
    // -------------------------------------------------------------------------

    dma_read_engine #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LEN_WIDTH(LEN_WIDTH)
    ) u_dma_read (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_transfer),
        .src_addr(desc_src),
        .transfer_length(desc_len),
        .ram_addr(read_ram_addr),
        .ram_rdata(read_ram_rdata),
        .m_axis_tdata(read_axis_tdata),
        .m_axis_tvalid(read_axis_tvalid),
        .m_axis_tready(read_axis_tready),
        .busy(),
        .done(read_done)
    );

    // -------------------------------------------------------------------------
    // One AXI-Stream register slice keeps the first integration shallow.
    // -------------------------------------------------------------------------
    axi_stream_register_slice #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_register_slice (
        .clk(clk),
        .rst_n(rst_n),
        .s_axis_tdata(read_axis_tdata),
        .s_axis_tvalid(read_axis_tvalid),
        .s_axis_tready(read_axis_tready),
        .m_axis_tdata(stream_tdata),
        .m_axis_tvalid(stream_tvalid),
        .m_axis_tready(stream_tready)
    );

    // -------------------------------------------------------------------------
    // DMA write engine
    // -------------------------------------------------------------------------
    dma_write_engine #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LEN_WIDTH(LEN_WIDTH)
    ) u_dma_write (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_transfer),
        .dst_addr(desc_dst),
        .transfer_length(desc_len),
        .s_axis_tdata(stream_tdata),
        .s_axis_tvalid(stream_tvalid),
        .s_axis_tready(stream_tready),
        .ram_addr(write_ram_addr),
        .ram_wdata(write_ram_wdata),
        .ram_we(write_ram_we),
        .busy(),
        .done(write_done)
    );

    // -------------------------------------------------------------------------
    // Source RAM
    // -------------------------------------------------------------------------
    // Include start_transfer so the RAM address mux switches on the same cycle
    // the read engine first presents its address (avoids a 1-cycle lag).
    assign src_ram_addr_i  = (transfer_active || start_transfer) ? read_ram_addr : src_mem_addr;
    assign src_ram_we_i    = (!(transfer_active || start_transfer)) && src_mem_we;
    assign src_ram_wdata_i = src_mem_wdata;

    ram_sp #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(MEM_DEPTH)
    ) u_source_ram (
        .clk(clk),
        .rst_n(rst_n),
        .addr(src_ram_addr_i),
        .wdata(src_ram_wdata_i),
        .we(src_ram_we_i),
        .rdata(read_ram_rdata)
    );

    // -------------------------------------------------------------------------
    // Destination RAM
    // -------------------------------------------------------------------------
    assign dst_ram_addr_i  = (transfer_active || start_transfer) ? write_ram_addr : dst_mem_addr;
    assign dst_ram_wdata_i = write_ram_wdata;
    assign dst_ram_we_i    = (transfer_active || start_transfer) && write_ram_we;

    ram_sp #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(MEM_DEPTH)
    ) u_destination_ram (
        .clk(clk),
        .rst_n(rst_n),
        .addr(dst_ram_addr_i),
        .wdata(dst_ram_wdata_i),
        .we(dst_ram_we_i),
        .rdata(dst_mem_rdata)
    );

    // -------------------------------------------------------------------------
    // Transfer control
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            transfer_active <= 1'b0;
            desc_clear      <= 1'b0;
            done            <= 1'b0;
        end else begin
            desc_clear <= 1'b0;
            done       <= 1'b0;

            if (start_transfer) begin
                if (desc_len == 0) begin
                    // Treat an empty descriptor as an immediate completion.
                    desc_clear <= 1'b1;
                    done       <= 1'b1;
                end else begin
                    transfer_active <= 1'b1;
                end
            end

            if (write_done) begin
                transfer_active <= 1'b0;
                desc_clear      <= 1'b1;
                done            <= 1'b1;
            end
        end
    end
endmodule
