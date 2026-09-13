`timescale 1ns/1ps

module axi_stream_switch #
(
    parameter DATA_WIDTH = 32
)
(
    input wire [DATA_WIDTH - 1: 0] s_axis_tdata,
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    output wire [DATA_WIDTH - 1: 0] m0_axis_tdata,
    output wire m0_axis_tvalid,
    input wire m0_axis_tready,
    output wire [DATA_WIDTH - 1: 0] m1_axis_tdata,
    output wire m1_axis_tvalid,
    input wire m1_axis_tready,
    input wire select
);
assign m0_axis_tdata = s_axis_tdata;
assign m1_axis_tdata = s_axis_tdata;
assign m0_axis_tvalid = s_axis_tvalid && select;
assign m1_axis_tvalid = s_axis_tvalid && (~select);
assign s_axis_tready =
        (!select) ? m0_axis_tready :
                    m1_axis_tready;
endmodule
