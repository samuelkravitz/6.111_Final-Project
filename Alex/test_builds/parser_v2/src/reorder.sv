`default_nettype none
`timescale 1ns / 1ps

`include "iverilog_hack.svh"

/*
different approach the the window length and sfb problem
I will have 4 versions of the variables, and reset them all
when the side information line goes high.
otherwise, the si_valid line is NOT used to verify the
actual side information inputs. Those are fed in from a different system
so I don't have to have 4x the number of lines into this module

STATUS:
*/

module reorder (
  input wire clk,
  input wire rst,

  input wire [1:0] grch_in,
  input wire [9:0] is_pos,
  input wire din_v,

  input wire window_switching_flag,
  input wire [1:0] block_type,
  input wire mixed_block_flag,
  input wire [8:0] big_values,

  output logic [1:0] grch_out,
  output logic [9:0] is_pos_out,
  output logic dout_v

  );

  logic [11:0] case_1_out, case_2_out, case_3_out;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(12),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(REORDER_TB_1.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) TB_CASE_1 (
    .addra(is_pos),     // Address bus, width determined from RAM_DEPTH
    .dina(12'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(case_1_out)      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(12),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(REORDER_TB_2.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) TB_CASE_2 (
    .addra(is_pos),     // Address bus, width determined from RAM_DEPTH
    .dina(12'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(case_2_out)      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(12),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(REORDER_TB_3.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) TB_CASE_3 (
    .addra(is_pos),     // Address bus, width determined from RAM_DEPTH
    .dina(12'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(case_3_out)      // RAM output data, width determined from RAM_WIDTH
  );

  //need to pipeline, takes 2 clock cycles after getting data
  //from is_pos for a valid output to appear:
  logic [1:0][1:0] grch_pipe;
  logic [1:0] din_v_pipe;
  logic [1:0][9:0] is_pos_pipe;
  logic [1:0] window_switching_flag_pipe;
  logic [1:0][1:0] block_type_pipe;
  logic [1:0] mixed_block_flag_pipe;
  logic [1:0][8:0] big_values_pipe;

  logic [9:0] count1;

  assign count1 = big_values_pipe[1] << 1;

  always_ff @(posedge clk) begin
    if (rst) begin
      grch_pipe <= 0;
      din_v_pipe <= 0;
      is_pos_out <= 0;
      is_pos_pipe <= 0;
    end else begin

      grch_out <= grch_pipe[1];
      dout_v <= din_v_pipe[1];

      if (window_switching_flag_pipe[1] && (block_type_pipe[1] == 2) && (mixed_block_flag_pipe[1])) begin
        is_pos_out <= (is_pos_pipe[1] < count1) ? case_1_out : is_pos_pipe[1];
      end else if (window_switching_flag_pipe[1] && (block_type_pipe[1] == 2)) begin
        is_pos_out <= (is_pos_pipe[1] < count1) ? case_2_out : is_pos_pipe[1];;
      end else begin
        is_pos_out <= (is_pos_pipe[1] < count1) ? case_3_out : is_pos_pipe[1];
      end


      grch_pipe[0] <= grch_in;
      grch_pipe[1] <= grch_pipe[0];

      din_v_pipe <= {din_v_pipe[0], din_v};

      is_pos_pipe[0] <= is_pos;
      is_pos_pipe[1] <= is_pos_pipe[0];

      window_switching_flag_pipe[0] <= window_switching_flag;
      window_switching_flag_pipe[1] <= window_switching_flag_pipe[0];

      block_type_pipe[0] <= block_type;
      block_type_pipe[1] <= block_type_pipe[0];

      mixed_block_flag_pipe[0] <= mixed_block_flag;
      mixed_block_flag_pipe[1] <= mixed_block_flag_pipe[0];

      big_values_pipe[0] <= big_values;
      big_values_pipe[1] <= big_values_pipe[0];
    end
  end

endmodule

`default_nettype wire
