`timescale 1ns/1ps

module sync_fifo_tb;

    localparam DATA_WIDTH = 8;
    localparam DEPTH = 16;

    
    reg clk;
    reg rst_n;
    reg wr_en;
    reg rd_en;
    reg [DATA_WIDTH-1:0] wr_data;

    
    wire [DATA_WIDTH-1:0] rd_data;
    wire full;
    wire empty;
    wire overflow;
    wire underflow;

    
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .full(full),
        .empty(empty),
        .overflow(overflow),
        .underflow(underflow)
    );
    integer i;
    integer errors = 0;
    initial clk =0;
    always #5 clk = ~clk;
    initial begin
        $dumpfile("sync_fifo.vcd");
        $dumpvars(0, sync_fifo_tb);
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        wr_data = 0;
        repeat(2) @(posedge clk);
        #1
        //check reset state
        if (empty !== 1'b1 || full !== 1'b0 ||
        overflow !== 1'b0 || underflow !== 1'b0 ||
        rd_data !== {DATA_WIDTH{1'b0}}) begin
            $display("Error: FIFO not in reset state");
            errors = errors + 1;
        end
        else begin
            $display("FIFO in reset state");
        end
        @(negedge clk);
        rst_n = 1;
        //writing 4 values 
        for(i=0; i<4; i=i+1) begin
            @(negedge clk);
            wr_en = 1;
            rd_en = 0;
            wr_data = i+1;
            @(posedge clk);
            #1;
            if (empty !== 1'b0 || full !== 1'b0 ||
            overflow !== 1'b0 || underflow !== 1'b0) begin
            errors = errors + 1;
            $display("FAIL: Write %0d", i + 1);
            end
            else begin
            $display("PASS: Write %0d", i + 1);
            end

        end
        //stop write before next rising edge
        @(negedge clk);
        wr_en = 0;
        //reading 4 values
        for(i=0; i<4; i=i+1) begin
            @(negedge clk);
            wr_en = 0;
            rd_en = 1;
            @(posedge clk);
            #1;
            if (rd_data !== (i + 1) ||
            empty !== (i == 3) ||
            full !== 1'b0 ||
            overflow !== 1'b0 ||
            underflow !== 1'b0) begin
            errors = errors + 1;
            $display("FAIL: Read %0d, expected %0d, got %0d",
                    i + 1, i + 1, rd_data);
            end
            else begin
                $display("PASS: Read %0d", i + 1);
            end
end
        //stop read before next rising edge (at this state fifo is empty)
        @(negedge clk);
        rd_en = 0;

        //underflow test
        @(negedge clk);
        wr_en = 0;
        rd_en = 1;
        @(posedge clk);
        #1;
        if (empty !== 1'b1 || full !== 1'b0 ||
        underflow !== 1'b1 || overflow !== 1'b0 ||
        rd_data !== 8'd4) begin
        errors = errors + 1;
        $display("FAIL: Underflow protection");
        end
    else begin
        $display("PASS: Underflow protection");
    end
    
        //remove read request and check that underflow is clears
        @(negedge clk);
        rd_en = 0;
        @(posedge clk);
        #1;
        if (underflow !== 1'b0) begin
        errors = errors + 1;
        $display("FAIL: Underflow did not clear");
        end
        else begin
        $display("PASS: Underflow cleared");
        end
        //filling fifo to test overflow
        for(i=0; i<DEPTH; i=i+1) begin
            @(negedge clk);
            wr_en = 1;
            rd_en = 0;
            wr_data = i+1;
            @(posedge clk);
            #1;
            if (empty !== 1'b0 ||
        full !== (i == DEPTH - 1) ||
        overflow !== 1'b0 ||
        underflow !== 1'b0) begin
        errors = errors + 1;
        $display("FAIL: Fill write %0d", i + 1);
        end
        else begin
            $display("PASS: Fill write %0d", i + 1);
        end
    end
        @(negedge clk);
        wr_en = 0; //stop write before next rising edge (at this state fifo is full)

        //try writing to full fifo to test overflow
        @(negedge clk);
        wr_en = 1;
        rd_en = 0;
        wr_data = 8'd99;
        @(posedge clk);
        #1;
        if (full !== 1'b1 || empty !== 1'b0 ||
        overflow !== 1'b1 || underflow !== 1'b0 ||
        rd_data !== 8'd4) begin
        errors = errors + 1;
        $display("FAIL: Overflow protection");
        end
        else begin
            $display("PASS: Overflow protection");
        end
        //remove write request and check that overflow is clears
        @(negedge clk);
        wr_en = 0;
        @(posedge clk);
        #1;
        if (overflow !== 1'b0) begin
        errors = errors + 1;
        $display("FAIL: Overflow did not clear");
        end
        else begin
        $display("PASS: Overflow cleared");
        end
        
        //draining fifo
        for(i=0; i<DEPTH; i=i+1) begin
            @(negedge clk);
            rd_en = 1;
            wr_en = 0;
            @(posedge clk);
            #1;
            if (rd_data !== (i + 1) ||
            empty !== (i == DEPTH - 1) ||
            full !== 1'b0 ||
            overflow !== 1'b0 ||
            underflow !== 1'b0) begin
            errors = errors + 1;
            $display("FAIL: Drain read %0d, expected %0d, got %0d",
                    i + 1, i + 1, rd_data);
        end
        else begin
                $display("PASS: Drain read %0d", i + 1);
            end
        end
        @(negedge clk);
        rd_en = 0; //stop read before next rising edge (fifo is empty)
        //test reading and writing on the same rising edge
        @(negedge clk);
        wr_en = 1;
        rd_en = 0;
        wr_data = 8'd55;
        @(posedge clk);
        #1;
        @(negedge clk);
        //read 55 while writing 66
        wr_en = 1;
        rd_en = 1;
        wr_data = 8'd66;
        @(posedge clk);
        #1;
        if (rd_data !== 8'd55 || empty !== 1'b0 || full !== 1'b0 ||
        overflow !== 1'b0 || underflow !== 1'b0) begin
        errors = errors + 1;
        $display("FAIL: Simultaneous read/write");
        end
        else begin
            $display("PASS: Simultaneous read/write");
        end
        @(negedge clk); //read the newly written item
        rd_en = 1;
        wr_en = 0;
        @(posedge clk);
        #1;
        if (rd_data !== 8'd66 || empty !== 1'b1 || full !== 1'b0 ||
        overflow !== 1'b0 || underflow !== 1'b0) begin
        errors = errors + 1;
        $display("FAIL: Read after simultaneous read/write");
        end
        else begin
            $display("PASS: Read after simultaneous read/write");
        end
        @(negedge clk);
        rd_en = 0;

        if (errors == 0) begin
            $display("All tests passed");
        end
        else begin
            $display("%0d tests failed", errors);
        end 

        
        $finish;
    end
endmodule
