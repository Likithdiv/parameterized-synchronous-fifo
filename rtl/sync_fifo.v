module sync_fifo #(
        parameter DATA_WIDTH = 8,
        parameter DEPTH = 16
)(
    input clk,
    input rst_n,
    input wr_en,
    input rd_en,
    input [DATA_WIDTH-1:0] wr_data,
    output reg [DATA_WIDTH-1:0] rd_data,
    output full,
    output empty,
    output reg overflow,
    output reg underflow
    

);



//fifo logic


endmodule
