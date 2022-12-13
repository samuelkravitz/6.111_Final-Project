`default_nettype none
`timescale  1ns / 1ps


`define WAIT    3'b000      //wait for incoming side information
`define DISCARD 3'b001      //allow bits to fall out of the reservoir and not go anywhere!
`define HOLD    3'b010      //hold until the FIFO buffer has enough bits (already checked the reservoir bits)
`define SF      3'b011       //send data to the sf_parser
`define HUFFMAN 3'b100      //send data to the huffman tables

module fifo_processor(
  input wire clk,
  input wire rst,
  input wire [15:0] fifo_sample_count,
  input wire fifo_data_in,
  input wire fifo_din_v,

  input wire si_valid_in,
  input wire [8:0] main_data_begin,
  input wire [1:0][1:0][11:0] part2_3_length,

  input wire [3:0] sf_parser_axiov,

  output logic res_discard_flag,
  output logic sf_parser_flag,
  output logic hf_decoder_flag,
  output logic gr,
  output logic ch,
  output logic data_out,
  output logic data_out_valid,

  output logic fifo_bit_request

  );


  logic [2:0] stage;
  logic [15:0] bit_counter;
  logic [15:0] num_discard_bits;
  logic [1:0] grch;
  logic [15:0] discard_bit_counter;

  logic target_sf_axiov;
  logic [11:0] target_p23_length;

  always_comb begin
    case(grch)
      2'b00 : target_sf_axiov = sf_parser_axiov[3];
      2'b01 : target_sf_axiov = sf_parser_axiov[2];
      2'b10 : target_sf_axiov = sf_parser_axiov[1];
      2'b11 : target_sf_axiov = sf_parser_axiov[0];
    endcase
    case(grch)
      2'b00 : target_p23_length = part2_3_length[0][0];
      2'b01 : target_p23_length = part2_3_length[0][1];
      2'b10 : target_p23_length = part2_3_length[1][0];
      2'b11 : target_p23_length = part2_3_length[1][1];
    endcase
  end

  logic [1:0] [1:0] dout_type_pipe;
  logic [1:0] [1:0] grch_pipe;

  logic [1:0] sf_parser_delay_counter;


  always_ff @(posedge clk) begin
    if (rst) begin
      stage <= `WAIT;
      grch <= 0;
      bit_counter <= 0;
      discard_bit_counter <= 0;
      fifo_bit_request <= 0;
      num_discard_bits <= 0;
      dout_type_pipe <= 0;

      grch_pipe <= 0;
      sf_parser_delay_counter <= 0;
    end else begin
        if (si_valid_in) begin
          grch <= 0;
          discard_bit_counter <= 0;
          bit_counter <= 0;

          num_discard_bits <= (fifo_sample_count > (main_data_begin << 3)) ? fifo_sample_count - (main_data_begin << 3) : 0;

          if (fifo_sample_count == main_data_begin) begin
            stage <= `HOLD;
          end else if (fifo_sample_count > main_data_begin) begin
            stage <= `DISCARD;
          end else begin
            stage <= `WAIT;
          end
        end else begin
                  grch_pipe[1] <= grch_pipe[0];
                  grch_pipe[0] <= grch;

                  {gr,ch} <= grch_pipe[1];

                  dout_type_pipe[1] <= dout_type_pipe[0];

                  res_discard_flag <= (dout_type_pipe[1] == 2'd1) ? 1 : 0;
                  sf_parser_flag <= (dout_type_pipe[1] == 2'd2) ? 1 : 0;
                  hf_decoder_flag <= (dout_type_pipe[1] == 2'd3) ? 1 : 0;

                  data_out <= fifo_data_in;
                  data_out_valid <= fifo_din_v;

                  case(stage)
                    `WAIT : begin
                    ///nothing
                      bit_counter <= 0;
                      fifo_bit_request <= 0;
                      dout_type_pipe[0] <= 0;
                    end

                    `DISCARD : begin
                      if (discard_bit_counter == num_discard_bits) begin
                        fifo_bit_request <= 0;      //dont request a bit on this clock cycle!
                        stage <= `HOLD;
                        dout_type_pipe[0] <= 0;
                        discard_bit_counter <= 0;
                      end else begin
                        fifo_bit_request <= 1;    //request a discarding bit
                        stage <= `DISCARD;
                        discard_bit_counter <= discard_bit_counter + 1;
                        dout_type_pipe[0] <= 2'd1;
                      end
                    end

                    `HOLD : begin
                      dout_type_pipe[0] <= 2'd0;
                      fifo_bit_request <= 0;        //never request a bit here...
                      if (target_p23_length < fifo_sample_count) begin
                        stage <= `SF;
                        bit_counter <= 0;
                      end
                    end

                    `SF : begin
                      if (bit_counter == target_p23_length) begin
                        bit_counter <= 0;
                        stage <= (grch == 2'd3) ? `WAIT : `HOLD;
                        grch <= grch + 1;
                        fifo_bit_request <= 0;
                        dout_type_pipe[0] <= 0;
                      end else if (target_sf_axiov) begin
                        fifo_bit_request <= 0;
                        stage <= `HUFFMAN;
                        dout_type_pipe[0] <= 0;
                      end else begin
                        sf_parser_delay_counter <= sf_parser_delay_counter + 1;
                        if (sf_parser_delay_counter == 2'd3) begin
                          bit_counter <= bit_counter + 1;
                          fifo_bit_request <= 1;          //request SF bits!
                          dout_type_pipe[0] <= 2'd2;
                        end else begin
                          bit_counter <= bit_counter;
                          fifo_bit_request <= 0;
                          dout_type_pipe[0] <= 2'd0;
                        end
                      end
                    end

                    `HUFFMAN : begin
                      if (bit_counter == target_p23_length) begin
                        bit_counter <= 0;
                        stage <= (grch == 2'd3) ? `WAIT : `HOLD;
                        grch <= grch + 1;

                        fifo_bit_request <= 0;
                        dout_type_pipe[0] <= 0;

                      end else begin
                        bit_counter <= bit_counter + 1;
                        fifo_bit_request <= 1;
                        dout_type_pipe[0] <= 2'd3;
                      end

                    end


                  endcase

          end

    end
  end

endmodule
