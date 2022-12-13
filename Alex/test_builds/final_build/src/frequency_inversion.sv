`default_nettype none
`timescale 1ns / 1ps


`define INV_SUBBANDS 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31
`define INV_IDX 1, 3, 5, 7, 9, 11, 13, 15, 17


module frequency_inversion(
    input wire clk,
    input wire rst,

    input wire new_frame_start,

    input wire [31:0] x_in,
    input wire x_valid_in,

    output logic [31:0] x_out,
    output logic x_valid_out
  );

  logic [9:0] sample_counter;
  logic [4:0] sb;
  logic [4:0] idx;

  logic [63:0] q4_60_intermediate;

  always_ff @(posedge clk) begin
    if (rst || new_frame_start) begin
      sample_counter <= 0;
      sb <= 0;
      idx <= 0;
    end else begin
      x_valid_out <= x_valid_in;
      if (x_valid_in) begin
        sample_counter <= (sample_counter == 10'd575) ? 0 : sample_counter + 1;
        idx <= (idx == 5'd17) ? 0 : idx + 1;
        if (idx == 5'd17) begin
          sb <= (sb == 5'd31) ? 0 : sb + 1;
        end
      end

      case(sb)
        `INV_SUBBANDS : begin
          case(idx)
            `INV_IDX :  x_out <= q4_60_intermediate >>> 30;
            default :   x_out <= x_in;
          endcase
        end
        default : x_out <= x_in;
      endcase

    end
  end

  assign q4_60_intermediate = $signed(x_in) * (-32'sb01000000000000000000000000000000);


endmodule


`default_nettype wire
