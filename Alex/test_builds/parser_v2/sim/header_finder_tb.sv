`default_nettype none
`timescale 1ns / 1ps

module header_tb;

  logic clk;
  logic rst;
  logic [7:0] axiid;
  logic axiiv;

  logic valid_header;
  logic prot;
  logic [1:0] mode;
  logic [1:0] mode_ext;
  logic [1:0] emphasis;
  logic [10:0] frame_size;

  logic [31:0] header_code;
  logic [39:0] header_code_2;

  header_finder uut (
      .clk(clk),
      .rst(rst),
      .axiid(axiid),
      .axiiv(axiiv),
      .valid_header(valid_header),
      .prot(prot),
      .mode(mode),
      .mode_ext(mode_ext),
      .emphasis(emphasis),
      .frame_size(frame_size)
    );

  always begin
    #10;
    clk = !clk;     //clock cycles now happend every 20!
  end

  initial begin
    $dumpfile("sim/header_finder_sim.vcd");
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

    header_code_2 = 40'b1100_1111_1111_1111_1111_1011_1001_0010_0110_0100;

    #200
    for (int j = 39; j > 0; j -= 8) begin
      axiiv = 1;
      axiid = header_code_2[j-:8];
      #20;

      axiiv = 0;
      #100;
    end


    $display("Finishing Sim");
    $finish;

  end

endmodule


`default_nettype wire
