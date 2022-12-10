`default_nettype none
`timescale  1ns / 1ps

module requantizer_tb;

logic clk;
logic rst;

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

logic [31:0] dout;
logic dout_v;

requantizer_v3 shit (
    .clk(clk),
    .rst(rst),

    .window_switching_flag_in(window_switching_flag),
    .block_type_in(block_type),
    .mixed_block_flag_in(mixed_block_flag),
    .scalefac_scale_in(scalefac_scale),
    .global_gain_in(global_gain),
    .preflag_in(preflag),
    .subblock_gain_in(subblock_gain),
    .big_values_in(big_values),
    .scalefac_l_in(scalefac_l_in),
    .scalefac_s_in(scalefac_s_in),
    .x_in(x_in),
    .is_pos(is_pos),
    .din_v(din_valid),
    .dout(dout),
    .dout_v(dout_v)
  );


always begin
  #10;
  clk = !clk;     //clock cycles now happend every 20!
end

initial begin
  $dumpfile("sim/requantizer_v3.vcd");
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
  x_in = 0;

  is_pos = 0;

  din_valid = 0;

  #20;
  rst = 1;
  #20;
  rst = 0;

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
  din_valid = 0;

  #200;

  window_switching_flag = 0;
  block_type = 0;
  mixed_block_flag = 0;
  scalefac_scale = 0;
  global_gain = 161;
  preflag = 0;
  subblock_gain = 0;
  big_values = 204;

  scalefac_l_in = 84'h343010000001000012000;
  scalefac_s_in = 0;


    din_valid = 1;

    x_in = 29;
    is_pos = 0;
    #20;

    x_in = -16'sd31;
    is_pos = 1;
    #20;

    x_in = -16'sd14;
    is_pos = 2;
    #20;

    x_in = 16'sd26;
    is_pos = 3;
    #20;

    x_in = 16'sd1;
    is_pos = 4;
    #20;

    x_in = 16'sd5;
    is_pos = 5;
    #20;

    din_valid = 0;
    
    #200;


  $display("Finishing Sim");
  $finish;

end

endmodule

`default_nettype wire
