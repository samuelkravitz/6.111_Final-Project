`default_nettype none
`timescale 1ns / 1ps

module fifo_nonsim_real(
  input wire clk,
  input wire srst,
  input wire [7:0] din,
  input wire wr_en,
  input wire rd_en,
  output logic [0:0] dout,
  output logic [15:0] dcount_out,
  output logic d_valid_out
  );

  logic FULL;
  logic EMPTY;

  main_data_fifo FIFO (
    .clk(clk),
    .srst(srst),
    .din(din),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .dout(dout),
    .full(FULL),
    .empty(EMPTY)
    );

  logic [15:0] output_idx;

  always_ff @(posedge clk) begin
    if (srst) begin
      dcount_out <= 0;
    end else begin
      if (rd_en) begin
        if (dcount_out > 0) begin
          d_valid_out <= 1;
        end else begin
          d_valid_out <= 0;
        end
      end else begin
        d_valid_out <= 0;
      end

      case({rd_en, wr_en})
        2'b00 : begin
          dcount_out <= dcount_out;
        end
        2'b01 : begin
          dcount_out <= dcount_out + 4'd8;
        end
        2'b10 : begin
          dcount_out <= (dcount_out > 0) ? dcount_out - 1 : 0;
        end
        2'b11 : begin
          dcount_out <= (~EMPTY) ? dcount_out + 4'd7 : 4'd8;     //im worried about behavior where it reads in from empty buffer while writing in a byte
          //i don't think the FIFO will seamledssely transition that shit.
        end
      endcase
    end
  end

endmodule

`default_nettype wire
