// `default_nettype none
// `timescale 1ns / 1ps

// module huffout_buffer(
//     input wire clk,
//     input wire rst,
//     input wire [15:0] v,
//     input wire [15:0] w,
//     input wire [15:0] x,
//     input wire [15:0] y,
//     input wire [9:0] bram_addra,

//     output logic [25:0] data_out
// );

// logic wr_en0, wr_en1, wr_en2, wr_en3;


// main_data_fifo f_0(.clk(clk), .srst(srst), .din(din0), .wr_en(wr_en0), rd_en(ptr), .dout(dout0), .full(full0), .empty(empty0));
// main_data_fifo f_1(.clk(clk), .srst(srst), .din(din1), .wr_en(wr_en1), rd_en(ptr), .dout(dout1), .full(full1), .empty(empty1));
// main_data_fifo f_2(.clk(clk), .srst(srst), .din(din2), .wr_en(wr_en2), rd_en(ptr), .dout(dout2), .full(full2), .empty(empty2));
// main_data_fifo f_3(.clk(clk), .srst(srst), .din(din3), .wr_en(wr_en3), rd_en(ptr), .dout(dout3), .full(full3), .empty(empty3));

// endmodule

// 'default_nettype wire