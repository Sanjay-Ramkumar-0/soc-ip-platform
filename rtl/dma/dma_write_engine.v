`timescale 1ns/1ps

// Simple DMA write engine for a synchronous-write RAM.
// transfer_length is expressed in bytes.
module dma_write_engine #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LEN_WIDTH  = 16
)(
    input wire clk,
    input wire rst_n,

    input wire start,
    input wire [ADDR_WIDTH-1:0] dst_addr,
    input wire [LEN_WIDTH-1:0]  transfer_length,

    input wire [DATA_WIDTH-1:0] s_axis_tdata,
    input wire                  s_axis_tvalid,
    output wire                 s_axis_tready,

    output wire [ADDR_WIDTH-1:0] ram_addr,
    output wire [DATA_WIDTH-1:0] ram_wdata,
    output wire                  ram_we,

    output reg busy,
    output reg done
);

    localparam [LEN_WIDTH-1:0] BYTES_PER_WORD = DATA_WIDTH / 8;

    reg [ADDR_WIDTH-1:0] current_addr;
    reg [LEN_WIDTH-1:0]  bytes_remaining;

    // A word is accepted only while a transfer is active.
    assign s_axis_tready = busy && (bytes_remaining != 0);

    // These signals are deliberately combinational so the RAM sees the
    // address/data for the same cycle in which the AXI beat is accepted.
    assign ram_addr  = current_addr;
    assign ram_wdata = s_axis_tdata;
    assign ram_we    = s_axis_tvalid && s_axis_tready;

    always @(posedge clk) begin
        if (!rst_n) begin
            current_addr    <= {ADDR_WIDTH{1'b0}};
            bytes_remaining <= {LEN_WIDTH{1'b0}};
            busy            <= 1'b0;
            done            <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                current_addr    <= dst_addr;
                bytes_remaining <= transfer_length;
                busy            <= (transfer_length != 0);
            end
            else if (busy && s_axis_tvalid && s_axis_tready) begin
                if (bytes_remaining <= BYTES_PER_WORD) begin
                    bytes_remaining <= 0;
                    busy            <= 1'b0;
                    done            <= 1'b1;
                end else begin
                    bytes_remaining <= bytes_remaining - BYTES_PER_WORD;
                    current_addr    <= current_addr + BYTES_PER_WORD;
                end
            end
        end
    end
endmodule
