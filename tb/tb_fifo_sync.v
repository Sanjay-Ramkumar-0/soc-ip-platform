`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Project : SoC IP Platform
// Module  : tb_fifo_sync
//
// Description:
// Self-checking testbench for fifo_sync
//
//////////////////////////////////////////////////////////////////////////////////

module tb_fifo_sync;

///////////////////////////////////////////////////////////////
// Parameters
///////////////////////////////////////////////////////////////

parameter DATA_WIDTH         = 8;
parameter DEPTH              = 16;
parameter ADDR_WIDTH         = 4;
parameter ALMOST_FULL_LEVEL  = DEPTH - 2;
parameter ALMOST_EMPTY_LEVEL = 2;

///////////////////////////////////////////////////////////////
// Testbench Signals
///////////////////////////////////////////////////////////////

reg clk;
reg rst_n;

reg wr_en;
reg rd_en;

reg [DATA_WIDTH-1:0] din;

wire [DATA_WIDTH-1:0] dout;

wire full;
wire empty;
wire almost_full;
wire almost_empty;
wire overflow;
wire underflow;
wire [ADDR_WIDTH:0] data_count;

///////////////////////////////////////////////////////////////
// Device Under Test
///////////////////////////////////////////////////////////////

fifo_sync #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .ALMOST_FULL_LEVEL(ALMOST_FULL_LEVEL),
    .ALMOST_EMPTY_LEVEL(ALMOST_EMPTY_LEVEL)
)
dut
(
    .clk(clk),
    .rst_n(rst_n),

    .wr_en(wr_en),
    .rd_en(rd_en),

    .din(din),
    .dout(dout),

    .full(full),
    .empty(empty),
    .almost_full(almost_full),
    .almost_empty(almost_empty),

    .overflow(overflow),
    .underflow(underflow),

    .data_count(data_count)
);

///////////////////////////////////////////////////////////////
// Clock Generator (100 MHz)
///////////////////////////////////////////////////////////////

initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end

///////////////////////////////////////////////////////////////
// Waveform Dump
///////////////////////////////////////////////////////////////

initial
begin
    $dumpfile("fifo_sync.vcd");
    $dumpvars(0, tb_fifo_sync);
end

///////////////////////////////////////////////////////////////
// Reset Task
///////////////////////////////////////////////////////////////

task fifo_reset;
begin

    rst_n = 0;
    wr_en = 0;
    rd_en = 0;
    din   = 0;

    repeat(2) @(posedge clk);

    rst_n = 1;

    @(posedge clk);

end
endtask

///////////////////////////////////////////////////////////////
// Write Task
///////////////////////////////////////////////////////////////

task fifo_write;

input [DATA_WIDTH-1:0] data;

begin

    @(posedge clk);

    wr_en = 1;
    rd_en = 0;
    din   = data;

    @(posedge clk);

    wr_en = 0;

end

endtask

///////////////////////////////////////////////////////////////
// Read Task
///////////////////////////////////////////////////////////////

task fifo_read;

begin

    @(posedge clk);

    wr_en = 0;
    rd_en = 1;

    @(posedge clk);

    rd_en = 0;

end

endtask

///////////////////////////////////////////////////////////////
// Main Test Sequence
///////////////////////////////////////////////////////////////

integer i;

initial
begin

    $display("");
    $display("======================================");
    $display("  FIFO SYNCHRONOUS TESTBENCH");
    $display("======================================");

    //----------------------------------------------------------
    // Reset
    //----------------------------------------------------------

    fifo_reset();

    if(empty)
        $display("PASS : Reset");
    else
        $display("FAIL : Reset");

    //----------------------------------------------------------
    // Single Write
    //----------------------------------------------------------

    fifo_write(8'hAA);

    if(data_count == 1)
        $display("PASS : Single Write");
    else
        $display("FAIL : Single Write");

    //----------------------------------------------------------
    // Single Read
    //----------------------------------------------------------

    fifo_read();

    if(dout == 8'hAA)
        $display("PASS : Single Read");
    else
        $display("FAIL : Single Read");

    //----------------------------------------------------------
    // Fill FIFO
    //----------------------------------------------------------

    for(i=0;i<DEPTH;i=i+1)
        fifo_write(i);

    if(full)
        $display("PASS : Full Flag");
    else
        $display("FAIL : Full Flag");

    //----------------------------------------------------------
    // Overflow Test
    //----------------------------------------------------------

    fifo_write(8'hFF);

    if(overflow)
        $display("PASS : Overflow");
    else
        $display("FAIL : Overflow");

    //----------------------------------------------------------
    // Empty FIFO
    //----------------------------------------------------------

    for(i=0;i<DEPTH;i=i+1)
        fifo_read();

    if(empty)
        $display("PASS : Empty Flag");
    else
        $display("FAIL : Empty Flag");

    //----------------------------------------------------------
    // Underflow Test
    //----------------------------------------------------------

    fifo_read();

    if(underflow)
        $display("PASS : Underflow");
    else
        $display("FAIL : Underflow");

    //----------------------------------------------------------
    // Almost Full
    //----------------------------------------------------------

    fifo_reset();

    for(i=0;i<ALMOST_FULL_LEVEL;i=i+1)
        fifo_write(i);

    if(almost_full)
        $display("PASS : Almost Full");
    else
        $display("FAIL : Almost Full");

    //----------------------------------------------------------
    // Almost Empty
    //----------------------------------------------------------

    while(data_count > ALMOST_EMPTY_LEVEL)
        fifo_read();

    if(almost_empty)
        $display("PASS : Almost Empty");
    else
        $display("FAIL : Almost Empty");

    //----------------------------------------------------------
    // End Simulation
    //----------------------------------------------------------

    $display("");
    $display("======================================");
    $display("Simulation Complete");
    $display("======================================");

    #20;

    $finish;

end

endmodule