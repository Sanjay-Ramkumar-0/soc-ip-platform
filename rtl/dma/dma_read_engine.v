`timescale 1ns/1ps

// Simple DMA read engine for a synchronous-read RAM.
// transfer_length is expressed in bytes.
module dma_read_engine #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LEN_WIDTH  = 16
)(
    input wire clk,
    input wire rst_n,

    input wire start,
    input wire [ADDR_WIDTH-1:0] src_addr,
    input wire [LEN_WIDTH-1:0]  transfer_length,

    output reg  [ADDR_WIDTH-1:0] ram_addr,
    input  wire [DATA_WIDTH-1:0] ram_rdata,

    output reg  [DATA_WIDTH-1:0] m_axis_tdata,
    output reg                   m_axis_tvalid,
    input  wire                  m_axis_tready,

    output reg busy,
    output reg done
);

    localparam [LEN_WIDTH-1:0] BYTES_PER_WORD = DATA_WIDTH / 8;
    localparam ST_IDLE  = 2'd0;
    localparam ST_WAIT1 = 2'd1;
    localparam ST_WAIT2 = 2'd2;
    localparam ST_SEND  = 2'd3;

    reg [1:0] state;
    reg [ADDR_WIDTH-1:0] current_addr;
    reg [LEN_WIDTH-1:0]  bytes_remaining;

    always @(posedge clk) begin
        if (!rst_n) begin
            state           <= ST_IDLE;
            current_addr    <= {ADDR_WIDTH{1'b0}};
            bytes_remaining <= {LEN_WIDTH{1'b0}};
            ram_addr        <= {ADDR_WIDTH{1'b0}};
            m_axis_tdata    <= {DATA_WIDTH{1'b0}};
            m_axis_tvalid   <= 1'b0;
            busy            <= 1'b0;
            done            <= 1'b0;
        end else begin
            done <= 1'b0;

            case (state)
                ST_IDLE: begin
                    busy          <= 1'b0;
                    m_axis_tvalid <= 1'b0;

                    if (start && (transfer_length != 0)) begin
                        current_addr    <= src_addr;
                        bytes_remaining <= transfer_length;
                        ram_addr        <= src_addr;
                        busy            <= 1'b1;
                        state           <= ST_WAIT1;
                    end
                end

                // Allow the synchronous RAM to see the new address.
                ST_WAIT1: begin
                    busy  <= 1'b1;
                    state <= ST_WAIT2;
                end

                // RAM output is now valid after this clock edge.
                ST_WAIT2: begin
                    busy          <= 1'b1;
                    m_axis_tdata  <= ram_rdata;
                    m_axis_tvalid <= 1'b1;
                    state         <= ST_SEND;
                end

                ST_SEND: begin
                    busy <= 1'b1;

                    // Advance only on a real AXI-Stream transfer.
                    if (m_axis_tvalid && m_axis_tready) begin
                        m_axis_tvalid <= 1'b0;

                        if (bytes_remaining <= BYTES_PER_WORD) begin
                            bytes_remaining <= 0;
                            busy            <= 1'b0;
                            done            <= 1'b1;
                            state           <= ST_IDLE;
                        end else begin
                            bytes_remaining <= bytes_remaining - BYTES_PER_WORD;
                            current_addr    <= current_addr + BYTES_PER_WORD;
                            ram_addr        <= current_addr + BYTES_PER_WORD;
                            state           <= ST_WAIT1;
                        end
                    end
                end

                default: begin
                    state <= ST_IDLE;
                    busy  <= 1'b0;
                end
            endcase
        end
    end
endmodule
