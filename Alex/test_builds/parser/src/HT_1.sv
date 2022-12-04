`default_nettype none
`timescale 1ns / 1ps

/*
implementation of huffman table 1 (as a lookup table)
*/

module HT_1(
    input wire clk,
    input wire rst,
    input wire axiiv,
    input wire axiid,         //fed in 1 bit at a time

    output logic err,
    output logic axiov,
    output logic [3:0] x_val,
    output logic [3:0] y_val
  );

  parameter MAX_BITS = 3;

  logic [2:0] buffer;
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
        buffer <= axiiv ? {axiid, 2'b00} : 3'b0;
      end else if (bit_counter > MAX_BITS) begin
        bit_counter <= 0;
        buffer <= 0;        //clear everything if no word can be found.
      end else if (axiiv) begin
        bit_counter <= bit_counter + 1;
        case (bit_counter)
          4'd0 : buffer[2] <= axiid;
          4'd1 : buffer[1] <= axiid;
          4'd2 : buffer[0] <= axiid;
        endcase
      end
    end
  end

  always_comb begin
    case (bit_counter)
      4'd0 : word = 10'b00_0000_0000;
      4'd1 : begin
            case (buffer[2])
              1'b1 : word = 10'b10_0000_0000;
              default : word = 10'b00_0000_0000;
            endcase
          end
      4'd2 : begin
            case (buffer[2:1])
              2'b01 : word = 10'b10_0001_0000;
              default : word = 10'b00_0000_0000;
            endcase
          end
      4'd3 : begin
            case (buffer[2:0])
              3'b001 : word = 10'b10_0000_0001;
              3'b000 : word = 10'b10_0001_0001;
              default : word = 10'b01_0000_0000;  //this raises the ERR line high (because it is the maximum amount)
            endcase
          end
      default : word = 10'b01_0000_0000;
    endcase
  end

endmodule

`default_nettype wire
