`default_nettype none
`timescale 1ns / 1ps

module huffman_plexer (
    input wire clk,
    input wire rst,
    input wire data_in,
    input wire data_in_valid,

    input wire si_valid,
    input wire [1:0][1:0][3:0] region0_count_in,
    input wire [1:0][1:0][3:0] region1_count_in,
    input wire [1:0][1:0][8:0] big_values_in,
    input wire [1:0][1:0][2:0][4:0] table_select_in,
    input wire [1:0][1:0] count1table_select_in,
    input wire [1:0][1:0] window_switching_flag_in,
    input wire [1:0][1:0][1:0] block_type_in,

    input wire gr,
    input wire ch,

    output logic [15:0] bram_data_out_v,
    output logic [15:0] bram_data_out_w,
    output logic [15:0] bram_data_out_x,
    output logic [15:0] bram_data_out_y,
    output logic [9:0] bram_addra,

    output logic bram_00_data_valid,
    output logic bram_01_data_valid,
    output logic bram_10_data_valid,
    output logic bram_11_data_valid
  );

  logic [1:0][1:0][3:0] region0_count_in_save;
  logic [1:0][1:0][3:0] region1_count_in_save;
  logic [1:0][1:0][8:0] big_values_in_save;
  logic [1:0][1:0][2:0][4:0] table_select_in_save;
  logic [1:0][1:0] count1table_select_in_save;
  logic [1:0][1:0] window_switching_flag_in_save;
  logic [1:0][1:0][1:0] block_type_in_save;

  logic [3:0] region0_count;
  logic [3:0] region1_count;
  logic [8:0] big_values;
  logic [2:0][4:0] table_select;
  logic count1table_select;
  logic window_switching_flag;
  logic [1:0] block_type;
  logic bram_data_valid;      //this is general bram data valid (the right table is high)

  always_comb begin
    case({gr,ch})
      2'b00 : begin
        region0_count = region0_count_in_save[0][0];
        region1_count = region1_count_in_save[0][0];
        big_values = big_values_in_save[0][0];
        table_select = table_select_in_save[0][0];
        count1table_select = count1table_select_in_save[0][0];
        window_switching_flag = window_switching_flag_in_save[0][0];
        block_type = block_type_in_save[0][0];
        {bram_00_data_valid, bram_01_data_valid, bram_10_data_valid, bram_11_data_valid} = {bram_data_valid && (bram_addra < 10'd576), 1'b0, 1'b0, 1'b0};
      end
      2'b01 : begin
        region0_count = region0_count_in_save[0][1];
        region1_count = region1_count_in_save[0][1];
        big_values = big_values_in_save[0][1];
        table_select = table_select_in_save[0][1];
        count1table_select = count1table_select_in_save[0][1];
        window_switching_flag = window_switching_flag_in_save[0][1];
        block_type = block_type_in_save[0][1];
        {bram_00_data_valid, bram_01_data_valid, bram_10_data_valid, bram_11_data_valid} = {1'b0, bram_data_valid && (bram_addra < 10'd576), 1'b0, 1'b0};
      end
      2'b10 : begin
        region0_count = region0_count_in_save[1][0];
        region1_count = region1_count_in_save[1][0];
        big_values = big_values_in_save[1][0];
        table_select = table_select_in_save[1][0];
        count1table_select = count1table_select_in_save[1][0];
        window_switching_flag = window_switching_flag_in_save[1][0];
        block_type = block_type_in_save[1][0];
        {bram_00_data_valid, bram_01_data_valid, bram_10_data_valid, bram_11_data_valid} = {1'b0, 1'b0, bram_data_valid && (bram_addra < 10'd576), 1'b0};
      end
      2'b11 : begin
        region0_count = region0_count_in_save[1][1];
        region1_count = region1_count_in_save[1][1];
        big_values = big_values_in_save[1][1];
        table_select = table_select_in_save[1][1];
        count1table_select = count1table_select_in_save[1][1];
        window_switching_flag = window_switching_flag_in_save[1][1];
        block_type = block_type_in_save[1][1];
        {bram_00_data_valid, bram_01_data_valid, bram_10_data_valid, bram_11_data_valid} = {1'b0, 1'b0, 1'b0, bram_data_valid && (bram_addra < 10'd576)};
      end
    endcase
  end

  logic [1:0] gr_ch_save;

  always_ff @(posedge clk) begin
    if (rst) begin
      bram_addra <= 0;
    end else begin
      if (si_valid) begin
        region0_count_in_save <= region0_count_in;
        region1_count_in_save <= region1_count_in;
        big_values_in_save <= big_values_in;
        table_select_in_save <= table_select_in;
        count1table_select_in_save <= count1table_select_in;
        window_switching_flag_in_save <= window_switching_flag_in;
        block_type_in_save <= block_type_in;

        bram_addra <= 0;
      end else begin
        gr_ch_save <= {gr,ch};
        if (gr_ch_save != {gr,ch}) begin
          bram_addra <= 0;
        end
        else if (bram_data_valid) begin
          //this means the correct huffman table just outputted a value
          bram_addra <= bram_addra + 2; //just let this counter go as high as it wants, it resets with every frame
          //but when it is greater than 575, the bram_{gr,ch}_data_valid will never be high (see combinational logic above)
        end
      end
    end
  end

  logic [29:0] hf_big_axiov;
  logic [29:0][15:0] hf_big_xval;
  logic [29:0][15:0] hf_big_yval;

  //table change anticipator: (the axiiv needs to go high DURING the clock cycle before the table number change):
  logic [5:0] next_table;
  always_comb begin
    if ((bram_addra + 2 == region1_start) && (bram_data_valid)) next_table = table_select[1];
    else if ((bram_addra + 2 == region2_start) && (bram_data_valid)) next_table = table_select[2];
    else next_table = 6'd63;    //just make it some out of range value so it doesn't trigger anything.
  end

  HT_00 LUT_00(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd00) || (next_table == 6'd00) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[0 ]), .x_val(hf_big_xval[0 ]), .y_val(hf_big_yval[0 ]));
  HT_01 LUT_01(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd01) || (next_table == 6'd01) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[1 ]), .x_val(hf_big_xval[1 ]), .y_val(hf_big_yval[1 ]));
  HT_02 LUT_02(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd02) || (next_table == 6'd02) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[2 ]), .x_val(hf_big_xval[2 ]), .y_val(hf_big_yval[2 ]));
  HT_03 LUT_03(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd03) || (next_table == 6'd03) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[3 ]), .x_val(hf_big_xval[3 ]), .y_val(hf_big_yval[3 ]));
  HT_05 LUT_05(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd05) || (next_table == 6'd05) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[4 ]), .x_val(hf_big_xval[4 ]), .y_val(hf_big_yval[4 ]));
  HT_06 LUT_06(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd06) || (next_table == 6'd06) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[5 ]), .x_val(hf_big_xval[5 ]), .y_val(hf_big_yval[5 ]));
  HT_07 LUT_07(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd07) || (next_table == 6'd07) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[6 ]), .x_val(hf_big_xval[6 ]), .y_val(hf_big_yval[6 ]));
  HT_08 LUT_08(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd08) || (next_table == 6'd08) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[7 ]), .x_val(hf_big_xval[7 ]), .y_val(hf_big_yval[7 ]));
  HT_09 LUT_09(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd09) || (next_table == 6'd09) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[8 ]), .x_val(hf_big_xval[8 ]), .y_val(hf_big_yval[8 ]));
  HT_10 LUT_10(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd10) || (next_table == 6'd10) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[9 ]), .x_val(hf_big_xval[9 ]), .y_val(hf_big_yval[9 ]));
  HT_11 LUT_11(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd11) || (next_table == 6'd11) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[10]), .x_val(hf_big_xval[10]), .y_val(hf_big_yval[10]));
  HT_12 LUT_12(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd12) || (next_table == 6'd12) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[11]), .x_val(hf_big_xval[11]), .y_val(hf_big_yval[11]));
  HT_13 LUT_13(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd13) || (next_table == 6'd13) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[12]), .x_val(hf_big_xval[12]), .y_val(hf_big_yval[12]));
  HT_15 LUT_15(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd15) || (next_table == 6'd15) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[13]), .x_val(hf_big_xval[13]), .y_val(hf_big_yval[13]));
  HT_16 LUT_16(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd16) || (next_table == 6'd16) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[14]), .x_val(hf_big_xval[14]), .y_val(hf_big_yval[14]));
  HT_17 LUT_17(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd17) || (next_table == 6'd17) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[15]), .x_val(hf_big_xval[15]), .y_val(hf_big_yval[15]));
  HT_18 LUT_18(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd18) || (next_table == 6'd18) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[16]), .x_val(hf_big_xval[16]), .y_val(hf_big_yval[16]));
  HT_19 LUT_19(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd19) || (next_table == 6'd19) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[17]), .x_val(hf_big_xval[17]), .y_val(hf_big_yval[17]));
  HT_20 LUT_20(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd20) || (next_table == 6'd20) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[18]), .x_val(hf_big_xval[18]), .y_val(hf_big_yval[18]));
  HT_21 LUT_21(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd21) || (next_table == 6'd21) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[19]), .x_val(hf_big_xval[19]), .y_val(hf_big_yval[19]));
  HT_22 LUT_22(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd22) || (next_table == 6'd22) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[20]), .x_val(hf_big_xval[20]), .y_val(hf_big_yval[20]));
  HT_23 LUT_23(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd23) || (next_table == 6'd23) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[21]), .x_val(hf_big_xval[21]), .y_val(hf_big_yval[21]));
  HT_24 LUT_24(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd24) || (next_table == 6'd24) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[22]), .x_val(hf_big_xval[22]), .y_val(hf_big_yval[22]));
  HT_25 LUT_25(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd25) || (next_table == 6'd25) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[23]), .x_val(hf_big_xval[23]), .y_val(hf_big_yval[23]));
  HT_26 LUT_26(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd26) || (next_table == 6'd26) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[24]), .x_val(hf_big_xval[24]), .y_val(hf_big_yval[24]));
  HT_27 LUT_27(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd27) || (next_table == 6'd27) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[25]), .x_val(hf_big_xval[25]), .y_val(hf_big_yval[25]));
  HT_28 LUT_28(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd28) || (next_table == 6'd28) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[26]), .x_val(hf_big_xval[26]), .y_val(hf_big_yval[26]));
  HT_29 LUT_29(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd29) || (next_table == 6'd29) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[27]), .x_val(hf_big_xval[27]), .y_val(hf_big_yval[27]));
  HT_30 LUT_30(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd30) || (next_table == 6'd30) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[28]), .x_val(hf_big_xval[28]), .y_val(hf_big_yval[28]));
  HT_31 LUT_31(.clk(clk), .rst(rst), .axiiv( ((table_num == 6'd31) || (next_table == 6'd31) ) && (data_in_valid)), .axiid(data_in), .axiov(hf_big_axiov[29]), .x_val(hf_big_xval[29]), .y_val(hf_big_yval[29]));

  //CODE TO SELECT A TABLE BASED ON THE RELEVANT SIDE INFORMATION:
  logic [229:0] G_SF_BAND_L;
  logic [139:0] G_SF_BAND_S;

  assign G_SF_BAND_L = 230'h24068956480ee310a22186e1684a0f8340b02407818050100300801000;
  assign G_SF_BAND_S = 140'h300881a854108340a01e058100300801000;

  logic [9:0] region1_start, region2_start;
  logic [7:0] shift_r1, shift_r2;
  always_comb begin
    if (window_switching_flag && (block_type == 2)) begin
      region1_start = 10'd36;
      region2_start = 10'd576;
    end else begin
      shift_r1 = 10 * (5'd22 - region0_count - 1);
      shift_r2 = 10 * (5'd22 - region0_count - 1 - region1_count - 1);
      region1_start = (G_SF_BAND_L << shift_r1) >> 8'd220;
      region2_start = (G_SF_BAND_L << shift_r2) >> 8'd220;   //dank indexing trick
    end
  end

  logic [5:0] table_num;


  always_comb begin
    if (bram_addra < (big_values << 1)) begin
      if      (bram_addra < region1_start)  table_num = table_select[0];
      else if (bram_addra < region2_start)  table_num = table_select[1];
      else                                  table_num = table_select[2];
    end
    else begin
      table_num = (count1table_select) ? 6'd33 : 6'd32;     //corresponding to table A and B
    end

    case(table_num)
      6'd00 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[0 ];
        bram_data_out_y = hf_big_yval[0 ];
        bram_data_valid = hf_big_axiov[0 ];
      end
      6'd01 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[1 ];
        bram_data_out_y = hf_big_yval[1 ];
        bram_data_valid = hf_big_axiov[1 ];
      end
      6'd02 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[2 ];
        bram_data_out_y = hf_big_yval[2 ];
        bram_data_valid = hf_big_axiov[2 ];
      end
      6'd03 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[3 ];
        bram_data_out_y = hf_big_yval[3 ];
        bram_data_valid = hf_big_axiov[3 ];
      end
      // 6'd04 : x_decode = hf_big_xval[05];
      6'd05 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[4 ];
        bram_data_out_y = hf_big_yval[4 ];
        bram_data_valid = hf_big_axiov[4 ];
      end
      6'd06 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[5 ];
        bram_data_out_y = hf_big_yval[5 ];
        bram_data_valid = hf_big_axiov[5 ];
      end
      6'd07 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[6 ];
        bram_data_out_y = hf_big_yval[6 ];
        bram_data_valid = hf_big_axiov[6 ];
      end
      6'd08 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[7 ];
        bram_data_out_y = hf_big_yval[7 ];
        bram_data_valid = hf_big_axiov[7 ];
      end
      6'd09 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[8 ];
        bram_data_out_y = hf_big_yval[8 ];
        bram_data_valid = hf_big_axiov[8 ];
      end
      6'd10 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[9 ];
        bram_data_out_y = hf_big_yval[9 ];
        bram_data_valid = hf_big_axiov[9 ];
      end
      6'd11 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[10];
        bram_data_out_y = hf_big_yval[10];
        bram_data_valid = hf_big_axiov[10];
      end
      6'd12 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[11];
        bram_data_out_y = hf_big_yval[11];
        bram_data_valid = hf_big_axiov[11];
      end
      6'd13 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[12];
        bram_data_out_y = hf_big_yval[12];
        bram_data_valid = hf_big_axiov[12];
      end
      // 6'd14 : x_decode = hf_big_xval[15];
      6'd15 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[13];
        bram_data_out_y = hf_big_yval[13];
        bram_data_valid = hf_big_axiov[13];
      end
      6'd16 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[14];
        bram_data_out_y = hf_big_yval[14];
        bram_data_valid = hf_big_axiov[14];
      end
      6'd17 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x = hf_big_xval[15];
        bram_data_out_y = hf_big_yval[15];
        bram_data_valid = hf_big_axiov[15];
      end
      6'd18 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[16];
        bram_data_out_y =  hf_big_yval[16];
        bram_data_valid = hf_big_axiov[16];
      end
      6'd19 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[17];
        bram_data_out_y =  hf_big_yval[17];
        bram_data_valid = hf_big_axiov[17];
      end
      6'd20 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[18];
        bram_data_out_y =  hf_big_yval[18];
        bram_data_valid = hf_big_axiov[18];
      end
      6'd21 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[19];
        bram_data_out_y =  hf_big_yval[19];
        bram_data_valid = hf_big_axiov[19];
      end
      6'd22 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[20];
        bram_data_out_y =  hf_big_yval[20];
        bram_data_valid = hf_big_axiov[20];
      end
      6'd23 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[21];
        bram_data_out_y =  hf_big_yval[21];
        bram_data_valid = hf_big_axiov[21];
      end
      6'd24 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[22];
        bram_data_out_y =  hf_big_yval[22];
        bram_data_valid = hf_big_axiov[22];
      end
      6'd25 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[23];
        bram_data_out_y =  hf_big_yval[23];
        bram_data_valid = hf_big_axiov[23];
      end
      6'd26 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[24];
        bram_data_out_y =  hf_big_yval[24];
        bram_data_valid = hf_big_axiov[24];
      end
      6'd27 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[25];
        bram_data_out_y =  hf_big_yval[25];
        bram_data_valid = hf_big_axiov[25];
      end
      6'd28 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[26];
        bram_data_out_y =  hf_big_yval[26];
        bram_data_valid = hf_big_axiov[26];
      end
      6'd29 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[27];
        bram_data_out_y =  hf_big_yval[27];
        bram_data_valid = hf_big_axiov[27];
      end
      6'd30 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[28];
        bram_data_out_y =  hf_big_yval[28];
        bram_data_valid = hf_big_axiov[28];
      end
      6'd31 : begin
        bram_data_out_v = 2;
        bram_data_out_w = 2;    //note that these are only ever 1 or 0 in real life.
        bram_data_out_x =  hf_big_xval[29];
        bram_data_out_y =  hf_big_yval[29];
        bram_data_valid = hf_big_axiov[29];
      end
      default : begin
        bram_data_out_v = 0;
        bram_data_out_w = 0;    //change this later for table A and B
        bram_data_out_x = 0;
        bram_data_out_y = 0;
        bram_data_valid = 0;
      end
    endcase
  end

endmodule

`default_nettype wire
