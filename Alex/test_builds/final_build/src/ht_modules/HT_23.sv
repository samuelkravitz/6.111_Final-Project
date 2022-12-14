`default_nettype none
`timescale 1ns / 1ps


module HT_23(
		input wire clk,
		input wire rst,
		
		input wire axiiv,
		input wire axiid,
		output logic axiov,
		output logic signed [15:0] x_val,
		output logic signed [15:0] y_val
	);

  parameter MAX_BITS = 17;
	parameter LINBITS =13;

	logic [16:0] buffer;
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
						5'd0 : buffer[16] <= axiid;
						5'd1 : buffer[15] <= axiid;
						5'd2 : buffer[14] <= axiid;
						5'd3 : buffer[13] <= axiid;
						5'd4 : buffer[12] <= axiid;
						5'd5 : buffer[11] <= axiid;
						5'd6 : buffer[10] <= axiid;
						5'd7 : buffer[9] <= axiid;
						5'd8 : buffer[8] <= axiid;
						5'd9 : buffer[7] <= axiid;
						5'd10 : buffer[6] <= axiid;
						5'd11 : buffer[5] <= axiid;
						5'd12 : buffer[4] <= axiid;
						5'd13 : buffer[3] <= axiid;
						5'd14 : buffer[2] <= axiid;
						5'd15 : buffer[1] <= axiid;
						5'd16 : buffer[0] <= axiid;
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
			5'd1 : begin
					case (buffer[16])
						1'b1 : word = 9'b1_0000_0000;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd2 : word = 10'b00_0000_0000;
			5'd3 : begin
					case (buffer[16:14])
						3'b011 : word = 9'b1_0001_0000;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd4 : begin
					case (buffer[16:13])
						4'b0101 : word = 9'b1_0000_0001;
						4'b0100 : word = 9'b1_0001_0001;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd5 : word = 10'b00_0000_0000;
			5'd6 : begin
					case (buffer[16:11])
						6'b001110 : word = 9'b1_0000_0010;
						6'b001100 : word = 9'b1_0001_0010;
						6'b001111 : word = 9'b1_0010_0000;
						6'b001101 : word = 9'b1_0010_0001;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd7 : begin
					case (buffer[16:10])
						7'b0010100 : word = 9'b1_0001_0011;
						7'b0010111 : word = 9'b1_0010_0010;
						7'b0010101 : word = 9'b1_0011_0001;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd8 : begin
					case (buffer[16:9])
						8'b00101100 : word = 9'b1_0000_0011;
						8'b00100011 : word = 9'b1_0001_0100;
						8'b00001001 : word = 9'b1_0001_1111;
						8'b00100110 : word = 9'b1_0010_0011;
						8'b00101101 : word = 9'b1_0011_0000;
						8'b00100111 : word = 9'b1_0011_0010;
						8'b00100100 : word = 9'b1_0100_0001;
						8'b00011110 : word = 9'b1_0101_0001;
						8'b00001010 : word = 9'b1_1111_0001;
						8'b00000111 : word = 9'b1_1111_0010;
						8'b00000011 : word = 9'b1_1111_1111;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd9 : begin
					case (buffer[16:8])
						9'b001001010 : word = 9'b1_0000_0100;
						9'b000111111 : word = 9'b1_0000_0101;
						9'b000010001 : word = 9'b1_0000_1111;
						9'b000111110 : word = 9'b1_0001_0101;
						9'b000110101 : word = 9'b1_0001_0110;
						9'b000101111 : word = 9'b1_0001_0111;
						9'b001000011 : word = 9'b1_0010_0100;
						9'b000111010 : word = 9'b1_0010_0101;
						9'b000010000 : word = 9'b1_0010_1111;
						9'b001000101 : word = 9'b1_0011_0011;
						9'b001000000 : word = 9'b1_0011_0100;
						9'b001001011 : word = 9'b1_0100_0000;
						9'b001000100 : word = 9'b1_0100_0010;
						9'b001000001 : word = 9'b1_0100_0011;
						9'b000001001 : word = 9'b1_0100_1111;
						9'b001000010 : word = 9'b1_0101_0000;
						9'b000111011 : word = 9'b1_0101_0010;
						9'b000111000 : word = 9'b1_0101_0011;
						9'b000110110 : word = 9'b1_0110_0001;
						9'b000110100 : word = 9'b1_0110_0010;
						9'b000110000 : word = 9'b1_0111_0001;
						9'b000001100 : word = 9'b1_1111_0000;
						9'b000001011 : word = 9'b1_1111_0011;
						9'b000001010 : word = 9'b1_1111_0100;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd10 : begin
					case (buffer[16:7])
						10'b0001101110 : word = 9'b1_0000_0110;
						10'b0001011101 : word = 9'b1_0000_0111;
						10'b0001010011 : word = 9'b1_0001_1000;
						10'b0001001011 : word = 9'b1_0001_1001;
						10'b0001000100 : word = 9'b1_0001_1010;
						10'b0001100111 : word = 9'b1_0010_0110;
						10'b0001011010 : word = 9'b1_0010_0111;
						10'b0001001000 : word = 9'b1_0010_1001;
						10'b0001110010 : word = 9'b1_0011_0101;
						10'b0001100011 : word = 9'b1_0011_0110;
						10'b0001010111 : word = 9'b1_0011_0111;
						10'b0000011010 : word = 9'b1_0011_1111;
						10'b0001110011 : word = 9'b1_0100_0100;
						10'b0001100101 : word = 9'b1_0100_0101;
						10'b0001100110 : word = 9'b1_0101_0100;
						10'b0000010000 : word = 9'b1_0101_1111;
						10'b0001101111 : word = 9'b1_0110_0000;
						10'b0001100100 : word = 9'b1_0110_0011;
						10'b0000001010 : word = 9'b1_0110_1111;
						10'b0001100010 : word = 9'b1_0111_0000;
						10'b0001011011 : word = 9'b1_0111_0010;
						10'b0001011000 : word = 9'b1_0111_0011;
						10'b0000001000 : word = 9'b1_0111_1111;
						10'b0001010101 : word = 9'b1_1000_0000;
						10'b0001010100 : word = 9'b1_1000_0001;
						10'b0001010001 : word = 9'b1_1000_0010;
						10'b0000000111 : word = 9'b1_1000_1111;
						10'b0001001100 : word = 9'b1_1001_0001;
						10'b0001001001 : word = 9'b1_1001_0010;
						10'b0001000011 : word = 9'b1_1010_0010;
						10'b0000000100 : word = 9'b1_1010_1111;
						10'b0000010001 : word = 9'b1_1111_0101;
						10'b0000001011 : word = 9'b1_1111_0110;
						10'b0000001001 : word = 9'b1_1111_0111;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd11 : begin
					case (buffer[16:6])
						11'b00010101100 : word = 9'b1_0000_1000;
						11'b00010010101 : word = 9'b1_0000_1001;
						11'b00010001010 : word = 9'b1_0000_1010;
						11'b00001110111 : word = 9'b1_0001_1011;
						11'b00001101011 : word = 9'b1_0001_1101;
						11'b00010100001 : word = 9'b1_0010_1000;
						11'b00001111111 : word = 9'b1_0010_1010;
						11'b00001110101 : word = 9'b1_0010_1011;
						11'b00001101110 : word = 9'b1_0010_1100;
						11'b00010011110 : word = 9'b1_0011_1000;
						11'b00010001100 : word = 9'b1_0011_1001;
						11'b00010110011 : word = 9'b1_0100_0110;
						11'b00010100100 : word = 9'b1_0100_0111;
						11'b00010011011 : word = 9'b1_0100_1000;
						11'b00010111001 : word = 9'b1_0101_0101;
						11'b00010101101 : word = 9'b1_0101_0110;
						11'b00010001110 : word = 9'b1_0101_1000;
						11'b00010111000 : word = 9'b1_0110_0100;
						11'b00010110010 : word = 9'b1_0110_0101;
						11'b00010100000 : word = 9'b1_0110_0110;
						11'b00010000101 : word = 9'b1_0110_0111;
						11'b00010100101 : word = 9'b1_0111_0100;
						11'b00010011101 : word = 9'b1_0111_0101;
						11'b00010010100 : word = 9'b1_0111_0110;
						11'b00010011111 : word = 9'b1_1000_0011;
						11'b00010011100 : word = 9'b1_1000_0100;
						11'b00010001111 : word = 9'b1_1000_0101;
						11'b00010011010 : word = 9'b1_1001_0000;
						11'b00010001101 : word = 9'b1_1001_0011;
						11'b00010000011 : word = 9'b1_1001_0100;
						11'b00000001011 : word = 9'b1_1001_1111;
						11'b00010001011 : word = 9'b1_1010_0000;
						11'b00010000001 : word = 9'b1_1010_0001;
						11'b00001111101 : word = 9'b1_1010_0011;
						11'b00001111000 : word = 9'b1_1011_0001;
						11'b00001110110 : word = 9'b1_1011_0010;
						11'b00001110011 : word = 9'b1_1011_0011;
						11'b00000000110 : word = 9'b1_1011_1111;
						11'b00000000100 : word = 9'b1_1100_1111;
						11'b00000000010 : word = 9'b1_1101_1111;
						11'b00001100110 : word = 9'b1_1110_0010;
						11'b00000000000 : word = 9'b1_1110_1111;
						11'b00000001101 : word = 9'b1_1111_1000;
						11'b00000001100 : word = 9'b1_1111_1001;
						11'b00000001010 : word = 9'b1_1111_1010;
						11'b00000000111 : word = 9'b1_1111_1011;
						11'b00000000101 : word = 9'b1_1111_1100;
						11'b00000000011 : word = 9'b1_1111_1101;
						11'b00000000001 : word = 9'b1_1111_1110;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd12 : begin
					case (buffer[16:5])
						12'b000011110010 : word = 9'b1_0000_1011;
						12'b000011100001 : word = 9'b1_0000_1100;
						12'b000011000011 : word = 9'b1_0000_1101;
						12'b000011001001 : word = 9'b1_0001_1100;
						12'b000011001111 : word = 9'b1_0001_1110;
						12'b000011010001 : word = 9'b1_0010_1101;
						12'b000011001110 : word = 9'b1_0010_1110;
						12'b000011111100 : word = 9'b1_0011_1010;
						12'b000011010100 : word = 9'b1_0011_1011;
						12'b000011000111 : word = 9'b1_0011_1100;
						12'b000100001000 : word = 9'b1_0100_1001;
						12'b000011110110 : word = 9'b1_0100_1010;
						12'b000011100010 : word = 9'b1_0100_1011;
						12'b000100001001 : word = 9'b1_0101_0111;
						12'b000011111101 : word = 9'b1_0101_1001;
						12'b000011101000 : word = 9'b1_0101_1010;
						12'b000100000001 : word = 9'b1_0110_1000;
						12'b000011110100 : word = 9'b1_0110_1001;
						12'b000011100100 : word = 9'b1_0110_1010;
						12'b000011011001 : word = 9'b1_0110_1011;
						12'b000100000101 : word = 9'b1_0111_0111;
						12'b000011111000 : word = 9'b1_0111_1000;
						12'b000100000100 : word = 9'b1_1000_0110;
						12'b000011111001 : word = 9'b1_1000_0111;
						12'b000100000000 : word = 9'b1_1001_0101;
						12'b000011110101 : word = 9'b1_1001_0110;
						12'b000011110111 : word = 9'b1_1010_0100;
						12'b000011101001 : word = 9'b1_1010_0101;
						12'b000011100101 : word = 9'b1_1010_0110;
						12'b000011011011 : word = 9'b1_1010_0111;
						12'b000011110011 : word = 9'b1_1011_0000;
						12'b000011100011 : word = 9'b1_1011_0100;
						12'b000011011111 : word = 9'b1_1011_0101;
						12'b000011001010 : word = 9'b1_1100_0000;
						12'b000011100000 : word = 9'b1_1100_0001;
						12'b000011011110 : word = 9'b1_1100_0010;
						12'b000011011010 : word = 9'b1_1100_0011;
						12'b000011011000 : word = 9'b1_1100_0100;
						12'b000011010011 : word = 9'b1_1101_0001;
						12'b000011010010 : word = 9'b1_1101_0010;
						12'b000011010000 : word = 9'b1_1101_0011;
						12'b000010111011 : word = 9'b1_1110_0011;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd13 : begin
					case (buffer[16:4])
						13'b0000101111000 : word = 9'b1_0000_1110;
						13'b0000110000011 : word = 9'b1_0011_1101;
						13'b0000101101101 : word = 9'b1_0011_1110;
						13'b0000110001011 : word = 9'b1_0100_1100;
						13'b0000101111110 : word = 9'b1_0100_1101;
						13'b0000101101010 : word = 9'b1_0100_1110;
						13'b0000110010000 : word = 9'b1_0101_1011;
						13'b0000110000100 : word = 9'b1_0101_1100;
						13'b0000101111010 : word = 9'b1_0101_1101;
						13'b0000110000001 : word = 9'b1_0110_1100;
						13'b0000101101110 : word = 9'b1_0110_1101;
						13'b0000110010111 : word = 9'b1_0111_1001;
						13'b0000110001101 : word = 9'b1_0111_1010;
						13'b0000101110100 : word = 9'b1_0111_1011;
						13'b0000101111100 : word = 9'b1_0111_1100;
						13'b0000110101011 : word = 9'b1_1000_1000;
						13'b0000110010001 : word = 9'b1_1000_1001;
						13'b0000110001000 : word = 9'b1_1000_1010;
						13'b0000101111111 : word = 9'b1_1000_1011;
						13'b0000110101010 : word = 9'b1_1001_0111;
						13'b0000110010110 : word = 9'b1_1001_1000;
						13'b0000110001010 : word = 9'b1_1001_1001;
						13'b0000110000000 : word = 9'b1_1001_1010;
						13'b0000101100111 : word = 9'b1_1001_1100;
						13'b0000101100000 : word = 9'b1_1001_1110;
						13'b0000110001001 : word = 9'b1_1010_1000;
						13'b0000110001100 : word = 9'b1_1011_0110;
						13'b0000011011111 : word = 9'b1_1011_1101;
						13'b0000110000101 : word = 9'b1_1100_0101;
						13'b0000110000010 : word = 9'b1_1100_0110;
						13'b0000101111101 : word = 9'b1_1100_0111;
						13'b0000101101100 : word = 9'b1_1100_1000;
						13'b0000101110010 : word = 9'b1_1101_0100;
						13'b0000101111011 : word = 9'b1_1101_0101;
						13'b0000101111001 : word = 9'b1_1110_0000;
						13'b0000101110001 : word = 9'b1_1110_0001;
						13'b0000101100110 : word = 9'b1_1110_0110;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd14 : begin
					case (buffer[16:3])
						14'b00000110111101 : word = 9'b1_0101_1110;
						14'b00001011001011 : word = 9'b1_0110_1110;
						14'b00001011010111 : word = 9'b1_1000_1100;
						14'b00001011001001 : word = 9'b1_1000_1101;
						14'b00001011000100 : word = 9'b1_1000_1110;
						14'b00001011011111 : word = 9'b1_1001_1011;
						14'b00001011000110 : word = 9'b1_1001_1101;
						14'b00001011100111 : word = 9'b1_1010_1001;
						14'b00001011100001 : word = 9'b1_1010_1010;
						14'b00001011010000 : word = 9'b1_1010_1011;
						14'b00000110110111 : word = 9'b1_1010_1110;
						14'b00001011101010 : word = 9'b1_1011_0111;
						14'b00001011100110 : word = 9'b1_1011_1000;
						14'b00001011100000 : word = 9'b1_1011_1001;
						14'b00001011010001 : word = 9'b1_1011_1010;
						14'b00001011001000 : word = 9'b1_1011_1011;
						14'b00001011000010 : word = 9'b1_1011_1100;
						14'b00000110110100 : word = 9'b1_1011_1110;
						14'b00000110111011 : word = 9'b1_1100_1010;
						14'b00001011000011 : word = 9'b1_1100_1011;
						14'b00000110111000 : word = 9'b1_1100_1100;
						14'b00000110110101 : word = 9'b1_1100_1101;
						14'b00001011101011 : word = 9'b1_1101_0000;
						14'b00001011011110 : word = 9'b1_1101_0110;
						14'b00001011010011 : word = 9'b1_1101_0111;
						14'b00001011001010 : word = 9'b1_1101_1000;
						14'b00001011010110 : word = 9'b1_1110_0100;
						14'b00001011010010 : word = 9'b1_1110_0101;
						14'b00001011000111 : word = 9'b1_1110_0111;
						14'b00001011000101 : word = 9'b1_1110_1000;
						14'b00000110110010 : word = 9'b1_1110_1110;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd15 : begin
					case (buffer[16:2])
						15'b000001101111001 : word = 9'b1_0111_1101;
						15'b000001101110100 : word = 9'b1_0111_1110;
						15'b000001101110101 : word = 9'b1_1010_1100;
						15'b000001101110010 : word = 9'b1_1010_1101;
						15'b000001101111000 : word = 9'b1_1100_1001;
						15'b000001101110011 : word = 9'b1_1101_1010;
						15'b000001101101101 : word = 9'b1_1101_1011;
						15'b000001101101100 : word = 9'b1_1101_1100;
						15'b000001101100001 : word = 9'b1_1101_1110;
						15'b000001101100010 : word = 9'b1_1110_1001;
						15'b000001101100111 : word = 9'b1_1110_1011;
						15'b000001101100110 : word = 9'b1_1110_1101;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd16 : begin
					case (buffer[16:1])
						16'b0000011011000000 : word = 9'b1_1100_1110;
						16'b0000011011000111 : word = 9'b1_1101_1001;
						16'b0000011011000110 : word = 9'b1_1110_1010;
						default : word = 9'b0_0000_0000;
					endcase
				end
			5'd17 : begin
					case (buffer[16:0])
						17'b00000110110000011 : word = 9'b1_1101_1101;
						17'b00000110110000010 : word = 9'b1_1110_1100;
						default : word = 9'b0_0000_0000;
					endcase
				end
			default : word = 9'b0_0000_0000;
		endcase
	end
endmodule


`default_nettype wire
