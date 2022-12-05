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
  input wire clk,
  input wire rst,

  input wire side_info_iv,
  input wire fifo_iv,
  input wire fifo_id,

  input wire [11:0] part2_3_length,
  input wire [3:0] scalefac_compress,
  input wire window_switching_flag,
  input wire mixed_block_flag,
  input wire [1:0] block_type,
  input wire [3:0] scfsi,
  input wire [3:0] region0_count,
  input wire [3:0] region1_count,
  input wire [8:0] big_values,
  input wire [2:0][4:0] table_select,
  input wire count1table_select,

  input wire gr,
  input wire ch,        //notes which channel and which granule the information stands for

  output logic done,
  output logic [20:0] scalefac_l,
  output logic [11:0][2:0] scalefac_s

  );

  logic read_status;
  logic [11:0] bit_counter;   //has to go as high as the part2_3_length number

  //variables are saved from the inputs when the header_iv or side_info_iv go high for a clk cycle
  logic [11:0] part2_3_length_save;
  logic [3:0] scalefac_compress_save;
  logic window_switching_flag_save;
  logic mixed_block_flag_save;
  logic [1:0] block_type_save;
  logic [3:0] scfsi_save;
  logic [3:0] region0_count_save;
  logic [3:0] region1_count_save;
  logic [8:0] big_values_save;
  logic [2:0][4:0] table_select_save;
  logic count1table_select_save;
  logic gr_save;
  logic ch_save;

  always_ff @(posedge clk) begin
    if (rst) begin
      //something...
      read_status <= 0;
      bit_counter <= 0;

      done <= 0;
      scalefac_l <= 0;
      scalefac_s <= 0;
    end else begin
      //START OF NEW DATA IN:
      if (side_info_iv) begin
        part2_3_length_save <= part2_3_length;
        scalefac_compress_save <= scalefac_compress;
        window_switching_flag_save <= window_switching_flag;
        mixed_block_flag_save <= mixed_block_flag;
        block_type_save <= block_type;
        scfsi_save <= scfsi;
        region0_count_save  <= region0_count;
        region1_count_save <= region1_count;
        big_values_save <= big_values;
        table_select_save <= table_select;
        count1table_select_save <= count1table_select;
        gr_save <= gr;
        ch_save <= ch;      //this is a way of remembering the important variables when they are valid.

        read_status <= 1;     //notates that we should begin reading information in.
        bit_counter <= 0;
      /// READ STATUS HIGH:
      end else if (read_status) begin
        if (bit_counter < part2_3_length_save) begin
          //read in data if it is available:
          if (fifo_iv) begin

          end

        end
      end
      ///END READ STATUS HIGH
    end
  end

endmodule

`default_nettype wire
