`default_nettype none
`timescale 1ns / 1ps

`include "iverilog_hack.svh"

/*
gameplan: assemble the 4 inputs from one antialias channel.
the next module will align the fucking granules and hold the channels separate
but we obviously need two modules seuqntially to take care of that
because otherwise we would need a 4-port RAM, which I don't know how to make

this module only really reorders the inputs from the antialias module,
which for simplicity on that end spit things out in some random order
whatever...
*/

module antialias_reorder (
    input wire clk,
    input wire rst,
    input wire new_frame_start,

    input wire [31:0] ch1_x_in,
    input wire [31:0] ch1_y_in,
    input wire [31:0] ch2_x_in,
    input wire [31:0] ch2_y_in,

    input wire [9:0] x_pos_in,
    input wire [9:0] y_pos_in,
    input wire valid_in,

    output logic signed [31:0] ch1_out,
    output logic signed [31:0] ch2_out,   //note that these are churned out in order
    output logic valid_out
  );

  logic [1:0] STATE;

  logic [9:0] sample_counter;   //only need to count to 288
  logic [9:0] readout_counter;     //counts all the way to 576. cus this only sends one is_pos at a time (for two channels simultaneously)

  logic [9:0] ch1_bram_addrA;
  logic [9:0] ch2_bram_addrA;

  assign ch1_bram_addrA = (STATE == 0) ? x_pos_in : readout_counter;
  assign ch2_bram_addrA = (STATE == 0) ? x_pos_in : readout_counter;

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH())                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) CH1 (
    .addra(ch1_bram_addrA),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(y_pos_in),   // Port B address bus, width determined from RAM_DEPTH
    .dina(ch1_x_in),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(ch1_y_in),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk),     // Port A clock
    .clkb(clk),     // Port B clock
    .wea(valid_in && (STATE == 0)),       // Port A write enable
    .web(valid_in && (STATE == 0)),       // Port B write enable
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
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH())                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) CH2 (
    .addra(ch2_bram_addrA),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(y_pos_in),   // Port B address bus, width determined from RAM_DEPTH
    .dina(ch2_x_in),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(ch2_y_in),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk),     // Port A clock
    .clkb(clk),     // Port B clock
    .wea(valid_in && (STATE == 0)),       // Port A write enable
    .web(valid_in && (STATE == 0)),       // Port B write enable
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
      sample_counter <= 0;
      readout_counter <= 0;
      valid_out_pipe <= 0;
    end else begin
      valid_out_pipe <= (STATE == 1) ? {valid_out_pipe[0],1'b1} : {valid_out_pipe[0],1'b0};
      case(STATE)
        2'b00 : begin
          //READING IN DATA:
          if (sample_counter == 10'd288) begin
            STATE <= 1;
          end else if (valid_in) begin
            sample_counter <= sample_counter + 1;
          end
        end

        2'b01 : begin
          if (readout_counter < 10'd575) begin
            readout_counter <= readout_counter + 1;
          end else begin
            STATE <= 2'b10;
          end
        end

        2'b10 : begin
          //just wait here until the frame restard. I don't want this thing churning out the wrong data.

        end

      endcase

    end

  end





endmodule


`default_nettype wire
