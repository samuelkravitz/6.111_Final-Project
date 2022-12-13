`default_nettype none
`timescale 1ns / 1ps

`include "iverilog_hack.svh"

/*
this module takes inputs from TWO separate antialias_reorder modules
each modules feeds in both channels at once (576 times) for their particular granule

the point of this module is to assemble the granules together, then ship out
the channels simultaneously over both granules (1152 samples for each channel).
This is useful becase the downstream hybrid synthesis module needs the granules to be
inputted sequentially too.
*/

module granule_assembler (
    input wire clk,
    input wire rst,
    input wire new_frame_start,

    input wire gr1_ch1_in,
    input wire gr1_ch2_in,
    input wire gr1_valid_in,

    input wire gr2_ch1_in,
    input wire gr2_ch2_in,
    input wire gr2_valid_in,

    output logic signed [31:0] ch1_out,
    output logic signed [31:0] ch2_out,
    output logic valid_out
  );

  logic [1:0] STATE;

  logic [10:0] sample_counter_gr1, sample_counter_gr2;       //input is 576 samples
  logic [10:0] readout_counter;     //this goes up to 1152, it churns out BOTH granules sequentially

  /*
  READ IN SCHEME (STATE == 0):
    Address A -> read in granule 1 data
    Address B -> read in granule 2 data (sample_counter + 576)

  READ OUT SCHEME (STATE == 1):
    Address A -> read out
    Address B -> NOT USED
  */

  logic [10:0] ch1_bram_addrA;
  logic [10:0] ch2_bram_addrA;

  assign ch1_bram_addrA = (STATE == 0) ? sample_counter_gr1 : readout_counter;
  assign ch2_bram_addrA = (STATE == 0) ? sample_counter_gr1 : readout_counter;

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(1152),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH())                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) CH1 (
    .addra(),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(sample_counter_gr2 + 10'd576),   // Port B address bus, width determined from RAM_DEPTH
    .dina(gr1_ch1_in),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(gr2_ch1_in),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk),     // Port A clock
    .clkb(clk),     // Port B clock
    .wea(gr1_valid_in && (STATE == 0)),       // Port A write enable
    .web(gr2_valid_in && (STATE == 0)),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),     // Port A output reset (does not affect memory contents)
    .rstb(rst),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(ch1_out),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb()    // Port B RAM output data, width determined from RAM_WIDTH
  );


  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(1152),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH())                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) CH2 (
    .addra(ch2_bram_addrA),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(sample_counter + 10'd576),   // Port B address bus, width determined from RAM_DEPTH
    .dina(gr1_ch2_in),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(gr2_ch2_in),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk),     // Port A clock
    .clkb(clk),     // Port B clock
    .wea(gr1_valid_in && (STATE == 0)),       // Port A write enable
    .web(gr2_valid_in && (STATE == 0)),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),     // Port A output reset (does not affect memory contents)
    .rstb(rst),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(ch2_out),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb()    // Port B RAM output data, width determined from RAM_WIDTH
  );


  logic [1:0] valid_out_pipe;

  assign valid_out = valid_out_pipe[1];

  always_ff @(posedge clk) begin
    if(rst || new_frame_start) begin
      STATE <= 0;
      sample_counter_gr1 <= 0;
      sample_counter_gr2 <= 0;
      readout_counter <= 0;
      valid_out_pipe <= 0;
    end else begin
      valid_out_pipe <= (STATE == 1) ? {valid_out_pipe[0],1'b1} : {valid_out_pipe[0],1'b0};
      case(STATE)
        2'b00 : begin
          //READING IN DATA:

          if ((sample_counter_gr1 == 10'd576) && (sample_counter_gr2 == 10'd576)) begin
            STATE <= 1;
          end else begin
                  if (gr1_valid_in) begin
                    sample_counter_gr1 <= sample_counter_gr1 + 1;
                  end

                  if (gr2_valid_in) begin
                    sample_counter_gr2 <= sample_counter_gr2 + 1;
                  end
          end
        end

        2'b01 : begin
          if (readout_counter < 10'd1152) begin
            readout_counter <= readout_counter + 1;
          end else begin
            STATE <= 2'b10;
          end
        end

        2'b10 : begin
          //just wait here until the frame restart. I don't want this thing churning out the wrong data.

        end

      endcase

    end

  end

endmodule


`default_nettype wire
