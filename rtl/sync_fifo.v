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

localparam ptr_width = (DEPTH > 1) ? $clog2(DEPTH) : 1;
localparam count_width = (DEPTH > 1) ? $clog2(DEPTH+1) : 1;

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
reg [ptr_width-1:0] wr_ptr;
reg [ptr_width-1:0] rd_ptr;
reg [count_width-1:0] count;

assign full = (count == DEPTH);
assign empty = (count == 0);
wire write_ok ;
wire read_ok;
assign write_ok = wr_en && !full;
assign read_ok = rd_en && !empty;


always @(posedge clk) begin
    if (!rst_n) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        count <= 0;
        overflow <= 0;
        underflow <= 0;
        rd_data <= 0;
    end
    else begin
        overflow <= wr_en && full;
        underflow <= rd_en && empty;

        if (write_ok) begin
            mem[wr_ptr] <= wr_data;
            if(wr_ptr == DEPTH-1)
                wr_ptr <= 0;
            else
                wr_ptr <= wr_ptr + 1;            
            
        end

        if (read_ok) begin
            rd_data <= mem[rd_ptr];
            if(rd_ptr == DEPTH-1)
                rd_ptr <= 0;
            else
                rd_ptr <= rd_ptr + 1;
            
        end
    case ({write_ok, read_ok})
        2'b10: count <= count + 1;
        2'b01: count <= count - 1;
        default: count <= count;
    endcase

        


end
end




endmodule