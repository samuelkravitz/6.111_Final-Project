`default_nettype none
`timescale 1ns / 1ps

/*
this is a template huffman coding module.
implements the bigvalues x,y full stack decoding
finds the signbits and the linbits
*/

module HT_01_ORIG(
		input wire clk,
		input wire rst,

		input wire axiiv,
		input wire axiid,
		output logic axiov,
		output logic signed [15:0] x_val,        //15 to incorporate a signed 14 bit number at most.
		output logic signed [15:0] y_val
	);

  parameter MAX_BITS = 3;
  parameter LINBITS = 0;

	logic [2:0] buffer;
	logic [3:0] bit_counter;    //stuff
  logic [3:0] x_linbit_counter;
  logic [3:0] y_linbit_counter;
  logic x_signbit_counter, y_signbit_counter;

	logic [9:0] word;
  logic found;

  logic [3:0] x_abs, y_abs;
  logic x_sign, y_sign;
  logic [LINBITS - 1:0] x_linval, y_linval;

	assign {found, x_abs, y_abs} = word;

  always_comb begin
    x_val = (~x_sign) ? x_abs + x_linval : -16'd1 * (x_abs + x_linval);
    y_val = (~y_sign) ? y_abs + y_linval : -16'd1 * (y_abs + y_linval);

    axiov = ( found )
         && ( (x_val < 4'd15) || (x_linbit_counter == LINBITS) )
         && ( (x_val == 0) || (x_signbit_counter) )
         && ( (y_val < 4'd15) || (y_linbit_counter == LINBITS) )
         && ( (y_val == 0) || (y_signbit_counter));
  end

	always_ff @(posedge clk) begin
		if (rst) begin
			bit_counter <= 0;
			buffer <= 0;

      x_sign <= 0;
      y_sign <= 0;

      x_linval <= 0;
      y_linval <= 0;

      x_linbit_counter <= 0;
      y_linbit_counter <= 0;

      x_signbit_counter <= 0;
      y_signbit_counter <= 0;
		end else begin
			if (axiov) begin
				bit_counter <= axiiv ? 1 : 0;
				buffer <= axiiv ? {axiid, 2'b00} : 3'b0;

        x_sign <= 0;
        y_sign <= 0;
        x_linval <= 0;
        y_linval <= 0;
        x_linbit_counter <= 0;
        y_linbit_counter <= 0;
        x_signbit_counter <= 0;
        y_signbit_counter <= 0;
      end else if (axiiv) begin
        if (~found) begin
  				bit_counter <= bit_counter + 1;
  				case (bit_counter)
  						4'd0 : buffer[2] <= axiid;
  						4'd1 : buffer[1] <= axiid;
  						4'd2 : buffer[0] <= axiid;
          endcase
        end else if ((x_abs == 4'd15) && (x_linbit_counter < LINBITS)) begin
          x_linval <= {x_linval[LINBITS - 2:0], axiid};
          x_linbit_counter <= x_linbit_counter + 1;
        end else if ((x_abs > 0) && ~x_signbit_counter) begin
          x_sign <= axiid;
          x_signbit_counter <= x_signbit_counter + 1;
        end else if ((y_abs == 4'd15) && (y_linbit_counter < LINBITS)) begin
          y_linval <= {y_linval[LINBITS - 2:0], axiid};
          y_linbit_counter <= y_linbit_counter + 1;
        end else if ((y_abs > 0) && ~y_signbit_counter) begin
          y_sign <= axiid;
          y_signbit_counter <= y_signbit_counter + 1;
        end
			end
		end
	end

	always_comb begin
		case (bit_counter)
			4'd0 : word = 9'b0_0000_0000;
			4'd1 : begin
					case (buffer[2])
						1'b1 : word = 9'b1_0000_0000;
						default : word = 9'b0_0000_0000;
					endcase
				end
			4'd2 : begin
					case (buffer[2:1])
						2'b01 : word = 9'b1_0001_0000;
						default : word = 9'b0_0000_0000;
					endcase
				end
			4'd3 : begin
					case (buffer[2:0])
						3'b001 : word = 9'b1_0000_0001;
						3'b000 : word = 9'b1_0001_0001;
						default : word = 9'b0_0000_0000;
					endcase
				end
			default : word = 9'b0_0000_0000;
		endcase
	end
endmodule


`default_nettype wire
