`timescale 1ns/1ps
module axi_stream_register_slice #
(
    parameter DATA_WIDTH = 32
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

    // Internal signals
    reg [DATA_WIDTH - 1: 0] data_reg;
    reg                     valid_reg;

    // Continuous assignments for outputs
    assign m_axis_tdata  = data_reg;
    assign m_axis_tvalid = valid_reg;

    // Ready if the register is empty, OR if the master is ready to accept the current data
    assign s_axis_tready = !valid_reg || m_axis_tready;

    always @(posedge clk) begin
        if (!rst_n) begin
            data_reg  <= {DATA_WIDTH{1'b0}};
            valid_reg <= 1'b0;
        end
        else begin
            if (s_axis_tready) begin
                valid_reg <= s_axis_tvalid;
                if (s_axis_tvalid) begin
                    data_reg <= s_axis_tdata; // Only gate data when valid to save dynamic power
                end
            end
        end
    end

endmodule
