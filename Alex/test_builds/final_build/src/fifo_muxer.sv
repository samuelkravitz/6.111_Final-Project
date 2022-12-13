`default_nettype none
`timescale 1ns / 1ps

`define WAIT    3'b000      //wait for incoming side information
`define DISCARD 3'b001      //allow bits to fall out of the reservoir and not go anywhere!
`define HOLD    3'b010      //hold until the FIFO buffer has enough bits (already checked the reservoir bits)
`define SF      3'b011       //send data to the sf_parser
`define HUFFMAN 3'b100      //send data to the huffman tables

module fifo_muxer(
    input wire clk,
    input wire rst,
    input wire [15:0] fifo_sample_count,
    input wire fifo_dout_v,

    input wire si_valid_in,
    input wire [8:0] main_data_begin,
    input wire [1:0][1:0][11:0] part2_3_length,

    input wire [3:0] sf_parser_axiov,   //this is the output validity from the SF parser

    output logic res_discard_flag,
    output logic sf_parser_flag,
    output logic hf_decoder_flag,
    output logic gr,
    output logic ch
);

  logic [2:0] stage;
  logic [15:0] bit_counter;
  logic [15:0] discard_bit_counter;
  logic [15:0] num_discard_bits;
  logic [1:0] grch;   //just a quick trick
  logic [8:0] main_data_begin_save;
  logic [1:0][1:0][11:0] part2_3_length_save;

  logic target_sf_axiov;
  logic [11:0] target_p23_length;

  assign {gr,ch} = grch;    //you see. this automatically rolls over.

  always_comb begin
    case(grch)
      2'b00 : target_sf_axiov = sf_parser_axiov[3];
      2'b01 : target_sf_axiov = sf_parser_axiov[2];
      2'b10 : target_sf_axiov = sf_parser_axiov[1];
      2'b11 : target_sf_axiov = sf_parser_axiov[0];
    endcase
    case(grch)
      2'b00 : target_p23_length = part2_3_length_save[0][0];
      2'b01 : target_p23_length = part2_3_length_save[0][1];
      2'b10 : target_p23_length = part2_3_length_save[1][0];
      2'b11 : target_p23_length = part2_3_length_save[1][1];
    endcase
  end

  always_comb begin
    sf_parser_flag = (~target_sf_axiov) && (stage == `SF);
    hf_decoder_flag = (stage == `HUFFMAN) && (bit_counter <= target_p23_length);
    res_discard_flag = (stage == `DISCARD) && (discard_bit_counter < num_discard_bits);
  end


    always_ff @(posedge clk) begin
      if (rst) begin
        stage <= `WAIT;
        grch <= 0;
        bit_counter <= 0;
        discard_bit_counter <= 0;
      end else begin
        if (si_valid_in) begin
          //RESET ALL PARAMETERS:
          grch <= 0;
          discard_bit_counter <= 0;
          bit_counter <= 0;
          //FIRST: save all the parameters from the inputs
          main_data_begin_save <= main_data_begin;
          part2_3_length_save <= part2_3_length;
          num_discard_bits <= (fifo_sample_count >= (main_data_begin << 3)) ? fifo_sample_count - (main_data_begin << 3) : 0;    //i don't want to deal with underflow

          if (fifo_sample_count == main_data_begin) begin
            stage <= `HOLD;   //the reservoir has exactly the right number of bits, no need to discard
          end else if (fifo_sample_count > main_data_begin) begin
            stage <= `DISCARD;
          end else begin
            stage <= `WAIT;   //the reservoir does NOT have enough bits, just skip processing this frame and wait for the next one
          end

          //SECOND: check to see whether there is enough data in the buffer: (reservoir bits now)
          // if (fifo_sample_count > main_data_begin) begin
          //   //here we can use main_data_begin just cus we know it is valid right now
          //   stage <= `HOLD;
          // end else stage <= `WAIT;     //we cant progress to the next stage because there is not enough data in reservoir
        end

        else begin
          case(stage)
            `WAIT : begin
              //don't do anything until si_valid in goes high bruh
              end
            `DISCARD : begin
              discard_bit_counter <= discard_bit_counter + 1;
              if (discard_bit_counter == num_discard_bits) begin
                stage <= `HOLD;   //now we can progress onto
              end
            end
            `HOLD : begin
                if (target_p23_length < fifo_sample_count) begin
                  stage <= `SF;  //progress to the scalefactor parsing stage
                  bit_counter <= 0;   //reset bit counter to 0.
                end
              end
            `SF : begin
                if (bit_counter == target_p23_length) begin
                  //skip the huffman coding cus this has run out of bits:
                  bit_counter <= 0;
                  stage <= (grch == 2'd3) ? `WAIT : `HOLD;
                  grch <= grch + 1;
                end else if ( ~target_sf_axiov ) begin
                  // bit_counter <= (fifo_dout_v) ? bit_counter + 1 : bit_counter;
                  bit_counter <= bit_counter + 1;
                end else begin
                  stage <= `HUFFMAN;
                  // bit_counter <= (fifo_dout_v) ? bit_counter + 1 : bit_counter;
                  bit_counter <= bit_counter + 1;
                end
              end
            `HUFFMAN : begin
                if (bit_counter + 1'b1 < target_p23_length) begin
                  // bit_counter <= (fifo_dout_v) ? bit_counter + 1 : bit_counter;
                  bit_counter <= bit_counter + 1;
                end else begin
                  bit_counter <= 0;
                  stage <= (grch == 2'd3) ? `WAIT : `HOLD;  //go back to waiting stage if both granules and channels are done
                  grch <= grch + 1;
                end
              end
          endcase
        end
      end
    end

endmodule

`default_nettype wire















// `default_nettype none
// `timescale 1ns / 1ps
//
// `define WAIT    3'b000      //wait for incoming side information
// `define DISCARD 3'b001      //allow bits to fall out of the reservoir and not go anywhere!
// `define HOLD    3'b010      //hold until the FIFO buffer has enough bits (already checked the reservoir bits)
// `define SF      3'b011       //send data to the sf_parser
// `define HUFFMAN 3'b100      //send data to the huffman tables
//
// module fifo_muxer(
//     input wire clk,
//     input wire rst,
//     input wire [15:0] fifo_sample_count,
//     input wire fifo_dout_v,
//
//     input wire si_valid_in,
//     input wire [8:0] main_data_begin,
//     input wire [1:0][1:0][11:0] part2_3_length,
//
//     input wire [3:0] sf_parser_axiov,   //this is the output validity from the SF parser
//
//     output logic res_discard_flag,
//     output logic sf_parser_flag,
//     output logic hf_decoder_flag,
//     output logic gr,
//     output logic ch
// );
//
//   logic [2:0] stage;
//   logic [15:0] bit_counter;
//   logic [15:0] discard_bit_counter;
//   logic [15:0] num_discard_bits;
//   logic [1:0] grch;   //just a quick trick
//   logic [8:0] main_data_begin_save;
//   logic [1:0][1:0][11:0] part2_3_length_save;
//
//   logic target_sf_axiov;
//   logic [11:0] target_p23_length;
//
//   assign {gr,ch} = grch;    //you see. this automatically rolls over.
//
//   always_comb begin
//     case(grch)
//       2'b00 : target_sf_axiov = sf_parser_axiov[3];
//       2'b01 : target_sf_axiov = sf_parser_axiov[2];
//       2'b10 : target_sf_axiov = sf_parser_axiov[1];
//       2'b11 : target_sf_axiov = sf_parser_axiov[0];
//     endcase
//     case(grch)
//       2'b00 : target_p23_length = part2_3_length_save[0][0];
//       2'b01 : target_p23_length = part2_3_length_save[0][1];
//       2'b10 : target_p23_length = part2_3_length_save[1][0];
//       2'b11 : target_p23_length = part2_3_length_save[1][1];
//     endcase
//   end
//
//   always_comb begin
//     sf_parser_flag = (~target_sf_axiov) && (stage == `SF);
//     hf_decoder_flag = (stage == `HUFFMAN) && (bit_counter <= target_p23_length);
//     res_discard_flag = (stage == `DISCARD) && (discard_bit_counter < num_discard_bits);
//   end
//
//
//     always_ff @(posedge clk) begin
//       if (rst) begin
//         stage <= `WAIT;
//         grch <= 0;
//         bit_counter <= 0;
//         discard_bit_counter <= 0;
//       end else begin
//         if (si_valid_in) begin
//           //RESET ALL PARAMETERS:
//           grch <= 0;
//           discard_bit_counter <= 0;
//           bit_counter <= 0;
//           //FIRST: save all the parameters from the inputs
//           main_data_begin_save <= main_data_begin;
//           part2_3_length_save <= part2_3_length;
//           num_discard_bits <= (fifo_sample_count >= main_data_begin) ? fifo_sample_count - main_data_begin : 0;    //i don't want to deal with underflow
//
//           if (fifo_sample_count == main_data_begin) begin
//             stage <= `HOLD;   //the reservoir has exactly the right number of bits, no need to discard
//           end else if (fifo_sample_count > main_data_begin) begin
//             stage <= `DISCARD;
//           end else begin
//             stage <= `WAIT;   //the reservoir does NOT have enough bits, just skip processing this frame and wait for the next one
//           end
//
//           //SECOND: check to see whether there is enough data in the buffer: (reservoir bits now)
//           // if (fifo_sample_count > main_data_begin) begin
//           //   //here we can use main_data_begin just cus we know it is valid right now
//           //   stage <= `HOLD;
//           // end else stage <= `WAIT;     //we cant progress to the next stage because there is not enough data in reservoir
//         end
//
//         else begin
//           case(stage)
//             `WAIT : begin
//               //don't do anything until si_valid in goes high bruh
//               end
//             `DISCARD : begin
//               discard_bit_counter <= discard_bit_counter + 1;
//               if (discard_bit_counter == num_discard_bits) begin
//                 stage <= `HOLD;   //now we can progress onto
//               end
//             end
//             `HOLD : begin
//                 if (target_p23_length < fifo_sample_count) begin
//                   stage <= `SF;  //progress to the scalefactor parsing stage
//                   bit_counter <= 0;   //reset bit counter to 0.
//                 end
//               end
//             `SF : begin
//                 if (bit_counter == target_p23_length) begin
//                   //skip the huffman coding cus this has run out of bits:
//                   bit_counter <= 0;
//                   stage <= (grch == 2'd3) ? `WAIT : `HOLD;
//                   grch <= grch + 1;
//                 end else if ( ~target_sf_axiov ) begin
//                   bit_counter <= (fifo_dout_v) ? bit_counter + 1 : bit_counter;
//                 end else begin
//                   stage <= `HUFFMAN;
//                   bit_counter <= (fifo_dout_v) ? bit_counter + 1 : bit_counter;
//                 end
//               end
//             `HUFFMAN : begin
//                 if (bit_counter < target_p23_length) begin
//                   bit_counter <= (fifo_dout_v) ? bit_counter + 1 : bit_counter;
//                 end else begin
//                   bit_counter <= 0;
//                   stage <= (grch == 2'd3) ? `WAIT : `HOLD;  //go back to waiting stage if both granules and channels are done
//                   grch <= grch + 1;
//                 end
//               end
//           endcase
//         end
//       end
//     end
//
// endmodule
//
// `default_nettype wire
