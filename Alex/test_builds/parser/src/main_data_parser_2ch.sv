`default_nettype none
`timescale 1ns / 1ps

/*
parses main_data bits being read off from a FIFO buffer
assuming there are 2 channels in the data
this thing creates the scalefac_l and scalefac_s wires
and also decodes the huffman bits eventually and pumps them into
a different buffer.
note that the inputs here only correspond to 1 gr and 1 channel.
i will either instantiate 4 simultaneously or have this one parser do shit.
dunno whether we'll run out of space or time.
*/

module main_data_parser_2ch(
  input wire header_iv,
  input wire side_info_iv,
  input wire fifo_iv,
  input wire [7:0] fifo_id,

  input wire [11:0] part2_3_length,
  input wire [3:0] scalefac_compress,
  input wire window_switching_flag,
  input wire mixed_block_flag,
  input wire [1:0] block_type
  input wire [3:0] scfsi,
  input wire [3:0] region0_count,
  input wire [8:0] big_values,
  input wire [2:0][4:0] table_select,
  input wire count1table_select

  );

endmodule

`default_nettype wire
