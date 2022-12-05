`default_nettype none
`timescale 1ns / 1ps

module sf_parser(
  input wire clk,
  input wire rst,
  input wire axiid,
  input wire axiiv,

  input wire gr,
  input wire [3:0] scalefac_compress,
  input wire window_switching_flag,
  input wire [1:0] block_type,
  input wire mixed_block_flag,
  input wire [3:0] scfsi,
  input wire si_valid,

  output logic [11:0][2:0] scalefac_s,
  output logic [20:0] scalefac_l,
  output logic axiov
  );

    logic bitlen_1, bitlen_2;

    logic [11:0] part2_3_length_save;
    logic [3:0] scalefac_compress_save;
    logic window_switching_flag_save;
    logic [1:0] block_type_save;
    logic mixed_block_flag_save;
    logic [3:0] scfsi_save;
    logic si_valid_save;
    logic gr_save;

    always_comb begin
      case(scalefac_compress_save)
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
      case(scalefac_compress_save)
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
    end

    logic [3:0] buffer;   //needs atmost 4 bits at a time.
    logic [31:0] bit_counter;  //idk what the max is. whatever
    logic done;       //cus there is not specific count for when tis finished...

    logic [2:0] shift_1, shift_2;

    assign shift_1 = 3'd4 - bitlen_1;
    assign shift_2 = 3'd4 - bitlen_2;   //these are useful terms for bitshifting

    always_ff @(posedge clk) begin
      if (rst) begin
        scalefac_l <= 0;
        scalefac_s <= 0;
        buffer <= 0;
        bit_counter <= 0;
        axiov <= 0;
      end else begin
        if (si_valid) begin
          scalefac_compress_save <= scalefac_compress;
          window_switching_flag_save <= window_switching_flag;
          block_type_save <= block_type;
          mixed_block_flag_save <= mixed_block_flag;
          scfsi_save <= scfsi;
          gr_save <= gr;

          //also just reset all the other variables for now:
          axiov <= 0;
          bit_counter <= (axiiv) ? 1 : 0;
          buffer <= (axiiv) ? {3'd0, axiid} : 4'd0;    //accommodate getting information along with SI stuff.
          scalefac_l <= 0;
          scalefac_s <= 0;
        end
        else if (axiov) begin
          axiov <= 0;
          bit_counter <= 0;
          buffer <= 0;
          scalefac_l <= 0;
          scalefac_s <= 0;
        end
        else if (axiiv) begin
          buffer <= {buffer[3:0], axiid};
          bit_counter <= bit_counter + 1;
          axiov <= 0;
        end
        else begin

                if (window_switching_flag_save && (block_type_save == 2) && (mixed_block_flag_save)) begin
                      //BRANCH 1:
                      if      (bit_counter == 1 * (bitlen_1)) scalefac_l[0] <= (buffer << shift_1) >> shift_1;
                      else if (bit_counter == 2 * (bitlen_1)) scalefac_l[1] <= (buffer << shift_1) >> shift_1;
                      else if (bit_counter == 3 * (bitlen_1)) scalefac_l[2] <= (buffer << shift_1) >> shift_1;
                      else if (bit_counter == 4 * (bitlen_1)) scalefac_l[3] <= (buffer << shift_1) >> shift_1;
                      else if (bit_counter == 5 * (bitlen_1)) scalefac_l[4] <= (buffer << shift_1) >> shift_1;
                      else if (bit_counter == 6 * (bitlen_1)) scalefac_l[5] <= (buffer << shift_1) >> shift_1;
                      else if (bit_counter == 7 * (bitlen_1)) scalefac_l[6] <= (buffer << shift_1) >> shift_1;
                      else if (bit_counter == 8 * (bitlen_1)) scalefac_l[7] <= (buffer << shift_1) >> shift_1;
                end

                else if (window_switching_flag_save && (block_type_save == 2)) begin
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
                        axiov <= 1;
                      end

                end

                else begin
                  //the default window. dont worry about copying over teh scalefactors when the gr == 1 here. do that upstream
                  if ((~gr_save) || ~scfsi_save[0]) begin
                    if      (bit_counter == 1 * (bitlen_1)) scalefac_l[0] <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == 2 * (bitlen_1)) scalefac_l[1] <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == 3 * (bitlen_1)) scalefac_l[2] <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == 4 * (bitlen_1)) scalefac_l[3] <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == 5 * (bitlen_1)) scalefac_l[4] <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == 6 * (bitlen_1)) scalefac_l[5] <= (buffer << shift_1) >> shift_1;
                  end

                  if (~gr_save || ~scfsi_save[1]) begin
                    if      (bit_counter == 7 * (bitlen_1)) scalefac_l[6]  <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == 8 * (bitlen_1)) scalefac_l[7]  <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == 9 * (bitlen_1)) scalefac_l[8]  <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == 10 * (bitlen_1)) scalefac_l[9]  <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == 11 * (bitlen_1)) scalefac_l[10] <= (buffer << shift_1) >> shift_1;
                  end

                  if (~gr_save || ~scfsi_save[2]) begin
                    if      (bit_counter == (11 * bitlen_1) + (1 * bitlen_2)) scalefac_l[11]  <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == (11 * bitlen_1) + (2 * bitlen_2)) scalefac_l[12]  <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == (11 * bitlen_1) + (3 * bitlen_2)) scalefac_l[13]  <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == (11 * bitlen_1) + (4 * bitlen_2)) scalefac_l[14]  <= (buffer << shift_1) >> shift_1;
                    else if (bit_counter == (11 * bitlen_1) + (5 * bitlen_2)) scalefac_l[15]  <= (buffer << shift_1) >> shift_1;
                  end

                  if (~gr_save || ~scfsi_save[3]) begin
                    if      (bit_counter == (11 * bitlen_1) + 6 *  (bitlen_2)) scalefac_l[16]  <= (buffer << shift_2) >> shift_2;
                    else if (bit_counter == (11 * bitlen_1) + 7 *  (bitlen_2)) scalefac_l[17]  <= (buffer << shift_2) >> shift_2;
                    else if (bit_counter == (11 * bitlen_1) + 8 *  (bitlen_2)) scalefac_l[18]  <= (buffer << shift_2) >> shift_2;
                    else if (bit_counter == (11 * bitlen_1) + 9 *  (bitlen_2)) scalefac_l[19]  <= (buffer << shift_2) >> shift_2;
                    else if (bit_counter == (11 * bitlen_1) + 10 * (bitlen_2)) begin
                      scalefac_l[20]  <= (buffer << shift_2) >> shift_2;
                      axiov <= 1;
                    end
                  end



                end




        end
      end
    end

endmodule

`default_nettype wire
