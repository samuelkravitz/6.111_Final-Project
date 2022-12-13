`default_nettype none
`timescale 1ns / 1ps

module top_level(
  input wire clk_100mhz,
  input wire btnc,
  input wire btnu,
  input wire btnr,
  input wire [15:0] sw,

  output logic [15:0] led

  );

  logic sys_rst;

  assign sys_rst = btnc;

  /////////////////////////////////////////
  logic [7:0] bram_axiod;
  logic bram_axiov;

  logic READY;

  logic btnu_old;
  always_ff @(posedge clk_100mhz) begin
      if (sys_rst) begin
        btnu_old <= 0;
      end else begin
        btnu_old <= btnu;
      end
  end

  bram_feeder data_out (
      .clk(clk_100mhz),
      .rst(sys_rst),
      .frame_num_iv((btnu && ~btnu_old && READY)),
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


  /////save some header information here:
  logic [1:0] mode_save;
  logic [1:0] mode_ext_save;

  always_ff @(posedge clk_100mhz) begin
      if (valid_header && ~side_info_flag && ~fifo_buffer_flag) begin
        mode_save <= mode;
        mode_ext_save <= mode_ext;
      end else begin
        mode_save <= mode_save;
        mode_ext_save <= mode_ext_save;
      end
  end

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


  //  save this side information globally because we need it globally for the brams later
    logic [8:0] main_data_begin_save;
    logic [2:0] private_bits_save;
    logic [1:0][3:0] scfsi_save;
    logic [1:0][1:0][11:0] part2_3_length_save;
    logic [1:0][1:0][8:0] big_values_save;
    logic [1:0][1:0][7:0] global_gain_save;
    logic [1:0][1:0][3:0] scalefac_compress_save;
    logic [1:0][1:0] window_switching_flag_save;
    logic [1:0][1:0][1:0] block_type_save;
    logic [1:0][1:0] mixed_block_flag_save;
    logic [1:0][1:0][2:0][4:0] table_select_save;
    logic [1:0][1:0][2:0][2:0] subblock_gain_save;
    logic [1:0][1:0][3:0] region0_count_save;
    logic [1:0][1:0][3:0] region1_count_save;
    logic [1:0][1:0] preflag_save;
    logic [1:0][1:0] scalefac_scale_save;
    logic [1:0][1:0] count1table_select_save;

    always_ff @(posedge clk_100mhz) begin
      if (side_info_axiov) begin
        main_data_begin_save <= main_data_begin;
        private_bits_save <= private_bits;
        scfsi_save <= scfsi;
        part2_3_length_save <= part2_3_length;
        big_values_save <= big_values;
        global_gain_save <= global_gain;
        scalefac_compress_save <= scalefac_compress;
        window_switching_flag_save <= window_switching_flag;
        block_type_save <= block_type;
        mixed_block_flag_save <= mixed_block_flag;
        table_select_save <= table_select;
        subblock_gain_save <= subblock_gain;
        region0_count_save <= region0_count;
        region1_count_save <= region1_count;
        preflag_save <= preflag;
        scalefac_scale_save <= scalefac_scale;
        count1table_select_save <= count1table_select;
      end
    end

  logic fifo_dout;
  logic fifo_dout_v;
  logic [15:0] fifo_dcount;

  logic sf_parser_flag, hf_decoder_flag, res_discard_flag, gr, ch;
  logic [3:0]parser_out_valid;

  logic fifo_rd_en, fifo_wr_en;

  assign fifo_wr_en = (fifo_buffer_flag && mux_data_out_valid);

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

  logic fifo_proc_dout;
  logic fifo_proc_dout_v;

  fifo_processor FIFO_proc (
      .clk(clk_100mhz),
      .rst(sys_rst),
      .fifo_sample_count(fifo_dcount),
      .fifo_data_in(fifo_dout),
      .fifo_din_v(fifo_dout_v),

      .si_valid_in(side_info_axiov),

      .main_data_begin(main_data_begin),
      .part2_3_length(part2_3_length_save),

      .sf_parser_axiov(parser_out_valid),

      .res_discard_flag(res_discard_flag),
      .sf_parser_flag(sf_parser_flag),
      .hf_decoder_flag(hf_decoder_flag),
      .gr(gr),
      .ch(ch),

      .data_out(fifo_proc_dout),
      .data_out_valid(fifo_proc_dout_v),
      .fifo_bit_request(fifo_rd_en)
    );

  logic [1:0][1:0][11:0][2:0][3:0] scalefac_s;
  logic [1:0][1:0][20:0][3:0] scalefac_l;

  sf_parser #(.GR(0), .CH(0)) parser_1
  (
      .clk(clk_100mhz),
      .rst(sys_rst),
      .axiid(fifo_proc_dout),
      .axiiv((fifo_proc_dout_v) && (~gr) && (~ch) && (sf_parser_flag)),

      .scalefac_compress_in(scalefac_compress[0][0]),
      .window_switching_flag_in(window_switching_flag[0][0]),
      .block_type_in(block_type[0][0]),
      .mixed_block_flag_in(mixed_block_flag[0][0]),
      .scfsi_in(scfsi[0]),
      .si_valid(side_info_axiov),
      .scalefac_s(scalefac_s[0][0]),
      .scalefac_l(scalefac_l[0][0]),
      .axiov(parser_out_valid[3])
    );


  sf_parser #(.GR(0), .CH(1)) parser_2
  (
      .clk(clk_100mhz),
      .rst(sys_rst),
      .axiid(fifo_proc_dout),
      .axiiv((fifo_proc_dout_v) && (~gr) && (ch) && (sf_parser_flag)),

      .scalefac_compress_in(scalefac_compress[0][1]),
      .window_switching_flag_in(window_switching_flag[0][1]),
      .block_type_in(block_type[0][1]),
      .mixed_block_flag_in(mixed_block_flag[0][1]),
      .scfsi_in(scfsi[1]),
      .si_valid(side_info_axiov),
      .scalefac_s(scalefac_s[0][1]),
      .scalefac_l(scalefac_l[0][1]),
      .axiov(parser_out_valid[2])
    );

  sf_parser #(.GR(1), .CH(0)) parser_3
  (
      .clk(clk_100mhz),
      .rst(sys_rst),
      .axiid(fifo_proc_dout),
      .axiiv((fifo_proc_dout_v) && (gr) && (~ch) && (sf_parser_flag)),

      .scalefac_compress_in(scalefac_compress[1][0]),
      .window_switching_flag_in(window_switching_flag[1][0]),
      .block_type_in(block_type[1][0]),
      .mixed_block_flag_in(mixed_block_flag[1][0]),
      .scfsi_in(scfsi[0]),
      .si_valid(side_info_axiov),
      .scalefac_s(scalefac_s[1][0]),
      .scalefac_l(scalefac_l[1][0]),
      .axiov(parser_out_valid[1])
    );

  sf_parser #(.GR(1), .CH(1)) parser_4
  (
      .clk(clk_100mhz),
      .rst(sys_rst),
      .axiid(fifo_proc_dout),
      .axiiv((fifo_proc_dout_v) && (gr) && (ch) && (sf_parser_flag)),

      .scalefac_compress_in(scalefac_compress[1][1]),
      .window_switching_flag_in(window_switching_flag[1][1]),
      .block_type_in(block_type[1][1]),
      .mixed_block_flag_in(mixed_block_flag[1][1]),
      .scfsi_in(scfsi[1]),
      .si_valid(side_info_axiov),
      .scalefac_s(scalefac_s[1][1]),
      .scalefac_l(scalefac_l[1][1]),
      .axiov(parser_out_valid[0])
    );


    ////SAVE THE SCALEFACTORS:
    logic [1:0][1:0][11:0][2:0][3:0] scalefac_s_save;
    logic [1:0][1:0][20:0][3:0] scalefac_l_save;

    always_ff @ (posedge clk_100mhz) begin
      if (sys_rst) begin
        scalefac_s_save <= 0;
        scalefac_l_save <= 0;
      end else begin
        if (parser_out_valid[0]) begin
          scalefac_s_save[1][1] <= scalefac_s[1][1];
          scalefac_l_save[1][1] <= scalefac_l[1][1];
        end
        if (parser_out_valid[1]) begin
          scalefac_s_save[1][0] <= scalefac_s[1][0];
          scalefac_l_save[1][0] <= scalefac_l[1][0];
        end
        if (parser_out_valid[2]) begin
          scalefac_s_save[0][1] <= scalefac_s[0][1];
          scalefac_l_save[0][1] <= scalefac_l[0][1];
        end
        if (parser_out_valid[3]) begin
          scalefac_s_save[0][0] <= scalefac_s[0][0];
          scalefac_l_save[0][0] <= scalefac_l[0][0];
        end
      end
    end

    logic hf_decoder_data_valid;
    logic [15:0] x_val, y_val, v_val, w_val;
    logic [9:0] IS_pos;
    logic [3:0] IS_dest;

    assign hf_decoder_data_valid = (fifo_proc_dout_v) && (hf_decoder_flag);

    huffman_plexer hf_decoder (
      .clk(clk_100mhz),
      .rst(sys_rst),
      .data_in(fifo_proc_dout),
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



  logic [15:0] requant_x_in;
  logic [9:0] requant_is_pos;
  logic [1:0] requant_grch;
  logic requant_din_v;

  ////////////////////////////////
  /*
  ROLLING FIFO MODULE HERE!!!!!
  */

  logic [10:0][27:0]BUFFER;
  logic [7:0]BUFFER_POSITION;

  logic [1:0] grch_out_of_fifo;
  always_comb begin
    case(IS_dest)
      4'b1000 : grch_out_of_fifo = 2'b00;
      4'b0100 : grch_out_of_fifo = 2'b01;
      4'b0010 : grch_out_of_fifo = 2'b10;
      4'b0001 : grch_out_of_fifo = 2'b11;
    endcase
  end

  always_ff @(posedge clk_100mhz) begin
      if (sys_rst) begin
        BUFFER <= 0;
        BUFFER_POSITION <= 0;
        requant_x_in <= 0;
        requant_is_pos <= 0;
        requant_grch <= 0;
      end
      else if (|IS_dest) begin
        if (BUFFER_POSITION > 0) BUFFER_POSITION <= BUFFER_POSITION + 1;
        else BUFFER_POSITION <= BUFFER_POSITION + 2;

        BUFFER[0] <= {y_val, IS_pos + 1'b1, grch_out_of_fifo} ;
        BUFFER[1] <= {x_val, IS_pos + 1'b0, grch_out_of_fifo} ;

        for (int i = 2; i < 10; i++) begin
          BUFFER[i] <= BUFFER[i-2];
        end

      end else begin
        if (BUFFER_POSITION > 0) BUFFER_POSITION <= BUFFER_POSITION - 1;
        else BUFFER_POSITION <= BUFFER_POSITION;
      end

      if (BUFFER_POSITION > 0) begin
        {requant_x_in, requant_is_pos, requant_grch} <= BUFFER >> ((BUFFER_POSITION - 1'b1) * 5'd28);
        requant_din_v <= 1;
      end else requant_din_v <= 0;
  end
  //////////////////////////////

  logic requant_window_switching_flag;
  logic [1:0] requant_block_type;
  logic requant_mixed_block_flag;
  logic requant_scalefac_scale;
  logic [7:0] requant_global_gain;
  logic requant_preflag;
  logic [2:0][2:0] requant_subblock_gain;
  logic [8:0] requant_big_values;
  logic [20:0][3:0] requant_scalefac_l;
  logic [11:0][2:0][3:0] requant_scalefac_s;

  logic [31:0] requant_dout;
  logic requant_dout_valid;

  always_comb begin
    case(requant_grch)
      2'b00 : begin
        requant_window_switching_flag = window_switching_flag_save[0][0];
        requant_block_type            = block_type_save[0][0];
        requant_mixed_block_flag      = mixed_block_flag_save[0][0];
        requant_scalefac_scale        = scalefac_scale_save[0][0];
        requant_global_gain           = global_gain_save[0][0];
        requant_preflag               = preflag_save[0][0];
        requant_subblock_gain         = subblock_gain_save[0][0];
        requant_big_values            = big_values_save[0][0];
        requant_scalefac_l            = scalefac_l_save[0][0];
        requant_scalefac_s            = scalefac_s_save[0][0];
      end
      2'b01 : begin
        requant_window_switching_flag = window_switching_flag_save[0][1];
        requant_block_type            = block_type_save[0][1];
        requant_mixed_block_flag      = mixed_block_flag_save[0][1];
        requant_scalefac_scale        = scalefac_scale_save[0][1];
        requant_global_gain           = global_gain_save[0][1];
        requant_preflag               = preflag_save[0][1];
        requant_subblock_gain         = subblock_gain_save[0][1];
        requant_big_values            = big_values_save[0][1];
        requant_scalefac_l            = scalefac_l_save[0][1];
        requant_scalefac_s            = scalefac_s_save[0][1];
      end
      2'b10 : begin
        requant_window_switching_flag = window_switching_flag_save[1][0];
        requant_block_type            = block_type_save[1][0];
        requant_mixed_block_flag      = mixed_block_flag_save[1][0];
        requant_scalefac_scale        = scalefac_scale_save[1][0];
        requant_global_gain           = global_gain_save[1][0];
        requant_preflag               = preflag_save[1][0];
        requant_subblock_gain         = subblock_gain_save[1][0];
        requant_big_values            = big_values_save[1][0];
        //NOTE THAT SCALEFACTORS MAY NEED TO BE COPIED OVER FROM LAST GRANULE:
        if (requant_window_switching_flag && (requant_block_type == 2)) begin
          requant_scalefac_l          = scalefac_l_save[1][0];
          requant_scalefac_s          = scalefac_s_save[1][0];
        end else begin
          for (int sfb = 0; sfb < 6; sfb ++) begin
            if (scfsi_save[0][0]) requant_scalefac_l[sfb]   = scalefac_l_save[0][0];
            else requant_scalefac_l[sfb]                    = scalefac_l_save[1][0];
          end

          for (int sfb = 6; sfb < 11; sfb ++) begin
            if (scfsi_save[0][1]) requant_scalefac_l[sfb]   = scalefac_l_save[0][0];
            else requant_scalefac_l[sfb]                    = scalefac_l_save[1][0];
          end

          for (int sfb = 11; sfb < 16; sfb ++) begin
            if (scfsi_save[0][2]) requant_scalefac_l[sfb]   = scalefac_l_save[0][0];
            else requant_scalefac_l[sfb]                    = scalefac_l_save[1][0];
          end

          for (int sfb = 16; sfb < 21; sfb ++) begin
            if (scfsi_save[0][3]) requant_scalefac_l[sfb]   = scalefac_l_save[0][0];
            else requant_scalefac_l[sfb]                    = scalefac_l_save[1][0];
          end

        end

      end
      2'b11 : begin
        requant_window_switching_flag = window_switching_flag_save[1][1];
        requant_block_type            = block_type_save[1][1];
        requant_mixed_block_flag      = mixed_block_flag_save[1][1];
        requant_scalefac_scale        = scalefac_scale_save[1][1];
        requant_global_gain           = global_gain_save[1][1];
        requant_preflag               = preflag_save[1][1];
        requant_subblock_gain         = subblock_gain_save[1][1];
        requant_big_values            = big_values_save[1][1];
        //NOTE THAT SCALEFACTORS MAY NEED TO BE COPIED OVER FROM LAST GRANULE:
        if (requant_window_switching_flag && (requant_block_type == 2)) begin
          requant_scalefac_l          = scalefac_l_save[1][0];
          requant_scalefac_s          = scalefac_s_save[1][0];
        end else begin
          for (int sfb = 0; sfb < 6; sfb ++) begin
            if (scfsi_save[1][0]) requant_scalefac_l[sfb]   = scalefac_l_save[0][1];
            else requant_scalefac_l[sfb]                    = scalefac_l_save[1][1];
          end

          for (int sfb = 6; sfb < 11; sfb ++) begin
            if (scfsi_save[1][1]) requant_scalefac_l[sfb]   = scalefac_l_save[0][1];
            else requant_scalefac_l[sfb]                    = scalefac_l_save[1][1];
          end

          for (int sfb = 11; sfb < 16; sfb ++) begin
            if (scfsi_save[1][2]) requant_scalefac_l[sfb]   = scalefac_l_save[0][1];
            else requant_scalefac_l[sfb]                    = scalefac_l_save[1][1];
          end

          for (int sfb = 16; sfb < 21; sfb ++) begin
            if (scfsi_save[1][3]) requant_scalefac_l[sfb]   = scalefac_l_save[0][1];
            else requant_scalefac_l[sfb]                    = scalefac_l_save[1][1];
          end

        end
      end
    endcase
  end

  ///// pass in the correct side information data:

  //// pipeline the is_pos of the incoming quantized value and the grch:
  logic [1:0][9:0] requant_is_pos_pipe;
  logic [1:0][1:0] requant_grch_pipe;

  always_ff @(posedge clk_100mhz) begin
      requant_is_pos_pipe[0] <= requant_is_pos;
      requant_is_pos_pipe[1] <= requant_is_pos_pipe[0];

      requant_grch_pipe[0] <= requant_grch;
      requant_grch_pipe[1] <= requant_grch_pipe[0];
  end

  requantizer_v3 requant (
    .clk(clk_100mhz),
    .rst(sys_rst),

    .window_switching_flag_in(requant_window_switching_flag),
    .block_type_in(requant_block_type),
    .mixed_block_flag_in(requant_mixed_block_flag),
    .scalefac_scale_in(requant_scalefac_scale),
    .global_gain_in(requant_global_gain),
    .preflag_in(requant_preflag),
    .subblock_gain_in(requant_subblock_gain),
    .big_values_in(requant_big_values),

    .scalefac_l_in(requant_scalefac_l),
    .scalefac_s_in(requant_scalefac_s),

    .x_in(requant_x_in),     //this is a signed value (in 2s complement, by the HT_00 type of modules)
    .is_pos(requant_is_pos),    //BRAM ADDRA in huffman_plexer
    .din_v(requant_din_v),

    .dout(requant_dout),
    .dout_v(requant_dout_valid)
    );


  logic [2:0][31:0]reorder_dout_pipe;

  always_ff @(posedge clk_100mhz) begin
    reorder_dout_pipe[0] <= requant_dout;
    reorder_dout_pipe[1] <= reorder_dout_pipe[0];
    reorder_dout_pipe[2] <= reorder_dout_pipe[1];
  end



  ///////////////////REORDERING MODULE : ###########################
  logic reorder_window_switching_flag;
  logic [1:0] reorder_block_type;
  logic reorder_mixed_block_flag;
  logic [8:0] reorder_big_values;

  logic [1:0] reorder_grch_out;
  logic [9:0] reorder_is_pos_out;
  logic reorder_dout_v;

  always_comb begin
    case(requant_grch_pipe[1])
        2'b00 : begin
          reorder_window_switching_flag = window_switching_flag_save[0][0];
          reorder_block_type            = block_type_save[0][0];
          reorder_mixed_block_flag      = mixed_block_flag_save[0][0];
          reorder_big_values            = big_values_save[0][0];
        end
        2'b01 : begin
          reorder_window_switching_flag = window_switching_flag_save[0][1];
          reorder_block_type            = block_type_save[0][1];
          reorder_mixed_block_flag      = mixed_block_flag_save[0][1];
          reorder_big_values            = big_values_save[0][1];
        end
        2'b10 : begin
          reorder_window_switching_flag = window_switching_flag_save[1][0];
          reorder_block_type            = block_type_save[1][0];
          reorder_mixed_block_flag      = mixed_block_flag_save[1][0];
          reorder_big_values            = big_values_save[1][0];
        end
        2'b11 : begin
          reorder_window_switching_flag = window_switching_flag_save[1][1];
          reorder_block_type            = block_type_save[1][1];
          reorder_mixed_block_flag      = mixed_block_flag_save[1][1];
          reorder_big_values            = big_values_save[1][1];
        end
      endcase
  end

  reorder reorderer (
    .clk(clk_100mhz),
    .rst(sys_rst),

    .grch_in(requant_grch_pipe[1]),
    .is_pos(requant_is_pos_pipe[1]),
    .din_v(requant_dout_valid),

    .window_switching_flag(reorder_window_switching_flag),
    .block_type(reorder_block_type),
    .mixed_block_flag(reorder_mixed_block_flag),
    .big_values(reorder_big_values),

    .grch_out(reorder_grch_out),
    .is_pos_out(reorder_is_pos_out),
    .dout_v(reorder_dout_v)
    );


  logic [31:0] reorder_assembler_ch1_gr1_out;
  logic [31:0] reorder_assembler_ch2_gr1_out;
  logic [31:0] reorder_assembler_ch1_gr2_out;
  logic [31:0] reorder_assembler_ch2_gr2_out;
  logic reorder_assembler_valid_out;

  reorder_assembler UUT_reorder_assembler (
      .clk(clk_100mhz),
      .rst(sys_rst),
      .grch_in(reorder_grch_out),
      .is_pos_in(reorder_is_pos_out),
      .x_in(reorder_dout_pipe[2]),
      .d_valid_in(reorder_dout_v),
      .big_values(big_values_save),
      .new_frame_start(side_info_axiov),
      .ch1_gr1_out(reorder_assembler_ch1_gr1_out),
      .ch2_gr1_out(reorder_assembler_ch2_gr1_out),
      .ch1_gr2_out(reorder_assembler_ch1_gr2_out),
      .ch2_gr2_out(reorder_assembler_ch2_gr2_out),
      .d_valid_out(reorder_assembler_valid_out)
    );

  logic [8:0] stereo_gr1_big_values_in;
  logic [8:0] stereo_gr2_big_values_in;

  //take the maximum big values number per granule
  always_comb begin
    if (big_values_save[0][0] > big_values_save[0][1]) stereo_gr1_big_values_in = big_values_save[0][0];
    else stereo_gr1_big_values_in = big_values_save[0][1];

    if (big_values_save[1][0] > big_values_save[1][1]) stereo_gr2_big_values_in = big_values_save[1][0];
    else stereo_gr2_big_values_in = big_values_save[1][1];
  end

  logic [9:0] stereo_is_pos;    //count to 576

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst || side_info_axiov) begin
      stereo_is_pos <= 0;
    end else begin
      if (stereo_is_pos < 10'd575) begin
        stereo_is_pos <= (reorder_assembler_valid_out) ? stereo_is_pos + 1 : stereo_is_pos;
      end else begin
        stereo_is_pos <= (reorder_assembler_valid_out) ? 0 : stereo_is_pos;
      end
    end
  end

  logic [31:0] stereo_gr1_ch1_out;
  logic [31:0] stereo_gr1_ch2_out;
  logic [31:0] stereo_gr2_ch1_out;
  logic [31:0] stereo_gr2_ch2_out;

  logic stereo_gr1_dout_valid;
  logic stereo_gr2_dout_valid;

  //this can take side info variables from ch1 always.
  stereo_32bit stereo_gr1 (
      .clk(clk_100mhz),
      .rst(sys_rst),

      .mode_in(mode_save),
      .mode_ext_in(mode_ext_save),
      .big_values_in(stereo_gr1_big_values_in),
      .window_switching_flag_in(window_switching_flag_save[0][0]),
      .block_type_in(block_type_save[0][0]),
      .mixed_block_flag_in(mixed_block_flag_save[0][0]),

      .scalefac_l_in(scalefac_l_save[0][0]),
      .scalefac_s_in(scalefac_s_save[0][0]),

      .ch1_in(reorder_assembler_ch1_gr1_out),
      .ch2_in(reorder_assembler_ch2_gr1_out),
      .is_pos_in(stereo_is_pos),
      .gr_in(1'b0),
      .din_v(reorder_assembler_valid_out),

      .ch1_out(stereo_gr1_ch1_out),
      .ch2_out(stereo_gr1_ch2_out),
      .gr_out(),
      .dout_v(stereo_gr1_dout_valid)
    );


    stereo_32bit stereo_gr2 (
        .clk(clk_100mhz),
        .rst(sys_rst),

        .mode_in(mode_save),
        .mode_ext_in(mode_ext_save),
        .big_values_in(stereo_gr2_big_values_in),
        .window_switching_flag_in(window_switching_flag_save[1][0]),
        .block_type_in(block_type_save[1][0]),
        .mixed_block_flag_in(mixed_block_flag_save[1][0]),

        .scalefac_l_in(scalefac_l_save[1][0]),
        .scalefac_s_in(scalefac_s_save[1][0]),

        .ch1_in(reorder_assembler_ch1_gr2_out),
        .ch2_in(reorder_assembler_ch2_gr2_out),
        .is_pos_in(stereo_is_pos),
        .gr_in(1'b1),
        .din_v(reorder_assembler_valid_out),

        .ch1_out(stereo_gr2_ch1_out),
        .ch2_out(stereo_gr2_ch2_out),
        .gr_out(),
        .dout_v(stereo_gr2_dout_valid)
      );

  ///antialiasing variables:
  logic [31:0] antialias_gr1_ch1_x_out, antialias_gr1_ch1_y_out;
  logic [31:0] antialias_gr1_ch2_x_out, antialias_gr1_ch2_y_out;
  logic [9:0] antialias_gr1_pos_x_out, antialias_gr1_pos_y_out;
  logic antialias_gr1_valid_out;

  logic [31:0] antialias_gr2_ch1_x_out, antialias_gr2_ch1_y_out;
  logic [31:0] antialias_gr2_ch2_x_out, antialias_gr2_ch2_y_out;
  logic [9:0] antialias_gr2_pos_x_out, antialias_gr2_pos_y_out;
  logic antialias_gr2_valid_out;

  antialias antaliaser_gr1 (
    .clk(clk_100mhz),
    .rst(sys_rst),
    .window_switching_flag_in(window_switching_flag_save[0]),
    .block_type_in(block_type_save[0]),
    .mixed_block_flag_in(mixed_block_flag_save[0]),
    .new_frame_start(side_info_axiov),

    .ch1_in(stereo_gr1_ch1_out),
    .ch2_in(stereo_gr1_ch2_out),

    .din_v(stereo_gr1_dout_valid),

    .ch1_out_x(antialias_gr1_ch1_x_out),
    .ch1_out_y(antialias_gr1_ch1_y_out),

    .ch2_out_x(antialias_gr1_ch2_x_out),
    .ch2_out_y(antialias_gr1_ch2_y_out),

    .is_pos_out_x(antialias_gr1_pos_x_out),
    .is_pos_out_y(antialias_gr1_pos_y_out),
    .dout_v(antialias_gr1_valid_out)
    );

  antialias antaliaser_gr2 (
    .clk(clk_100mhz),
    .rst(sys_rst),
    .window_switching_flag_in(window_switching_flag_save[1]),
    .block_type_in(block_type_save[1]),
    .mixed_block_flag_in(mixed_block_flag_save[1]),
    .new_frame_start(side_info_axiov),
    .ch1_in(stereo_gr2_ch1_out),
    .ch2_in(stereo_gr2_ch2_out),
    .din_v(stereo_gr2_dout_valid),

    .ch1_out_x(antialias_gr2_ch1_x_out),
    .ch1_out_y(antialias_gr2_ch1_y_out),

    .ch2_out_x(antialias_gr2_ch2_x_out),
    .ch2_out_y(antialias_gr2_ch2_y_out),

    .is_pos_out_x(antialias_gr2_pos_x_out),
    .is_pos_out_y(antialias_gr2_pos_y_out),
    .dout_v(antialias_gr2_valid_out)
    );

  /// reorder the antialiasing stuff: ///////////////////////////////////////////
  logic [31:0] gr1_alias_reorder_ch1_out, gr1_alias_reorder_ch2_out;
  logic gr1_alias_reorder_valid_out;

  logic [31:0] gr2_alias_reorder_ch1_out, gr2_alias_reorder_ch2_out;
  logic gr2_alias_reorder_valid_out;

  antialias_reorder gr1_alias_reorder_UUT (
      .clk(clk_100mhz),
      .rst(sys_rst),
      .new_frame_start(side_info_axiov),

      .ch1_x_in(antialias_gr1_ch1_x_out),
      .ch1_y_in(antialias_gr1_ch1_y_out),
      .ch2_x_in(antialias_gr1_ch2_x_out),
      .ch2_y_in(antialias_gr1_ch2_y_out),
      .x_pos_in(antialias_gr1_pos_x_out),
      .y_pos_in(antialias_gr1_pos_y_out),
      .valid_in(antialias_gr1_valid_out),

      .ch1_out(gr1_alias_reorder_ch1_out),
      .ch2_out(gr1_alias_reorder_ch2_out),
      .valid_out(gr1_alias_reorder_valid_out)
    );

  antialias_reorder gr2_alias_reorder_UUT (
      .clk(clk_100mhz),
      .rst(sys_rst),
      .new_frame_start(side_info_axiov),

      .ch1_x_in(antialias_gr2_ch1_x_out),
      .ch1_y_in(antialias_gr2_ch1_y_out),
      .ch2_x_in(antialias_gr2_ch2_x_out),
      .ch2_y_in(antialias_gr2_ch2_y_out),
      .x_pos_in(antialias_gr2_pos_x_out),
      .y_pos_in(antialias_gr2_pos_y_out),
      .valid_in(antialias_gr2_valid_out),

      .ch1_out(gr2_alias_reorder_ch1_out),
      .ch2_out(gr2_alias_reorder_ch2_out),
      .valid_out(gr2_alias_reorder_valid_out)
    );

  logic [31:0] granule_assembler_ch1_out, granule_assembler_ch2_out;
  logic granule_assembler_valid_out;

  granule_assembler GR_assemble (
    .clk(clk_100mhz),
    .rst(sys_rst),
    .new_frame_start(side_info_axiov),

    .gr1_ch1_in(gr1_alias_reorder_ch1_out),
    .gr1_ch2_in(gr1_alias_reorder_ch2_out),
    .gr1_valid_in(gr1_alias_reorder_valid_out),

    .gr2_ch1_in(gr2_alias_reorder_ch1_out),
    .gr2_ch2_in(gr2_alias_reorder_ch2_out),
    .gr2_valid_in(gr2_alias_reorder_valid_out),

    .ch1_out(granule_assembler_ch1_out),
    .ch2_out(granule_assembler_ch2_out),
    .valid_out(granule_assembler_valid_out)
    );


  //HYBRID SYNTHESIS ///////////////////////////////////////////////////////////////////////////
  logic hybrid_window_switching_flag_ch1;
  logic [1:0] hybrid_block_type_ch1;
  logic hybrid_mixed_block_flag_ch1;

  logic hybrid_window_switching_flag_ch2;
  logic [1:0] hybrid_block_type_ch2;
  logic hybrid_mixed_block_flag_ch2;

  logic [10:0] hybrid_sample_in_counter;

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      hybrid_sample_in_counter <= 0;
    end else if (granule_assembler_valid_out) begin
      if (hybrid_sample_in_counter < 11'd1151) begin
        hybrid_sample_in_counter <= hybrid_sample_in_counter + 1;
      end else begin
        hybrid_sample_in_counter <= 0;      //reset this thing to 0!
      end
    end
  end

  always_comb begin
      if (hybrid_sample_in_counter < 11'd575) begin
        hybrid_window_switching_flag_ch1 = window_switching_flag_save[0][0];
        hybrid_block_type_ch1 = block_type_save[0][0];
        hybrid_mixed_block_flag_ch1 = mixed_block_flag_save[0][0];
        hybrid_mixed_block_flag_ch1 = mixed_block_flag_save[0][0];

        hybrid_window_switching_flag_ch2 = window_switching_flag_save[0][1];
        hybrid_block_type_ch2 = block_type_save[0][1];
        hybrid_mixed_block_flag_ch2 = mixed_block_flag_save[0][1];
        hybrid_mixed_block_flag_ch2 = mixed_block_flag_save[0][1];
      end else begin
        hybrid_window_switching_flag_ch1 = window_switching_flag_save[1][0];
        hybrid_block_type_ch1 = block_type_save[1][0];
        hybrid_mixed_block_flag_ch1 = mixed_block_flag_save[1][0];
        hybrid_mixed_block_flag_ch1 = mixed_block_flag_save[1][0];

        hybrid_window_switching_flag_ch2 = window_switching_flag_save[1][1];
        hybrid_block_type_ch2 = block_type_save[1][1];
        hybrid_mixed_block_flag_ch2 = mixed_block_flag_save[1][1];
        hybrid_mixed_block_flag_ch2 = mixed_block_flag_save[1][1];
      end
  end


  logic [31:0] hybrid_ch1_data_out;
  logic [31:0] hybrid_ch2_data_out;

  logic hybrid_ch1_data_valid_out, hybrid_ch2_data_valid_out;

  hybrid_synthesis HS_CH1_UUT(
      .clk(clk_100mhz),
      .rst(sys_rst),

      .window_switching_flag_in(hybrid_window_switching_flag_ch1),
      .block_type_in(hybrid_block_type_ch1),
      .mixed_block_flag_in(hybrid_mixed_block_flag_ch1),
      .new_frame_start(side_info_axiov),
      .x_in(granule_assembler_ch1_out),
      .din_valid(granule_assembler_valid_out),

      .x_out(hybrid_ch1_data_out),
      .dout_valid(hybrid_ch1_data_valid_out)
    );


  hybrid_synthesis HS_CH2_UUT(
      .clk(clk_100mhz),
      .rst(sys_rst),

      .window_switching_flag_in(hybrid_window_switching_flag_ch2),
      .block_type_in(hybrid_block_type_ch2),
      .mixed_block_flag_in(hybrid_mixed_block_flag_ch2),
      .new_frame_start(side_info_axiov),
      .x_in(granule_assembler_ch2_out),
      .din_valid(granule_assembler_valid_out),

      .x_out(hybrid_ch2_data_out),
      .dout_valid(hybrid_ch2_data_valid_out)
    );


  logic [31:0] freq_inverter_ch1_out, freq_inverter_ch2_out;
  logic freq_inverter_ch1_valid, freq_inverter_ch2_valid;

  frequency_inversion ch1_inverter (
      .clk(clk_100mhz),
      .rst(sys_rst),
      .new_frame_start(side_info_axiov),
      .x_in(hybrid_ch1_data_out),
      .x_valid_in(hybrid_ch1_data_valid_out),

      .x_out(freq_inverter_ch1_out),
      .x_valid_out(freq_inverter_ch1_valid)
    );

  frequency_inversion ch2_inverter (
      .clk(clk_100mhz),
      .rst(sys_rst),
      .new_frame_start(side_info_axiov),
      .x_in(hybrid_ch2_data_out),
      .x_valid_in(hybrid_ch2_data_valid_out),

      .x_out(freq_inverter_ch2_out),
      .x_valid_out(freq_inverter_ch2_valid)
    );

  logic [10:0] STORE_ADDRA;
  logic [31:0] STORE_OUTPUT;

  logic STATE;

  logic old_btnr;

  always_ff @(posedge clk_100mhz) begin
      if (sys_rst || side_info_axiov) begin
        STORE_ADDRA <= 0;
        STATE <= 0;
        old_btnr <= 0;
      end else begin
        old_btnr <= btnr;

        case(STATE)
          1'd0 : begin

            if (freq_inverter_ch1_valid) begin
              if (STORE_ADDRA == 11'd1151) begin
                STORE_ADDRA <= 0;
                STATE <= 1;
              end else begin
                STORE_ADDRA <= STORE_ADDRA + 1;
              end
            end
          end

          1'd1 : begin
            if (btnr && ~old_btnr) begin
              //this means to increment the data displayed by 1:
              STORE_ADDRA <= (STORE_ADDRA < 11'd1151) ? STORE_ADDRA + 1 : 0;
            end
          end
        endcase
      end
  end


  always_ff @(posedge clk_100mhz) begin
      if (sys_rst) begin
        READY <= 1;
      end else begin
        case(READY)
          1'd0 : begin
            if (STATE) begin
              READY <= 1;
            end
          end

          1'd1 : begin
            if (side_info_axiov) begin
              READY <= 0;
            end
          end
        endcase
      end
  end

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(1152),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) DATA_STORAGE (
    .addra(STORE_ADDRA),     // Address bus, width determined from RAM_DEPTH
    .dina(freq_inverter_ch1_out),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_100mhz),       // Clock
    .wea(freq_inverter_ch1_valid),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(sys_rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(STORE_OUTPUT)
    );



  assign led = STORE_OUTPUT[15:0];

endmodule


`default_nettype wire
