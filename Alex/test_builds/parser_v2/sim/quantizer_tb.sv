`default_nettype none
`timescale  1ns / 1ps

module requantizer_tb;

logic clk;
logic rst;
logic si_valid;
logic sf_valid;

logic window_switching_flag;
logic [1:0]block_type;
logic mixed_block_flag;
logic scalefac_scale;
logic [7:0]global_gain;
logic preflag;
logic [2:0][2:0]subblock_gain;
logic [8:0]big_values;

logic [20:0][3:0]scalefac_l_in;
logic [11:0][2:0][3:0]scalefac_s_in;

logic [15:0] x_in;
logic [9:0] is_pos;
logic din_valid;

logic [15:0] x_out;
logic [9:0] x_base_out;
logic dout_v;

requantizer shit (
    .clk(clk),
    .rst(rst),
    .si_valid(si_valid),
    .sf_valid(sf_valid),

    .window_switching_flag(window_switching_flag),
    .block_type(block_type),
    .mixed_block_flag(mixed_block_flag),
    .scalefac_scale(scalefac_scale),
    .global_gain(global_gain),
    .preflag(preflag),
    .subblock_gain(subblock_gain),
    .big_values(big_values),
    .scalefac_l_in(scalefac_l_in),
    .scalefac_s_in(scalefac_s_in),
    .x_in(x_in),
    .is_pos(is_pos),
    .din_valid(din_valid),
    .x_out(x_out),
    .x_base_out(x_base_out),
    .dout_v(dout_v)
  );


always begin
  #10;
  clk = !clk;     //clock cycles now happend every 20!
end

initial begin
  $dumpfile("sim/requantizer.vcd");
  $dumpvars(0, requantizer_tb);
  $display("Starting Sim");

  window_switching_flag = 0;
  block_type = 0;
  mixed_block_flag = 0;
  scalefac_scale = 0;
  global_gain = 159;
  preflag = 0;
  subblock_gain = 0;
  big_values = 217;

  scalefac_l_in = 8'h10;
  scalefac_s_in = 0;

  clk = 0;
  rst = 0;
  si_valid = 0;
  sf_valid = 0;
  din_valid = 0;

  #20;
  rst = 1;
  #20;
  rst = 0;

  si_valid = 1;
  sf_valid = 1;
  #20;
  si_valid = 0;
  sf_valid = 0;
  #20;

  din_valid = 1;

  x_in = 7;
  is_pos = 0;
  #20;

  x_in = 15'sd4;
  is_pos = 1;
  #20;

  x_in = -15'sd4;
  is_pos = 2;
  #20;

  x_in = 15'sd32;
  is_pos = 3;
  #20;

  x_in = -15'sd9;
  is_pos = 4;
  #20;
  #200;





  $display("Finishing Sim");
  $finish;

end

endmodule

`default_nettype wire
