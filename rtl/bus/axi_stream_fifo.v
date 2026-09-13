`timescale 1ns/1ps
module axi_stream_fifo #
(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)
(
    input wire clk,
    input wire rst_n,

    // Slave AXI Stream interface
    input wire [DATA_WIDTH - 1: 0] s_axis_tdata,
    input wire                     s_axis_tvalid,
    output wire                    s_axis_tready,

    // Master AXI Stream interface
    output wire [DATA_WIDTH - 1: 0] m_axis_tdata,
    output wire                     m_axis_tvalid,
    input wire                      m_axis_tready
);

    // Internal FIFO signals
    wire [DATA_WIDTH - 1: 0] fifo_dout;
    wire                     fifo_full;
    wire                     fifo_empty;
    wire                     fifo_almost_full;
    wire                     fifo_almost_empty;
    wire                     fifo_overflow;
    wire                     fifo_underflow;
    wire [ADDR_WIDTH:0]      fifo_data_count;
    
    wire                     fifo_wr_en;
    reg                      fifo_rd_en; // Changed to reg to match always block

    // Output buffer registers
    reg [DATA_WIDTH - 1: 0]  m_data_reg;
    reg                      m_valid_reg;

    // Slave Handshake logic
    assign s_axis_tready = !fifo_full;
    assign fifo_wr_en    = s_axis_tvalid && s_axis_tready;

    // Connect Master interface directly to your output registers
    assign m_axis_tdata  = m_data_reg;
    assign m_axis_tvalid = m_valid_reg;

    // Output buffer controller
    always @(posedge clk) begin
        if (!rst_n) begin
            fifo_rd_en  <= 1'b0;
            m_valid_reg <= 1'b0;
            m_data_reg  <= {DATA_WIDTH{1'b0}};
        end
        else begin
            // Default: clear read enable unless explicitly set below
            fifo_rd_en <= 1'b0;

            // 1. Handle downstream consumer acceptance
            if (m_valid_reg && m_axis_tready) begin
                m_valid_reg <= 1'b0;
            end
            
            // 2. Request next word from FIFO if:
            // - The FIFO has data AND
            // - The output register is currently empty (or about to be cleared) AND
            // - We haven't already issued a read command on the previous cycle
            if (!fifo_empty && (!m_valid_reg || m_axis_tready) && !fifo_rd_en) begin
                fifo_rd_en <= 1'b1;
            end
            
            // 3. Capture FIFO data 1 clock cycle after fifo_rd_en was asserted
            if (fifo_rd_en) begin
                m_data_reg  <= fifo_dout;
                m_valid_reg <= 1'b1;
            end
        end
    end

    // Instantiate the synchronous FIFO
    fifo_sync #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    )
    u_fifo
    (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(fifo_wr_en),
        .din(s_axis_tdata),
        .rd_en(fifo_rd_en),
        .dout(fifo_dout),
        .full(fifo_full),
        .empty(fifo_empty),
        .almost_full(fifo_almost_full),
        .almost_empty(fifo_almost_empty),
        .overflow(fifo_overflow),
        .underflow(fifo_underflow),
        .data_count(fifo_data_count)
    );

endmodule

