`timescale 1ns / 1ps
`default_nettype none

/*
this module directs the output of the SD card reader to other modules
it takes in a byte (from the sd card reader, sd_out)
and based on the byte counter (some value from 0-511)
it directs the info to:
  header
  side_info_1 (1 channel side information parser)
  side_info_2 (2 channel side information parser)
  fifo_buffer (main data...)
*/

module plexer(
    input wire clk,
    input wire rst,

    input wire axiiv,
    input wire [7:0] axiid,

    input wire valid_header,     //this is the output of the header module. says whether a valid header just passed
    input wire [1:0] mode,
    input wire prot,    //this is whether or not the header has a CRC16 protection (takes 2 more bytes after header), 1 == no protection
    input wire [10:0] frame_size,    //computed number of bytes in the frame...

    output logic crc_16_ov,
    output logic side_info_ov,
    output logic fifo_buffer_ov,      //output valids for all the downstream modules

    output logic data_out_valid,
    output logic [7:0] data_out
  );

  logic [11:0] byte_counter;
  logic [2:0] output_codeword;

  logic [1:0] crc_length;
  logic [5:0] side_info_length;
  logic [10:0] main_data_length;
  logic [10:0] frame_size_saved;
  logic old_valid_header;
  logic status;     //HIGH when it is parsing through a frame's data, LOW when waiting from a valid header

  assign {crc_16_ov, side_info_ov, fifo_buffer_ov} = output_codeword;

  always_ff @(posedge clk) begin
    if (rst) begin
      byte_counter    <= 0;
      output_codeword <= 0;
      status <= 0;
      data_out <= 0;
      data_out_valid <= 0;
    end else begin
            if (status) begin
              data_out_valid <= axiiv;
              if (axiiv) begin
                data_out <= axiid;
                byte_counter <= byte_counter + 1;
                if (byte_counter < (crc_length)) output_codeword <= 3'b100;
                else if (byte_counter < (crc_length + side_info_length)) output_codeword <= 3'b010;
                else if (byte_counter + 3'd4 < frame_size_saved) output_codeword <= 3'b001;
                else if (byte_counter + 3'd4 < frame_size_saved + 3'd3) output_codeword <= 3'b000;
                else begin
                  output_codeword <= 3'b000;
                  status <= 0;
                  byte_counter <= 0;
                end
              end
            end

            else if (valid_header) begin
            //this means a header was deteced. update the parameters of the frame:
            //note that we only check for these if we are not already reading in a frame's data.
                if (prot) crc_length            <= 2'd0;
                else crc_length                 <= 2'd2;

                if (mode == 3) side_info_length <= 6'd17;
                else side_info_length           <= 6'd32;

                frame_size_saved <= frame_size;
                status <= 1;

                byte_counter <= 0;
            end

            else begin
              output_codeword <= 3'b000;
            end
      end

    end

endmodule


`default_nettype wire
