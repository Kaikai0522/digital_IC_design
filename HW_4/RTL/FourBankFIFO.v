`timescale 1ns / 10ps
module FourBankFIFO(
    input           clk         ,
    input           rst         ,
    input           wr_en_M0    ,
    input  [7:0]    data_in_M0  ,
    input           rd_en_M0    ,
    input  [1:0]    rd_id_M0    ,
    input           wr_en_M1    ,
    input  [7:0]    data_in_M1  ,
    input           rd_en_M1    ,
    input  [1:0]    rd_id_M1    ,
    output reg [7:0]    data_out_M0 ,
    output reg [7:0]    data_out_M1 ,
    output reg         valid_M0,
    output reg         valid_M1
);
    reg  [1:0] wr_bank_ptr;
    reg        last_served_M0;
    
    reg        grant_M0;
    reg        grant_M1;
    
    wire       req_M0 = wr_en_M0 || rd_en_M0;
    wire       req_M1 = wr_en_M1 || rd_en_M1;

    reg        wr_en [0:3];
    reg        rd_en [0:3];
    reg  [7:0] data_in;
    wire [7:0] data_out [0:3];
    wire       full [0:3];
    wire       empty [0:3];

    reg [1:0]  reg_rd_id_M0;
    reg [1:0]  reg_rd_id_M1;

    integer i;
    
    always @(*) begin
        grant_M0 = 0;
        grant_M1 = 0;
        if(req_M0 && req_M1)begin
            if(last_served_M0)
                grant_M1 = 1;
            else
                grant_M0 = 1;
        end
        else if(req_M0)begin
            grant_M0 = 1;
        end
        else if(req_M1)begin
            grant_M1 = 1;
        end
    end

    always @(posedge clk or posedge rst)begin
        if(rst)begin
            last_served_M0 <= 0;
            wr_bank_ptr <= 0;
        end
        else begin
            if(grant_M0) last_served_M0 <= 1;
            else if(grant_M1) last_served_M0 <= 0;
            
            if((grant_M0 && wr_en_M0 && !full[wr_bank_ptr]) || (grant_M1 && wr_en_M1 && !full[wr_bank_ptr]))
                wr_bank_ptr <= wr_bank_ptr + 1;
        end
    end

    always @(*)begin
        for(i = 0;i < 4;i = i + 1)begin
            wr_en[i] = 0;
            rd_en[i] = 0;
        end
        data_in = 0;
        if(grant_M0)begin
            data_in = data_in_M0;
            if(wr_en_M0 && !full[wr_bank_ptr])begin
                wr_en[wr_bank_ptr] = 1;
            end
            if(rd_en_M0 && !empty[rd_id_M0])begin
                rd_en[rd_id_M0] = 1;
            end
        end
        else if(grant_M1)begin
            data_in = data_in_M1;
            if(wr_en_M1 && !full[wr_bank_ptr])begin
                wr_en[wr_bank_ptr] = 1;
            end
            if(rd_en_M1 && !empty[rd_id_M1])begin
                rd_en[rd_id_M1] = 1;
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if(rst)begin
            valid_M0 <= 0;
            valid_M1 <= 0;
            reg_rd_id_M0 <= 0;
            reg_rd_id_M1 <= 0;
        end
        else begin
            valid_M0 <= (grant_M0 && rd_en_M0 && !empty[rd_id_M0]);
            valid_M1 <= (grant_M1 && rd_en_M1 && !empty[rd_id_M1]);
            if(rd_en_M0) reg_rd_id_M0 <= rd_id_M0;
            if(rd_en_M1) reg_rd_id_M1 <= rd_id_M1;
        end
    end

    always @(*) begin
        data_out_M0 = 0;
        data_out_M1 = 0;
        if(valid_M0) data_out_M0 = data_out[reg_rd_id_M0];
        if(valid_M1) data_out_M1 = data_out[reg_rd_id_M1];
    end


    genvar j;
    
    generate
        for(j = 0;j < 4; j = j + 1)begin : BANK_GEN
            FIFO_sync bank (
                .clk (clk),
                .rst (rst),
                .wr_en(wr_en[j]),
                .rd_en(rd_en[j]),
                .data_in(data_in),
                .full(full[j]),
                .empty(empty[j]),
                .data_out(data_out[j])
            );
        end
    endgenerate

endmodule