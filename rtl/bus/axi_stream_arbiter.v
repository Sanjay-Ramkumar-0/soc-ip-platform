// We are using 2 input fixed priority arbitration policy
//Priority 0> Priority 1
`timescale 1ns/1ps
module axi_stream_arbiter #
(
    parameter DATA_WIDTH = 32
)
(
    //Slave AXI Stream interface 0
    input wire [DATA_WIDTH - 1: 0] s0_axis_tdata,
    input wire s0_axis_tvalid,
    output wire s0_axis_tready,
    //Slave AXI Stream interface 1
    input wire [DATA_WIDTH - 1: 0] s1_axis_tdata,
    input wire s1_axis_tvalid,
    output wire s1_axis_tready,
    //Master AXI Stream interface
    output wire [DATA_WIDTH - 1: 0] m_axis_tdata,
    output wire m_axis_tvalid,
    input wire m_axis_tready
);

wire select_s0;
wire select_s1;
assign select_s0 = s0_axis_tvalid;
assign select_s1 = (~s0_axis_tvalid) && s1_axis_tvalid;

//Output multiplexer
assign m_axis_tdata = 
    select_s0 ? s0_axis_tdata : 
    select_s1 ? s1_axis_tdata : {DATA_WIDTH{1'b0}};
assign m_axis_tvalid = select_s0 || select_s1;

//Ready propagation
assign s0_axis_tready = select_s0 && m_axis_tready;
assign s1_axis_tready = select_s1 && m_axis_tready;


endmodule
