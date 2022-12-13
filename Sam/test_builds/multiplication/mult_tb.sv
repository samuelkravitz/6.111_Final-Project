`default_nettype none
`timescale 1ns / 1ps

module mult_tb;

logic clk;

logic signed [15:0] A, B, D;
logic signed [31:0] C;

always begin
  #10;
  clk = !clk;     //clock cycles now happend every 20!
end


initial begin
  $dumpfile("mult_tb.vcd");
  $dumpvars(0, mult_tb);
  $display("Starting Sim");

  A = 16'b0011_1100_1100_1100;
  B = 16'b0011_1100_1100_1100;
  D = 16'b0011_0010_0111_1001;

  C = A * B;
  #20;


  $display("Finishing Sim");
  $finish;

end
endmodule

`default_nettype wire
