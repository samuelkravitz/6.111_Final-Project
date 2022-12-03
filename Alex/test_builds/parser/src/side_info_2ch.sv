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
    output logic [3:0][1:0][1:0] scalefac_compress,
    output logic [1:0][1:0] window_switching_flag,
    output logic [1:0][1:0][1:0] block_type,
    output logic [1:0][1:0] mixed_block_flag,

    output logic [1:0][1:0][4:0] table_select_1,
    output logic [1:0][1:0][4:0] table_select_2,
    output logic [1:0][1:0][4:0] table_select_3,

    output logic [1:0][1:0][2:0] subblock_gain_1,
    output logic [1:0][1:0][2:0] subblock_gain_2,
    output logic [1:0][1:0][2:0] subblock_gain_3,

    output logic [1:0][1:0][3:0] region0_count,
    output logic [1:0][1:0][2:0] region1_count,
    output logic [1:0][1:0] preflag,
    output logic [1:0][1:0] scalefac_scale,
    output logic [1:0][1:0] count1table_select
);

  logic [255:0] side_info;
  logic [4:0] side_info_byte_counter;

  always_ff @(posedge clk) begin
    if (rst) begin
      side_info <= 0;
      side_info_byte_counter <= 0;
      axiov <= 0;
    end else begin
        if (axiiv) begin
          side_info <= {side_info[247:0], axiid};

          if (side_info_byte_counter == 5'd31) begin
            axiov <= 1;
            side_info_byte_counter <= 0;
          end else begin
            side_info_byte_counter <= side_info_byte_counter + 1;
            axiov <= 0;
          end
        end else begin
          axiov <= 0;
        end
    end
  end

  assign main_data_begin = side_info[255:247];
  assign private_bits = side_info[246:244];

  /// logic for assigning all the variables according to the data in side_info
  logic [1:0][3:0] scfsi_branch_1;
  logic [1:0][1:0][11:0] part2_3_length_branch_1;
  logic [1:0][1:0][8:0] big_values_branch_1;
  logic [1:0][1:0][7:0] global_gain_branch_1;
  logic [3:0][1:0][1:0] scalefac_compress_branch_1;
  logic [1:0][1:0] window_switching_flag_branch_1;
  logic [1:0][1:0][1:0] block_type_branch_1;
  logic [1:0][1:0] mixed_block_flag_branch_1;

  logic [1:0][1:0][4:0] table_select_1_branch_1;
  logic [1:0][1:0][4:0] table_select_2_branch_1;
  logic [1:0][1:0][4:0] table_select_3_branch_1;

  logic [1:0][1:0][2:0] subblock_gain_1_branch_1;
  logic [1:0][1:0][2:0] subblock_gain_2_branch_1;
  logic [1:0][1:0][2:0] subblock_gain_3_branch_1;

  logic [1:0][1:0][3:0] region0_count_branch_1;
  logic [1:0][1:0][2:0] region1_count_branch_1;
  logic [1:0][1:0] preflag_branch_1;
  logic [1:0][1:0] scalefac_scale_branch_1;
  logic [1:0][1:0] count1table_select_branch_1;


  //branch 2: window_switching_flag is not 1
  logic [1:0][3:0] scfsi_branch_2;
  logic [1:0][1:0][11:0] part2_3_length_branch_2;
  logic [1:0][1:0][8:0] big_values_branch_2;
  logic [1:0][1:0][7:0] global_gain_branch_2;
  logic [3:0][1:0][1:0] scalefac_compress_branch_2;
  logic [1:0][1:0] window_switching_flag_branch_2;
  logic [1:0][1:0][1:0] block_type_branch_2;
  logic [1:0][1:0] mixed_block_flag_branch_2;

  logic [1:0][1:0][4:0] table_select_1_branch_2;
  logic [1:0][1:0][4:0] table_select_2_branch_2;
  logic [1:0][1:0][4:0] table_select_3_branch_2;

  logic [1:0][1:0][2:0] subblock_gain_1_branch_2;
  logic [1:0][1:0][2:0] subblock_gain_2_branch_2;
  logic [1:0][1:0][2:0] subblock_gain_3_branch_2;

  logic [1:0][1:0][3:0] region0_count_branch_2;
  logic [1:0][1:0][2:0] region1_count_branch_2;
  logic [1:0][1:0] preflag_branch_2;
  logic [1:0][1:0] scalefac_scale_branch_2;
  logic [1:0][1:0] count1table_select_branch_2;


  always_comb begin
          int ptr_1;
          int ptr_2;
          ptr_1 = 243;
          ptr_2 = 243;

          ///BRANCH 1: (window_switching_flag is 1)--these have to be explicitly enumerated.
          //CH == 0:    (I can't have a for loop on the earlist variable for some reason, kill me)
          for (int scfsi_band = 0; scfsi_band < 4; scfsi_band += 1) begin
            scfsi_branch_1[0][scfsi_band] = side_info[ptr_1-:1]; ptr_1 -= 1;
          end

          //CH == 1:
          for (int scfsi_band = 0; scfsi_band < 4; scfsi_band += 1) begin
            scfsi_branch_1[1][scfsi_band] = side_info[ptr_1-:1]; ptr_1 -= 1;
          end


          //GR == 0:
          for (int ch=0; ch < 2; ch += 1) begin
              part2_3_length_branch_1[0][ch] = side_info[ptr_1-:12]; ptr_1 -= 12;
              big_values_branch_1[0][ch] = side_info[ptr_1-:9]; ptr_1 -= 9;
              global_gain_branch_1[0][ch] = side_info[ptr_1-:8]; ptr_1 -= 8;

              scalefac_compress_branch_1[0][ch] = side_info[ptr_1-:4]; ptr_1 -= 4;
              window_switching_flag_branch_1[0][ch] = side_info[ptr_1-:1]; ptr_1 -= 1;

              //Here is where the branch would have occured: (if window_switching_flag == 1)
              block_type_branch_1[0][ch] = side_info[ptr_1-:2]; ptr_1 -= 2;
              mixed_block_flag_branch_1[0][ch] = side_info[ptr_1-:1]; ptr_1 -= 1;

              //for region in range(2)...
              table_select_1_branch_1[0][ch] = side_info[ptr_1-:5]; ptr_1 -= 5;
              table_select_2_branch_1[0][ch] = side_info[ptr_1-:5]; ptr_1 -= 5;
              table_select_3_branch_1[0][ch] = 5'd0;     //this one is a default to zero for this case.

              //for window in range(3)...
              subblock_gain_1_branch_1[0][ch] = side_info[ptr_1-:3]; ptr_1 -= 3;
              subblock_gain_2_branch_1[0][ch] = side_info[ptr_1-:3]; ptr_1 -= 3;
              subblock_gain_3_branch_1[0][ch] = side_info[ptr_1-:3]; ptr_1 -= 3;

              //and take care of defaulting values here:
              if ( (block_type_branch_1[0][ch] == 2) && (mixed_block_flag_branch_1[0][ch] == 0) ) begin
                  region0_count_branch_1[0][ch] = 4'd8;
              end else begin
                region0_count_branch_1[0][ch] = 4'd7;
              end
              region1_count_branch_1[0][ch] = 20 - region0_count_branch_1[0][ch];

              preflag_branch_1[0][ch] = side_info[ptr_1-:1]; ptr_1 -= 1;
              scalefac_scale_branch_1[0][ch] = side_info[ptr_1-:1]; ptr_1 -= 1;
              count1table_select_branch_1[0][ch] = side_info[ptr_1-:1]; ptr_1 -= 1;
          end

          //gr == 2:
          for (int ch=0; ch < 2; ch += 1) begin
              part2_3_length_branch_1[1][ch] = side_info[ptr_1-:12]; ptr_1 -= 12;
              big_values_branch_1[1][ch] = side_info[ptr_1-:9]; ptr_1 -= 9;
              global_gain_branch_1[1][ch] = side_info[ptr_1-:8]; ptr_1 -= 8;

              scalefac_compress_branch_1[1][ch] = side_info[ptr_1-:4]; ptr_1 -= 4;
              window_switching_flag_branch_1[1][ch] = side_info[ptr_1-:1]; ptr_1 -= 1;

              //Here is where the branch would have occured: (if window_switching_flag == 1)
              block_type_branch_1[1][ch] = side_info[ptr_1-:2]; ptr_1 -= 2;
              mixed_block_flag_branch_1[1][ch] = side_info[ptr_1-:1]; ptr_1 -= 1;

              //for region in range(2)...
              table_select_1_branch_1[1][ch] = side_info[ptr_1-:5]; ptr_1 -= 5;
              table_select_2_branch_1[1][ch] = side_info[ptr_1-:5]; ptr_1 -= 5;
              table_select_3_branch_1[1][ch] = 5'd0;     //this one is a default to zero for this case.

              //for window in range(3)...
              subblock_gain_1_branch_1[1][ch] = side_info[ptr_1-:3]; ptr_1 -= 3;
              subblock_gain_2_branch_1[1][ch] = side_info[ptr_1-:3]; ptr_1 -= 3;
              subblock_gain_3_branch_1[1][ch] = side_info[ptr_1-:3]; ptr_1 -= 3;

              //and take care of defaulting values here:
              if ( (block_type_branch_1[1][ch] == 2) && (mixed_block_flag_branch_1[1][ch] == 0) ) begin
                  region0_count_branch_1[1][ch] = 4'd8;
              end else begin
                region0_count_branch_1[1][ch] = 4'd7;
              end
              region1_count_branch_1[1][ch] = 20 - region0_count_branch_1[1][ch];

              preflag_branch_1[1][ch] = side_info[ptr_1-:1]; ptr_1 -= 1;
              scalefac_scale_branch_1[1][ch] = side_info[ptr_1-:1]; ptr_1 -= 1;
              count1table_select_branch_1[1][ch] = side_info[ptr_1-:1]; ptr_1 -= 1;
          end



          //////branch 2:
          //CH == 0:    (I can't have a for loop on the earlist variable for some reason, kill me)
          for (int scfsi_band = 0; scfsi_band < 4; scfsi_band += 1) begin
            scfsi_branch_2[0][scfsi_band] = side_info[ptr_2-:1]; ptr_2 -= 1;
          end

          //CH == 1:
          for (int scfsi_band = 0; scfsi_band < 4; scfsi_band += 1) begin
            scfsi_branch_2[1][scfsi_band] = side_info[ptr_2-:1]; ptr_2 -= 1;
          end


          //GR == 0:
          for (int ch=0; ch < 2; ch += 1) begin
              part2_3_length_branch_2[0][ch] = side_info[ptr_2-:12]; ptr_2 -= 12;
              big_values_branch_2[0][ch] = side_info[ptr_2-:9]; ptr_2 -= 9;
              global_gain_branch_2[0][ch] = side_info[ptr_2-:8]; ptr_2 -= 8;

              scalefac_compress_branch_2[0][ch] = side_info[ptr_2-:4]; ptr_2 -= 4;
              window_switching_flag_branch_2[0][ch] = side_info[ptr_2-:1]; ptr_2 -= 1;

              // now go down the branch where window_switching_flag == 0:
              table_select_1_branch_2[0][ch] = side_info[ptr_2-:5]; ptr_2 -= 5;
              table_select_2_branch_2[0][ch] = side_info[ptr_2-:5]; ptr_2 -= 5;
              table_select_3_branch_2[0][ch] = side_info[ptr_2-:5]; ptr_2 -= 5;

              region0_count_branch_2[0][ch] = side_info[ptr_2-:4]; ptr_2 -= 4;
              region1_count_branch_2[0][ch] = side_info[ptr_2-:3]; ptr_2 -= 3;
              block_type_branch_2[0][ch] = 0;     //implicit from the PDMP3 library

          end

          //gr == 2:
          for (int ch=0; ch < 2; ch += 1) begin
              part2_3_length_branch_2[1][ch] = side_info[ptr_2-:12]; ptr_2 -= 12;
              big_values_branch_2[1][ch] = side_info[ptr_2-:9]; ptr_2 -= 9;
              global_gain_branch_2[1][ch] = side_info[ptr_2-:8]; ptr_2 -= 8;

              scalefac_compress_branch_2[1][ch] = side_info[ptr_2-:4]; ptr_2 -= 4;
              window_switching_flag_branch_2[1][ch] = side_info[ptr_2-:1]; ptr_2 -= 1;

              // now go down the branch where window_switching_flag == 0:
              table_select_1_branch_2[1][ch] = side_info[ptr_2-:5]; ptr_2 -= 5;
              table_select_2_branch_2[1][ch] = side_info[ptr_2-:5]; ptr_2 -= 5;
              table_select_3_branch_2[1][ch] = side_info[ptr_2-:5]; ptr_2 -= 5;

              region0_count_branch_2[1][ch] = side_info[ptr_2-:4]; ptr_2 -= 4;
              region1_count_branch_2[1][ch] = side_info[ptr_2-:3]; ptr_2 -= 3;
              block_type_branch_2[1][ch] = 0;     //implicit from the PDMP3 library

          end
  end


  //choose which branch to return:
  always_comb begin
      scfsi = scfsi_branch_1;
      part2_3_length = part2_3_length_branch_1;
      big_values = big_values_branch_1;
      global_gain = global_gain_branch_1;
      scalefac_compress = scalefac_scale_branch_1;
      window_switching_flag = window_switching_flag_branch_1;

      //granule 0:
      for (int ch = 0; ch < 2; ch += 1) begin
        mixed_block_flag[0][ch] = (window_switching_flag[0][ch]) ? mixed_block_flag_branch_1[0][ch] : mixed_block_flag_branch_2[0][ch];
        subblock_gain_1[0][ch] = (window_switching_flag[0][ch]) ? subblock_gain_1_branch_1[0][ch] : subblock_gain_1_branch_2[0][ch];
        subblock_gain_2[0][ch] = (window_switching_flag[0][ch]) ? subblock_gain_2_branch_1[0][ch] : subblock_gain_2_branch_2[0][ch];
        subblock_gain_3[0][ch] = (window_switching_flag[0][ch]) ? subblock_gain_3_branch_1[0][ch] : subblock_gain_3_branch_2[0][ch];
        block_type[0][ch] = (window_switching_flag[0][ch]) ? block_type_branch_1[0][ch] : block_type_branch_2[0][ch];
        table_select_1[0][ch] = (window_switching_flag[0][ch]) ? table_select_1_branch_1[0][ch] : table_select_1_branch_2[0][ch];
        table_select_2[0][ch] = (window_switching_flag[0][ch]) ? table_select_2_branch_1[0][ch] : table_select_2_branch_2[0][ch];
        table_select_3[0][ch] = (window_switching_flag[0][ch]) ? table_select_3_branch_1[0][ch] : table_select_3_branch_2[0][ch];
        region0_count[0][ch] = (window_switching_flag[0][ch]) ? region0_count_branch_1[0][ch] : region0_count_branch_2[0][ch];
        region1_count[0][ch] = (window_switching_flag[0][ch]) ? region1_count_branch_1[0][ch] : region1_count_branch_2[0][ch];
        preflag[0][ch] = (window_switching_flag[0][ch]) ? preflag_branch_1[0][ch] : preflag_branch_2[0][ch];
        scalefac_scale[0][ch] = (window_switching_flag[0][ch]) ? scalefac_scale_branch_1[0][ch] : scalefac_scale_branch_2[0][ch];
        count1table_select[0][ch] = (window_switching_flag[0][ch]) ? count1table_select_branch_1[0][ch] : count1table_select_branch_2[0][ch];
      end

      //granule 1:
      for (int ch = 0; ch < 2; ch += 1) begin
        mixed_block_flag[1][ch] = (window_switching_flag[1][ch]) ? mixed_block_flag_branch_1[1][ch] : mixed_block_flag_branch_2[1][ch];
        subblock_gain_1[1][ch] = (window_switching_flag[1][ch]) ? subblock_gain_1_branch_1[1][ch] : subblock_gain_1_branch_2[1][ch];
        subblock_gain_2[1][ch] = (window_switching_flag[1][ch]) ? subblock_gain_2_branch_1[1][ch] : subblock_gain_2_branch_2[1][ch];
        subblock_gain_3[1][ch] = (window_switching_flag[1][ch]) ? subblock_gain_3_branch_1[1][ch] : subblock_gain_3_branch_2[1][ch];
        block_type[1][ch] = (window_switching_flag[1][ch]) ? block_type_branch_1[1][ch] : block_type_branch_2[1][ch];
        table_select_1[1][ch] = (window_switching_flag[1][ch]) ? table_select_1_branch_1[1][ch] : table_select_1_branch_2[1][ch];
        table_select_2[1][ch] = (window_switching_flag[1][ch]) ? table_select_2_branch_1[1][ch] : table_select_2_branch_2[1][ch];
        table_select_3[1][ch] = (window_switching_flag[1][ch]) ? table_select_3_branch_1[1][ch] : table_select_3_branch_2[1][ch];
        region1_count[1][ch] = (window_switching_flag[1][ch]) ? region1_count_branch_1[1][ch] : region1_count_branch_2[1][ch];
        region1_count[1][ch] = (window_switching_flag[1][ch]) ? region1_count_branch_1[1][ch] : region1_count_branch_2[1][ch];
        preflag[1][ch] = (window_switching_flag[1][ch]) ? preflag_branch_1[1][ch] : preflag_branch_2[1][ch];
        scalefac_scale[1][ch] = (window_switching_flag[1][ch]) ? scalefac_scale_branch_1[1][ch] : scalefac_scale_branch_2[1][ch];
        count1table_select[1][ch] = (window_switching_flag[1][ch]) ? count1table_select_branch_1[1][ch] : count1table_select_branch_2[1][ch];
      end

  end


endmodule


`default_nettype wire
