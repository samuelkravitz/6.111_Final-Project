`default_nettype none
`timescale  1ns / 1ps

`include "iverilog_hack.svh"

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


  logic [10:0] OUT_addrA, OUT_addrB;
  logic [31:0] OUT_din, OUT_data_out;
  logic OUT_wea;

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(1152),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) OUT (
    .addra(OUT_addrA),   // Port A address bus, width determined from RAM_DEPTH
    .addrb(OUT_addrB),   // Port B address bus, width determined from RAM_DEPTH
    .dina(),     // Port A RAM input data, width determined from RAM_WIDTH
    .dinb(OUT_din),     // Port B RAM input data, width determined from RAM_WIDTH
    .clka(clk),     // Port A clock
    .clkb(clk),     // Port B clock
    .wea(1'b0),       // Port A write enable
    .web(OUT_wea),       // Port B write enable
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),     // Port A output reset (does not affect memory contents)
    .rstb(rst),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(OUT_data_out),   // Port A RAM output data, width determined from RAM_WIDTH
    .doutb()    // Port B RAM output data, width determined from RAM_WIDTH
  );



  logic [3:0] STATE;
  logic [10:0] sample_counter;

  logic [4:0] parts_counter;      //goes up to 31
  logic [10:0] output_idx_counter;    //goes up to 1152

  logic [17:0] [31:0] IS_samples;
  logic [31:0][31:0] V_samples;

  logic [5:0] IS_sample_counter;
  logic [5:0] V_sample_counter;

  logic [2:0] bram_read_valid_pipe;

  logic [10:0] V_idx;

  logic [31:0] matmul_result;

  matmul_compute matrix_multiply (
      .clk(clk),
      .rst(rst),
      .in_idx(parts_counter),
      .out_idx(OUT_addrB),
      .IS_in(IS_samples),
      .V_in(V_samples),
      .data_out(matmul_result)
    );


  always_ff @(posedge clk) begin
    if (rst) begin
      STATE <= 0;
      sample_counter <= 0;

      IS_samples <= 0;
      V_samples <= 0;

      IS_sample_counter <= 0;
      V_sample_counter <= 0;

      output_idx_counter <= 0;
      parts_counter <= 0;

      IS_samples <= 0;
      V_samples <= 0;

      V_vec_addra <= 0;
      OUT_addrA <= 0;
      OUT_addrB <= 0;

      V_vec_wea <= 0;
      OUT_wea <= 0;

      bram_read_valid_pipe <= 0;
      V_vec_din <= 0;

      IS_vec_addra <= 0;
      OUT_din <= 0;

    end else begin
      case(STATE)
        4'd0 : begin
          //READ IN DATA TO THE IS BRAM:
          if (sample_counter == 11'd1152) begin
            STATE <= 1;
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
          //load in 18 samples from the IS vector:

          IS_vec_addra <= IS_sample_counter + (parts_counter * 5'd18);
          IS_sample_counter <= IS_sample_counter + 1;

          IS_samples[0] <= (bram_read_valid_pipe[2]) ? IS_vec_dout : IS_samples[0];

          for (int i = 1; i < 18; i++) begin
            IS_samples[i] <= (bram_read_valid_pipe[2]) ? IS_samples[i-1] : IS_samples[i];
          end

          if (IS_sample_counter < 5'd18) begin
            bram_read_valid_pipe <= {bram_read_valid_pipe[1:0], 1'b1};
          end else if (IS_sample_counter < 5'd21) begin
            bram_read_valid_pipe <= {bram_read_valid_pipe[1:0], 1'b0};
          end else begin
            bram_read_valid_pipe <= 0;    //just make sure it is set to 0, though it should already be
            STATE <= 4'd2;
            IS_sample_counter <= 0;
          end
        end

        4'd2 : begin
          //load in 32 samples from the V vector
          V_vec_addra <= V_sample_counter + (parts_counter * 6'd32);
          V_sample_counter <= V_sample_counter + 1;

          V_samples[0] <= (bram_read_valid_pipe[2]) ? V_vec_dout : V_samples[0];

          for (int i = 1; i < 32; i++) begin
            V_samples[i] <= (bram_read_valid_pipe[2]) ? V_samples[i-1] : V_samples[i];
          end

          if (V_sample_counter < 6'd32) begin
            bram_read_valid_pipe <= {bram_read_valid_pipe[1:0], 1'b1};
          end else if (V_sample_counter < 6'd35) begin
            bram_read_valid_pipe <= {bram_read_valid_pipe[1:0], 1'b0};
          end else begin
            bram_read_valid_pipe <= 0;    //just make sure it is set to 0, though it should already be
            STATE <= 4'd3;
            V_sample_counter <= 0;
          end
        end

        4'd3 : begin
          //iteratre through all 1152 output indices and add the current result to them:
          if (OUT_addrA < 11'd1151) begin
            OUT_addrA <= OUT_addrA + 1;
          end
          if (OUT_addrA < 11'd2) begin
            OUT_wea <= 0;   //dont try writing yet because the result is not ready...
          end else if (OUT_addrB < 11'd1151) begin
            OUT_wea <= 1;
            OUT_din <= matmul_result + OUT_data_out;    //this writes into the BRAM at port B
            OUT_addrB <= OUT_addrB + 1;
          end else begin
            OUT_wea <= 0;
            OUT_din <= 0;
            OUT_addrB <= 0;
            parts_counter <= parts_counter + 1;
            STATE <= (parts_counter == 6'd31) ? 4'd4 : 4'd1;
          end
        end

        4'd4 : begin
          //matrix multiply to recompute the new V
          //load in 32 samples from IS at a time. i will reuse the 'V_samples' variable bruh
          //load in 32 samples from the V vector
            // V_vec_addra <= V_sample_counter + (parts_counter * 6'd32);
            // V_sample_counter <= V_sample_counter + 1;
            //
            // V_samples[0] <= (bram_read_valid_pipe[2]) ? V_vec_dout : V_samples[0];
            //
            // for (int i = 1; i < 32; i++) begin
            //   V_samples[i] <= (bram_read_valid_pipe[2]) ? V_samples[i-1] : V_samples[i];
            // end
            //
            // if (V_sample_counter < 6'd32) begin
            //   bram_read_valid_pipe <= {bram_read_valid_pipe[1:0], 1'b1};
            // end else if (V_sample_counter < 6'd35) begin
            //   bram_read_valid_pipe <= {bram_read_valid_pipe[1:0], 1'b0};
            // end else begin
            //   bram_read_valid_pipe <= 0;    //just make sure it is set to 0, though it should already be
            //   STATE <= 4'd3;
            //   V_sample_counter <= 0;
            // end
        end

        4'd4 : begin
          //iterate through 1024 possible values and add the product to them:

        end

        4'd5 : begin
          //

        end
      endcase


    end


  end

endmodule



module matmul_compute (
    input wire clk,
    input wire rst,

    input wire [4:0] in_idx,          //0-31, tells you which set of coefficients to grab too
    input wire [10:0] out_idx,        //0-1151, tells you which OUT index to consider (and consequently coefficients)

    input wire [17:0] [31:0] IS_in,
    input wire [31:0] [31:0] V_in,


    output logic [31:0] data_out
  );


  logic [15:0] coeffs_BRAM_addra;
  logic [17:0] [31:0] IS_coeffs;
  logic [31:0] [31:0] V_coeffs;

  assign coeffs_BRAM_addra = out_idx << 5;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32 * 18),                       // 18 separate 32-bit Q2_30 coefficients
    .RAM_DEPTH(1152 * 32),                     // stacked coefficients 32 FIRST!!!
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(IS_coeffs_matrix.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) IS_coeffs_tab (
    .addra(coeffs_BRAM_addra),     // Address bus, width determined from RAM_DEPTH
    .dina(),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(IS_coeffs)      // RAM output data, width determined from RAM_WIDTH
  );


  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32 * 32),                       // 18 separate 32-bit Q2_30 coefficients
    .RAM_DEPTH(1152 * 32),                     // stacked coefficients 32 FIRST!!!
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(V_coeffs_matrix.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) V_coeffs_tab (
    .addra(coeffs_BRAM_addra),     // Address bus, width determined from RAM_DEPTH
    .dina(),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(V_coeffs)      // RAM output data, width determined from RAM_WIDTH
  );



  logic [1:0] [17:0][31:0] IS_in_pipe;
  logic [1:0] [31:0][31:0] V_in_pipe;

  always_ff @(posedge clk) begin
    if (rst) begin
      IS_in_pipe <= 0;
      V_in_pipe <= 0;
    end else begin
      IS_in_pipe[0] <= IS_in;
      IS_in_pipe[1] <= IS_in_pipe[0];

      V_in_pipe[0] <= V_in;
      V_in_pipe[1] <= V_in_pipe[0];
    end
  end

  logic [17:0][63:0] IS_q4_60;
  logic [31:0][63:0] V_q4_60;

  logic [17:0][31:0] IS_q2_30;
  logic [31:0][31:0] V_q2_30;


  always_comb begin
    for (int i = 0; i < 18; i ++) begin
      IS_q4_60[i] = $signed(IS_in_pipe[1][i]) * $signed(IS_coeffs[i]);
      IS_q2_30[i] = IS_q4_60[i] >>> 30;
    end

    for (int i=0; i < 32; i ++) begin
      V_q4_60[i] = $signed(V_in_pipe[1][i]) * $signed(V_coeffs[i]);
      V_q2_30[i] = V_q4_60[i] >>> 30;
    end

    data_out =  $signed(IS_q2_30[00]) + $signed(V_q2_30[00]) +
                $signed(IS_q2_30[01]) + $signed(V_q2_30[01]) +
                $signed(IS_q2_30[02]) + $signed(V_q2_30[02]) +
                $signed(IS_q2_30[03]) + $signed(V_q2_30[03]) +
                $signed(IS_q2_30[04]) + $signed(V_q2_30[04]) +
                $signed(IS_q2_30[05]) + $signed(V_q2_30[05]) +
                $signed(IS_q2_30[06]) + $signed(V_q2_30[06]) +
                $signed(IS_q2_30[07]) + $signed(V_q2_30[07]) +
                $signed(IS_q2_30[08]) + $signed(V_q2_30[08]) +
                $signed(IS_q2_30[09]) + $signed(V_q2_30[09]) +
                $signed(IS_q2_30[10]) + $signed(V_q2_30[10]) +
                $signed(IS_q2_30[11]) + $signed(V_q2_30[11]) +
                $signed(IS_q2_30[12]) + $signed(V_q2_30[12]) +
                $signed(IS_q2_30[13]) + $signed(V_q2_30[13]) +
                $signed(IS_q2_30[14]) + $signed(V_q2_30[14]) +
                $signed(IS_q2_30[15]) + $signed(V_q2_30[15]) +
                $signed(IS_q2_30[16]) + $signed(V_q2_30[16]) +
                $signed(IS_q2_30[17]) + $signed(V_q2_30[17]) +
                $signed(V_q2_30[18]) +
                $signed(V_q2_30[19]) +
                $signed(V_q2_30[20]) +
                $signed(V_q2_30[21]) +
                $signed(V_q2_30[22]) +
                $signed(V_q2_30[23]) +
                $signed(V_q2_30[24]) +
                $signed(V_q2_30[25]) +
                $signed(V_q2_30[26]) +
                $signed(V_q2_30[27]) +
                $signed(V_q2_30[28]) +
                $signed(V_q2_30[29]) +
                $signed(V_q2_30[30]) +
                $signed(V_q2_30[31]);
  end




endmodule



module v_restore_matmul (
  input wire clk,
  input wire rst,
  input wire in_idx,
  input wire shit
  );

endmodule

`default_nettype wire
