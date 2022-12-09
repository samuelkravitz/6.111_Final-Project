`default_nettype none
`timescale 1ns / 1ps


module reorder_tb;

logic clk;
logic rst;

logic [1:0] grch_in;
logic [9:0] is_pos;
logic din_v;

logic window_switching_flag;
logic [1:0] block_type;
logic mixed_block_flag;
logic [8:0] big_values;

logic [1:0] grch_out;
logic [9:0] is_pos_out;
logic dout_v;

reorder UUT (
  .clk(clk),
  .rst(rst),
  .grch_in(grch_in),
  .is_pos(is_pos),
  .din_v(din_v),
  .window_switching_flag(window_switching_flag),
  .block_type(block_type),
  .mixed_block_flag(mixed_block_flag),
  .big_values(big_values),
  .grch_out(grch_out),
  .is_pos_out(is_pos_out),
  .dout_v(dout_v)
  );


always begin
  #10;
  clk = !clk;     //clock cycles now happend every 20!
end

initial begin
  $dumpfile("sim/reorder.vcd");
  $dumpvars(0, reorder_tb);
  $display("Starting Sim");



  ///////////TEST 1: ////////////////////////////
  window_switching_flag = 0;
  block_type = 0;
  mixed_block_flag = 0;
  big_values = 9'd215;
  grch_in = 0;
  is_pos = 0;
  din_v = 0;

  clk = 0;
  rst = 0;
  #20;
  rst = 1;
  #20;
  rst = 0;
  #20;

  din_v = 1;
  is_pos = 9'd15;
  #20;
  is_pos = 9'd18;
  #20;
  din_v = 0;
  // #100;
  ///////////////////TEST 2: ///////////////////////////
  window_switching_flag = 1;
  block_type = 2;
  mixed_block_flag = 1;

  din_v = 1;
  is_pos = 9'd78;
  #20;
  is_pos = 9'd79;
  #20;
  din_v = 0;
  #100;






  $display("Finishing Sim");
  $finish;

end

endmodule


`default_nettype wire
