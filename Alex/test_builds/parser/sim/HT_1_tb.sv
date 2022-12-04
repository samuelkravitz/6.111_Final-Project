`default_nettype none
`timescale 1ns / 1ps

module HT_1_tb;

logic clk;
logic rst;
logic axiiv;
logic axiid;

logic err;
logic axiov;
logic [3:0] x_val;
logic [3:0] y_val;

HT_5 UUT (clk, rst, axiiv, axiid, err, axiov, x_val, y_val);

logic [18:0] code;

always begin
  #10;
  clk = !clk;     //clock cycles now happend every 20!
end

initial begin
  $dumpfile("sim/HT_1_sim.vcd");
  $dumpvars(0, HT_1_tb);
  $display("Starting Sim");

  code = 19'b001_000110_0000101_010;

  clk = 0;
  rst = 0;

  axiiv = 0;
  axiid = 0;    //make the inputs 0 too!
  #20;
  rst = 1;
  #20;
  rst = 0;

  //TRANSMIT DESTINATION

  for (int i = 0; i < 19; i += 1) begin
    axiiv = 1;
    axiid = code[18-i];
    #20;
    axiiv = 0;
  end
  #200;


  $display("Finishing Sim");
  $finish;

end
endmodule

`default_nettype wire
