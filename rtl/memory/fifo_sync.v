`timescale 1ns/1ps
module fifo_sync#
(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = 4,
    parameter ALMOST_FULL_LEVEL = DEPTH - 2,
    parameter ALMOST_EMPTY_LEVEL = 2
)
(
    //Clock and reset
    input clk,
    input rst_n,

    //Write interface
    input wr_en,
    input [DATA_WIDTH-1:0] din,

    //Read interface
    input rd_en,
    output reg [DATA_WIDTH-1:0] dout,

    //Status outputs
    output full,
    output empty,
    output almost_full,
    output almost_empty,
    output reg overflow,
    output reg underflow,
    output [ADDR_WIDTH:0] data_count
);

//Internal memory
reg [DATA_WIDTH-1:0] fifo_mem [0:DEPTH-1];

//Internal registers
reg [ADDR_WIDTH-1:0] wr_ptr;
reg [ADDR_WIDTH-1:0] rd_ptr;
reg [ADDR_WIDTH:0] fifo_count;

//Control signals
wire do_write;
wire do_read;

//Status logic
assign full = (fifo_count == DEPTH);
assign empty = (fifo_count == 0);
assign almost_full = (fifo_count >= ALMOST_FULL_LEVEL);
assign almost_empty = (fifo_count <= ALMOST_EMPTY_LEVEL);
assign data_count = fifo_count;

//Control logic
assign do_write = wr_en & ~full;
assign do_read = rd_en & ~empty;

//Sequential logic
always@(posedge clk)
begin
    
    //Reset
    if(!rst_n)
    begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        fifo_count <= 0;
        dout <= 0;
        overflow <= 0;
        underflow <= 0; 
    end

    //Normal operation
    else
    begin
        //Default pulse flags
        overflow <= 0;
        underflow <= 0;

        //Overflow detection
        if(wr_en & full)
            overflow <= 1;
        
        //Underflow detection
        if(rd_en & empty)
            underflow <= 1;
        
        //Write operation
        if(do_write)
        begin
            fifo_mem[wr_ptr] <= din;
            if(wr_ptr == DEPTH - 1)
                wr_ptr <= 0;
            else
                wr_ptr <= wr_ptr + 1; 
        end

        //Read operation
        if(do_read)
        begin
            dout <= fifo_mem[rd_ptr];
            if(rd_ptr == DEPTH - 1)
                rd_ptr <= 0;
            else
                rd_ptr <= rd_ptr + 1;   
        end

        //Occupancy counter
        case({do_write, do_read})
            2'b10: fifo_count <= fifo_count + 1; //Write only
            2'b01: fifo_count <= fifo_count - 1; //Read only
            default: fifo_count <= fifo_count; //No change or simultaneous read/write
        endcase
    end
end

endmodule
