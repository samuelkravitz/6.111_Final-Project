`default_nettype none
`timescale 1ns / 1ps

`include "iverilog_hack.svh"

module requantizer_v2 (
  input wire clk,
  input wire rst,

  input wire window_switching_flag_in,
  input wire [1:0]block_type_in,
  input wire mixed_block_flag_in,
  input wire scalefac_scale_in,
  input wire [7:0]global_gain_in,
  input wire preflag_in,
  input wire [2:0][2:0]subblock_gain_in,
  input wire [8:0]big_values_in,

  input wire [20:0][3:0]scalefac_l_in,
  input wire [11:0][2:0][3:0]scalefac_s_in,

  input wire [15:0] x_in,     //this is a signed value (in 2s complement, by the HT_00 type of modules)
  input wire [9:0] is_pos,    //BRAM ADDRA in huffman_plexer
  input wire din_v,

  output logic [15:0] x_out,
  output logic [9:0] x_base_out,    //the assumption is that the base is negative. it always is man. so the is x_out >> x_base_out
  output logic dout_v
  );

  logic [11:0] c1_sfb, c2_sfb, c3_sfb;
  logic [3:0] c1_win, c2_win, c3_win;   //these are bigger than they need to be because of hex problems
  logic [3:0] c1_bt, c2_bt, c3_bt;    //case 1 -> (sfb, win, block type (short == 0, long == 1))

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(20),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(FULL_WIN_SFB_TB_1.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) TB_CASE_1 (
    .addra(is_pos),     // Address bus, width determined from RAM_DEPTH
    .dina(20'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta({c1_sfb, c1_win, c1_bt})      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(20),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(FULL_WIN_SFB_TB_2.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) TB_CASE_2 (
    .addra(is_pos),     // Address bus, width determined from RAM_DEPTH
    .dina(20'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta({c2_sfb, c2_win, c2_bt})      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(20),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(FULL_WIN_SFB_TB_3.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) TB_CASE_3 (
    .addra(is_pos),     // Address bus, width determined from RAM_DEPTH
    .dina(20'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta({c3_sfb, c3_win, c3_bt})      // RAM output data, width determined from RAM_WIDTH
  );

  //DETERMINE THE |X| ^ 4/3:
  logic [9:0] p43_table_input;
  logic [15:0] x_abs;
  logic [15:0] x_in_mask;

  logic [15:0] x_pow_43;
  logic [3:0] x_tab_base;   //outputs from the xilinx table BRAMs

  assign x_in_mask = $signed(x_in) >>> 6'd15;
  assign x_abs = (x_in ^ x_in_mask) - x_in_mask; //get the absolute value of x_in;
  assign p43_table_input = (x_abs > 10'd999) ? 10'd999 : x_abs[9:0];

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(20),                       // Specify RAM data width
    .RAM_DEPTH(1000),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(pow_43_tab.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) POW43_TB (
    .addra(p43_table_input),     // Address bus, width determined from RAM_DEPTH
    .dina(20'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta({x_tab_base, x_pow_43})      // RAM output data, width determined from RAM_WIDTH
  );

  logic [2:0] window_switching_flag_pipe;
  logic [2:0] [1:0]block_type_pipe;
  logic [2:0] mixed_block_flag_pipe;
  logic [2:0] scalefac_scale_pipe;
  logic [2:0] [7:0]global_gain_pipe;
  logic [2:0] preflag_pipe;
  logic [2:0] [2:0][2:0]subblock_gain_pipe;
  logic [2:0] [8:0]big_values_pipe;

  logic [2:0] [20:0][3:0]scalefac_l_pipe;
  logic [2:0] [11:0][2:0][3:0]scalefac_s_pipe;

  logic [2:0] [9:0] is_pos_pipe;
  logic [2:0] din_v_pipe;
  logic [2:0] [15:0] x_in_pipe;     //you need to remember these just in case its outside of count1

  logic [9:0] count1;
  assign count1 = big_values_in << 1;

  logic [1:0] bt;   //0 -> short, 1 -> long, 2->NONE (count1 region)
  logic [11:0] sfb;
  logic [2:0] win;

  logic [2:0] target_subblock_gain;
  logic signed [9:0] exp1;
  logic signed [11:0] exp2;
  logic signed [11:0] x_quant_base_signed;
  logic [11:0] x_quant_base_signed_mask;
  logic [3:0] scalefac_sel;
  logic [2:0] pretab;
  logic scalefac_shift;


  //COMPUTE THE requantized x values for all 3 cases:
  always_comb begin
    dout_v = din_v_pipe[1];
    scalefac_shift = (scalefac_scale_pipe[1]) ? 0 : 1;    //takes only the first 4 bits (just verilog)

    case(win)
      2'd0 : target_subblock_gain = subblock_gain_pipe[1][0];
      2'd1 : target_subblock_gain = subblock_gain_pipe[1][1];
      2'd2 : target_subblock_gain = subblock_gain_pipe[1][2];
      default : target_subblock_gain = 0;
    endcase

    //DETERMINE WHICH BRANCH TO TAKE:
    if (window_switching_flag_pipe[1] && (block_type_pipe[1] == 2) && (mixed_block_flag_pipe[1])) begin
      bt  = (is_pos_pipe[1] < count1) ? c1_bt : 2;
      win = c1_win;
      sfb = c1_sfb;
    end else if (window_switching_flag_pipe[1] && (block_type_pipe[1] == 2)) begin
      bt  = (is_pos_pipe[1] < count1) ? c2_bt : 2;
      win = c2_win;
      sfb = c2_sfb;
    end else begin
      bt  = (is_pos_pipe[1] < count1) ? c3_bt : 2;
      win = c3_win;
      sfb = c3_sfb;
    end

    case(bt)
      2'd1 : begin
        //LONG BLOCK FORMULA:
        scalefac_sel = scalefac_l_pipe[1] >> (sfb << 2);  //sfb * 4 gives the shift
        exp1 = $signed(global_gain_pipe[1] - 10'sd210);   //this is supposed to be divided by 4, but i will just call it fixed point
        exp2 = ($signed(scalefac_sel + preflag_pipe[1] * pretab)) <<< (2'd2 - scalefac_shift);  //making this 'fixed point'...
        x_quant_base_signed = $signed(exp1 - exp2 - (x_tab_base << 2));
        x_quant_base_signed_mask = x_quant_base_signed >>> 10;
        x_base_out = (x_quant_base_signed ^ x_quant_base_signed_mask) - x_quant_base_signed_mask;    //if the x_base_out_signed is positive, just set the base to 0. don't want to deal with that.
        x_out = (x_in_pipe[1][15]) ? -1'sd1 * x_pow_43 : x_pow_43;
      end
      2'd0 : begin
        //SHORT BLOCK FORMULA
        scalefac_sel = scalefac_s_pipe[1] >> ( (3 * sfb) << 2 - (win << 2) );
        exp1 = $signed(global_gain_pipe[1] - 10'sd210 - (target_subblock_gain << 3)  );
        x_quant_base_signed = $signed(exp1 - exp2 - (x_tab_base << 2));
        exp2 = ($signed(scalefac_sel)) <<< (2'd2 - scalefac_shift);
        x_quant_base_signed_mask = x_quant_base_signed >>> 10;
        x_base_out = (x_quant_base_signed ^ x_quant_base_signed_mask) - x_quant_base_signed_mask;    //if the x_base_out_signed is positive, just set the base to 0. don't want to deal with that.
        x_out = (x_in_pipe[1][15]) ? -1'sd1 * x_pow_43 : x_pow_43;
      end
      2'd2 : begin
        //COUNT1 REGION FORMULA: (ASSUMED?)
        x_out = x_in_pipe[1];
        x_base_out = 0;     //its just 1,0, or -1
      end
    endcase



  end

  always_ff @(posedge clk) begin
    if (rst) begin
      window_switching_flag_pipe <= 0;
      block_type_pipe <= 0;
      mixed_block_flag_pipe <= 0;
      scalefac_scale_pipe <= 0;
      global_gain_pipe <= 0;
      preflag_pipe <= 0;
      subblock_gain_pipe <= 0;
      big_values_pipe <= 0;
      scalefac_l_pipe <= 0;
      scalefac_s_pipe <= 0;

      is_pos_pipe <= 0;
      din_v_pipe <= 0;
      x_in_pipe <= 0;
    end else begin


    //UPDATE ALL PIPELINING VARIABLES!!!
    window_switching_flag_pipe[0] <= window_switching_flag_in;
    block_type_pipe[0] <= block_type_in;
    mixed_block_flag_pipe[0] <= mixed_block_flag_in;
    scalefac_scale_pipe[0] <= scalefac_scale_in;
    global_gain_pipe[0] <= global_gain_in;
    preflag_pipe[0] <= preflag_in;
    subblock_gain_pipe[0] <= subblock_gain_in;
    big_values_pipe[0] <= big_values_in;
    scalefac_l_pipe[0] <= scalefac_l_in;
    scalefac_s_pipe[0] <= scalefac_s_in;
    is_pos_pipe[0] <= is_pos;
    din_v_pipe[0] <= din_v;
    x_in_pipe[0] <= x_in;

    window_switching_flag_pipe[1] <= window_switching_flag_pipe[0];
    block_type_pipe[1] <= block_type_pipe[0];
    mixed_block_flag_pipe[1] <= mixed_block_flag_pipe[0];
    scalefac_scale_pipe[1] <= scalefac_scale_pipe[0];
    global_gain_pipe[1] <= global_gain_pipe[0];
    preflag_pipe[1] <= preflag_pipe[0];
    subblock_gain_pipe[1] <= subblock_gain_pipe[0];
    big_values_pipe[1] <= big_values_pipe[0];
    scalefac_l_pipe[1] <= scalefac_l_pipe[0];
    scalefac_s_pipe[1] <= scalefac_s_pipe[0];
    is_pos_pipe[1] <= is_pos_pipe[0];
    din_v_pipe[1] <= din_v_pipe[0];
    x_in_pipe[1] <= x_in_pipe[0];

    end
  end


  always_comb begin
    case(sfb)
      7'd00 : pretab = 0;
      7'd01 : pretab = 0;
      7'd02 : pretab = 0;
      7'd03 : pretab = 0;
      7'd04 : pretab = 0;
      7'd05 : pretab = 0;
      7'd06 : pretab = 0;
      7'd07 : pretab = 0;
      7'd08 : pretab = 0;
      7'd09 : pretab = 0;
      7'd10 : pretab = 0;
      7'd11 : pretab = 1;
      7'd12 : pretab = 1;
      7'd13 : pretab = 1;
      7'd14 : pretab = 1;
      7'd15 : pretab = 2;
      7'd16 : pretab = 2;
      7'd17 : pretab = 3;
      7'd18 : pretab = 3;
      7'd19 : pretab = 3;
      7'd20 : pretab = 2;
      7'd21 : pretab = 0;
    endcase
  end



endmodule

`default_nettype wire
