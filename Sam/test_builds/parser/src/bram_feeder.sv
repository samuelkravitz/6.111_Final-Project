`timescale 1ns / 1ps
`default_nettype none

`include "iverilog_hack.svh"

module bram_feeder(
  input wire clk,
  input wire rst,
  input wire frame_num_iv,
  input wire [6:0] frame_num_id,   //for testing, only has to go to 125

  output logic [7:0] axiod,
  output logic axiov,
  output logic frame_start      //notifies downstream stuff that the frame is just starting to be read off.
  );

  parameter delay = 18; //number of clock cycles to wait between axiov

  //reads out 512 bytes from the specified addra id
  logic [8:0] byte_counter;   //goes up to 511
  logic [4:0] delay_counter;    //goes to 18
  logic [15:0] frame_num_saved;   //save the address when it is valid
  logic [15:0] frame_addr;
  logic reading_status;

  always_comb begin
    //compute the read in address:
    //multiply by 512 and add byte counter to it
    frame_addr = (frame_num_saved << 9) + byte_counter;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      byte_counter <= 0;
      reading_status <= 0;
      delay_counter <= 0;
    end else begin
      if (frame_num_iv) begin
        reading_status <= 1;
        frame_num_saved <= (frame_num_id < 7'd124) ? frame_num_id : 7'd124;
        byte_counter <= 0;
      end else if (reading_status) begin
        if (delay_counter == delay) begin
          delay_counter <= 0;
          axiov <= 1;
          byte_counter <= byte_counter + 1;
          if (byte_counter == 9'd511) begin
            reading_status <= 0;
          end
        end else begin
          delay_counter <= delay_counter + 1;
          axiov <= 0;
        end
      end else begin
        axiov <= 0;
      end
    end
  end

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(64000),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(mp3_song.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image_BROM (
    .addra(frame_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(8'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(axiod)      // RAM output data, width determined from RAM_WIDTH
  );

endmodule

`default_nettype wire
