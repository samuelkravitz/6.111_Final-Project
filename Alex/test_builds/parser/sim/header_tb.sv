`default_nettype none
`timescale 1ns / 1ps

module header_tb;

  logic clk;
  logic rst;
  logic [7:0] axiid;
  logic axiiv;

  logic axiov;
  logic prot;
  logic [8:0] bitrate;
  logic [15:0] samp_rate;
  logic padding;
  logic private;
  logic [1:0] mode;
  logic [1:0] mode_ext;
  logic [1:0] emphasis;
  logic [8:0] frame_sample;
  logic [2:0] slot_size;
  logic [10:0] frame_size;

  logic [31:0] header_code;


  header shit (
      clk,
      rst,
      axiid,
      axiiv,
      axiov,
      prot,
      bitrate,
      samp_rate,
      padding,
      private,
      mode,
      mode_ext,
      emphasis,
      frame_sample,
      slot_size,
      frame_size
    );

  always begin
    #10;
    clk = !clk;     //clock cycles now happend every 20!
  end

  initial begin
    $dumpfile("sim/header_sim.vcd");
    $dumpvars(0, header_tb);
    $display("Starting Sim");

    header_code = 32'b1111_1111_1111_1011_1001_0010_0110_0100;

    clk = 0;
    rst = 0;

    axiiv = 0;
    axiid = 0;    //make the inputs 0 too!
    #20;
    rst = 1;
    #20;
    rst = 0;

    //TRANSMIT DESTINATION

    for (int i = 31; i > 0; i -= 8) begin
      axiiv = 1;
      axiid = header_code[i-:8];
      #20;

      axiiv = 0;
      #100;
    end


    #200
    for (int j = 31; j > 0; j -= 8) begin
      axiiv = 1;
      axiid = header_code[j-:8];
      #20;

      axiiv = 0;
      #100;
    end


    $display("Finishing Sim");
    $finish;

  end

endmodule


`default_nettype wire
