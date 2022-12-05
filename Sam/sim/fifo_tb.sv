`default_nettype none
`timescale 1ns / 1ps

module fifo_tb;
    logic clk;
    logic rst;

    logic [7:0] data_in;
    logic rd;
    logic wr;
    logic data_out;
    logic empty;
    logic full;
    logic [31:0] data_count;

    fifo_sim uut(
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .rd(rd),
        .wr(wr),
        .data_out(data_out),
        .empty(empty),
        .full(full),
        .data_count(data_count)
    );

    always begin
    #10;
    clk = !clk;
    end

    initial begin
        $dumpfile("fifo.vcd");
        $dumpvars(0, fifo_tb);
        $display("Starting Sim");
        clk = 0;
        rst = 0;
        data_in = 0;
        rd = 0;
        wr = 0;

        #20;
        rst = 1;
        #20;
        rst = 0;
        #20;
        for (int i = 255; i > 245; i = i-1)begin
            data_in = 8'b10101010;
            wr = 1;
            #20;
        end
        for (int i = 0; i < 50; i = i+1) begin
            wr = 0;
            rd = 1;
            #20;
        end
        rd = 0;
        for (int i = 255; i > 245; i = i-1)begin
            wr = 1;
            data_in = 8'b10101010;
            #20;
        end
        $finish;
    end
endmodule
`default_nettype wire