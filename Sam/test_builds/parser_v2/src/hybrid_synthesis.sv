`default_nettype none
`timescale 1ns / 1ps

`include "iverilog_hack.svh"

module hybrid_synthesis (
  input wire clk,
  input wire rst,

  input wire window_switching_flag_in,
  input wire [1:0] block_type_in,
  input wire mixed_block_flag_in,

  input wire new_frame_start,

  input wire [31:0] x_in,
  input wire din_valid,

  output logic [31:0] x_out,
  output logic dout_valid
  );

  logic [4:0] sb;     // goes from 0 to 31
  logic [4:0] idx;    //goes from 0-17, it tells the downstream module what cosine table to use.
  logic [4:0] readout_counter;      //useful for indexing into the finished buffer.

  logic gr;           //either 0 (meaning still reading in from the first granule) or 1 (reading in from the second granule)
  logic mux;        //selects whether to feed into buffer 1 (if mux == 0) or buffer 2 (mux == 1)
  logic STATE;
  logic READOUT_STATE;        //if HIGH, it means readout from the other buffer
  logic [4:0] delayed_sample_counter; //this counts how many samples have been inputted into the buffer (from 0-17) at a 2 cc delay

  /*
  STATE:
    0 -> read in data (samples in is less that 1152 (32 * 18), meaning it has not read in the full 2 granules)
    1 -> pause until the next frame starts.
      note that since this module streams out the data too, it shouldn't have to deal with a 3rd STATE
  */

  logic [9:0] store_bram_addrA;
  logic [9:0] store_bram_addrB;
  logic [31:0] store_out;       //32-bit Q2_30 signed number corresponding to a store bit out.
  logic [31:0] store_in;

  assign store_bram_addrA = (sb > 0) ? idx + ((sb-1) * 18) : idx + 10'd558;    //this needs to align with the current x_out, but 2 CCs before
  assign store_bram_addrB = readout_counter + ((sb - 1) * 18);   //this is aligned with the current x_out.

  xilinx_true_dual_port_read_first_2_clock_ram #(
    .RAM_WIDTH(32),                       // Specify RAM data width
    .RAM_DEPTH(576),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) STORE (
    .addra(store_bram_addrA),   //READ PORT: this allows the module to read in values from the store
    .addrb(store_bram_addrB),   // WRITE PORT: write in store values using port b. this is synchronized with the x_out delivery
    .dina(32'b0),     // nothing becuase tihs port is not used for writing
    .dinb(store_out),     // this is assigned in the last always_comb -> takes on a value from 'store'
    .clka(clk),     // Port A clock
    .clkb(clk),     // Port B clock
    .wea(1'b0),       // Port A write enable
    .web(dout_valid),       // Port B write enable -> can align with the x_out validity
    .ena(1'b1),       // Port A RAM Enable, for additional power savings, disable port when not in use
    .enb(1'b1),       // Port B RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),     // Port A output reset (does not affect memory contents)
    .rstb(rst),     // Port B output reset (does not affect memory contents)
    .regcea(1'b1), // Port A output register enable
    .regceb(1'b1), // Port B output register enable
    .douta(store_in),   // use this data to add to the current synthesized value
    .doutb()    // port B output not used, only input used.
  );


  logic [35:0][31:0] out_buffer_1;
  logic [35:0][31:0] out_buffer_2;
  logic [35:0][31:0] conv_win;

  logic [1:0] bt;

  always_comb begin
    if (window_switching_flag_in && (mixed_block_flag_in) && (sb < 2)) begin
      bt = 0;
    end else begin
      bt = block_type_in;
    end
  end

  long_block_win_convolution LongWin (
      .clk(clk),
      .rst(rst),
      .x_in(x_in),
      .idx(idx),
      .bt(bt),
      .OUT(conv_win)
    );

  logic [1:0] din_valid_pipe;
  logic [1:0] mux_pipe;

  always_ff @(posedge clk) begin
    if (rst || new_frame_start) begin
      for (int i=0; i < 36; i++) begin
        out_buffer_1[i] <= 0;
        out_buffer_2[i] <= 0;
      end

      sb <= 0;
      idx <= 0;
      readout_counter <= 0;
      gr <= 0;
      mux <= 0;
      STATE <= 0;
      dout_valid <= 0;
      READOUT_STATE <= 0;
      delayed_sample_counter <= 0;

    end else begin
      mux_pipe <= {mux_pipe[0], mux};
      din_valid_pipe <= (STATE == 0) ? {din_valid_pipe[0], din_valid} : {din_valid_pipe[0], 1'b0};

      if (din_valid_pipe[1]) begin
        delayed_sample_counter <= (delayed_sample_counter < 5'd17) ? delayed_sample_counter + 1 : 0;
      end

      case(READOUT_STATE)
        1'b0 : begin
          //this means don't read out from the other buffer!
          if (delayed_sample_counter == 5'd17) begin
            READOUT_STATE <= 1;
            readout_counter <= 0;
            dout_valid <= 1;
          end
        end
        1'b1 : begin
          readout_counter <= readout_counter + 1;
          if (readout_counter == 5'd17) begin
            READOUT_STATE <= (delayed_sample_counter == 5'd17) ? 1 : 0;   //return to this state anyway if delayed sample counter has hit 17
            readout_counter <= 0;   //always reset this to 0
            dout_valid <= (delayed_sample_counter == 5'd17) ? 1 : 0;
          end
        end
      endcase

      case (STATE)
        1'b0 : begin
              if ((sb == 5'd31) && (idx == 5'd17) && (din_valid) && (gr)) begin
                STATE <= 1;     //transition to the next state because all
              end
              else if (din_valid) begin
                sb <= (idx == 5'd17) ? sb + 1 : sb;    //automatically cycles to 0 after 31
                idx <= (idx == 5'd17) ? 0 : idx + 1;  //does not automatically cycle to 0
                gr <= ((sb == 5'd31) && (idx==5'd17)) ? gr + 1 : gr;    //also automatically cycles to 0.

                if (idx == 5'd17) begin
                  //this means the 18th bit of data was just read into a buffer. it is time to switch the muxer and signal to read out from the last one:
                  mux <= mux + 1;
                end
              end
        end

        1'b1 : begin
              //just wait here for the start of the next frame.

        end
      endcase

      //COMPUTE THE NEW OUT_BUFFERS (only if the input two clock cycles ago was valid)
      if (din_valid_pipe[1]) begin
            if (~mux_pipe[1]) begin
              for (int i=0; i < 36; i ++) begin
                out_buffer_1[i] <= (delayed_sample_counter > 0) ?
                                    $signed(out_buffer_1[i]) + $signed(conv_win[i]) :
                                    $signed(conv_win[i]);
              end
            end else begin
              for (int i=0; i < 36; i ++) begin
                out_buffer_2[i] <= (delayed_sample_counter > 0) ?
                                    $signed(out_buffer_2[i]) + $signed(conv_win[i]) :
                                    $signed(conv_win[i]);
              end
            end
      end
    end
  end

  logic [11:0] buffer_shift;
  logic [11:0] store_shift;

  always_comb begin
      buffer_shift = (readout_counter) << 5;
      store_shift = (readout_counter + 5'd18) << 5;

      //determine the value of x_out:
      if (mux_pipe[1]) begin
        //this means read out from buffer 1:
        x_out = (out_buffer_1 >> buffer_shift) + store_in;
        store_out = out_buffer_1 >>> (store_shift);
      end else begin
        x_out = (out_buffer_2 >> buffer_shift) + store_in;
        store_out = out_buffer_2 >>> (store_shift);
      end
  end

endmodule


module long_block_win_convolution(
  input wire clk,
  input wire rst,
  input wire [4:0] idx,
  input wire [1:0] bt,
  input wire signed [31:0] x_in,

  output logic [35:0][31:0] OUT
  );

  /*
  this module is only supposed to compute the cosine table windowing.
  given some x and index i, it retrieves the proper cosine table and multiplies
  everythign pointwise.

  it takes 2 clock cycles to compute (because the BRAM LUT takes 2)
  */

  logic [35:0][31:0] cosine_tab;      //allows all 36 values to be instantly assigned by the table

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(1152),                       // 36 separate 32-bit Q2_30 numbers (cosine values)
    .RAM_DEPTH(18),                     // 18 possible cosine tables (dependign on input position idx)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(cosN36_tab.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) COS36_tab (
    .addra(idx),     // Address bus, width determined from RAM_DEPTH
    .dina(1152'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(cosine_tab)      // RAM output data, width determined from RAM_WIDTH
  );


  /*
  THE FOLLOWING BRAM IS ONLY USED WHEN THE BLOCK TYPE IS 2!!!!!!!!!
  */

  logic [35:0][31:0] bt2_coeffs_tab;      //allows all 36 values to be instantly assigned by the table

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(1152),                    // this table exists because BT==2 has a totally different set of coefficients
    .RAM_DEPTH(18),                     // 18 possible cosine tables (dependign on input position idx)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(bt_2_hybrid_synth_coeffs0.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) BT_2_coeffs (
    .addra(idx),     // Address bus, width determined from RAM_DEPTH
    .dina(1152'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(bt2_coeffs_tab)      // RAM output data, width determined from RAM_WIDTH
  );

  logic [35:0][31:0] imdct_tab;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(1152),                       // 36 separate 32-bit Q2_30 numbers (cosine values)
    .RAM_DEPTH(4),                     // 18 possible cosine tables (dependign on input position idx)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(imdctWin_tab.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) IMDCTWIN (
    .addra(bt),     // Address bus, width determined from RAM_DEPTH
    .dina(1152'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(imdct_tab)      // RAM output data, width determined from RAM_WIDTH
  );

  logic [1:0][31:0] x_in_pipe;

  always_ff @(posedge clk) begin
    if (rst) begin
      x_in_pipe <= 0;
    end else begin
      //pipelining:
      x_in_pipe[0] <= x_in;
      x_in_pipe[1] <= x_in_pipe[0];
    end
  end

  logic [63:0] TMP_1 [35:0];    //need to save the intermediate result into a 64 bit array
  logic [31:0] TMP_2 [35:0];
  logic [63:0] TMP_3 [35:0];


  logic [31:0] TAG_COS, TAG_X_IN;

  assign TAG_COS = cosine_tab[0];
  assign TAG_X_IN = x_in_pipe[1];

  always_comb begin
  //TODO: ADD IN THE CASE FOR BT == 2 (IT HAS A DIFFERENT FORMULA ALL TOGETHER)
      for (int i=0; i < 36; i ++) begin

        if (bt == 2) begin
          TMP_1[i] = $signed(x_in_pipe[1]) * $signed(bt2_coeffs_tab[i]);
          TMP_2[i] = $signed(TMP_1[i]) >>> 30;
          OUT[i] = TMP_2[i];
          TMP_3[i] = 0;
        end

        else begin
          TMP_1[i] = $signed(x_in_pipe[1]) * $signed(cosine_tab[i]);
          TMP_2[i] = $signed(TMP_1[i]) >>> 30;       //parts select the correct 32 bits (skip first two bits)
          TMP_3[i] = $signed(TMP_2[i]) * $signed(imdct_tab[i]);
          OUT[i] = $signed(TMP_3[i]) >>> 30;
        end
      end
  end

endmodule


`default_nettype wire
