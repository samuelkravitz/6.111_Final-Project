`default_nettype none
`timescale 1ns / 1ps

`include "iverilog_hack.svh"

/*
implemented just like the threaded one. I don't want to try this combinationally.
we have all the time in the world

it expects an entire channel (back to back granules)
this is because the V_vec carries over and is shared between granules.

input things sequentially...
*/


module subband_synthesis(
    input wire clk,
    input wire rst,

    input wire new_frame_start,

    input wire [31:0] x_in,
    input wire x_valid_in
  );

  logic [9:0] V_vec_addra;
  logic [31:0] V_vec_din;
  logic V_vec_wea;
  logic [31:0] V_vec_dout;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // 36 separate 32-bit Q2_30 numbers (cosine values)
    .RAM_DEPTH(1024),                     // 18 possible cosine tables (dependign on input position idx)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) V_vec (
    .addra(V_vec_addra),     // Address bus, width determined from RAM_DEPTH
    .dina(V_vec_din),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(V_vec_wea),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(V_vec_dout)      // RAM output data, width determined from RAM_WIDTH
  );


  logic [4:0] S_vec_addra;
  logic [31:0] S_vec_din;
  logic S_vec_wea;
  logic [31:0] S_vec_dout;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // 36 separate 32-bit Q2_30 numbers (cosine values)
    .RAM_DEPTH(32),                     // 18 possible cosine tables (dependign on input position idx)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) S_vec (
    .addra(S_vec_addra),     // Address bus, width determined from RAM_DEPTH
    .dina(S_vec_din),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(S_vec_wea),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(S_vec_dout)      // RAM output data, width determined from RAM_WIDTH
  );


  logic [8:0] U_vec_addra;
  logic [31:0] U_vec_din;
  logic U_vec_wea;
  logic [31:0] U_vec_dout;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // 36 separate 32-bit Q2_30 numbers (cosine values)
    .RAM_DEPTH(512),                     // 18 possible cosine tables (dependign on input position idx)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) U_vec (
    .addra(U_vec_addra),     // Address bus, width determined from RAM_DEPTH
    .dina(U_vec_din),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(U_vec_wea),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(U_vec_dout)      // RAM output data, width determined from RAM_WIDTH
  );


  logic [10:0] IS_vec_addra;
  logic [31:0] IS_vec_din;
  logic IS_vec_wea;
  logic [31:0] IS_vec_dout;

  assign IS_vec_din = x_in;
  assign IS_vec_wea = x_valid_in && (STATE == 0);

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // 36 separate 32-bit Q2_30 numbers (cosine values)
    .RAM_DEPTH(1152),                     // 18 possible cosine tables (dependign on input position idx)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) IS_vec (
    .addra(IS_vec_addra),     // Address bus, width determined from RAM_DEPTH
    .dina(IS_vec_din),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(IS_vec_wea),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(IS_vec_dout)      // RAM output data, width determined from RAM_WIDTH
  );


  logic [3:0] STATE;
  logic [10:0] sample_counter;
  logic [4:0] ss;
  logic [10:0] i_idx;
  logic [8:0] j_idx;
  logic ram_2cc_delay;

  logic rd_wr_muxer;     //used for copying over data within the V VECTOR

  logic [1:0][4:0] S_vec_addra_pipe;
  logic [1:0] S_vec_wea_pipe;

  always_ff @(posedge clk) begin
    if (rst || new_frame_start) begin
      STATE <= 0;
      sample_counter <= 0;
      ram_2cc_delay <= 0;
      rd_wr_muxer <= 0;


      V_vec_addra <= 0;
      V_vec_din <= 0;
      V_vec_wea <= 0;

      U_vec_addra <= 0;
      U_vec_din <= 0;
      U_vec_wea <= 0;

      S_vec_addra <= 0;
      S_vec_din <= 0;
      S_vec_wea <= 0;

      IS_vec_addra <= 0;

      i_idx <= 0;
      ss <= 0;

      S_vec_addra_pipe <= 0;
      S_vec_wea_pipe <= 0;

    end else begin
      ram_2cc_delay <= ram_2cc_delay + 1;
          case(STATE)
            4'd0 : begin
              //READ IN DATA TO THE IS BRAM:
              if (sample_counter == 11'd1152) begin
                STATE <= 1;
                i_idx <= 0;
                sample_counter <= 0;
                IS_vec_addra <= 0;
              end else begin
                if (x_valid_in) begin
                  sample_counter <= sample_counter + 1;
                  IS_vec_addra <= sample_counter + 1;
                end
              end
            end

            4'd1 : begin
              //COPY THE BEGINNING OF THE V VEC INTO THE END (0-960 into 64-1024):
              if (ram_2cc_delay) begin
                //only operate every 2 clock cycles to give time for the BRAM:
                rd_wr_muxer <= rd_wr_muxer + 1;
                        if (~rd_wr_muxer) begin
                          //this means we are READING from place (i):
                          if (i_idx == 11'd960) begin
                            //this means we have finished READING from 959 AND writing to 1023.
                            STATE <= 4'd2;
                            i_idx <= 0;
                          end else begin
                            V_vec_addra <= i_idx;
                            i_idx <= i_idx + 1;
                          end
                        end else begin
                          //write to i + 64:
                          V_vec_addra <= (i_idx + 11'd63);
                          V_vec_din <= V_vec_wea;
                          V_vec_wea <= 1;
                        end
              end else V_vec_wea <= 0;
            end


            4'd2 : begin
              //build the S vector:
              i_idx <= i_idx + 1;
              S_vec_wea <= S_vec_wea_pipe[1];

              S_vec_addra_pipe[0] <= i_idx;
              S_vec_addra_pipe[1] <= S_vec_addra_pipe[0];

              //set addresses:
              S_vec_addra <= S_vec_addra_pipe[1];
              S_vec_din <= IS_vec_dout;
              IS_vec_addra <= ss + (18 * i_idx);

              S_vec_wea_pipe[1] <= S_vec_wea_pipe[0];

              //set write enables:
              if (i_idx < 11'd31) begin
                S_vec_wea_pipe[0] <= 1'b1;

              end else if (i_idx < 11'd34) begin
                //this means we have just about finished writing
                S_vec_wea_pipe[0] <= 1'b0;
              end else begin
                S_vec_wea <= 0;
                S_vec_wea_pipe <= 0;
                STATE <= 4'd3;
              end
            end

            4'd3 : begin
                //compute first 64 values of V:



            end

          endcase


    end
  end




endmodule

`default_nettype wire
