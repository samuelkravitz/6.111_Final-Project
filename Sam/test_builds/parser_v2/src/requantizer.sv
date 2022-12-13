`default_nettype none
`timescale  1ns / 1ps

`include "iverilog_hack.svh"

/*
honestly not robust code at all, in that the window length and counter
do no reset to 0 in a reliable way. I need a better system.
maybe reset the counters when the side information valid goes high?
but then you also have to reset it everytime a
new granule is processed.
idk man
*/

module requantizer (
    input wire clk,
    input wire rst,
    input wire si_valid,
    input wire sf_valid,

    input wire window_switching_flag,
    input wire [1:0]block_type,
    input wire mixed_block_flag,
    input wire scalefac_scale,
    input wire [7:0]global_gain,
    input wire preflag,
    input wire [2:0][2:0]subblock_gain,
    input wire [8:0]big_values,

    input wire [20:0][3:0]scalefac_l_in,
    input wire [11:0][2:0][3:0]scalefac_s_in,

    input wire [15:0] x_in,     //this is a signed value (in 2s complement, by the HT_00 type of modules)
    input wire [9:0] is_pos,    //BRAM ADDRA in huffman_plexer
    input wire din_valid,

    output logic [15:0] x_out,
    output logic [9:0] x_base_out,    //the assumption is that the base is negative. it always is man. so the is x_out >> x_base_out
    output logic dout_v    //again, one hot vector for each granule/channel
  );

  logic [15:0] x_pow_43;
  logic [3:0] x_tab_base;
  logic [9:0] count1;

  logic [15:0] x_abs;
  logic [15:0] x_in_mask;

  assign count1 = big_values << 1;    //2 times big values.
  assign x_in_mask = $signed(x_in) >>> 6'd15;
  assign x_abs = (x_in ^ x_in_mask) - x_in_mask; //get the absolute value of x_in;

  logic [2:0] dout_v_pipe;
  logic [2:0] x_in_sign_pipe;

  always_ff @(posedge clk) begin
    if (rst) dout_v_pipe <= 0;
    else begin
      dout_v_pipe <= {dout_v_pipe[1:0], din_valid};
      x_in_sign_pipe <= {x_in_sign_pipe[1:0], x_in[15]};
    end
  end

  assign dout_v = dout_v_pipe[2];

  logic [6:0] sfb;    //7 long to accomodate 22 * 4
  logic scalefac_shift;   //1 or 0, depending on scalefac_scale
  logic [1:0] pretab;

  logic [1:0][9:0] is_pos_pipe;

  always_ff @(posedge clk) begin
    is_pos_pipe[0] <= is_pos;
    is_pos_pipe[1] <= is_pos_pipe[0];
  end

  logic [9:0] p43_table_input;

  always_ff @(posedge clk) begin
    p43_table_input <= (x_abs > 10'd999) ? 10'd999 : x_abs[9:0];
  end

  xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(20),                       // Specify RAM data width
    .RAM_DEPTH(1000),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
    .INIT_FILE(`FPATH(pow_43_tab.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) pow43_tab (
    .addra(p43_table_input),     // Address bus, width determined from RAM_DEPTH
    .dina(20'b0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk),       // Clock
    .wea(1'b0),         // Write enable
    .ena(1'b1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst),       // Output reset (does not affect memory contents)
    .regcea(1'b1),   // Output register enable
    .douta({x_tab_base, x_pow_43})      // RAM output data, width determined from RAM_WIDTH
  );

  always_comb begin
    case(sfb)
      7'd00 : pretab = 0;
      7'd01 : pretab = 0;
      7'd02 : pretab = 0;
      7'd03 : pretab = 0;
      7'd04 : pretab = 0;
      7'd05 : pretab = 0;
      7'd06 : pretab = 0;
      7'd07 : pretab = 0;
      7'd08 : pretab = 0;
      7'd09 : pretab = 0;
      7'd10 : pretab = 0;
      7'd11 : pretab = 1;
      7'd12 : pretab = 1;
      7'd13 : pretab = 1;
      7'd14 : pretab = 1;
      7'd15 : pretab = 2;
      7'd16 : pretab = 2;
      7'd17 : pretab = 3;
      7'd18 : pretab = 3;
      7'd19 : pretab = 3;
      7'd20 : pretab = 2;
      7'd21 : pretab = 0;
    endcase
  end


  logic [1:0] band_type;    //0 for long, 1 for short
  logic [3:0] scalefac_sel;
  logic [1:0] win;

  logic signed [9:0] exp1;
  logic signed [11:0] exp2;
  logic signed [11:0] x_quant_base_signed;
  logic [11:0] x_quant_base_signed_mask;

  logic [2:0] target_subblock_gain;

  always_comb begin
    scalefac_shift = (scalefac_scale) ? 0 : 1;    //takes only the first 4 bits (just verilog)

    case(win)
      2'd0 : target_subblock_gain = subblock_gain[0];
      2'd1 : target_subblock_gain = subblock_gain[1];
      2'd2 : target_subblock_gain = subblock_gain[2];
      default : target_subblock_gain = 0;
    endcase

    if (band_type==0) begin
      //long band types
      scalefac_sel = scalefac_l_in >> (sfb << 2);;  //sfb * 4 gives the shift
      exp1 = $signed(global_gain - 10'sd210);   //this is supposed to be divided by 4, but i will just call it fixed point
      exp2 = ($signed(scalefac_sel + preflag * pretab)) <<< (2'd2 - scalefac_shift);  //making this 'fixed point'...
      x_quant_base_signed = $signed(exp1 - exp2 - (x_tab_base << 2));
      x_quant_base_signed_mask = x_quant_base_signed >>> 10;
      x_base_out = (x_quant_base_signed ^ x_quant_base_signed_mask) - x_quant_base_signed_mask;    //if the x_base_out_signed is positive, just set the base to 0. don't want to deal with that.
      x_out = (x_in_sign_pipe[2]) ? -1'sd1 * x_pow_43 : x_pow_43;
    end
    else if (band_type == 1) begin
      //short band types
      scalefac_sel = scalefac_s_in >> ( (3 * sfb)<<2 - (win << 2) );
      exp1 = $signed(global_gain - 10'sd210 - (target_subblock_gain << 3)  );
      exp2 = ($signed(scalefac_sel)) <<< (2'd2 - scalefac_shift);
      x_quant_base_signed_mask = x_quant_base_signed >>> 10;
      x_base_out = (x_quant_base_signed ^ x_quant_base_signed_mask) - x_quant_base_signed_mask;    //if the x_base_out_signed is positive, just set the base to 0. don't want to deal with that.
      x_out = (x_in_sign_pipe[2]) ? -1'sd1 * x_pow_43 : x_pow_43;
    end
    else begin
      //no band type (count1 regions for instance)
      x_base_out = 0;
      x_out = x_in;
    end
  end

  logic [8:0] win_len;
  logic [8:0] win_len_counter;

  always_ff @(posedge clk) begin
    if (rst) begin
      band_type <= 0;
      win <= 0;
      win_len <= 0;
      win_len_counter <= 0;
    end else begin
      if (din_valid) begin
        if (window_switching_flag && (block_type == 2)) begin
          if (mixed_block_flag) begin
            //check if it is in a long band:
            if (is_pos_pipe[1] < 10'd36) begin
              band_type <= 0;
              if      (is_pos_pipe[1] < 10'd4)    sfb <= 0;
              else if (is_pos_pipe[1] < 10'd8)    sfb <= 1;
              else if (is_pos_pipe[1] < 10'd12)   sfb <= 2;
              else if (is_pos_pipe[1] < 10'd16)   sfb <= 3;
              else if (is_pos_pipe[1] < 10'd20)   sfb <= 4;
              else if (is_pos_pipe[1] < 10'd24)   sfb <= 5;
              else if (is_pos_pipe[1] < 10'd30)   sfb <= 6;
              else                                sfb <= 7;     //THIS case only goes up to 36 by definition
              win = 0;
            end else if (is_pos_pipe[1] < count1) begin
              //short bands for the mixed blocks!
              band_type <= 1;
              if      (is_pos_pipe[1] < 10'd48) begin
                sfb <= 3;
                win_len <= 9'd4;
              end
              else if (is_pos_pipe[1] < 10'd66) begin
                sfb <= 4;
                win_len <= 9'd6;
              end
              else if (is_pos_pipe[1] < 10'd90) begin
                sfb <= 5;
                win_len <= 9'd8;
              end
              else if (is_pos_pipe[1] < 10'd120) begin
                sfb <= 6;
                win_len <= 9'd10;
              end
              else if (is_pos_pipe[1] < 10'd156) begin
                sfb <= 7;
                win_len <= 9'd12;
              end
              else if (is_pos_pipe[1] < 10'd198) begin
                sfb <= 8;
                win_len <= 9'd14;
              end
              else if (is_pos_pipe[1] < 10'd252) begin
                sfb <= 9;
                win_len <= 9'd8;
              end
              else if (is_pos_pipe[1] < 10'd318) begin
                sfb <= 10;
                win_len <= 9'd22;
              end
              else if (is_pos_pipe[1] < 10'd408) begin
                sfb <= 11;
                win_len <= 9'd30;
              end
              else if (is_pos_pipe[1] < 10'd576) begin
                sfb <= 12;
                win_len <= 9'd56;
              end

              win <= (win_len_counter == win_len) ? win + 1 : win;
              win_len_counter <= (win_len_counter == win_len) ? 0 : win_len_counter + 1;
            end else begin
              band_type <= 2;
              win <= 0;
              win_len_counter <= 0;
            end
          end else begin
            //all short blocks:
            if (is_pos_pipe[1] < count1) begin
              band_type <= 1;
              if      (is_pos_pipe[1] < 10'd12) begin
                sfb <= 0;
                win_len <= 9'd4;
              end
              if      (is_pos_pipe[1] < 10'd24) begin
                sfb <= 1;
                win_len <= 9'd4;
              end
              if      (is_pos_pipe[1] < 10'd36) begin
                sfb <= 2;
                win_len <= 9'd4;
              end
              if      (is_pos_pipe[1] < 10'd48) begin
                sfb <= 3;
                win_len <= 9'd4;
              end
              else if (is_pos_pipe[1] < 10'd66) begin
                sfb <= 4;
                win_len <= 9'd6;
              end
              else if (is_pos_pipe[1] < 10'd90) begin
                sfb <= 5;
                win_len <= 9'd8;
              end
              else if (is_pos_pipe[1] < 10'd120) begin
                sfb <= 6;
                win_len <= 9'd10;
              end
              else if (is_pos_pipe[1] < 10'd156) begin
                sfb <= 7;
                win_len <= 9'd12;
              end
              else if (is_pos_pipe[1] < 10'd198) begin
                sfb <= 8;
                win_len <= 9'd14;
              end
              else if (is_pos_pipe[1] < 10'd252) begin
                sfb <= 9;
                win_len <= 9'd8;
              end
              else if (is_pos_pipe[1] < 10'd318) begin
                sfb <= 10;
                win_len <= 9'd22;
              end
              else if (is_pos_pipe[1] < 10'd408) begin
                sfb <= 7'd11;
                win_len <= 9'd30;
              end
              else if (is_pos_pipe[1] < 10'd576) begin
                sfb <= 12;
                win_len <= 9'd56;
              end

              win <= (win_len_counter == win_len) ? win + 1 : win;
              win_len_counter <= (win_len_counter == win_len) ? 0 : win_len_counter + 1;

            end else begin
              band_type <= 2;
              win <= 0;
              win_len_counter <= 0;
            end
          end
        end else begin
          if (is_pos_pipe[1] < count1) begin
            band_type <= 0;
            if      (is_pos_pipe[1] < 10'd4)    sfb = 0;
            else if (is_pos_pipe[1] < 10'd8)    sfb = 1;
            else if (is_pos_pipe[1] < 10'd12)   sfb = 2;
            else if (is_pos_pipe[1] < 10'd16)   sfb = 3;
            else if (is_pos_pipe[1] < 10'd20)   sfb = 4;
            else if (is_pos_pipe[1] < 10'd24)   sfb = 5;
            else if (is_pos_pipe[1] < 10'd30)   sfb = 6;
            else if (is_pos_pipe[1] < 10'd36)   sfb = 7;
            else if (is_pos_pipe[1] < 10'd44)   sfb = 8;
            else if (is_pos_pipe[1] < 10'd52)   sfb = 9;
            else if (is_pos_pipe[1] < 10'd62)   sfb = 10;
            else if (is_pos_pipe[1] < 10'd74)   sfb = 11;
            else if (is_pos_pipe[1] < 10'd90)   sfb = 12;
            else if (is_pos_pipe[1] < 10'd110)  sfb = 13;
            else if (is_pos_pipe[1] < 10'd134)  sfb = 14;
            else if (is_pos_pipe[1] < 10'd162)  sfb = 15;
            else if (is_pos_pipe[1] < 10'd196)  sfb = 16;
            else if (is_pos_pipe[1] < 10'd238)  sfb = 17;
            else if (is_pos_pipe[1] < 10'd288)  sfb = 18;
            else if (is_pos_pipe[1] < 10'd342)  sfb = 19;
            else if (is_pos_pipe[1] < 10'd418)  sfb = 20;
            else                                sfb = 21;
            win = 0;
          end else begin
            band_type <= 2;
            win <= 0;
          end
        end
      end
    end
  end

endmodule
