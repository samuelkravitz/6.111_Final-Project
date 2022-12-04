`default_nettype none
`timescale 1ns / 1ps

module sf_parser_tb;

logic clk;
logic rst;

logic [1037:0] bit_code;

logic gr;
logic [11:0] part2_3_length;
logic [3:0] scalefac_compress;
logic window_switching_flag;
logic [1:0] block_type;
logic mixed_block_flag;
logic [3:0] scfsi;
logic si_valid;

logic [11:0][2:0] scalefac_s;
logic [20:0] scalefac_l;
logic axiov;

logic axiid, axiiv;


sf_parser UUT (
    .clk(clk),
    .rst(rst),
    .axiid(axiid),
    .axiiv(axiiv),
    .gr(gr),
    .scalefac_compress(scalefac_compress),
    .window_switching_flag(window_switching_flag),
    .block_type(block_type),
    .mixed_block_flag(mixed_block_flag),
    .scfsi(scfsi),
    .si_valid(si_valid),
    .scalefac_s(scalefac_s),
    .scalefac_l(scalefac_l),
    .axiov(axiov)
  );

//////////////////////////////////////////

  always begin
    #10;
    clk = !clk;     //clock cycles now happend every 20!
  end

  initial begin
    $dumpfile("sim/sf_parser_sim.vcd");
    $dumpvars(0, sf_parser_tb);
    $display("Starting Sim");

    bit_code = 1038'b010100100000000000001001100011100110011000100110000111011111000101100001110010111011100111001111011001011000111000011100010010011110000001101010000100100001100101001011011100111000101101001011101000111100111111111011100010000010000001000000010001000001011000010110110011010000000111100000000000010001001000100000000101000011000001011000011010000111100001000001000110001100001001010001100011100001111000101101010010011001101101001010001000000000111101011101100011101000100001010110011000100001000111100010101000101010111011100110001000110110110010011010101110101011011001001010000110101100001001000110100000011100001111001001010000010110001011000101100010101000010111110110101110011011011111101111100010011010101010100001100010101010111001001101010100110111011101111111010010110101001101101010110110001110000111110000111101010111110001011100010001101001000100110100100111101101001111010111000100111101011100010111011101111111110100010011101010111111110111001101011111001111000010010101111001001110010001010010110000100110001101110111001011;

    gr = 0;
    mixed_block_flag = 0;
    scalefac_compress = 5;
    window_switching_flag = 1;
    block_type = 3;
    scfsi = 0;
    si_valid = 0;
    axiiv = 0;
    axiid = 0;

    rst = 0;
    clk = 0;
    #20;
    rst = 1;
    #20;
    rst = 0;
    #20;
    si_valid = 1;
    #20;
    si_valid = 0;
    for (int i = 1037; i > 0; i --) begin
      axiid = bit_code[i];
      axiiv = 1;
      #20;
      axiiv = 0;
      #80;
    end


    $display("Finishing Sim");
    $finish;

  end

endmodule


`default_nettype wire
