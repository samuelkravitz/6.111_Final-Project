`default_nettype none
`timescale 1ns / 1ps

module fifo_sim_real(
  input wire clk,
  input wire srst,
  input wire [7:0] din,
  input wire wr_en,
  input wire rd_en,
  output logic [0:0] dout,
  output logic [15:0] dcount_out,
  output logic d_valid_out
  );


  logic full, empty;
  logic [15:0] output_idx;
  // logic [65535:0] memory;

  // always_ff @(posedge clk) begin
  //   if (srst) begin
  //     memory <= 0;
  //     output_idx <= 0;
  //     dcount_out <= 0;
  //   end else begin
  //     if (wr_en) memory <= {memory[65525:0], din};
  //     if (rd_en) begin
  //       if (dcount_out > 0) begin
  //         dout <= (memory << (65535 - output_idx + 1)) >> 65535;
  //         d_valid_out <= 1;
  //       end else begin
  //         dout <= 0;
  //         d_valid_out <= 0;
  //       end
  //     end else begin
  //       d_valid_out <= 0;
  //       dout <= 0;
  //     end

   main_data_fifo fifo(.clk(clk), .srst(srst), .din(din), .wr_en(wr_en), .rd_en(rd_en), .dout(dout), .full(full), .empty(empty));

  always_ff @(posedge clk) begin
    case({rd_en, wr_en})
      2'b00 : begin
        output_idx <= output_idx;
        dcount_out <= dcount_out;
        d_valid_out <= 0;
      end
      2'b01 : begin
        output_idx <= output_idx + 4'd8;
        dcount_out <= (~full) ? dcount_out + 4'd8 : dcount_out;
        d_valid_out <= (~full) ? 1 : 0;
      end
      2'b10 : begin
        output_idx <= (output_idx > 0) ? output_idx - 1 : 0;
        dcount_out <= (~empty) ? dcount_out - 1 : dcount_out;
        d_valid_out <= 0;
      end
      2'b11 : begin
        // output_idx <= output_idx + 4'd7;
        dcount_out <= (~empty && ~full) ? dcount_out + 7 : dcount_out; 
        d_valid_out <= 1;
      end
    endcase
    end
  

endmodule

`default_nettype wire
