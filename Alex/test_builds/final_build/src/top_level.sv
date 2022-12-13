`default_nettype none
`timescale 1ns / 1ps

module top_level(
  input wire clk_100mhz,
  input wire btnc,
  input wire btnu,
  input wire [15:0] sw,

  output logic [15:0] led
  );

  logic sys_rst;
  assign sys_rst = btnc;

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


    // //save this side information globally because we need it globally for the brams later
    // logic [8:0] main_data_begin_save;
    // logic [2:0] private_bits_save;
    // logic [1:0][3:0] scfsi_save;
    // logic [1:0][1:0][11:0] part2_3_length_save;
    // logic [1:0][1:0][8:0] big_values_save;
    // logic [1:0][1:0][7:0] global_gain_save;
    // logic [1:0][1:0][3:0] scalefac_compress_save;
    // logic [1:0][1:0] window_switching_flag_save;
    // logic [1:0][1:0][1:0] block_type_save;
    // logic [1:0][1:0] mixed_block_flag_save;
    // logic [1:0][1:0][2:0][4:0] table_select_save;
    // logic [1:0][1:0][2:0][2:0] subblock_gain_save;
    // logic [1:0][1:0][3:0] region0_count_save;
    // logic [1:0][1:0][3:0] region1_count_save;
    // logic [1:0][1:0] preflag_save;
    // logic [1:0][1:0] scalefac_scale_save;
    // logic [1:0][1:0] count1table_select_save;
    //
    // always_ff @(posedge clk_100mhz) begin
    //   if (side_info_axiov) begin
    //     main_data_begin_save <= main_data_begin;
    //     private_bits_save <= private_bits;
    //     scfsi_save <= scfsi;
    //     part2_3_length_save <= part2_3_length;
    //     big_values_save <= big_values;
    //     global_gain_save <= global_gain;
    //     scalefac_compress_save <= scalefac_compress;
    //     window_switching_flag_save <= window_switching_flag;
    //     block_type_save <= block_type;
    //     mixed_block_flag_save <= mixed_block_flag;
    //     table_select_save <= table_select;
    //     subblock_gain_save <= subblock_gain;
    //     region0_count_save <= region0_count;
    //     region1_count_save <= region1_count;
    //     preflag_save <= preflag;
    //     scalefac_scale_save <= scalefac_scale;
    //     count1table_select_save <= count1table_select;
    //   end
    // end


    /////// NEW CODE (as of 12/9/22) integrating the huffman decoding and the FIFO buffer!!! ########################
    logic fifo_dout;
    logic fifo_dout_v;
    logic [15:0] fifo_dcount;

    logic sf_parser_flag, hf_decoder_flag, res_discard_flag, gr, ch;
    logic [3:0]parser_out_valid;

    logic fifo_rd_en, fifo_wr_en;

    assign fifo_wr_en = (fifo_buffer_flag && mux_data_out_valid);
    assign fifo_rd_en = (sf_parser_flag || hf_decoder_flag || res_discard_flag);

    fifo_nonsim_real FIFO (
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

    logic [11:0][2:0][3:0] scalefac_s_00, scalefac_s_01, scalefac_s_10, scalefac_s_11;
    logic [20:0][3:0] scalefac_l_00, scalefac_l_01, scalefac_l_10, scalefac_l_11;

    sf_parser #(.GR(0), .CH(0)) parser_1
    (
        .clk(clk_100mhz),
        .rst(sys_rst),
        .axiid(fifo_dout),
        .axiiv((fifo_dout_v) && (~gr) && (~ch) && (sf_parser_flag)),

        .scalefac_compress_in(scalefac_compress[0][0]),
        .window_switching_flag_in(window_switching_flag[0][0]),
        .block_type_in(block_type[0][0]),
        .mixed_block_flag_in(mixed_block_flag[0][0]),
        .scfsi_in(scfsi[0]),
        .si_valid(side_info_axiov),
        .scalefac_s(scalefac_s_00),
        .scalefac_l(scalefac_l_00),
        .axiov(parser_out_valid[3])
      );


    sf_parser #(.GR(0), .CH(1)) parser_2
    (
        .clk(clk_100mhz),
        .rst(sys_rst),
        .axiid(fifo_dout),
        .axiiv((fifo_dout_v) && (~gr) && (ch) && (sf_parser_flag)),

        .scalefac_compress_in(scalefac_compress[0][1]),
        .window_switching_flag_in(window_switching_flag[0][1]),
        .block_type_in(block_type[0][1]),
        .mixed_block_flag_in(mixed_block_flag[0][1]),
        .scfsi_in(scfsi[1]),
        .si_valid(side_info_axiov),
        .scalefac_s(scalefac_s_01),
        .scalefac_l(scalefac_l_01),
        .axiov(parser_out_valid[2])
      );

    sf_parser #(.GR(1), .CH(0)) parser_3
    (
        .clk(clk_100mhz),
        .rst(sys_rst),
        .axiid(fifo_dout),
        .axiiv((fifo_dout_v) && (gr) && (~ch) && (sf_parser_flag)),

        .scalefac_compress_in(scalefac_compress[1][0]),
        .window_switching_flag_in(window_switching_flag[1][0]),
        .block_type_in(block_type[1][0]),
        .mixed_block_flag_in(mixed_block_flag[1][0]),
        .scfsi_in(scfsi[0]),
        .si_valid(side_info_axiov),
        .scalefac_s(scalefac_s_10),
        .scalefac_l(scalefac_l_10),
        .axiov(parser_out_valid[1])
      );

    sf_parser #(.GR(1), .CH(1)) parser_4
    (
        .clk(clk_100mhz),
        .rst(sys_rst),
        .axiid(fifo_dout),
        .axiiv((fifo_dout_v) && (gr) && (ch) && (sf_parser_flag)),

        .scalefac_compress_in(scalefac_compress[1][1]),
        .window_switching_flag_in(window_switching_flag[1][1]),
        .block_type_in(block_type[1][1]),
        .mixed_block_flag_in(mixed_block_flag[1][1]),
        .scfsi_in(scfsi[1]),
        .si_valid(side_info_axiov),
        .scalefac_s(scalefac_s_11),
        .scalefac_l(scalefac_l_11),
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


    // always_comb begin
    //   //taper the inputs into the requantizer depending on the activated granule and channel:
    //   case({gr,ch})
    //     2'b00 : begin
    //       window_switching_flag_active = window_switching_flag_save[0][0];
    //       scfsi_active = scfsi_save[0];
    //       part2_3_length_active = part2_3_length_save[0][0];
    //       big_values_active = big_values_save[0][0];
    //       global_gain_active = global_gain_save[0][0];
    //       scalefac_compress_active = scalefac_compress_save[0][0];
    //       window_switching_flag_active = window_switching_flag_save[0][0];
    //       block_type_active = block_type_save[0][0];
    //       mixed_block_flag_active = mixed_block_flag_save[0][0];
    //       table_select_active = table_select_save[0][0];
    //       subblock_gain_active = subblock_gain_save[0][0];
    //       region0_count_active = region0_count_save[0][0];
    //       region1_count_active = region1_count_save[0][0];
    //       preflag_active = preflag_save[0][0];
    //       scalefac_scale_active = scalefac_scale_save[0][0];
    //       count1table_select_active = count1table_select_save[0][0];
    //     end
    //     2'b01 : begin
    //       window_switching_flag_active = window_switching_flag_save[0][1];
    //       scfsi_active = scfsi_save[1];
    //       part2_3_length_active = part2_3_length_save[0][1];
    //       big_values_active = big_values_save[0][1];
    //       global_gain_active = global_gain_save[0][1];
    //       scalefac_compress_active = scalefac_compress_save[0][1];
    //       window_switching_flag_active = window_switching_flag_save[0][1];
    //       block_type_active = block_type_save[0][1];
    //       mixed_block_flag_active = mixed_block_flag_save[0][1];
    //       table_select_active = table_select_save[0][1];
    //       subblock_gain_active = subblock_gain_save[0][1];
    //       region0_count_active = region0_count_save[0][1];
    //       region1_count_active = region1_count_save[0][1];
    //       preflag_active = preflag_save[0][1];
    //       scalefac_scale_active = scalefac_scale_save[0][1];
    //       count1table_select_active = count1table_select_save[0][1];
    //     end
    //     2'b10 : begin
    //       window_switching_flag_active = window_switching_flag_save[1][0];
    //       scfsi_active = scfsi_save[0];
    //       part2_3_length_active = part2_3_length_save[1][0];
    //       big_values_active = big_values_save[1][0];
    //       global_gain_active = global_gain_save[1][0];
    //       scalefac_compress_active = scalefac_compress_save[1][0];
    //       window_switching_flag_active = window_switching_flag_save[1][0];
    //       block_type_active = block_type_save[1][0];
    //       mixed_block_flag_active = mixed_block_flag_save[1][0];
    //       table_select_active = table_select_save[1][0];
    //       subblock_gain_active = subblock_gain_save[1][0];
    //       region0_count_active = region0_count_save[1][0];
    //       region1_count_active = region1_count_save[1][0];
    //       preflag_active = preflag_save[1][0];
    //       scalefac_scale_active = scalefac_scale_save[1][0];
    //       count1table_select_active = count1table_select_save[1][0];
    //     end
    //     2'b00 : begin
    //       window_switching_flag_active = window_switching_flag_save[1][1];
    //       scfsi_active = scfsi_save[1];
    //       part2_3_length_active = part2_3_length_save[1][1];
    //       big_values_active = big_values_save[1][1];
    //       global_gain_active = global_gain_save[1][1];
    //       scalefac_compress_active = scalefac_compress_save[1][1];
    //       window_switching_flag_active = window_switching_flag_save[1][1];
    //       block_type_active = block_type_save[1][1];
    //       mixed_block_flag_active = mixed_block_flag_save[1][1];
    //       table_select_active = table_select_save[1][1];
    //       subblock_gain_active = subblock_gain_save[1][1];
    //       region0_count_active = region0_count_save[1][1];
    //       region1_count_active = region1_count_save[1][1];
    //       preflag_active = preflag_save[1][1];
    //       scalefac_scale_active = scalefac_scale_save[1][1];
    //       count1table_select_active = count1table_select_save[1][1];
    //     end
    //   endcase
    // end
    //
    //
    // logic
    //
    // requantizer_v2 requant (
    //     .clk(clk_100mhz),
    //     .rst(sys_rst),
    //
    //     .window_switching_flag_in(window_switching_flag_active),
    //     .block_type_in(block_type_active),
    //     .mixed_block_flag_in(mixed_block_flag_active),
    //     .scalefac_scale_in(scalefac_scale_active),
    //     .global_gain_in(global_gain_active),
    //     .preflag_in(preflag_active),
    //     .subblock_gain_in(subblock_gain_active),
    //     .big_values_in(big_values_active),
    //     .scalefac_l_in(scalefac_l_in_active),
    //     .scalefac_s_in(scalefac_s_in_active),
    //     .x_in(x_in_active),
    //     .is_pos(is_pos_active),
    //     .din_v(din_valid_active),
    //
    //     .x_out(x_out_quant),
    //     .x_base_out(x_base_out_quant),
    //     .dout_v(dout_v_active)
    //   );


  logic old_is_dest;

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      led[15:0] <= 0;
      old_is_dest <= 0;
    end else begin
      old_is_dest <= IS_dest[3];

      led[15:0] = ((IS_pos == 0) && (IS_dest[3] == 1)) ? x_val  : led[8:0];
    end
  end

endmodule

`default_nettype wire
