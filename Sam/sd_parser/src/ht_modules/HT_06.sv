`default_nettype none
`timescale 1ns / 1ps


module HT_06(
		input wire clk,
		input wire rst,
		
		input wire axiiv,
		input wire axiid,
		output logic axiov,
		output logic signed [15:0] x_val,
		output logic signed [15:0] y_val
	);

  parameter MAX_BITS = 7;
	parameter LINBITS =0;

	logic [6:0] buffer;
	logic [4:0] bit_counter;
	logic [3:0] x_linbit_counter, y_linbit_counter;
	logic x_signbit_counter, y_signbit_counter;

	logic [8:0] word;
	logic found;
	logic [3:0] x_abs, y_abs;
	logic x_sign, y_sign;
	logic [LINBITS - 1:0] x_linval, y_linval;

	assign {found, x_abs, y_abs} = word;

	logic [MAX_BITS-2:0] buffer_clearer_with_input;
	assign buffer_clearer_with_input = 0;


	always_comb begin
		x_val = (~x_sign) ? x_abs + x_linval : -8'sd1 * (x_abs + x_linval);
		y_val = (~y_sign) ? y_abs + y_linval : -8'sd1 * (y_abs + y_linval);

		axiov = ( found )
				&& ( (x_abs < 4'd15) || (x_linbit_counter == LINBITS) )
				&& ( (x_abs == 0) || (x_signbit_counter) )
				&& ( (y_abs < 4'd15) || (y_linbit_counter == LINBITS) )
				&& ( (y_abs == 0) || (y_signbit_counter));
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
				buffer <= axiiv ? {axiid, buffer_clearer_with_input} : 0;
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
						5'd0 : buffer[6] <= axiid;
						5'd1 : buffer[5] <= axiid;
						5'd2 : buffer[4] <= axiid;
						5'd3 : buffer[3] <= axiid;
						5'd4 : buffer[2] <= axiid;
						5'd5 : buffer[1] <= axiid;
						5'd6 : buffer[0] <= axiid;
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
			5'd0 : word = 9'b0_0000_0000;
			5'd1 : word = 10'b00_0000_0000;
			5'd2 : begin
					case (buffer[6:5])
						2'b10 : word = 9'b1_0001_0001;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd3 : begin
					case (buffer[6:4])
						3'b111 : word = 9'b1_0000_0000;
						3'b011 : word = 9'b1_0000_0001;
						3'b110 : word = 9'b1_0001_0000;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd4 : begin
					case (buffer[6:3])
						4'b0011 : word = 9'b1_0001_0010;
						4'b0101 : word = 9'b1_0010_0000;
						4'b0100 : word = 9'b1_0010_0001;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd5 : begin
					case (buffer[6:2])
						5'b00101 : word = 9'b1_0000_0010;
						5'b00010 : word = 9'b1_0001_0011;
						5'b00100 : word = 9'b1_0010_0010;
						5'b00011 : word = 9'b1_0011_0001;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd6 : begin
					case (buffer[6:1])
						6'b000001 : word = 9'b1_0010_0011;
						6'b000011 : word = 9'b1_0011_0000;
						6'b000010 : word = 9'b1_0011_0010;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd7 : begin
					case (buffer[6:0])
						7'b0000001 : word = 9'b1_0000_0011;
						7'b0000000 : word = 9'b1_0011_0011;
						default : word = 9'b0_0000_0000;
					endcase
				end
			default : word = 9'b0_0000_0000;
		endcase
	end
endmodule


`default_nettype wire
