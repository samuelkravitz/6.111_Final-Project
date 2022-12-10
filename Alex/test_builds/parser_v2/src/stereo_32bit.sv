`default_nettype none
`timescale 1ns / 1ps

`include "iverilog_hack.svh"

module stereo_32bit (
    input wire clk,
    input wire rst,

    input wire [1:0] mode_in,
    input wire [1:0] mode_ext_in,
    input wire [8:0] big_values_in,
    input wire window_switching_flag_in,
    input wire [1:0] block_type_in,
    input wire mixed_block_flag_in,

    input wire [20:0][3:0]scalefac_l_in,
    input wire [11:0][2:0][3:0]scalefac_s_in,

    input wire signed [31:0] ch1_in,
    input wire signed [31:0] ch2_in,       //31 bit Q2_30 2s complement values
    input wire [9:0] is_pos_in,
    input wire gr_in,
    input wire din_v,

    output logic signed [31:0] ch1_out,
    output logic signed [31:0] ch2_out,
    output logic gr_out,
    output logic dout_v
  );

  logic [7:0] c1_sfb, c2_sfb, c3_sfb;
  logic [3:0] c1_bt, c2_bt, c3_bt;
  logic [3:0] c1_win, c2_win, c3_win;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(408),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(IS_stereo_sfb_idx_1.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) TB_CASE_1 (
    .addra(is_pos_in),     // Address bus, width determined from RAM_DEPTH
    .dina(16'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta({c1_sfb, c1_win, c1_bt})      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(408),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(IS_stereo_sfb_idx_2.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) TB_CASE_2 (
    .addra(is_pos_in),     // Address bus, width determined from RAM_DEPTH
    .dina(16'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta({c2_sfb, c2_win, c2_bt})      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(16),                       // Specify RAM data width
    .RAM_DEPTH(418),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(IS_stereo_sfb_idx_3.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) TB_CASE_3 (
    .addra(is_pos_in),     // Address bus, width determined from RAM_DEPTH
    .dina(16'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta({c3_sfb, c3_win, c3_bt})      // RAM output data, width determined from RAM_WIDTH
  );


  ///PIPELINING:
  logic [1:0][1:0] mode_pipe;
  logic [1:0][1:0] mode_ext_pipe;
  logic [1:0][8:0] big_values_pipe;
  logic [1:0]window_switching_flag_pipe;
  logic [1:0][1:0] block_type_pipe;
  logic [1:0]mixed_block_flag_pipe;

  logic [1:0][20:0][3:0]scalefac_l_pipe;
  logic [1:0][11:0][2:0][3:0]scalefac_s_pipe;

  logic [1:0][31:0] ch1_pipe;
  logic [1:0][31:0] ch2_pipe;
  logic [1:0][9:0] is_pos_pipe;

  logic [1:0]gr_pipe;
  logic [1:0]din_v_pipe;

  always_ff @(posedge clk) begin
    if (rst) begin
        mode_pipe <= 0;
        mode_ext_pipe <= 0;
        big_values_pipe <= 0;
        window_switching_flag_pipe <= 0;
        block_type_pipe <= 0;
        mixed_block_flag_pipe <= 0;

        scalefac_l_pipe <= 0;
        scalefac_s_pipe <= 0;

        ch1_pipe <= 0;
        ch2_pipe <= 0;
        is_pos_pipe <= 0;
        gr_pipe <= 0;
        din_v_pipe <= 0;
    end
    else begin
        mode_pipe[0] <= mode_in;
        mode_ext_pipe[0] <= mode_ext_in;
        big_values_pipe[0] <= big_values_in;
        window_switching_flag_pipe[0] <= window_switching_flag_in;
        block_type_pipe[0] <=  block_type_in;
        mixed_block_flag_pipe[0] <= mixed_block_flag_in;

        scalefac_l_pipe[0] <= scalefac_l_in;
        scalefac_s_pipe[0] <= scalefac_s_in;

        ch1_pipe[0] <= ch1_in;
        ch2_pipe[0] <= ch2_in;
        is_pos_pipe[0] <= is_pos_in;
        gr_pipe[0] <= gr_in;
        din_v_pipe[0] <= din_v;

        mode_pipe[1] <= mode_pipe[0];
        mode_ext_pipe[1] <= mode_ext_pipe[0];
        big_values_pipe[1] <= big_values_pipe[0];
        window_switching_flag_pipe[1] <= window_switching_flag_pipe[0];
        block_type_pipe[1] <=  block_type_pipe[0];
        mixed_block_flag_pipe[1] <= mixed_block_flag_pipe[0];

        scalefac_l_pipe[1] <= scalefac_l_pipe[0];
        scalefac_s_pipe[1] <= scalefac_s_pipe[0];

        ch1_pipe[1] <= ch1_pipe[0];
        ch2_pipe[1] <= ch2_pipe[0];
        is_pos_pipe[1] <= is_pos_pipe[0];
        gr_pipe[1] <= gr_pipe[0];
        din_v_pipe[1] <= din_v_pipe[0];
    end
  end


  //FIRST COMPUTE THE MS STEREO VALUES:

  logic [9:0] count1;
  assign count1 = big_values_pipe[1] << 1;

  logic [9:0] sfb;
  logic [3:0] win;
  logic [1:0] bt;

  logic STEREO;

  always_ff @(posedge clk) begin
    gr_out <= gr_pipe[1];
    dout_v <= din_v_pipe[1];

    if ((mode_pipe[1] == 2'b01) && mode_ext_pipe[1][1] && (is_pos_pipe[1] < count1)) begin
      //this menas MS Stereo is used:
      STEREO <= 1;

    end else begin
      STEREO <= 0;
    end

    if ((mode_pipe[1] == 2'b01) && mode_ext_pipe[1][0] && (is_pos_pipe[1] < count1)) begin
      //PROCESS INTENSITY:
      if (window_switching_flag_pipe[1] && (block_type_pipe[1]==2) && mixed_block_flag_pipe[1]) begin
        sfb   <=  c1_sfb;
        bt    <=  c1_bt;
        win   <=  c1_win;
      end else if (window_switching_flag_pipe[1] && (block_type_pipe[1]==2)) begin
        sfb   <=  c2_sfb;
        bt    <=  c2_bt;
        win   <=  c2_win;
      end else begin
        sfb   <=  c3_sfb;
        bt    <=  c3_bt;
        win   <=  c3_win;
      end
    end else begin
      sfb     <= 2'd0;
      bt      <= 2'd2;      //sets the block type to 2 so the later combinational logic knows to just multiply by 1
      win     <= 2'd0;
    end
  end


  logic [3:0] ratio_idx;

  logic signed [63:0] A, B;
  logic signed [63:0] ms_comp_l_int, ms_comp_r_int;    //used to store the intermediate 32-bit multiplication
  logic signed [31:0] ms_comp_l, ms_comp_r;
  logic signed [31:0] ratio_l, ratio_r;

  always_comb begin
    //compute the relevant stereo things:
    if (STEREO) begin
      ms_comp_l_int = $signed( $signed(ch1_pipe[1]) - $signed(ch2_pipe[1]) ) * 32'sh2d413ccc;
      ms_comp_r_int = $signed( $signed(ch1_pipe[1]) + $signed(ch2_pipe[1]) ) * 32'sh2d413ccc;   //multiplying by root(2)/2...

      ms_comp_l = ms_comp_l_int >>> 30;
      ms_comp_r = ms_comp_r_int >>> 30;     //parts select for the fixed point float maintainence.
    end else begin
      ms_comp_l_int = $signed(ch1_pipe[1]) - $signed(ch2_pipe[1]);
      ms_comp_r_int = $signed(ch1_pipe[1]) + $signed(ch2_pipe[1]);   //multiplying by root(2)/2...

      ms_comp_l = ms_comp_l_int;
      ms_comp_r = ms_comp_r_int;     //parts select just the last 32 bits automatically because no multiplication happened.
    end

    if (bt == 1) begin
      //long block type:
      ratio_idx = (scalefac_l_pipe[1] >> (sfb << 2));

    end else if (bt == 0) begin
      //short block type:
      ratio_idx = scalefac_s_pipe[1] >> (12 * sfb + (win << 2));

    end else begin
      //probably is_pos in the count1 region... don't do anything to these values
      ratio_idx = 4'd7;    //pulls the ratios to their default 1 value.
    end

    ///LUT FOR RATIOS: (these are in 2s complement with f.p. at 14th bit (*2^-14))
    case(ratio_idx)
      4'd0 : begin
        ratio_l = 32'sh00000000;
        ratio_r = 32'sh40000000;
      end
      4'd1 : begin
        ratio_l = 32'sh0d865839;
        ratio_r = 32'sh3279a7c6;
      end
      4'd2 : begin
        ratio_l = 32'sh176cf55c;
        ratio_r = 32'sh28930aa3;
      end
      4'd3 : begin
        ratio_l = 32'sh20000000;
        ratio_r = 32'sh20000000;
      end
      4'd4 : begin
        ratio_l = 32'sh28930a4a;
        ratio_r = 32'sh176cf5b5;
      end
      4'd5 : begin
        ratio_l = 32'sh3279a74e;
        ratio_r = 32'sh0d8658b1;
      end
      4'd6 : begin
        ratio_l = 32'sh40000000;
        ratio_r = 32'sh00000000;
      end
      default : begin
        ratio_l = 32'sh40000000;
        ratio_r = 32'sh40000000;   //default case makes both of these 1 (so the value is not changed)
      end
    endcase


    //compute the output:
    A = ms_comp_l * ratio_l;
    B = ms_comp_r * ratio_r;    //these are the 64-bit outputs

    ch1_out = A >>> 30;
    ch2_out = B >>> 30;

  end

endmodule

`default_nettype wire
