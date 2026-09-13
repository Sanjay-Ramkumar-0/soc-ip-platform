`timescale 1ns/1ps
// A descriptor is simply a job description for the DMA, it has source address,
// destination address and transfer length. The descriptor manager is responsible
// for storing the descriptor and providing it to the DMA controller when requested.
module dma_descriptor_manager #
(
    parameter ADDR_WIDTH = 32,
    parameter LEN_WIDTH  = 16
)
(
    input wire clk,
    input wire rst_n,
    // Descriptor write interface (CPU -> DMA)
    input wire descriptor_valid,
    input wire [ADDR_WIDTH-1:0] src_addr,
    input wire [ADDR_WIDTH-1:0] dst_addr,
    input wire [LEN_WIDTH-1:0] transfer_len,
    // Descriptor read interface (DMA controller)
    output wire descriptor_valid_out,
    output wire [ADDR_WIDTH-1:0] dma_src_addr,
    output wire [ADDR_WIDTH-1:0] dma_dst_addr,
    output wire [LEN_WIDTH-1:0] dma_transfer_len,
    // control interface
    input wire descriptor_clear
);

    // Internal registers
    reg [ADDR_WIDTH-1:0] src_addr_reg;
    reg [ADDR_WIDTH-1:0] dst_addr_reg;
    reg [LEN_WIDTH-1:0]  transfer_len_reg;
    reg                  descriptor_valid_reg;

    // Output connections
    assign dma_src_addr     = src_addr_reg;
    assign dma_dst_addr     = dst_addr_reg;
    assign dma_transfer_len = transfer_len_reg;

    // Force valid_out low while clear is asserted so that start_transfer
    // cannot re-fire in the one-cycle window after transfer_active drops
    // but before the registered valid is cleared.
    assign descriptor_valid_out = descriptor_valid_reg && !descriptor_clear;

    // Descriptor storage: clear has priority over a new load.
    always @(posedge clk) begin
        if (!rst_n) begin
            src_addr_reg         <= {ADDR_WIDTH{1'b0}};
            dst_addr_reg         <= {ADDR_WIDTH{1'b0}};
            transfer_len_reg     <= {LEN_WIDTH{1'b0}};
            descriptor_valid_reg <= 1'b0;
        end else begin
            if (descriptor_clear) begin
                descriptor_valid_reg <= 1'b0;
            end else if (descriptor_valid) begin
                src_addr_reg         <= src_addr;
                dst_addr_reg         <= dst_addr;
                transfer_len_reg     <= transfer_len;
                descriptor_valid_reg <= 1'b1;
            end
        end
    end
endmodule
