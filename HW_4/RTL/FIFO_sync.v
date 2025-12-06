module FIFO_sync(
    input             clk     ,
    input             rst     ,
    input             wr_en   ,
    input             rd_en   ,
    input       [7:0] data_in ,
    output reg        full    ,
    output reg        empty   ,
    output reg  [7:0] data_out
);
reg [7:0] register [0:31];
reg [4:0] right, left;
reg [5:0] count;

always @(posedge clk or posedge rst)
begin
    if(rst) begin
        full <= 1'b0;
        empty <= 1'b1;
        data_out <= 8'b0;
        left <= 5'b0;
        right <= 5'b0;
        count <= 6'b0;
    end
    else begin
        if(wr_en && !full)begin
            register[right] <= data_in;
            right <= right + 1;
            count <= count + 1;
            empty <= 0;
            if(count == 31)begin
                full <= 1;
            end
        end
        if(rd_en && !empty)begin
            data_out <= register[left];
            left <= left + 1;
            count <= count - 1;
            full <= 0;
            if(count == 1)begin
                empty <= 1;
            end
        end
        if(wr_en && rd_en && !full && !empty)
            count <= count;
        if(empty)
            data_out <= 0;
    end
end

endmodule