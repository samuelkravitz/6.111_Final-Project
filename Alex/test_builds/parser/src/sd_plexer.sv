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

module sd_plexer(
    input wire clk,
    input wire rst,

    input wire sd_iv,
    input wire [7:0] sd_din,

    input wire header_iv,     //pulses for one clock cycle, tells us whether the header input data is valid or not
    input wire [1:0] mode,    //this is from the header module (circular logic lmao)
    input wire prot,    //this is whether or not the header has a CRC16 protection (takes 2 more bytes after header), 1 == no protection
    input wire [10:0] frame_size,    //computed number of bytes in the frame...

    output logic header_ov,
    output logic crc_16_ov,
    output logic side_info_1_ov,
    output logic side_info_2_ov,
    output logic fifo_buffer_ov,      //output valids for all the downstream modules

    output logic [7:0] d_out
  );

  logic [8:0] byte_counter;      //this counts from 0 to 511 (512 bytes), so it only needs 9 bits...
  logic [4:0] output_codeword;

  logic [3:0] header_length;
  logic [1:0] crc_length;
  logic [5:0] side_info_length;
  logic [10:0] main_data_length;

  assign {header_ov, crc_16_ov, side_info_1_ov, side_info_2_ov, fifo_buffer_ov} = output_codeword;
  assign main_data_length = frame_size - (header_length + crc_length + side_info_length);
  assign d_out = sd_din;

  always_ff @(posedge clk) begin
    if (rst) begin
      byte_counter    <= 0;
      output_codeword <= 0;
      header_length   <= 4'd4;
    end else begin

            if (sd_iv) begin
              byte_counter <= byte_counter + 1;

              if (byte_counter < header_length) begin
                output_codeword                 <= 5'b10000;
              end else if (byte_counter < (header_length + crc_length)) begin
                output_codeword                 <= 5'b01000;
              end else if (byte_counter < (header_length + crc_length + side_info_length)) begin
                if (mode == 3) output_codeword  <= 5'b00100;
                else output_codeword            <= 5'b00010;
              end else if (byte_counter < (header_length + crc_length + side_info_length + main_data_length)) begin
                output_codeword                 <= 5'b00001;
              end else begin
                output_codeword                 <= 5'b00000;
              end
            end else begin
              output_codeword                   <= 5'b00000;
            end


            //adjust frame delination parameters if the header has been fully processed.
            if (header_iv) begin
                header_length                   <= 4'd4;

                if (prot) crc_length            <= 2'd0;
                else crc_length                 <= 2'd2;

                if (mode == 3) side_info_length <= 6'd17;
                else side_info_length           <= 6'd32;
            end

      end

    end

endmodule


`default_nettype wire
