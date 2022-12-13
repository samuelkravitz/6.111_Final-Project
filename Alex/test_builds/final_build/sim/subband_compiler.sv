`default_nettype none
`timescale 1ns / 1ps


module subband_compiler (
    input wire clk,
    input wire rst,
    input wire data_in,
    input wire data_valid_in,


    output logic [31:0][31:0] data_out,
    output logic  data_valid_out
  );


  logic [4:0] ss;
  logic [31:0][11:0] idx_table_out;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(386),                       // 32 separate 12 bit items
    .RAM_DEPTH(18),                     // 18 possible cosine tables (dependign on input position idx)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(FINAL_BRAM_IS_IDXs.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) IDX_table (
    .addra(ss),     // Address bus, width determined from RAM_DEPTH
    .dina(386'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(idx_table_out)      // RAM output data, width determined from RAM_WIDTH
  );


  logic [10:0] imdct_addra;
  logic [31:0] imdct_tab_out;

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(32),                       // 32 separate 12 bit items
    .RAM_DEPTH(1152),                     // 18 possible cosine tables (dependign on input position idx)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE()          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) IMDCT_STORE (
    .addra(imdct_addra),     // Address bus, width determined from RAM_DEPTH
    .dina(data_in),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(data_valid_in),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta(imdct_tab_out)      // RAM output data, width determined from RAM_WIDTH
  );

  logic [2:0] STAGE;
  logic [10:0] sample_in_counter;
  logic [2:0] 2cc_delay;
  logic [4:0] is_idx;
  logic [1:0] is_bram_read_pipe;

  always_ff @(posedge clk) begin
    if (rst) begin
      imdct_addra <= 0;
      data_out <= 0;
      data_valid_out <= 0;
      ss <= 0;
      STAGE <= 0;
      sample_in_counter <= 0;
      is_idx <= 0;
      is_bram
    end else begin
      if (data_valid_out) data_valid_out <= 0;
      case(STAGE)
        2'd0 : begin
          //read in data from the IMDCT MODULE:
          imdct_addra <= sample_in_counter;
          if (sample_in_counter == 11'd1152) begin
            STAGE <= 2'd1;
            imdct_addra <= ss;
            2cc_delay <= 0;
          end else begin
            if (data_valid_in) begin
              sample_in_counter <= sample_in_counter + 1;
            end
          end
        end

        2'd1 : begin
          //read in the correct set of indexes:
          2cc_delay <= 2cc_delay + 1;
          if (2cc_delay == 2'd2) begin
            //move on, the indexes are correct!
            STAGE <= 2'd2;
            is_idx <= 0;      //start from the first index!
          end
        end

        2'd2: begin
          //read in the correct samples into the data out:


        end
      endcase

    end
  end



endmodule

`default_nettype wire
