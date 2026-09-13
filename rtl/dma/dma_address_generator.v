//Generates the next memory address for each data transfer
`timescale 1ns/1ps
module dma_address_generator #(
    parameter ADDR_WIDTH = 32,
    parameter [ADDR_WIDTH-1:0] ADDR_INCREMENT = 4
)
(
    input wire clk,
    input wire rst_n,
    //Load interface
    input wire load_address,
    input wire [ADDR_WIDTH-1:0] start_address,
    //increment
    input wire increment_address,
    //Output interface
    output wire [ADDR_WIDTH-1:0] current_address
);
//Internal register
reg [ADDR_WIDTH-1:0] address_reg;
assign current_address = address_reg;
always@(posedge clk)begin
    if(!rst_n)
        address_reg <= {ADDR_WIDTH{1'b0}};
    else if (load_address)
        address_reg <= start_address;
    else if (increment_address)
        address_reg <= address_reg + ADDR_INCREMENT;
end

endmodule
