`default_nettype none
`timescale 1ns / 1ps

module stereo_tb;

logic clk;
logic rst;

logic [1:0] mode_in;
logic [1:0] mode_ext_in;
logic [8:0] big_values_in;
logic window_switching_flag_in;
logic [1:0] block_type_in;
logic mixed_block_flag_in;

logic [20:0][3:0]scalefac_l_in;
logic [11:0][2:0][3:0]scalefac_s_in;

logic [31:0] ch1_in;
logic [31:0] ch2_in;
logic [9:0] is_pos_in;
logic gr_in;
logic din_v;

logic [31:0] ch1_out;
logic [31:0] ch2_out;
logic gr_out;
logic dout_v;


logic [575:0][31:0] ch1_code, ch2_code;

stereo_32bit UUT (
    .clk(clk),
    .rst(rst),
    .mode_in(mode_in),
    .mode_ext_in(mode_ext_in),
    .big_values_in(big_values_in),
    .window_switching_flag_in(window_switching_flag_in),
    .block_type_in(block_type_in),
    .mixed_block_flag_in(mixed_block_flag_in),
    .scalefac_l_in(scalefac_l_in),
    .scalefac_s_in(scalefac_s_in),
    .ch1_in(ch1_in),
    .ch2_in(ch2_in),
    .is_pos_in(is_pos_in),
    .gr_in(gr_in),
    .din_v(din_v),
    .ch1_out(ch1_out),
    .ch2_out(ch2_out),
    .gr_out(gr_out),
    .dout_v(dout_v)
  );


always begin
  #10;
  clk = !clk;     //clock cycles now happend every 20!
end


initial begin
  $dumpfile("sim/stereo_32b_tb.vcd");
  $dumpvars(0, stereo_tb);
  $display("Starting Sim");

  ch1_code = 18432'h00229d2e001428a300000000ffebd75dffcd3403ffbb99d9ffa8c739ffa8c739ffa8c739ffa8c739ffbb99d9ffcd3403ffdd62d2ffebd75dfff80000fff80000fff80000fff80000001428a3001428a300080000000800000008000000080000001428a3001428a3001428a3001428a3001428a3001428a3001428a3001428a30008000000080000fff80000fff80000001428a300229d2e00229d2e00229d2e00229d2e001428a3001428a3001428a3001428a3000800000008000000000000000000000000000000000000fff80000fff80000fff80000001428a3000800000008000000000000fff80000fff80000ffebd75dffebd75dffebd75dffebd75dffebd75dffebd75dffebd75dfff80000fff80000fff80000fff80000fff80000001428a3001428a3001428a3001428a3001428a3001428a3001428a3001428a300080000000800000008000000080000000800000008000000080000000800000008000000080000fff80000fff80000fff80000fff80000fff8000000000000000000000000000000000000000000000000000000000000000800000008000000080000001428a3001428a3001428a3ffdd62d2ffdd62d2ffdd62d2ffdd62d2ffebd75dfff80000fff800000000000000080000001428a3001428a3001428a3001428a3001428a3000800000008000000000000fff80000001428a3001428a3001428a3001428a3001428a3001428a3001428a3001428a3001428a3001428a3001428a3001428a3001428a3001428a300080000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;

  ch2_code = 18432'h0;

  clk = 0;

  window_switching_flag_in = 1;
  block_type_in = 1;
  mixed_block_flag_in = 0;
  big_values_in = 9'd71;
  scalefac_l_in = 0;
  scalefac_s_in = 0;
  mode_in = 1;
  mode_ext_in = 2;

  is_pos_in = 0;
  din_v = 0;
  gr_in = 0;

  rst = 0;
  #20;
  rst = 1;
  #20;
  rst = 0;
  #20;

  din_v = 1;
  for (int i = 0; i < 576; i++) begin
    ch1_in = ch1_code[575 - i];
    ch2_in = ch2_code[575 - i];
    is_pos_in = i;
    #20;
  end


  $display("Finishing Sim");
  $finish;

end
endmodule

`default_nettype wire