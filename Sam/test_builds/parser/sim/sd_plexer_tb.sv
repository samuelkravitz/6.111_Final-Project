`default_nettype none
`timescale 1ns / 1ps

module plexer_tb;

  logic clk;
  logic rst;

  logic sd_iv;
  logic [7:0] sd_din;

  logic header_iv;     //pulses for one clock cycle, tells us whether the header input data is valid or not
  logic [1:0] mode;    //this is from the header module (circular logic lmao)
  logic prot;    //this is whether or not the header has a CRC16 protection (takes 2 more bytes after header), 1 == no protection
  logic [10:0] frame_size;    //computed number of bytes in the frame...
  logic [8:0] bitrate;
  logic [15:0] samp_rate;
  logic padding;
  logic private;
  logic [1:0] mode_ext;
  logic [1:0] emphasis;
  logic [8:0] frame_sample;
  logic [2:0] slot_size;
  logic header_ov;
  logic crc_16_ov;
  logic side_info_1_ov;
  logic side_info_2_ov;
  logic fifo_buffer_ov;      //output valids for all the downstream modules

  logic [7:0] d_out;
  logic [8:0] byte_counter;


  logic [3343:0] frame_code;


  sd_plexer p (
      clk,
      rst,

      sd_iv,
      sd_din,

      header_iv,     //pulses for one clock cycle, tells us whether the header input data is valid or not
      mode,    //this is from the header module (circular logic lmao)
      prot,    //this is whether or not the header has a CRC16 protection (takes 2 more bytes after header), 1 == no protection
      frame_size,    //computed number of bytes in the frame...

      header_ov,
      crc_16_ov,
      side_info_1_ov,
      side_info_2_ov,
      fifo_buffer_ov,      //output valids for all the downstream modules

      d_out
    );

  header h (
      clk,
      rst,
      d_out,
      header_ov,

      header_iv,
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
    $dumpfile("sim/plexer_sim.vcd");
    $dumpvars(0, plexer_tb);
    $display("Starting Sim");

    frame_code = 3344'hfffb92642082f40e6056af69000000000d20e000010ec95f58cd18554800003480000004e6236c9abab64a1ac24681c3c94162c58a85f6b9b7ef89aaa18aae4d53777f4b536ad8e1f0f57c5c4691349ed3d713d71777fd13abfdcd7cf095e4e452c263772c2000462b01b908a4da32745b6b301352861e7acef35ca684bd116bd59e7fa6ad4b52db1fa7b517c2b543b019148fadd2b081341fbfa8b9151af93746a325fcafeb1db19eb775f62bb31285a560a77692ce942e92114862ee0d8e3b1667217b6a975b77bf76dbdadcce24227829da2dbc5a7fba45effb02051001047e06ec78c45e4ff6f9385c85b1464c54050529543962187cc4a54701d101f6899000010ea13ec00cf65b2168de5216ad32aa9f940d554a6f393d51ad38d7918a65a71597352dca19881c1576421086e2d39fc3eeb4aa68e70d9213667015044390a0b810624382c6e6de752630abae6a664a1575741f3b514a6c128200752c60644050640ac4d45dc952c8eadb45fa030a0445e3027e9017c32bc292eb8b15c38374a980b51451a7975812659a7398cdb41e7e184044ef08eecd375172e6fecdddec;

    clk = 0;
    rst = 0;

    sd_iv = 0;
    sd_din = 0;    //make the inputs 0 too!
    #20;
    rst = 1;
    #20;
    rst = 0;

    //TRANSMIT DESTINATION

    for (int i = 0; i < 418; i += 1) begin
      sd_iv = 1;
      sd_din = frame_code[(3343 - (8*i)) -: 8];
      #20;

      sd_iv = 0;
      #100;
    end


    $display("Finishing Sim");
    $finish;

  end

endmodule


`default_nettype wire
