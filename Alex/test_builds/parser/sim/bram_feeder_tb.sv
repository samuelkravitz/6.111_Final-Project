`default_nettype none
`timescale 1ns / 1ps

module bram_feeder_tb;

  logic clk;
  logic rst;
  logic [7:0] axiod;
  logic axiov;
  logic frame_num_iv;
  logic [6:0] frame_num_id;

  bram_feeder UUT (.clk(clk),
                   .rst(rst),
                   .frame_num_iv(frame_num_iv),
                   .frame_num_id(frame_num_id),
                   .axiod(axiod),
                   .axiov(axiov));

  always begin
    #10;
    clk = !clk;     //clock cycles now happend every 20!
  end

  initial begin
    $dumpfile("sim/bram_feeder_sim.vcd");
    $dumpvars(0, bram_feeder_tb);
    $display("Starting Sim");

    clk = 0;
    rst = 0;

    frame_num_id = 0;
    frame_num_iv = 0;

    #20;
    rst = 1;
    #20;
    rst = 0;

    //ask for data:
    frame_num_id = 0;
    frame_num_iv = 1;
    #20;
    frame_num_iv = 0;

    #300000;

    // frame_num_id = 5;
    // frame_num_iv = 1;
    // #20;
    //
    // frame_num_iv = 0;
    //
    // #10000;

    $display("Finishing Sim");
    $finish;

  end

endmodule


`default_nettype wire
