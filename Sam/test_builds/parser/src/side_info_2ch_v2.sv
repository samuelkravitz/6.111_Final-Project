//Try 2, just make everything explicit and more verilogy
`default_nettype none
`timescale 1ns / 1ps

module side_info_2ch(
    input wire clk,
    input wire rst,
    input wire [7:0] axiid,
    input wire axiiv,

    output logic axiov,
    output logic [8:0] main_data_begin,
    output logic [2:0] private_bits,
    output logic [1:0][3:0] scfsi,
    output logic [1:0][1:0][11:0] part2_3_length,
    output logic [1:0][1:0][8:0] big_values,
    output logic [1:0][1:0][7:0] global_gain,
    output logic [1:0][1:0][3:0] scalefac_compress,
    output logic [1:0][1:0] window_switching_flag,
    output logic [1:0][1:0][1:0] block_type,
    output logic [1:0][1:0] mixed_block_flag,
    output logic [1:0][1:0][2:0][4:0] table_select,
    output logic [1:0][1:0][2:0][2:0] subblock_gain,
    output logic [1:0][1:0][3:0] region0_count,
    output logic [1:0][1:0][3:0] region1_count,       //note: you have to make this 4 bits long to account for the default case (=12 or 13)
    output logic [1:0][1:0] preflag,
    output logic [1:0][1:0] scalefac_scale,
    output logic [1:0][1:0] count1table_select
);

    logic [5:0] side_info_byte_counter;
    logic [23:0] side_info_buffer;        //at most we need to keep track of 3 bytes at a time

    always_ff @(posedge clk) begin
      if (rst) begin
        side_info_buffer <= 0;
        side_info_byte_counter <= 0;
        axiov <= 0;
      end else begin
          if (axiiv && (side_info_byte_counter != 6'd32)) begin
            side_info_buffer <= {side_info_buffer[15:0], axiid};

            side_info_byte_counter <= side_info_byte_counter + 1;
            axiov <= 0;

          end else if (axiiv) begin
            //this is a weird case (in anticipation) where there is incoming data but
            //the module was just about to finish processing and outputting the last set.
            //shouldn't happen because the data should come in really slowly (over 18 clock cycles)
            //but just in case:
            side_info_buffer <= {side_info_buffer[15:0], axiid};
            side_info_byte_counter <= 1;    //just set it at the right thing assuming this is the first byte
            axiov <= 0;   //skip sending out the last data, it was too slow.
          end else begin
            if (side_info_byte_counter == 6'd32) begin
              axiov <= 1;
              side_info_byte_counter <= 0;
            end else begin
              axiov <= 0;
            end
          end
      end
    end

    always_ff @(posedge clk) begin
      if (rst) begin
        main_data_begin <= 0;
        private_bits <= 0;
        scfsi <= 0;
        part2_3_length <= 0;
        big_values <= 0;
        global_gain <= 0;
        scalefac_compress <= 0;
        window_switching_flag <= 0;
        block_type <= 0;
        mixed_block_flag <= 0;
        table_select <= 0;
        subblock_gain <= 0;
        region0_count <= 0;
        region1_count <= 0;
        preflag <= 0;
        scalefac_scale <= 0;
        count1table_select <= 0;
      end else begin
            case (side_info_byte_counter)
              5'd1 : begin
                  end
              5'd2 : begin
                      main_data_begin   <= side_info_buffer[15:7];
                      private_bits      <= side_info_buffer[6:4];
                      scfsi[0][0]       <= side_info_buffer[3];
                      scfsi[0][1]       <= side_info_buffer[2];
                      scfsi[0][2]       <= side_info_buffer[1];
                      scfsi[0][3]       <= side_info_buffer[0];
                  end
              5'd3 : begin
                      scfsi[1][0] <= side_info_buffer[7];
                      scfsi[1][1] <= side_info_buffer[6];
                      scfsi[1][2] <= side_info_buffer[5];
                      scfsi[1][3] <= side_info_buffer[4];
                    end
              5'd4 : begin
                      part2_3_length[0][0] <= side_info_buffer[11:0];
                    end
              5'd5 : begin

                    end
              5'd6 : begin
                      big_values[0][0] <= side_info_buffer[15:7];
                    end
              5'd7 : begin
                      global_gain[0][0] <= side_info_buffer[14:7];
                      scalefac_compress[0][0] <= side_info_buffer[6:3];
                      window_switching_flag[0][0] <= side_info_buffer[2];
                    end
              5'd8 : begin
                      if (window_switching_flag[0][0]) begin
                        block_type[0][0] <= side_info_buffer[9:8];
                        mixed_block_flag[0][0] <= side_info_buffer[7];
                        table_select[0][0][0] <= side_info_buffer[6:2];
                      end else begin
                        table_select[0][0][0] <= side_info_buffer[9:5];
                        table_select[0][0][1] <= side_info_buffer[4:0];
                      end
                    end
              5'd9 : begin
                      if (window_switching_flag[0][0]) begin
                        table_select[0][0][1] <= side_info_buffer[9:5];
                        table_select[0][0][2] <= 0;    //default value, this branch has no third region.
                        subblock_gain[0][0][0] <= side_info_buffer[4:2];
                      end else begin
                        table_select[0][0][2] <= side_info_buffer[7:3];
                      end
                    end
              5'd10 : begin
                      if (window_switching_flag[0][0]) begin
                        subblock_gain[0][0][1] <= side_info_buffer[9:7];
                        subblock_gain[0][0][2] <= side_info_buffer[6:4];
                        if ( (block_type[0][0] == 2) && (mixed_block_flag[0][0] == 0) ) begin
                          region0_count[0][0] <= 4'd8;
                          region1_count[0][0] <= 4'd12;
                        end else begin
                          region0_count[0][0] <= 4'd7;
                          region1_count[0][0] <= 4'd13;
                        end
                      end else begin
                        region0_count[0][0] <= side_info_buffer[10:7];
                        region1_count[0][0] <= side_info_buffer[6:4];
                        block_type[0][0] <= 0;
                      end

                      preflag[0][0] <= side_info_buffer[3];
                      scalefac_scale[0][0] <= side_info_buffer[2];
                      count1table_select[0][0] <= side_info_buffer[1];
                    end
              5'd11 : begin
                      //there is not enough data to make the next part2_3_length...
                    end
              5'd12 : begin
                      part2_3_length[0][1] <= side_info_buffer[16:5];
                    end
              5'd13 : begin
                      big_values[0][1] <= side_info_buffer[12:4];
                    end
              5'd14 : begin
                      global_gain[0][1] <= side_info_buffer[11:4];
                      scalefac_compress[0][1] <= side_info_buffer[3:0];
                    end
              5'd15 : begin
                      window_switching_flag[0][1] <= side_info_buffer[7];
                    end //end this early cus we need the current result for the next branch
              5'd16 : begin
                      if (window_switching_flag[0][1]) begin
                        block_type[0][1] <= side_info_buffer[14:13];
                        mixed_block_flag[0][1] <= side_info_buffer[12];
                        table_select[0][1][0] <= side_info_buffer[11:7];
                        table_select[0][1][1] <= side_info_buffer[6:2];
                        table_select[0][1][2] <= 0;    //default value
                      end else begin
                        table_select[0][1][0] <= side_info_buffer[14:10];
                        table_select[0][1][1] <= side_info_buffer[9:5];
                        table_select[0][1][2] <= side_info_buffer[4:0];
                      end
                    end
              5'd17 : begin
                      if (window_switching_flag[0][1]) begin
                        subblock_gain[0][1][0] <= side_info_buffer[9:7];
                        subblock_gain[0][1][1] <= side_info_buffer[6:4];
                        subblock_gain[0][1][2] <= side_info_buffer[3:1];
                        if ( (block_type[0][1] == 2) && (mixed_block_flag[0][1] == 0) ) begin
                          region0_count[0][1] <= 4'd8;
                          region1_count[0][1] <= 4'd12;
                        end else begin
                          region0_count[0][1] <= 4'd7;
                          region1_count[0][1] <= 4'd13;
                        end
                      end else begin
                        region0_count[0][1] <= side_info_buffer[7:4];
                        region1_count[0][1] <= side_info_buffer[3:1];
                        block_type[0][1] <= 0;   //implicit.
                        end
                    preflag[0][1] <= side_info_buffer[0];
                  end
              5'd18 : begin
                      scalefac_scale[0][1] <= side_info_buffer[7];
                      count1table_select[0][1] <= side_info_buffer[6];
                    end
              5'd19 : begin
                      part2_3_length[1][0] <= side_info_buffer[13:2];
                    end
              5'd20 : begin
                      big_values[1][0] <= side_info_buffer[9:1];
                    end
              5'd21 : begin
                      global_gain[1][0] <= side_info_buffer[8:1];
                    end
              5'd22 : begin
                      scalefac_compress[1][0] <= side_info_buffer[8:5];
                      window_switching_flag[1][0] <= side_info_buffer[4];
                    end
              5'd23 : begin
                      if (window_switching_flag[1][0]) begin
                        block_type[1][0] <= side_info_buffer[11:10];
                        mixed_block_flag[1][0] <= side_info_buffer[9];
                        table_select[1][0][0] <= side_info_buffer[8:4];
                      end else begin
                        table_select[1][0][0] <= side_info_buffer[11:7];
                        table_select[1][0][1] <= side_info_buffer[6:2];
                      end
                    end
              5'd24 : begin
                      if (window_switching_flag[1][0]) begin
                        table_select[1][0][1] <= side_info_buffer[11:7];
                        table_select[1][0][2] <= 0;     //default value
                        subblock_gain[1][0][0] <= side_info_buffer[6:4];
                        subblock_gain[1][0][1] <= side_info_buffer[3:1];
                      end else begin
                        table_select[1][0][2] <= side_info_buffer[9:5];
                        region0_count[1][0] <= side_info_buffer[4:1];
                      end
                    end
              5'd25 : begin
                      if (window_switching_flag[1][0]) begin
                        subblock_gain[1][0][2] <= side_info_buffer[8:6];
                        if ( (block_type[1][0] == 2) && (mixed_block_flag[1][0] == 0) ) begin
                          region0_count[1][0] <= 4'd8;
                          region1_count[1][0] <= 4'd12;
                        end else begin
                          region0_count[1][0] <= 4'd7;
                          region1_count[1][0] <= 4'd13;
                        end
                      end else begin
                        region1_count[1][0] <= side_info_buffer[8:6];
                        block_type[1][0] <= 0;
                      end
                      preflag[1][0] <= side_info_buffer[5];
                      scalefac_scale[1][0] <= side_info_buffer[4];
                      count1table_select[1][0] <= side_info_buffer[3];
                    end
              5'd26 : begin
                      //not enough bits
                    end
              5'd27 : begin
                      part2_3_length[1][1] <= side_info_buffer[18:7];
                    end
              5'd28 : begin
                      big_values[1][1] <= side_info_buffer[14:6];
                    end
              5'd29 : begin
                      global_gain[1][1] <= side_info_buffer[13:6];
                      scalefac_compress[1][1] <= side_info_buffer[5:2];
                      window_switching_flag[1][1] <= side_info_buffer[1];
                    end
              5'd30 : begin
                      if (window_switching_flag[1][1]) begin
                        block_type[1][1] <= side_info_buffer[8:7];
                        mixed_block_flag[1][1] <= side_info_buffer[6];
                        table_select[1][1][0] <= side_info_buffer[5:1];
                      end else begin
                        table_select[1][1][0] <= side_info_buffer[8:4];
                      end
                    end
              5'd31 : begin
                      if (window_switching_flag[1][1]) begin
                        table_select[1][1][1] <= side_info_buffer[8:4];
                        table_select[1][1][2] <= 0;   //default value
                        subblock_gain[1][1][0] <= side_info_buffer[3:1];
                      end else begin
                        table_select[1][1][1] <= side_info_buffer[11:7];
                        table_select[1][1][2] <= side_info_buffer[6:2];
                      end
                    end
              6'd32 : begin
                      if (window_switching_flag[1][1]) begin
                        subblock_gain[1][1][1] <= side_info_buffer[8:6];
                        subblock_gain[1][1][2] <= side_info_buffer[5:3];
                        if ( (block_type[1][1] == 2) && (mixed_block_flag[1][1] == 0) ) begin
                          region0_count[1][1] <= 4'd8;
                          region1_count[1][1] <= 4'd12;
                        end else begin
                          region0_count[1][1] <= 4'd7;
                          region1_count[1][1] <= 4'd13;
                        end
                      end else begin
                        region0_count[1][1] <= side_info_buffer[9:6];
                        region1_count[1][1] <= side_info_buffer[5:3];
                        block_type[1][1] <= 0;
                      end
                      preflag[1][1] <= side_info_buffer[2];
                      scalefac_scale[1][1] <= side_info_buffer[1];
                      count1table_select[1][1] <= side_info_buffer[0];   //tada
                    end
            endcase
      end

    end





endmodule
