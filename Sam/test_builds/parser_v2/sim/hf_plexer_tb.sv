`default_nettype none
`timescale 1ns / 1ps

module hf_plexer_tb;

logic clk;
logic rst;
logic data_in;
logic data_in_valid;

logic si_valid;
logic [1:0][1:0][3:0] region0_count_in;
logic [1:0][1:0][3:0] region1_count_in;
logic [1:0][1:0][8:0] big_values_in;
logic [1:0][1:0][2:0][4:0] table_select_in;
logic [1:0][1:0] count1table_select_in;
logic [1:0][1:0] window_switching_flag_in;
logic [1:0][1:0][1:0] block_type_in;

logic gr;
logic ch;

logic [15:0] bram_data_out_v;
logic [15:0] bram_data_out_w;
logic [15:0] bram_data_out_x;
logic [15:0] bram_data_out_y;
logic [9:0] bram_addra;

logic bram_00_data_valid;
logic bram_01_data_valid;
logic bram_10_data_valid;
logic bram_11_data_valid;



huffman_plexer UUT (
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_in_valid(data_in_valid),
    .si_valid(si_valid),
    .region0_count_in(region0_count_in),
    .region1_count_in(region1_count_in),
    .big_values_in(big_values_in),
    .table_select_in(table_select_in),
    .count1table_select_in(count1table_select_in),
    .window_switching_flag_in(window_switching_flag_in),
    .block_type_in(block_type_in),
    .gr(gr),
    .ch(ch),
    .bram_data_out_v(bram_data_out_v),
    .bram_data_out_w(bram_data_out_w),
    .bram_data_out_x(bram_data_out_x),
    .bram_data_out_y(bram_data_out_y),
    .bram_addra(bram_addra),
    .bram_00_data_valid(bram_00_data_valid),
    .bram_01_data_valid(bram_01_data_valid),
    .bram_10_data_valid(bram_10_data_valid),
    .bram_11_data_valid(bram_11_data_valid)
  );

always begin
  #10;
  clk = !clk;     //clock cycles now happend every 20!
end

logic [1449:0] code_00;

logic [1554:0] code_10;


initial begin
  $dumpfile("sim/hf_plexer_sim.vcd");
  $dumpvars(0, hf_plexer_tb);
  $display("Starting Sim");


  region0_count_in = 16'hd0c;
  region1_count_in = 16'h403;
  big_values_in = 36'h35400d9;
  table_select_in = 45'h77e800029f9;
  count1table_select_in = 3'h4;
  window_switching_flag_in = 4'h0;
  block_type_in = 8'h0;
  gr = 0;
  ch = 0;

  code_00 = 1450'b0110100110000011101100010010111101000001011000011100111011110111110101101001000010001000011101001010001100111001010100010110111011101011011000010010010101001100100110010000111110001001000001011000011001001010010100011001000001000100111010110101100010001011111110010100010111001101011100111101111001100100111111000100111000100100010000100101101110001001011000001011001001000001110000001001011011011010010111000010010000101101011000011000100010011110001110100010010111101010110101110010000000001000000001101000110100100011000010011100100101100101100010111110011001110000110111010011110000000110111000101110100000101101000111001101101100111101110111100010101011111010010100011111100001001111001010001010101010110110001001000010111000101101010101010001000111010110110111011101110100100100000100010111001111101110000010101000011011001101011010111000000001100100101000111101100011101010011001100010110111100011001110010011001011110111000101101110110010101010011111110001100001011110000101100101010101001110001000111010100111100001001011010000110101000010010100010100101110010001101010011110101101010000110011001011011000010101000001010010111010100110100010011101001101100000110110101010110001111001000100110101100010100001011101001100010000100011011001101010111010101101110010011101001001111000101101101101100100001001011111001010100011011011100100110010111001111011011010100101101110110111101101110110111000111011110010101011011000101111011111100101110101;

  code_10 = 1555'b0101011110100110001101001110100011110000000101000010010010001111000101010000110011001000000011000000110001010000001110000011101101100010101001010001101001100010100111101010011001001100100000010010001101000010100000000010000001100000010000101010101011000011110000010000111000001100011001001000001110000000100011010000000001001000100000010101000000110011010100100001010100010110101001011010010111111011011110001100110001010000000101011101100100100001000110100010110100111100000011010101101011110100101110011000100100010100010010100001000110010010110000010011011010001000000011110001010001010001011110101110101011010010000010110001001110001010101011000111110001000110100000011100001000011010100111010001001011101000101011101001000100000000011001101001011011000110000110000000111110011010111100101011101110110000001100101100101111011110100110000000111101110000101110101011111010110000101011101100110000010011100001001100100000011011011001111110110011101001001000011010110111101011001000010000010011010110111100100011110110011011001101110011001011111100010111001110111000101010101010111110001101101000010000111101100011011000100000001011010110111001001100110010010000001111010000101110100111111101000010110010110001101011101011101101100110110101011011001001100101011001110101101001101111110101100011010110000111011111100110000001000110110011110011100101110011000010110110101001110010111000100100110101101010001100110011010001110100000010100111001011011100001011101111110001100011100111111100111111101011110101000110100111000111001110001000010010111111101100100;


  clk = 0;
  rst = 0;

  data_in_valid = 0;
  data_in = 0;    //make the inputs 0 too!
  #20;
  rst = 1;
  #20;
  rst = 0;

  #40;
  si_valid = 1;
  #20;
  si_valid = 0;
  #20;

  #1000;

  data_in_valid = 1;
  for (int i=1449; i >= 0; i --) begin
    data_in = code_00[i];
    #20;
  end
  data_in_valid = 0;

  #2000;

  gr = 1; ch = 0;

  #1000;
  data_in_valid = 1;
  for (int j=1554; j >= 0; j--) begin
    data_in = code_10[j];
    #20;
  end
  #2000;

  $display("Finishing Sim");
  $finish;

end
endmodule

`default_nettype wire