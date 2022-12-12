`default_nettype none
`timescale 1ns / 1ps

module top_level(
  input wire clk_100mhz,
  input wire btnc,
  input wire btnu,
  input wire btnd,
  input wire [15:0] sw,
  input wire sd_cd,

  inout wire [3:0] sd_dat,

  output  logic sd_reset, 
  output  logic sd_sck, 
  output  logic sd_cmd,
  output logic [15:0] led,
  output logic ca, cb, cc, cd, ce, cf, cg,
  output logic [7:0] an
  );

  logic sys_rst;
  assign sys_rst = btnc;

  logic clk_25mhz;
  clk_wiz_0 clocks(.clk_in1(clk_100mhz), .clk_out1(clk_25mhz));

  assign sd_dat[2:1] = 2'b11;

  logic rd;                   // read enable
  logic wr;                   // write enable
  logic [7:0] din;            // data to sd card
  logic [31:0] addr;          // starting address for read/write operation
  
  // sd_controller outputs
  logic ready;                // high when ready for new read/write operation
  logic [7:0] dout;           // data from sd card
  logic byte_available;       // high when byte available for read
  logic ready_for_next_byte;  // high when ready for new byte to be written

  logic old_byte_avail;
  
  // handles reading from the SD card
  sd_controller sd(.reset(sys_rst), .clk(clk_25mhz), .cs(sd_dat[3]), .mosi(sd_cmd), 
                  .miso(sd_dat[0]), .sclk(sd_sck), .ready(ready), .address(addr),
                  .rd(rd), .dout(dout), .byte_available(byte_available),
                  .wr(wr), .din(din), .ready_for_next_byte(ready_for_next_byte));

  logic [31:0] byte_index;
  logic [31:0] to_seven;
  logic clean_down;

  debouncer down_button(
    .clk_in(clk_100mhz),
    .rst_in(sys_rst),
    .dirty_in(btnd),
    .clean_out(clean_down)
  );

  logic old_clean;

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      byte_index <= 0;
    end else if (~old_clean && clean_down) begin
      byte_index <= byte_index + 1;
    end else begin
      byte_index <= byte_index;
    end
    old_clean <= clean_down;
  end

  logic [7:0] sd_ram_out;
  logic [15:0] read_counter;

  always_ff @(posedge clk_100mhz) begin
    if (sys_rst) begin
      read_counter <= 0;
    end else begin
      read_counter <= (~old_byte_avail && byte_available) ? read_counter + 1 : read_counter;
      old_byte_avail <= byte_available;
    end
  end

  logic [15:0] bram_add;
  always_comb begin
    bram_add = (read_counter < 512) ? read_counter : byte_index;
  end

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(512),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image_BROM (
    .addra(bram_add),     // Address bus, width determined from RAM_DEPTH
    .dina(dout),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_100mhz),       // Clock
    .wea((~old_byte_avail && byte_available) && (read_counter < 512)),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(sys_rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(sd_ram_out)      // RAM output data, width determined from RAM_WIDTH
  );

  always_comb begin
    to_seven = {16'd0, read_counter};
  end

  seven_segment_controller #(.COUNT_TO('d100_000)) sev_seg
                        (.clk_in(clk_100mhz),
                        .rst_in(sys_rst),
                        .val_in(to_seven),
                        .cat_out({cg, cf, ce, cd, cc, cb, ca}),
                        .an_out(an)
                        );

  always_ff @(posedge clk_100mhz) begin
    if(sys_rst) begin
      rd <= 0;
      wr <= 0;
      din <= 0;
      addr <= 0;
    end else if (ready && (read_counter < 512)) begin
      addr <= 31'd512;
      rd <= 1;
    end else begin
      led[14:0] <= read_counter;
      rd <= 0;
      wr <= 0;
      din <= 0;
      addr <= 0;
    end
    led[15] <= ready;
  end
  //6 and 0 on?

  // logic [7:0] bram_axiod;
  // logic bram_axiov;

  

  // bram_feeder data_out (
  //     .clk(clk_100mhz),
  //     .rst(sys_rst),
  //     .frame_num_iv(btnu),
  //     .frame_num_id(sw),
  //     .axiod(bram_axiod),
  //     .axiov(bram_axiov)
  //   );


  logic valid_header;
  logic prot;
  logic [1:0] mode, mode_ext, emphasis;
  logic [10:0] frame_size;

  header_finder light (
      .clk(clk_100mhz),
      .rst(sys_rst),
      // .axiid(bram_axiod),
      // .axiiv(bram_axiov),
      .axiid(dout),
      .axiiv(~old_byte_avail && byte_available),
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
      // .axiid(bram_axiod),
      // .axiiv(bram_axiov),
      .axiid(dout),
      .axiiv(~old_byte_avail && byte_available),
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

  // always_ff @(posedge clk_100mhz) begin
  //   if (sys_rst) begin
  //     led[8:0] <= 0;
  //   end else begin
  //     led[8:0] = (side_info_axiov) ? main_data_begin : led[8:0];
  //   end
  // end

endmodule

`default_nettype wire
