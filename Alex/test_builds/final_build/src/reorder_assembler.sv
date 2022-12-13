/*
utility of this module is to assemble the output of the reorder module
into channels, and then eventually read off the data into the stereo module,


it takes in the granule and channel, position, and validity from the reorder module
additionally, it takes in the requantized value from requantizer_v3 pipelined though,
because the stereo module takes 2 clock cycles to function I think.
*/

`default_nettype none
`timescale 1ns / 1ps

module reorder_assembler (
    input wire clk,
    input wire rst,
    input wire [1:0] grch_in,
    input wire [9:0] is_pos_in,
    input wire [31:0] x_in,           //note that this doesnt come from the reorder module. it is pipelined from the requantizer
    input wire d_valid_in,

    input wire [1:0][1:0][8:0] big_values,
    input wire new_frame_start,

    output logic [31:0] ch1_gr1_out,
    output logic [31:0] ch2_gr1_out,
    output logic [31:0] ch1_gr2_out,
    output logic [31:0] ch2_gr2_out,
    output logic d_valid_out
  );

  logic [2:0] READ_STATUS;
  logic [3:0] [9:0] MAX_IS_POS;     //keeps track of the highest ISPOS coded for.
  /*
  STATES:
    0 -> reading in data for gr0 ch0
    1 -> reading in data for gr0 ch1
    2 -> reading in data for gr1 ch0
    3 -> reading in data for gr1 ch1

    4 -> writing out data for gr0
    5 -> writing out data for gr1
  */

  logic [31:0] x_gr1_ch1_out;
  logic [31:0] x_gr2_ch1_out;
  logic [31:0] x_gr1_ch2_out;
  logic [31:0] x_gr2_ch2_out;


  logic [9:0] bram_addra;
  logic [31:0] bram_input;

  always_comb begin
    if (READ_STATUS != 3'b100) begin
      bram_addra = is_pos_in;
      bram_input = x_in;
    end else begin
      bram_addra = output_counter;
      bram_input = 32'b0;           ///useful to flush out the BRAMS!!!
    end

  end

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) GR1_CH1 (
    .addra(bram_addra),     // Address bus, width determined from RAM_DEPTH
    .dina(bram_input),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(((grch_in == 2'b00) && (d_valid_in) || (READ_STATUS == 3'b100))),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(x_gr1_ch1_out)      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) GR1_CH2 (
    .addra(bram_addra),     // Address bus, width determined from RAM_DEPTH
    .dina(bram_input),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(((grch_in == 2'b01) && (d_valid_in) || (READ_STATUS == 3'b100))),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(x_gr1_ch2_out)      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) GR2_CH1 (
    .addra(bram_addra),     // Address bus, width determined from RAM_DEPTH
    .dina(bram_input),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(((grch_in == 3'b10) && (d_valid_in) || (READ_STATUS == 3'b100))),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(x_gr2_ch1_out)      // RAM output data, width determined from RAM_WIDTH
  );

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) GR2_CH2 (
    .addra(bram_addra),     // Address bus, width determined from RAM_DEPTH
    .dina(bram_input),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(((grch_in == 2'b11) && (d_valid_in) || (READ_STATUS == 3'b100))),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(x_gr2_ch2_out)      // RAM output data, width determined from RAM_WIDTH
  );

  logic [9:0] output_counter;
  logic [9:0] sample_counter;

  logic [1:0] d_valid_out_pipe;

  always_ff @(posedge clk) begin
    d_valid_out_pipe <= (READ_STATUS == 3'b100) ? {d_valid_out_pipe[0], 1'b1} : {d_valid_out_pipe[0], 1'b0};
  end

  assign d_valid_out = d_valid_out_pipe[1];

  always_comb begin
    ch1_gr1_out = x_gr1_ch1_out;
    ch2_gr1_out = x_gr1_ch2_out;
    ch1_gr2_out = x_gr2_ch1_out;
    ch2_gr2_out = x_gr2_ch2_out;
  end

  always_ff @(posedge clk) begin
    if (rst || new_frame_start) begin
      READ_STATUS <= 0;
      MAX_IS_POS <= 0;      //the maximum coded positions are all zero on reset
      output_counter <= 0;
      sample_counter <= 0;
    end else begin
      case(READ_STATUS)
        3'b000 : begin
          //reading into gr1 ch1 BRAM
          if (d_valid_in) begin
            if (grch_in != 2'b00) begin
              MAX_IS_POS[0] <= sample_counter;
              sample_counter <= 1;
              READ_STATUS <= grch_in;
            end else if (sample_counter + 1'b1 == big_values[0][0] << 1) begin
              READ_STATUS <= 3'b001;
              sample_counter <= 0;
              MAX_IS_POS[0] <= big_values[0][0];
            end else begin
              sample_counter <= sample_counter + 1;
            end
          end else if (sample_counter >= big_values[0][0] << 1) begin
            READ_STATUS <= 3'b001;
            MAX_IS_POS[0] <= sample_counter;
          end
        end
        3'b001 : begin
          //reading into gr1 ch1 BRAM
          if (d_valid_in) begin
            if (grch_in != 2'b01) begin
              MAX_IS_POS[1] <= sample_counter;
              sample_counter <= 1;
              READ_STATUS <= grch_in;
            end else if (sample_counter + 1'b1 == big_values[0][1] << 1) begin
              READ_STATUS <= 3'b010;
              sample_counter <= 0;
              MAX_IS_POS[1] <= big_values[0][1];
            end else begin
              sample_counter <= sample_counter + 1;
            end
          end else if (sample_counter >= big_values[0][1] << 1) begin
            READ_STATUS <= 3'b010;
            MAX_IS_POS[1] <= sample_counter;
          end
        end
        3'b010 : begin
          //reading into gr1 ch1 BRAM
          if (d_valid_in) begin
            if (grch_in != 2'b10) begin
              MAX_IS_POS[2] <= sample_counter;
              sample_counter <= 1;
              READ_STATUS <= grch_in;
            end else if (sample_counter + 1'b1 == big_values[1][0] << 1) begin
              READ_STATUS <= 3'b011;
              sample_counter <= 0;
              MAX_IS_POS[2] <= big_values[1][0] << 1;
            end else begin
              sample_counter <= sample_counter + 1;
            end
          end else if (sample_counter >= big_values[1][0] << 1) begin
            READ_STATUS <= 3'b011;
            MAX_IS_POS[2] <= sample_counter;
          end
        end
        3'b011 : begin
          //reading into gr1 ch1 BRAM
          if (d_valid_in) begin
            if (grch_in != 2'b11) begin
              MAX_IS_POS[3] <= sample_counter;
              sample_counter <= 1;
              READ_STATUS <= 3'b100;
            end else if (sample_counter + 1'b1 == big_values[1][1] << 1) begin
              READ_STATUS <= 3'b100;
              sample_counter <= 0;
              MAX_IS_POS[3] <= big_values[1][1];
            end else begin
              sample_counter <= sample_counter + 1;
            end
          end else if (sample_counter >= big_values[1][1] << 1) begin
            READ_STATUS <= 3'b100;
            MAX_IS_POS[3] <= sample_counter;
          end
        end

        3'b100 : begin
          //time to readout to the stereo module:
          output_counter <= output_counter + 1;
          if (output_counter == 10'd575) begin
            READ_STATUS <= 3'b101;    //set it to something higher so it defaults to the waiting routine.
          end
        end
        default : begin
            //just wait until the next frame starts.

        end
      endcase
    end

  end


endmodule


`default_nettype wire
