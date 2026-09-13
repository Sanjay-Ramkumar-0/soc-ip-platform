`timescale 1ns/1ps

module tb_ram_sp;
    reg clk, rst_n, we;
    reg [31:0] addr, wdata;
    wire [31:0] rdata;
    integer errors;

    ram_sp #(.ADDR_WIDTH(32), .DATA_WIDTH(32), .DEPTH(16)) dut (
        .clk(clk), .rst_n(rst_n), .addr(addr), .wdata(wdata), .we(we), .rdata(rdata)
    );

    always #5 clk = ~clk;

    task write_word;
        input [31:0] a;
        input [31:0] d;
        begin
            @(negedge clk); addr=a; wdata=d; we=1'b1;
            @(posedge clk);
            @(negedge clk); we=1'b0;
        end
    endtask

    task read_check;
        input [31:0] a;
        input [31:0] expected;
        begin
            @(negedge clk); addr=a; we=1'b0;
            @(posedge clk); #1;
            if (rdata === expected)
                $display("RAM PASS: addr=0x%08h data=0x%08h", a, rdata);
            else begin
                $display("RAM FAIL: addr=0x%08h expected=0x%08h got=0x%08h", a, expected, rdata);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        clk=0; rst_n=0; we=0; addr=0; wdata=0; errors=0;
        repeat(2) @(posedge clk);
        @(negedge clk); rst_n=1;
        write_word(32'h0000_0000, 32'hA5A5_0001);
        write_word(32'h0000_0004, 32'hB6B6_0002);
        write_word(32'h0000_0008, 32'hC7C7_0003);
        read_check(32'h0000_0000, 32'hA5A5_0001);
        read_check(32'h0000_0004, 32'hB6B6_0002);
        read_check(32'h0000_0008, 32'hC7C7_0003);
        if(errors==0) $display("RAM TEST PASSED");
        else $display("RAM TEST FAILED: %0d errors", errors);
        #10 $finish;
    end
endmodule
