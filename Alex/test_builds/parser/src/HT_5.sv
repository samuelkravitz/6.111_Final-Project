`default_nettype none
`timescale 1ns / 1ps


module HT_5(
		input wire clk,
		input wire rst,

		input wire axiiv,
		input wire axiid,
		output logic err,
		output logic axiov,
		output logic [3:0] x_val,
		output logic [3:0] y_val
	);

  parameter MAX_BITS = 8;

	logic [7:0] buffer;
	logic [3:0] bit_counter;    //i don't think any word lengths are greater than 12.

	logic [9:0] word;

	assign {axiov, err, x_val, y_val} = word;

	always_ff @(posedge clk) begin
		if (rst) begin
			bit_counter <= 0;
			buffer <= 0;
		end else begin
			if (axiov || err) begin
				bit_counter <= axiiv ? 1 : 0;
				buffer <= axiiv ? {axiid, 7'b00} : 8'b0;
			end else if (bit_counter > MAX_BITS) begin
				bit_counter <= 0;
				buffer <= 0;        //clear everything if no word can be found.
			end else if (axiiv) begin
				bit_counter <= bit_counter + 1;
				case (bit_counter)
						4'd0 : buffer[7] <= axiid;
						4'd1 : buffer[6] <= axiid;
						4'd2 : buffer[5] <= axiid;
						4'd3 : buffer[4] <= axiid;
						4'd4 : buffer[3] <= axiid;
						4'd5 : buffer[2] <= axiid;
						4'd6 : buffer[1] <= axiid;
						4'd7 : buffer[0] <= axiid;
        endcase
			end
		end
	end

	always_comb begin
		case (bit_counter)
			4'd0 : word = 10'b00_0000_0000;
			4'd1 : begin
					case (buffer[7])
						1'b1 : word = 10'b10_0000_0000;
						default : word = 10'b00_0000_0000;
					endcase
				end
			4'd2 : word = 10'b00_0000_0000;
			4'd3 : begin
					case (buffer[7:5])
						3'b010 : word = 10'b10_0000_0001;
						3'b011 : word = 10'b10_0001_0000;
						3'b001 : word = 10'b10_0001_0001;
						default : word = 10'b00_0000_0000;
					endcase
				end
			4'd4 : word = 10'b00_0000_0000;
			4'd5 : word = 10'b00_0000_0000;
			4'd6 : begin
					case (buffer[7:2])
						6'b000110 : word = 10'b10_0000_0010;
						6'b000100 : word = 10'b10_0001_0010;
						6'b000111 : word = 10'b10_0010_0000;
						6'b000101 : word = 10'b10_0010_0001;
						6'b000001 : word = 10'b10_0011_0001;
						default : word = 10'b00_0000_0000;
					endcase
				end
			4'd7 : begin
					case (buffer[7:1])
						7'b0000101 : word = 10'b10_0000_0011;
						7'b0000100 : word = 10'b10_0001_0011;
						7'b0000111 : word = 10'b10_0010_0010;
						7'b0000110 : word = 10'b10_0011_0000;
						7'b0000001 : word = 10'b10_0011_0010;
						default : word = 10'b00_0000_0000;
					endcase
				end
			4'd8 : begin
					case (buffer[7:0])
						8'b00000001 : word = 10'b10_0010_0011;
						8'b00000000 : word = 10'b10_0011_0011;
						default : word = 10'b00_0000_0000;
					endcase
				end
			default : word = 10'b01_0000_0000;
		endcase
	end
endmodule


`default_nettype wire
