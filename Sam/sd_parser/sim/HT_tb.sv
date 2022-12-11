`default_nettype none
`timescale 1ns / 1ps

module HT_tb;

logic clk;
logic rst;
logic axiiv;
logic axiid;

logic err;
logic axiov;
logic [15:0] x_val;
logic [15:0] y_val;

HT_17 UUT (clk, rst, axiiv, axiid, axiov, x_val, y_val);

logic [22:0] code;

always begin
  #10;
  clk = !clk;     //clock cycles now happend every 20!
end

initial begin
  $dumpfile("sim/HT_sim.vcd");
  $dumpvars(0, HT_tb);
  $display("Starting Sim");

  // code = 18'b001_11_0_001_01_1_1_01_10_0;
  code = 23'b0001100010_0_00010010101_1;
  //DECODE:   (7,0)     +x  (0,9)     -y
  clk = 0;
  rst = 0;

  axiiv = 0;
  axiid = 0;    //make the inputs 0 too!
  #20;
  rst = 1;
  #20;
  rst = 0;

  //TRANSMIT DESTINATION

  for (int i = 0; i < 23; i += 1) begin
    axiiv = 1;
    axiid = code[22-i];
    #20;
    axiiv = 0;
  end
  #200;


  $display("Finishing Sim");
  $finish;

end
endmodule

`default_nettype wire
