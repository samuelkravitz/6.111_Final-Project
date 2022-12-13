`timescale 1ns / 1ps
`default_nettype none

module top_level(
  input wire clk_100mhz,
  input wire btnc,
  input wire btnu,
  input wire [15:0] sw,

  output logic [15:0] led
  );

    logic sys_rst;
    assign sys_rst = btnc;

    logic clk_25mhz, clk_8mhz;
    logic clk_gen_locked;



    clk_wiz_0_clk_wiz clk_gen(
      .clk_25mhz(clk_25mhz),
      .clk_8mhz(clk_8mhz),
      .reset(sys_rst),
      .locked(clk_gen_locked),
      .clk_100mhz(clk_100mhz)
    );

    logic [7:0] bram_axiod;
    logic bram_axiov;

    bram_feeder data_out (
        .clk(clk_25mhz),
        .rst(sys_rst),
        .frame_num_iv(btnu),
        .frame_num_id(sw[6:0]),
        .axiod(bram_axiod),
        .axiov(bram_axiov)
      );

    logic header_axiov;
    logic prot;
    logic [8:0] bitrate;
    logic [15:0] samp_rate;
    logic padding;
    logic private;
    logic [1:0] mode;
    logic [1:0] mode_ext;
    logic [1:0] emphasis;
    logic [8:0] frame_sample;
    logic [2:0] slot_size;
    logic [10:0] frame_size;

    logic header_iv;
    logic crc_16_iv;
    logic side_info_1_iv;
    logic side_info_2_iv;
    logic fifo_buffer_iv;

    logic [7:0] plexer_dout;

    sd_plexer muxer (
        .clk(clk_25mhz),
        .rst(sys_rst),
        .sd_iv(bram_axiov),
        .sd_din(bram_axiod),
        .header_iv(header_axiov),
        .mode(mode),
        .prot(prot),
        .frame_size(frame_size),
        .header_ov(header_iv),
        .crc_16_ov(crc_16_iv),
        .side_info_1_ov(side_info_1_iv),
        .side_info_2_ov(side_info_2_iv),
        .fifo_buffer_ov(fifo_buffer_iv),
        .d_out(plexer_dout)
      );

    header h_parser(
        .clk(clk_25mhz),
        .rst(sys_rst),
        .axiid(plexer_dout),
        .axiiv(header_iv),
        .axiov(header_axiov),
        .prot(prot),
        .bitrate(bitrate),
        .samp_rate(samp_rate),
        .padding(padding),
        .private(private),
        .mode(mode),
        .mode_ext(mode_ext),
        .emphasis(emphasis),
        .frame_sample(frame_sample),
        .slot_size(slot_size),
        .frame_size(frame_size)
      );

      always_ff @(posedge clk_25mhz) begin
        if (header_axiov) begin
          led[8:0] <= bitrate;
        end
      end

endmodule

`default_nettype wire
