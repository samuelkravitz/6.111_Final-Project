`default_nettype none
`timescale 1ns / 1ps

module integration_tb;

logic clk_100mhz, clk;
logic sys_rst, rst;
logic btnu;
logic [6:0] sw;

assign clk_100mhz = clk;    //for ease
assign sys_rst = rst;

/////////////////////////////////////////
logic [7:0] bram_axiod;
logic bram_axiov;

bram_feeder data_out (
    .clk(clk_100mhz),
    .rst(sys_rst),
    .frame_num_iv(btnu),
    .frame_num_id(sw),
    .axiod(bram_axiod),
    .axiov(bram_axiov)
  );


logic valid_header;
logic prot;
logic [1:0] mode, mode_ext, emphasis;
logic [10:0] frame_size;

header_finder light (
    .clk(clk_100mhz),
    .rst(sys_rst),
    .axiid(bram_axiod),
    .axiiv(bram_axiov),
    .valid_header(valid_header),
    .prot(prot),
    .mode(mode),
    .mode_ext(mode_ext),
    .emphasis(emphasis),
    .frame_size(frame_size)
  );

logic crc_16_flag, side_info_flag, fifo_buffer_flag;
logic [7:0] mux_data_out;
logic mux_data_out_valid;

plexer mux (
    .clk(clk_100mhz),
    .rst(sys_rst),
    .axiiv(bram_axiov),
    .axiid(bram_axiod),
    .valid_header(valid_header),
    .mode(mode),
    .prot(prot),
    .frame_size(frame_size),
    .crc_16_ov(crc_16_flag),
    .side_info_ov(side_info_flag),
    .fifo_buffer_ov(fifo_buffer_flag),
    .data_out(mux_data_out),
    .data_out_valid(mux_data_out_valid)
  );

logic side_info_axiov;
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

side_info_2ch si_parser(
    .clk(clk_100mhz),
    .rst(sys_rst),
    .axiid(mux_data_out),
    .axiiv(mux_data_out_valid & side_info_flag),
    .axiov(side_info_axiov),
    .main_data_begin(main_data_begin),
    .private_bits(private_bits),
    .scfsi(scfsi),
    .part2_3_length(part2_3_length),
    .big_values(big_values),
    .global_gain(global_gain),
    .scalefac_compress(scalefac_compress),
    .window_switching_flag(window_switching_flag),
    .block_type(block_type),
    .mixed_block_flag(mixed_block_flag),
    .table_select(table_select),
    .subblock_gain(subblock_gain),
    .region0_count(region0_count),
    .region1_count(region1_count),
    .preflag(preflag),
    .scalefac_scale(scalefac_scale),
    .count1table_select(count1table_select)
  );



//////////////////////////////////////////

  always begin
    #10;
    clk = !clk;     //clock cycles now happend every 20!
  end

  initial begin
    $dumpfile("sim/integration_sim.vcd");
    $dumpvars(0, integration_tb);
    $display("Starting Sim");


    rst = 0;
    clk = 0;
    sw = 0;
    btnu = 0;
    #40;
    rst = 1;
    #20;
    rst = 0;
    #20
    sw = 5;
    btnu = 1;
    #20;
    btnu = 0;
    #150000;

    sw = 4;
    btnu = 1;
    #20;
    btnu = 0;
    #150000;

    $display("Finishing Sim");
    $finish;

  end

endmodule


`default_nettype wire
