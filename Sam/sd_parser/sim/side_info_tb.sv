`default_nettype none
`timescale 1ns / 1ps

module side_info_tb;

  logic clk;
  logic rst;
  logic [7:0] axiid;
  logic axiiv;

  logic axiov;
  logic [8:0] main_data_begin;
  logic [2:0] private_bits;
  logic [1:0][3:0] scfsi;
  logic [1:0][1:0][11:0] part2_3_length;
  logic [1:0][1:0][8:0] big_values;
  logic [1:0][1:0][7:0] global_gain;
  logic [1:0][1:0][3:0] scalefac_compress;
  logic [1:0][1:0] window_switching_flag;
  logic [1:0][1:0][1:0] block_type;
  logic [1:0][1:0] mixed_block_flag;

  logic [1:0][1:0][2:0][4:0] table_select;
  logic [1:0][1:0][2:0][2:0] subblock_gain;

  logic [1:0][1:0][3:0] region0_count;
  logic [1:0][1:0][3:0] region1_count;
  logic [1:0][1:0] preflag;
  logic [1:0][1:0] scalefac_scale;
  logic [1:0][1:0] count1table_select;

  logic [255:0] sideinfo_code;

  side_info_2ch ohmygod (
    clk,
    rst,
    axiid,
    axiiv,
    axiov,

    main_data_begin,
    private_bits,
    scfsi,
    part2_3_length,
    big_values,
    global_gain,
    scalefac_compress,
    window_switching_flag,
    block_type,
    mixed_block_flag,

    table_select,
    subblock_gain,

    region0_count,
    region1_count,
    preflag,
    scalefac_scale,
    count1table_select
    );

  always begin
    #10;
    clk = !clk;     //clock cycles now happend every 20!
  end

  initial begin
    $dumpfile("sim/side_info_sim.vcd");
    $dumpvars(0, side_info_tb);
    $display("Starting Sim");

    // sideinfo_code = 256'h2082f40e6056af69000000000d20e000010ec95f58cd18554800003480000004;
    // sideinfo_code = 256'h6380f3e542d5c3291be000000d200000010f6d11542db0cd0000003480000004;
    sideinfo_code = 256'hf584f5e06ccfab4f564000000d2000000115b5a147acacfc8000003480000004;


    clk = 0;
    rst = 0;

    axiiv = 0;
    axiid = 0;    //make the inputs 0 too!
    #20;
    rst = 1;
    #20;
    rst = 0;

    //TRANSMIT DESTINATION

    for (int i = 255; i > 0; i -= 8) begin
      axiiv = 1;
      axiid = sideinfo_code[i-:8];
      #20;

      axiiv = 0;
      #40;
    end
    #200;


    sideinfo_code = 256'h6380f3e542d5c3291be000000d200000010f6d11542db0cd0000003480000004;

    //transmit new side information:
    for (int i = 255; i > 0; i -= 8) begin
      axiiv = 1;
      axiid = sideinfo_code[i-:8];
      #20;

      axiiv = 0;
      #40;
    end
    #200;


    $display("Finishing Sim");
    $finish;

  end

endmodule


`default_nettype wire
