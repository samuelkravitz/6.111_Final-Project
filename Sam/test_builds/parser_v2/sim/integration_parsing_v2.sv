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

plexer sd_mux (
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

logic fifo_dout;
logic fifo_dout_v;
logic [15:0] fifo_dcount;

logic sf_parser_flag, hf_decoder_flag, res_discard_flag, gr, ch;
logic [3:0]parser_out_valid;

logic fifo_rd_en, fifo_wr_en;

assign fifo_wr_en = (fifo_buffer_flag && mux_data_out_valid);
assign fifo_rd_en = (sf_parser_flag || hf_decoder_flag || res_discard_flag);

fifo_sim_real FIFO (
  .clk(clk_100mhz),
  .srst(sys_rst),
  .din(mux_data_out),
  .wr_en(fifo_wr_en),
  .rd_en(fifo_rd_en),
  .dout(fifo_dout),
  .dcount_out(fifo_dcount),
  .d_valid_out(fifo_dout_v)
  );

fifo_muxer FIFO_mux (
    .clk(clk_100mhz),
    .rst(sys_rst),
    .fifo_sample_count(fifo_dcount),
    .fifo_dout_v(fifo_dout_v),
    .si_valid_in(side_info_axiov),
    .main_data_begin(main_data_begin),
    .part2_3_length(part2_3_length),
    .sf_parser_axiov(parser_out_valid),
    .res_discard_flag(res_discard_flag),
    .sf_parser_flag(sf_parser_flag),
    .hf_decoder_flag(hf_decoder_flag),
    .gr(gr),
    .ch(ch)
  );

logic [1:0][1:0][11:0][2:0][3:0] scalefac_s;
logic [1:0][1:0][20:0][3:0] scalefac_l;

sf_parser #(.GR(0), .CH(0)) parser_1
(
    .clk(clk),
    .rst(rst),
    .axiid(fifo_dout),
    .axiiv((fifo_dout_v) && (~gr) && (~ch) && (sf_parser_flag)),

    .scalefac_compress_in(scalefac_compress),
    .window_switching_flag_in(window_switching_flag),
    .block_type_in(block_type),
    .mixed_block_flag_in(mixed_block_flag),
    .scfsi_in(scfsi),
    .si_valid(side_info_axiov),
    .scalefac_s(scalefac_s[0][0]),
    .scalefac_l(scalefac_l[0][0]),
    .axiov(parser_out_valid[3])
  );


sf_parser #(.GR(0), .CH(1)) parser_2
(
    .clk(clk),
    .rst(rst),
    .axiid(fifo_dout),
    .axiiv((fifo_dout_v) && (~gr) && (ch) && (sf_parser_flag)),

    .scalefac_compress_in(scalefac_compress),
    .window_switching_flag_in(window_switching_flag),
    .block_type_in(block_type),
    .mixed_block_flag_in(mixed_block_flag),
    .scfsi_in(scfsi),
    .si_valid(side_info_axiov),
    .scalefac_s(scalefac_s[0][1]),
    .scalefac_l(scalefac_l[0][1]),
    .axiov(parser_out_valid[2])
  );

sf_parser #(.GR(1), .CH(0)) parser_3
(
    .clk(clk),
    .rst(rst),
    .axiid(fifo_dout),
    .axiiv((fifo_dout_v) && (gr) && (~ch) && (sf_parser_flag)),

    .scalefac_compress_in(scalefac_compress),
    .window_switching_flag_in(window_switching_flag),
    .block_type_in(block_type),
    .mixed_block_flag_in(mixed_block_flag),
    .scfsi_in(scfsi),
    .si_valid(side_info_axiov),
    .scalefac_s(scalefac_s[1][0]),
    .scalefac_l(scalefac_l[1][0]),
    .axiov(parser_out_valid[1])
  );

sf_parser #(.GR(1), .CH(1)) parser_4
(
    .clk(clk),
    .rst(rst),
    .axiid(fifo_dout),
    .axiiv((fifo_dout_v) && (gr) && (ch) && (sf_parser_flag)),

    .scalefac_compress_in(scalefac_compress),
    .window_switching_flag_in(window_switching_flag),
    .block_type_in(block_type),
    .mixed_block_flag_in(mixed_block_flag),
    .scfsi_in(scfsi),
    .si_valid(side_info_axiov),
    .scalefac_s(scalefac_s[1][1]),
    .scalefac_l(scalefac_l[1][1]),
    .axiov(parser_out_valid[0])
  );

logic hf_decoder_data_valid;
logic [15:0] x_val, y_val, v_val, w_val;
logic [9:0] IS_pos;
logic [3:0] IS_dest;

assign hf_decoder_data_valid = (fifo_dout_v) && (hf_decoder_flag);

huffman_plexer hf_decoder (
  .clk(clk_100mhz),
  .rst(sys_rst),
  .data_in(fifo_dout),
  .data_in_valid(hf_decoder_data_valid),
  .si_valid(side_info_axiov),
  .region0_count_in(region0_count),
  .region1_count_in(region1_count),
  .big_values_in(big_values),
  .table_select_in(table_select),
  .count1table_select_in(count1table_select),
  .window_switching_flag_in(window_switching_flag),
  .block_type_in(block_type),
  .gr(gr),
  .ch(ch),

  //outputs of the module:
  .bram_data_out_v(v_val),
  .bram_data_out_w(w_val),
  .bram_data_out_x(x_val),
  .bram_data_out_y(y_val),
  .bram_addra(IS_pos),
  .bram_00_data_valid(IS_dest[3]),
  .bram_01_data_valid(IS_dest[2]),
  .bram_10_data_valid(IS_dest[1]),
  .bram_11_data_valid(IS_dest[0])
  );



//////////////////////////////////////////

  always begin
    #10;
    clk = !clk;     //clock cycles now happend every 20!
  end

  initial begin
    $dumpfile("sim/integration_v2_sim.vcd");
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
    sw = 0;
    btnu = 1;
    #20;
    btnu = 0;
    #150000;


    sw = 1;
    btnu = 1;
    #20;
    btnu = 0;
    #150000;

    sw = 2;
    btnu = 1;
    #20;
    btnu = 0;
    #150000;
    #150000;

    $display("Finishing Sim");
    $finish;

  end

endmodule


`default_nettype wire
