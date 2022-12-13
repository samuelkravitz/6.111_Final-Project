`default_nettype none
`timescale 1ns / 1ps

/*
this module takes in a bit by bit serial input and figures out the scalefactor
values (for a single granule and channel).
it has an internal counter that knows how many bits it needs,
but it otherwise operates as normal no matter what
so the parent module should first pump it with useful SI and then
one by one with the corresponding btis for that ch and gr.
the SI can be pumped simultaneously with the first bit.
this last part was tested by teh sf_parser_tb (look for the second SI HIGH,
it is paired with incoming data.)

*/

module sf_parser #(parameter GR = 0,
                   parameter CH = 0)
(
  input wire clk,
  input wire rst,
  input wire axiid,
  input wire axiiv,

  input wire si_valid,
  input wire [3:0] scalefac_compress_in,
  input wire window_switching_flag_in,
  input wire [1:0] block_type_in,
  input wire mixed_block_flag_in,
  input wire [3:0] scfsi_in,

  output logic [11:0][2:0][3:0] scalefac_s,
  output logic [20:0][3:0] scalefac_l,
  output logic axiov
  );

    logic [2:0] bitlen_1, bitlen_2; //maximum value of 4
    logic [8:0] A, B, C, D;

    logic TAGA0, TAGA1, TAGA2;
    logic TAGB0, TAGB1, TAGB2;
    logic TAGC0, TAGC1, TAGC2;
    logic TAGD0, TAGD1, TAGD2;
    logic [8:0] TAGA3, TAGB3, TAGC3, TAGD3;

    logic [11:0] part2_3_length;
    logic [3:0] scalefac_compress;
    logic window_switching_flag;
    logic [1:0] block_type;
    logic mixed_block_flag;
    logic [3:0] scfsi;

    always_comb begin
      case(scalefac_compress)
        4'd0    : bitlen_1 = 0;
        4'd1    : bitlen_1 = 0;
        4'd2    : bitlen_1 = 0;
        4'd3    : bitlen_1 = 0;
        4'd4    : bitlen_1 = 3;
        4'd5    : bitlen_1 = 1;
        4'd6    : bitlen_1 = 1;
        4'd7    : bitlen_1 = 1;
        4'd8    : bitlen_1 = 2;
        4'd9    : bitlen_1 = 2;
        4'd10   : bitlen_1 = 2;
        4'd11   : bitlen_1 = 3;
        4'd12   : bitlen_1 = 3;
        4'd13   : bitlen_1 = 3;
        4'd14   : bitlen_1 = 4;
        4'd15   : bitlen_1 = 4;
      endcase
      case(scalefac_compress)
        4'd0    : bitlen_2 = 0;
        4'd1    : bitlen_2 = 1;
        4'd2    : bitlen_2 = 2;
        4'd3    : bitlen_2 = 3;
        4'd4    : bitlen_2 = 0;
        4'd5    : bitlen_2 = 1;
        4'd6    : bitlen_2 = 2;
        4'd7    : bitlen_2 = 3;
        4'd8    : bitlen_2 = 1;
        4'd9    : bitlen_2 = 2;
        4'd10   : bitlen_2 = 3;
        4'd11   : bitlen_2 = 1;
        4'd12   : bitlen_2 = 2;
        4'd13   : bitlen_2 = 3;
        4'd14   : bitlen_2 = 2;
        4'd15   : bitlen_2 = 3;
      endcase

      // A = (~scfsi[0] || ~GR) ? bitlen_1 * 6 : 9'd0;
      // B = (~scfsi[1] || ~GR) ? bitlen_1 * 5 : 9'd0;
      // C = (~scfsi[2] || ~GR) ? bitlen_2 * 5 : 9'd0;
      // D = (~scfsi[3] || ~GR) ? bitlen_2 * 5 : 9'd0;



      TAGA0 = ~scfsi[0];
      TAGA1 = ~GR;
      TAGA2 = (TAGA0 || TAGA1);
      TAGA3 = (TAGA0 || TAGA1) ? bitlen_1 * 6 : 0;
      A = TAGA3;                                         /////WHY DO I HAVE TO DO THIS????

      TAGB0 = ~scfsi[1];
      TAGB1 = ~GR;
      TAGB2 = (TAGB0 || TAGB1);
      TAGB3 = (TAGB0 || TAGB1) ? bitlen_1 * 5 : 0;
      B = TAGB3;                                         /////WHY DO I HAVE TO DO THIS????

      TAGC0 = ~scfsi[2];
      TAGC1 = ~GR;
      TAGC2 = (TAGC0 || TAGC1);
      TAGC3 = (TAGC0 || TAGC1) ? bitlen_2 * 5 : 0;
      C = TAGC3;                                         /////WHY DO I HAVE TO DO THIS????

      TAGD0 = ~scfsi[3];
      TAGD1 = ~GR;
      TAGD2 = (TAGD0 || TAGD1);
      TAGD3 = (TAGD0 || TAGD1) ? bitlen_2 * 5 : 0;
      D = TAGD3;                                         /////WHY DO I HAVE TO DO THIS????

    end



    logic [3:0] buffer;   //needs atmost 4 bits at a time.
    logic [31:0] bit_counter;  //idk what the max is. whatever
    logic [2:0] shift_1, shift_2;

    assign shift_1 = 3'd4 - bitlen_1;
    assign shift_2 = 3'd4 - bitlen_2;   //these are useful terms for bitshifting

    always_comb begin
      if (window_switching_flag && (block_type == 2) && mixed_block_flag) begin
        axiov = (bit_counter == (27 * bitlen_1 + 18 * bitlen_2)) ? 1 : 0;
      end else if (window_switching_flag && (block_type == 2)) begin
        axiov = (bit_counter == (18 * bitlen_1 + 18 * bitlen_2)) ? 1 : 0;
      end else begin
        axiov = (bit_counter == A + B + C + D) ? 1: 0;
      end
    end

    always_ff @(posedge clk) begin
      if (rst) begin
        scalefac_l <= 0;
        scalefac_s <= 0;
        buffer <= 0;
        bit_counter <= 0;
      end else begin
        if (si_valid) begin
          scalefac_compress <= scalefac_compress_in;
          window_switching_flag <= window_switching_flag_in;
          block_type <= block_type_in;
          mixed_block_flag <= mixed_block_flag_in;
          scfsi <= scfsi_in;

          //also just reset all the other variables for now:
          bit_counter <= (axiiv) ? 1 : 0;
          buffer <= (axiiv) ? {3'd0, axiid} : 4'd0;    //accommodate getting information along with SI stuff.
          scalefac_l <= 0;
          scalefac_s <= 0;
        end
        else if (axiov) begin
          bit_counter <= (axiiv) ? 1 : 0;
          buffer <= (axiiv) ? {3'd0, axiid} : 4'd0;    //accommodate getting information along with SI stuff.
          scalefac_l <= 0;
          scalefac_s <= 0;
        end else begin

                        if (axiiv) begin
                          buffer <= {buffer[2:0], axiid};
                          bit_counter <= bit_counter + 1;
                        end


                        if (window_switching_flag && (block_type == 2) && (mixed_block_flag)) begin
                              //BRANCH 1:
                              if      (bit_counter == 1 * (bitlen_1)) scalefac_l[0] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == 2 * (bitlen_1)) scalefac_l[1] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == 3 * (bitlen_1)) scalefac_l[2] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == 4 * (bitlen_1)) scalefac_l[3] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == 5 * (bitlen_1)) scalefac_l[4] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == 6 * (bitlen_1)) scalefac_l[5] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == 7 * (bitlen_1)) scalefac_l[6] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == 8 * (bitlen_1)) scalefac_l[7] <= (buffer << shift_1) >> shift_1;

                              else if (bit_counter == (9  * bitlen_1)) scalefac_s[3][0] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (10 * bitlen_1)) scalefac_s[3][1] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (11 * bitlen_1)) scalefac_s[3][2] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (12 * bitlen_1)) scalefac_s[4][0] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (13 * bitlen_1)) scalefac_s[4][1] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (14 * bitlen_1)) scalefac_s[4][2] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (15 * bitlen_1)) scalefac_s[5][0] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (16 * bitlen_1)) scalefac_s[5][1] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (17 * bitlen_1)) scalefac_s[5][2] <= (buffer << shift_1) >> shift_1;

                              else if (bit_counter == (17 * bitlen_1 + 1  * bitlen_2)) scalefac_s[6 ][0] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (17 * bitlen_1 + 2  * bitlen_2)) scalefac_s[6 ][1] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (27 * bitlen_1 + 3  * bitlen_2)) scalefac_s[6 ][2] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (17 * bitlen_1 + 4  * bitlen_2)) scalefac_s[7 ][0] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (17 * bitlen_1 + 5  * bitlen_2)) scalefac_s[7 ][1] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (27 * bitlen_1 + 6  * bitlen_2)) scalefac_s[7 ][2] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (17 * bitlen_1 + 7  * bitlen_2)) scalefac_s[8 ][0] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (17 * bitlen_1 + 8  * bitlen_2)) scalefac_s[8 ][1] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (27 * bitlen_1 + 9  * bitlen_2)) scalefac_s[8 ][2] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (17 * bitlen_1 + 10 * bitlen_2)) scalefac_s[9 ][0] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (17 * bitlen_1 + 11 * bitlen_2)) scalefac_s[9 ][1] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (27 * bitlen_1 + 12 * bitlen_2)) scalefac_s[9 ][2] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (17 * bitlen_1 + 13 * bitlen_2)) scalefac_s[10][0] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (17 * bitlen_1 + 14 * bitlen_2)) scalefac_s[10][1] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (27 * bitlen_1 + 15 * bitlen_2)) scalefac_s[10][2] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (17 * bitlen_1 + 16 * bitlen_2)) scalefac_s[11][0] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (17 * bitlen_1 + 17 * bitlen_2)) scalefac_s[11][1] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (27 * bitlen_1 + 18 * bitlen_2)) begin
                                scalefac_s[11][2] <= (buffer << shift_2) >> shift_2;
                                end
                        end

                        else if (window_switching_flag && (block_type == 2)) begin
                          //Branch 2:

                              if      (bit_counter == (1 * bitlen_1)) scalefac_s[0][0] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (2 * bitlen_1)) scalefac_s[0][1] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (3 * bitlen_1)) scalefac_s[0][2] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (4 * bitlen_1)) scalefac_s[1][0] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (5 * bitlen_1)) scalefac_s[1][1] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (6 * bitlen_1)) scalefac_s[1][2] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (7 * bitlen_1)) scalefac_s[2][0] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (8 * bitlen_1)) scalefac_s[2][1] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (9 * bitlen_1)) scalefac_s[2][2] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (10 * bitlen_1)) scalefac_s[3][0] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (11 * bitlen_1)) scalefac_s[3][1] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (12 * bitlen_1)) scalefac_s[3][2] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (13 * bitlen_1)) scalefac_s[4][0] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (14 * bitlen_1)) scalefac_s[4][1] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (15 * bitlen_1)) scalefac_s[4][2] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (16 * bitlen_1)) scalefac_s[5][0] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (17 * bitlen_1)) scalefac_s[5][1] <= (buffer << shift_1) >> shift_1;
                              else if (bit_counter == (18 * bitlen_1)) scalefac_s[5][2] <= (buffer << shift_1) >> shift_1;

                              else if (bit_counter == (18 * bitlen_1 + 1  * bitlen_2)) scalefac_s[6 ][0] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 2  * bitlen_2)) scalefac_s[6 ][1] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 3  * bitlen_2)) scalefac_s[6 ][2] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 4  * bitlen_2)) scalefac_s[7 ][0] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 5  * bitlen_2)) scalefac_s[7 ][1] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 6  * bitlen_2)) scalefac_s[7 ][2] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 7  * bitlen_2)) scalefac_s[8 ][0] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 8  * bitlen_2)) scalefac_s[8 ][1] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 9  * bitlen_2)) scalefac_s[8 ][2] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 10 * bitlen_2)) scalefac_s[9 ][0] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 11 * bitlen_2)) scalefac_s[9 ][1] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 12 * bitlen_2)) scalefac_s[9 ][2] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 13 * bitlen_2)) scalefac_s[10][0] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 14 * bitlen_2)) scalefac_s[10][1] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 15 * bitlen_2)) scalefac_s[10][2] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 16 * bitlen_2)) scalefac_s[11][0] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 17 * bitlen_2)) scalefac_s[11][1] <= (buffer << shift_2) >> shift_2;
                              else if (bit_counter == (18 * bitlen_1 + 18 * bitlen_2)) begin
                                scalefac_s[11][2] <= (buffer << shift_2) >> shift_2;
                              end
                        end

                        else begin
                          //the default window. dont worry about copying over teh scalefactors when the gr == 1 here. do that upstream
                          if (~GR) begin
                            if      (bit_counter == 1 * (bitlen_1)) scalefac_l[0] <= (buffer << shift_1) >> shift_1;
                            else if (bit_counter == 2 * (bitlen_1)) scalefac_l[1] <= (buffer << shift_1) >> shift_1;
                            else if (bit_counter == 3 * (bitlen_1)) scalefac_l[2] <= (buffer << shift_1) >> shift_1;
                            else if (bit_counter == 4 * (bitlen_1)) scalefac_l[3] <= (buffer << shift_1) >> shift_1;
                            else if (bit_counter == 5 * (bitlen_1)) scalefac_l[4] <= (buffer << shift_1) >> shift_1;
                            else if (bit_counter == 6 * (bitlen_1)) scalefac_l[5] <= (buffer << shift_1) >> shift_1;

                            else if (bit_counter == 7 * (bitlen_1)) scalefac_l[6]  <= (buffer << shift_1) >> shift_1;
                            else if (bit_counter == 8 * (bitlen_1)) scalefac_l[7]  <= (buffer << shift_1) >> shift_1;
                            else if (bit_counter == 9 * (bitlen_1)) scalefac_l[8]  <= (buffer << shift_1) >> shift_1;
                            else if (bit_counter == 10 * (bitlen_1)) scalefac_l[9]  <= (buffer << shift_1) >> shift_1;
                            else if (bit_counter == 11 * (bitlen_1)) scalefac_l[10] <= (buffer << shift_1) >> shift_1;

                            else if (bit_counter == (11 * bitlen_1) + (1 * bitlen_2)) scalefac_l[11]  <= (buffer << shift_2) >> shift_2;
                            else if (bit_counter == (11 * bitlen_1) + (2 * bitlen_2)) scalefac_l[12]  <= (buffer << shift_2) >> shift_2;
                            else if (bit_counter == (11 * bitlen_1) + (3 * bitlen_2)) scalefac_l[13]  <= (buffer << shift_2) >> shift_2;
                            else if (bit_counter == (11 * bitlen_1) + (4 * bitlen_2)) scalefac_l[14]  <= (buffer << shift_2) >> shift_2;
                            else if (bit_counter == (11 * bitlen_1) + (5 * bitlen_2)) scalefac_l[15]  <= (buffer << shift_2) >> shift_2;

                            if      (bit_counter == (11 * bitlen_1) + 6 *  (bitlen_2)) scalefac_l[16]  <= (buffer << shift_2) >> shift_2;
                            else if (bit_counter == (11 * bitlen_1) + 7 *  (bitlen_2)) scalefac_l[17]  <= (buffer << shift_2) >> shift_2;
                            else if (bit_counter == (11 * bitlen_1) + 8 *  (bitlen_2)) scalefac_l[18]  <= (buffer << shift_2) >> shift_2;
                            else if (bit_counter == (11 * bitlen_1) + 9 *  (bitlen_2)) scalefac_l[19]  <= (buffer << shift_2) >> shift_2;
                            else if (bit_counter == (11 * bitlen_1) + 10 * (bitlen_2)) scalefac_l[20]  <= (buffer << shift_2) >> shift_2;

                          end else begin
                              if (~scfsi[0]) begin
                                if      (bit_counter == 1 * (bitlen_1)) scalefac_l[0] <= (buffer << shift_1) >> shift_1;
                                else if (bit_counter == 2 * (bitlen_1)) scalefac_l[1] <= (buffer << shift_1) >> shift_1;
                                else if (bit_counter == 3 * (bitlen_1)) scalefac_l[2] <= (buffer << shift_1) >> shift_1;
                                else if (bit_counter == 4 * (bitlen_1)) scalefac_l[3] <= (buffer << shift_1) >> shift_1;
                                else if (bit_counter == 5 * (bitlen_1)) scalefac_l[4] <= (buffer << shift_1) >> shift_1;
                                else if (bit_counter == 6 * (bitlen_1)) scalefac_l[5] <= (buffer << shift_1) >> shift_1;
                              end

                              if (~scfsi[1]) begin
                                if      (bit_counter == A + 1 * (bitlen_1)) scalefac_l[6]  <= (buffer << shift_1) >> shift_1;
                                else if (bit_counter == A + 2 * (bitlen_1)) scalefac_l[7]  <= (buffer << shift_1) >> shift_1;
                                else if (bit_counter == A + 3 * (bitlen_1)) scalefac_l[8]  <= (buffer << shift_1) >> shift_1;
                                else if (bit_counter == A + 4 * (bitlen_1)) scalefac_l[9]  <= (buffer << shift_1) >> shift_1;
                                else if (bit_counter == A + 5 * (bitlen_1)) scalefac_l[10] <= (buffer << shift_1) >> shift_1;
                              end

                              if (~scfsi[2]) begin
                                if      (bit_counter == (A + B) + (1 * bitlen_2)) scalefac_l[11]  <= (buffer << shift_2) >> shift_2;
                                else if (bit_counter == (A + B) + (2 * bitlen_2)) scalefac_l[12]  <= (buffer << shift_2) >> shift_2;
                                else if (bit_counter == (A + B) + (3 * bitlen_2)) scalefac_l[13]  <= (buffer << shift_2) >> shift_2;
                                else if (bit_counter == (A + B) + (4 * bitlen_2)) scalefac_l[14]  <= (buffer << shift_2) >> shift_2;
                                else if (bit_counter == (A + B) + (5 * bitlen_2)) scalefac_l[15]  <= (buffer << shift_2) >> shift_2;
                              end

                              if (~scfsi[3]) begin
                                if      (bit_counter == (A + B + C) + 1 *  (bitlen_2)) scalefac_l[16]  <= (buffer << shift_2) >> shift_2;
                                else if (bit_counter == (A + B + C) + 2 *  (bitlen_2)) scalefac_l[17]  <= (buffer << shift_2) >> shift_2;
                                else if (bit_counter == (A + B + C) + 3 *  (bitlen_2)) scalefac_l[18]  <= (buffer << shift_2) >> shift_2;
                                else if (bit_counter == (A + B + C) + 4 *  (bitlen_2)) scalefac_l[19]  <= (buffer << shift_2) >> shift_2;
                                else if (bit_counter == (A + B + C) + 5 * (bitlen_2)) begin
                                  scalefac_l[20]  <= (buffer << shift_2) >> shift_2;
                                end
                              end
                            end
                        end




        end
      end
    end

endmodule

`default_nettype wire
