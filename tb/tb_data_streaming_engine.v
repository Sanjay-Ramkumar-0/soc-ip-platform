`timescale 1ns/1ps

// Shallow, self-checking system testbench.
// Tests: source RAM preload -> descriptor -> DMA read -> AXI register slice
// -> DMA write -> destination RAM readback.
module tb_data_streaming_engine;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam LEN_WIDTH  = 16;
    localparam MEM_DEPTH  = 1024;
    localparam WORD_BYTES = DATA_WIDTH / 8;
    localparam NUM_WORDS  = 8;

    reg clk;
    reg rst_n;

    reg [ADDR_WIDTH-1:0] src_addr;
    reg [ADDR_WIDTH-1:0] dst_addr;
    reg [LEN_WIDTH-1:0]  transfer_len;
    reg descriptor_valid;

    wire busy;
    wire done;

    reg [ADDR_WIDTH-1:0] src_mem_addr;
    reg [DATA_WIDTH-1:0] src_mem_wdata;
    reg src_mem_we;

    reg [ADDR_WIDTH-1:0] dst_mem_addr;
    wire [DATA_WIDTH-1:0] dst_mem_rdata;

    reg [DATA_WIDTH-1:0] expected_data [0:NUM_WORDS-1];
    integer i;
    integer errors;
    integer timeout_count;

    data_streaming_engine #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .LEN_WIDTH(LEN_WIDTH),
        .MEM_DEPTH(MEM_DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .src_addr(src_addr),
        .dst_addr(dst_addr),
        .transfer_len(transfer_len),
        .descriptor_valid(descriptor_valid),
        .busy(busy),
        .done(done),
        .src_mem_addr(src_mem_addr),
        .src_mem_wdata(src_mem_wdata),
        .src_mem_we(src_mem_we),
        .dst_mem_addr(dst_mem_addr),
        .dst_mem_rdata(dst_mem_rdata)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_data_streaming_engine.vcd");
        $dumpvars(0, tb_data_streaming_engine);
    end

    task reset_dut;
    begin
        rst_n = 1'b0;
        src_addr = 0;
        dst_addr = 0;
        transfer_len = 0;
        descriptor_valid = 1'b0;
        src_mem_addr = 0;
        src_mem_wdata = 0;
        src_mem_we = 1'b0;
        dst_mem_addr = 0;
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
    end
    endtask

    task preload_word;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] data;
    begin
        @(negedge clk);
        src_mem_addr  = addr;
        src_mem_wdata = data;
        src_mem_we    = 1'b1;
        @(posedge clk);
        @(negedge clk);
        src_mem_we    = 1'b0;
    end
    endtask

    task submit_descriptor;
        input [ADDR_WIDTH-1:0] saddr;
        input [ADDR_WIDTH-1:0] daddr;
        input [LEN_WIDTH-1:0] len;
    begin
        @(negedge clk);
        src_addr       = saddr;
        dst_addr       = daddr;
        transfer_len   = len;
        descriptor_valid = 1'b1;
        @(posedge clk);
        @(negedge clk);
        descriptor_valid = 1'b0;
    end
    endtask

    task check_word;
        input integer index;
        input [ADDR_WIDTH-1:0] addr;
        input [DATA_WIDTH-1:0] expected;
        inout integer error_count;
    begin
        @(negedge clk);
        dst_mem_addr = addr;
        @(posedge clk);
        #1;
        if (dst_mem_rdata === expected)
            $display("PASS: word %0d  addr=0x%08h  data=0x%08h", index, addr, dst_mem_rdata);
        else begin
            $display("FAIL: word %0d  addr=0x%08h  expected=0x%08h  got=0x%08h",
                     index, addr, expected, dst_mem_rdata);
            error_count = error_count + 1;
        end
    end
    endtask

    initial begin
        clk = 1'b0;
        errors = 0;

        expected_data[0] = 32'h1111_0001;
        expected_data[1] = 32'h2222_0002;
        expected_data[2] = 32'h3333_0003;
        expected_data[3] = 32'h4444_0004;
        expected_data[4] = 32'h5555_0005;
        expected_data[5] = 32'h6666_0006;
        expected_data[6] = 32'h7777_0007;
        expected_data[7] = 32'h8888_0008;

        $display("");
        $display("================================================");
        $display(" DATA STREAMING ENGINE - BASIC SYSTEM TEST");
        $display("================================================");

        reset_dut();

        // Eight 32-bit words = 32 bytes.
        for (i = 0; i < NUM_WORDS; i = i + 1)
            preload_word(32'h0000_0100 + i*WORD_BYTES, expected_data[i]);

        $display("Source RAM preloaded.");

        submit_descriptor(32'h0000_0100, 32'h0000_0200, NUM_WORDS*WORD_BYTES);
        $display("Descriptor submitted. Waiting for DMA completion...");

        timeout_count = 0;
        while ((done !== 1'b1) && (timeout_count < 1000)) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end

        if (timeout_count >= 1000) begin
            $display("FAIL: DMA timeout");
            $finish;
        end

        $display("DMA transfer completed.");

        for (i = 0; i < NUM_WORDS; i = i + 1)
            check_word(i, 32'h0000_0200 + i*WORD_BYTES, expected_data[i], errors);

        $display("================================================");
        if (errors == 0)
            $display(" TEST PASSED: all transferred words match");
        else
            $display(" TEST FAILED: %0d mismatches", errors);
        $display("================================================");

        #20;
        $finish;
    end
endmodule
