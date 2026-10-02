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

    @(negedge clk);
        rst_n = 1;
        @(posedge clk);
        #3;
        if(empty !== 1'b1 || full !== 1'b0 || overflow !== 1'b0 || underflow !== 1'b0 || rd_data !== 0)
            $display("Test failed at time %t: Initial state incorrect", $time);
        else 
            $display("Initial state correct at time %t", $time);
        
    //first write
    @(negedge clk);
    wr_data = 8'hA5;
    wr_en = 1;
    @(posedge clk);
    #3;
    if(empty !== 1'b0 || full !== 1'b0 || overflow !== 1'b0 || underflow !== 1'b0 || rd_data !== 0)
        $display("Test failed at time %t: After write, state incorrect", $time);
    else    
        $display("After write, state correct at time %t", $time);
    //first read

    @(negedge clk);
    wr_en=0;
    rd_en=1;
    @(posedge clk);
    #3;
    if(empty !== 1'b1 || full !== 1'b0 || overflow !== 1'b0 || underflow !== 1'b0 || rd_data !== 8'hA5)
        $display("Test failed at time %t: After read, state incorrect", $time);
    else    
        $display("After read, state correct at time %t", $time);
//second write
    @(negedge clk);
    rd_en=0;
    wr_en=1;
    wr_data = 8'h5B;
    @(posedge clk);
    #3;
    if(empty !== 1'b0 || full !== 1'b0 || overflow !== 1'b0 || underflow !== 1'b0 || rd_data !== 0)
        $display("Test failed at time %t: After  write, state incorrect", $time);
    else    
        $display("After write, state correct at time %t", $time);

//second read
    @(negedge clk);
    wr_en=0;
    rd_en=1;
    @(posedge clk);
    #3;
    if(empty !== 1'b1 || full !== 1'b0 || overflow !== 1'b0 || underflow !== 1'b0 || rd_data !== 8'h5B)
        $display("Test failed at time %t: After read, state incorrect", $time);
    else    
        $display("After read, state correct at time %t", $time);


    @(negedge clk);
    wr_en = 0;
    rd_en = 1;
    @(posedge clk);
    #3;
    if(empty !== 1'b1 || full !== 1'b0 || overflow !== 1'b0 || underflow !== 1'b1 || rd_data !== 8'h5B)
        $display("Test failed at time %t: After read, state incorrect", $time);
    else    
        $display("After read, state correct at time %t", $time);
        
    $finish;

    end
    //undeflow case

    
    

endmodule
