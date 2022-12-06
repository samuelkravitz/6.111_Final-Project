`default_nettype none
`timescale 1ns / 1ps


module HT_11(
		input wire clk,
		input wire rst,
		
		input wire axiiv,
		input wire axiid,
		output logic axiov,
		output logic signed [15:0] x_val,
		output logic signed [15:0] y_val
	);

  parameter MAX_BITS = 11;
	parameter LINBITS =0;

	logic [10:0] buffer;
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
						5'd0 : buffer[10] <= axiid;
						5'd1 : buffer[9] <= axiid;
						5'd2 : buffer[8] <= axiid;
						5'd3 : buffer[7] <= axiid;
						5'd4 : buffer[6] <= axiid;
						5'd5 : buffer[5] <= axiid;
						5'd6 : buffer[4] <= axiid;
						5'd7 : buffer[3] <= axiid;
						5'd8 : buffer[2] <= axiid;
						5'd9 : buffer[1] <= axiid;
						5'd10 : buffer[0] <= axiid;
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
					case (buffer[10:9])
						2'b11 : word = 9'b1_0000_0000;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd3 : begin
					case (buffer[10:8])
						3'b100 : word = 9'b1_0000_0001;
						3'b101 : word = 9'b1_0001_0000;
						3'b011 : word = 9'b1_0001_0001;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd4 : begin
					case (buffer[10:7])
						4'b0100 : word = 9'b1_0001_0010;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd5 : begin
					case (buffer[10:6])
						5'b01010 : word = 9'b1_0000_0010;
						5'b01011 : word = 9'b1_0010_0000;
						5'b00111 : word = 9'b1_0010_0001;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd6 : begin
					case (buffer[10:5])
						6'b001010 : word = 9'b1_0001_0011;
						6'b001101 : word = 9'b1_0010_0010;
						6'b001011 : word = 9'b1_0011_0001;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd7 : begin
					case (buffer[10:4])
						7'b0011000 : word = 9'b1_0000_0011;
						7'b0001011 : word = 9'b1_0001_0110;
						7'b0010010 : word = 9'b1_0010_0011;
						7'b0011001 : word = 9'b1_0011_0000;
						7'b0010011 : word = 9'b1_0011_0010;
						7'b0001100 : word = 9'b1_0110_0001;
						7'b0001001 : word = 9'b1_0110_0010;
						7'b0000100 : word = 9'b1_0111_0001;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd8 : begin
					case (buffer[10:3])
						8'b00100010 : word = 9'b1_0000_0100;
						8'b00010101 : word = 9'b1_0000_0110;
						8'b00100000 : word = 9'b1_0001_0100;
						8'b00010001 : word = 9'b1_0001_0101;
						8'b00001010 : word = 9'b1_0001_0111;
						8'b00011110 : word = 9'b1_0010_0100;
						8'b00010100 : word = 9'b1_0010_0110;
						8'b00000101 : word = 9'b1_0010_0111;
						8'b00011011 : word = 9'b1_0011_0100;
						8'b00001100 : word = 9'b1_0011_0110;
						8'b00100011 : word = 9'b1_0100_0000;
						8'b00100001 : word = 9'b1_0100_0001;
						8'b00011111 : word = 9'b1_0100_0010;
						8'b00011100 : word = 9'b1_0101_0000;
						8'b00011010 : word = 9'b1_0101_0001;
						8'b00001110 : word = 9'b1_0110_0000;
						8'b00001101 : word = 9'b1_0110_0011;
						8'b00001011 : word = 9'b1_0111_0000;
						8'b00000110 : word = 9'b1_0111_0010;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd9 : begin
					case (buffer[10:2])
						9'b000100001 : word = 9'b1_0000_0101;
						9'b000001111 : word = 9'b1_0000_0111;
						9'b000011111 : word = 9'b1_0010_0101;
						9'b000111011 : word = 9'b1_0011_0011;
						9'b000000101 : word = 9'b1_0011_0111;
						9'b000111010 : word = 9'b1_0100_0011;
						9'b000011110 : word = 9'b1_0100_0100;
						9'b000000111 : word = 9'b1_0100_0110;
						9'b000100000 : word = 9'b1_0101_0010;
						9'b000001110 : word = 9'b1_0110_0100;
						9'b000000110 : word = 9'b1_0111_0011;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd10 : begin
					case (buffer[10:1])
						10'b0000010010 : word = 9'b1_0011_0101;
						10'b0000010000 : word = 9'b1_0100_0101;
						10'b0000000101 : word = 9'b1_0100_0111;
						10'b0000010011 : word = 9'b1_0101_0011;
						10'b0000010001 : word = 9'b1_0101_0100;
						10'b0000001000 : word = 9'b1_0101_0110;
						10'b0000001001 : word = 9'b1_0110_0101;
						10'b0000000100 : word = 9'b1_0110_0110;
						10'b0000000001 : word = 9'b1_0110_0111;
						10'b0000000110 : word = 9'b1_0111_0100;
						10'b0000000011 : word = 9'b1_0111_0101;
						10'b0000000010 : word = 9'b1_0111_0110;
						10'b0000000000 : word = 9'b1_0111_0111;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd11 : begin
					case (buffer[10:0])
						11'b00000001111 : word = 9'b1_0101_0101;
						11'b00000001110 : word = 9'b1_0101_0111;
						default : word = 9'b0_0000_0000;
					endcase
				end
			default : word = 9'b0_0000_0000;
		endcase
	end
endmodule


`default_nettype wire
