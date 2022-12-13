`default_nettype none
`timescale 1ns / 1ps

`include "iverilog_hack.svh"

/*
plan is to have 2 input values and a flag telling you whether to compute their antialiased
value or not. the module outputs two values (woah) along with their is_poses BOTH!
the downstream thing can read these into aa BRAM and compile the data before
constructing the hybrid filterbank. It shouldn't be that hard I think.


ARGS:
  x_in -> assumed to be the earlier value in the alias computation, expected to be signed Q2_30.
  y_in -> assumed to be the later value in the alias computation
  compute_alias -> HIGH when this module should compute the alias. LOW when it should not (and consequently ignore the second input y_in)
  din_v -> high when the input data is valid
  c_idx -> number 0-7, corresponds to the 'i' in go-main library alias function. tells us which cs and ca coefficients to use
*/

module antialias (
    input wire clk,
    input wire rst,

    input wire window_switching_flag_in,
    input wire [1:0] block_type_in,
    input wire mixed_block_flag_in,

    input wire new_frame_start,

    input wire [31:0] ch1_in,
    input wire [31:0] ch2_in,
    input wire din_v,

    output logic [31:0] ch1_out_x,
    output logic [31:0] ch1_out_y,
    output logic [31:0] ch2_out_x,
    output logic [31:0] ch2_out_y,

    output logic [9:0] is_pos_out_x,
    output logic [9:0] is_pos_out_y,
    output logic dout_v
  );

  logic [8:0] aliasing_lut_in;
  logic [11:0] li, ui;
  logic [3:0] alias_flag, c_idx;
  logic [7:0] sb;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(40),                       // Specify RAM data width
    .RAM_DEPTH(288),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(aliasing_LUT.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) ALIASING_DATA (
    .addra(aliasing_lut_in),     // Address bus, width determined from RAM_DEPTH
    .dina(40'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta({li, ui, alias_flag, c_idx, sb})      // RAM output data, width determined from RAM_WIDTH
  );

  logic [1:0] STATE;    //0 -> reading in data from stereo module
                  //1 -> writing off data to the synthesis modules

  logic [9:0] stereo_counter;

  //variables for interfacing with the BRAM that stores the granule's complete data
  logic [9:0] gr_bram_pos_x, gr_bram_pos_y;
  logic [31:0] ch1_x, ch2_x;
  logic [31:0] ch1_y, ch2_y;

  assign gr_bram_pos_x = (STATE == 2'b0) ? stereo_counter : li;
  assign gr_bram_pos_y = ui;      //it can always be that, we don't need two ports to write, just to read.

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(64),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH())                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) granule_data (
    .addra(gr_bram_pos_x),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(gr_bram_pos_y),   // Port B address bus, width determined from RAM_DEPTH
    .dina({ch1_in, ch2_in}),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(64'b0),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk),     // Port A clock
    .clkb(clk),     // Port B clock
    .wea(din_v && (STATE == 0)),       // Port A write enable
    .web(1'b0),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),     // Port A output reset (does not affect memory contents)
    .rstb(rst),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta({ch1_x, ch2_x}),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb({ch1_y, ch2_y})    // Port B RAM output data, width determined from RAM_WIDTH
  );

  logic [9:0] li_pipe [1:0];
  logic [9:0] ui_pipe [1:0];
  logic alias_flag_pipe [1:0];
  logic [7:0] sb_pipe [1:0];
  logic [2:0] c_idx_pipe [1:0];

  always_ff @(posedge clk) begin
    li_pipe[0] <= li;
    li_pipe[1] <= li_pipe[0];

    ui_pipe[0] <= ui;
    ui_pipe[1] <= ui_pipe[0];

    alias_flag_pipe[0] <= alias_flag;
    alias_flag_pipe[1] <= alias_flag_pipe[0];

    sb_pipe[0] <= sb;
    sb_pipe[1] <= sb_pipe[0];

    c_idx_pipe[0] <= c_idx[2:0];
    c_idx_pipe[1] <= c_idx_pipe[0];
  end

  assign is_pos_out_x = li_pipe[1];
  assign is_pos_out_y = ui_pipe[1];

  logic [31:0] ch1_x_aliased, ch1_y_aliased;
  logic [31:0] ch2_x_aliased, ch2_y_aliased;

  compute_antialiased_values ch1_computer (
      .x_in(ch1_x),
      .y_in(ch1_y),
      .c_idx_in(c_idx_pipe[1]),

      .x_out(ch1_x_aliased),
      .y_out(ch1_y_aliased)
    );

  compute_antialiased_values ch2_computer (
      .x_in(ch2_x),
      .y_in(ch2_y),
      .c_idx_in(c_idx_pipe[1]),

      .x_out(ch2_x_aliased),
      .y_out(ch2_y_aliased)
    );

  always_comb begin
    //combinatinal logic to compute the aliased outputs:
    if (~alias_flag_pipe[1]) begin
    //obviously no aliasing anyway if the aliasing flag was LOW
      ch1_out_x = ch1_x;
      ch2_out_x = ch2_x;

      ch1_out_y = ch1_y;
      ch2_out_y = ch2_y;      //grab the second pipe value here
    end
    else if (window_switching_flag_in && (block_type_in == 2) && ~mixed_block_flag_in) begin
      //no long blocks used, so no antialiasting:
      ch1_out_x = ch1_x;
      ch2_out_x = ch2_x;

      ch1_out_y = ch1_y;
      ch2_out_y = ch2_y;      //grab the second pipe value here
    end
    else if (window_switching_flag_in && (block_type_in == 2)) begin
      //long blocks used only for the first sb... so only alias if sb == 1:
      ch1_out_x = (sb_pipe[1] == 1) ? ch1_x_aliased : ch1_x;
      ch2_out_x = (sb_pipe[1] == 1) ? ch2_x_aliased : ch2_x;

      ch1_out_y = (sb_pipe[1] == 1) ? ch1_y_aliased : ch1_y;
      ch2_out_y = (sb_pipe[1] == 1) ? ch2_y_aliased : ch2_y;      //grab the second pipe value here

    end
    else begin
      ch1_out_x = (sb_pipe[1] < 6'd32) ? ch1_x_aliased : ch1_x;
      ch2_out_x = (sb_pipe[1] < 6'd32) ? ch2_x_aliased : ch2_x;

      ch1_out_y = (sb_pipe[1] < 6'd32) ? ch1_y_aliased : ch1_y;
      ch2_out_y = (sb_pipe[1] < 6'd32) ? ch2_y_aliased : ch2_y;      //grab the second pipe value here
    end
  end

  logic [3:0] dout_v_pipe;
  assign dout_v = dout_v_pipe[3];   //has to be long enough to wait for 2 brams

  always_ff @(posedge clk) begin
    if (rst || new_frame_start) begin
      STATE <= 0;
      stereo_counter <= 0;
      dout_v_pipe <= 0;
      aliasing_lut_in <= 0;
    end else begin
      dout_v_pipe <= (STATE == 1) ? {dout_v_pipe[2:0], 1'b1} : {dout_v_pipe[2:0], 1'b0};    //load in a valid into pipe, does not take effect for three CCs
      case(STATE)
        2'b00 : begin
          //we are still reading in the data from the stereo module:
          if ((stereo_counter == 10'd575)) begin
            STATE <= 1;   //DONE READING FROM THE STEREO MODULE
            aliasing_lut_in <= 0;    //set this to 0, and start the count off in the next state!
            stereo_counter <= 0;
          end else if (din_v) begin
            stereo_counter <= stereo_counter + 1;
          end
        end

        2'b01 : begin
          //in the process of reading off data to the next modules:
          //note that dout_v should have already been set by this thing!
          if (aliasing_lut_in == 9'd287) begin
            STATE <= 2'b10;   //DONE READING EVERYTHING OFF!
            aliasing_lut_in <= 0;   //reset this to 0.
          end
          else begin
            aliasing_lut_in <= aliasing_lut_in + 1; //increment, this reads up the first BRAM
          end
        end

        2'b10 : begin
          //just here to wait and prevent the bram from reading anything new. a new frame will trigger the reset
        end

      endcase

    end
  end

endmodule



/*
purely combinational implement of the aliasing math:
features a combinational lookup tabel for the CS and CA coefficients
32-bit Q2_30 math outputs (signed)
*/
module compute_antialiased_values (
    input wire signed [31:0] x_in,
    input wire signed [31:0] y_in,
    input wire [2:0] c_idx_in,

    output logic signed [31:0] x_out,
    output logic signed [31:0] y_out
  );

  logic signed [31:0] ca, cs;
  logic signed [63:0] q4_60_x, q4_60_y;
  logic signed [31:0] q2_30_x, q2_30_y;

  always_comb begin
    //these are in Q2_30 format
    case(c_idx_in)
      3'd0 : begin
        cs = 32'sb00110110111000010010101001010001;      //0.857493
        ca = 32'sb11011111000100100111111101011111;
      end
      3'd1 : begin
        cs = 32'sb00111000011011100111010111111111;      //0.881742
        ca = 32'sb11100001110011110010010010010110;
      end
      3'd2 : begin
        cs = 32'sb00111100110001101011100010110110;      //0.949629
        ca = 32'sb11101011111100011010000110011001;
      end
      3'd3 : begin
        cs = 32'sb00111110111011101010001000001001;      //0.9833
        ca = 32'sb11110100010110111000100110010100;
      end
      3'd4 : begin
        cs = 32'sb00111111101101101001000100100001;      //etc
        ca = 32'sb11111001111100100111111111100101;
      end
      3'd5 : begin
        cs = 32'sb00111111111100100100000011111010;
        ca = 32'sb11111101011000001101000000100101;
      end
      3'd6 : begin
        cs = 32'sb00111111111111100101100001100000;
        ca = 32'sb11111111000101110101110100010100;
      end
      3'd7 : begin
        cs = 32'sb00111111111111111110001010100011;
        ca = 32'sb11111111110000110110000100010100;
      end
    endcase

    q4_60_x = cs * x_in - ca * y_in;
    q4_60_y = cs * y_in + ca * x_in;

    q2_30_x = q4_60_x >>> 5'd30;
    q2_30_y = q4_60_y >>> 5'd30;    //parts select happens automatically'

    x_out = q2_30_x;
    y_out = q2_30_y;

  end



endmodule

`default_nettype wire
