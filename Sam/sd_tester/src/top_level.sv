`default_nettype none
`timescale 1ns / 1ps

module top_level(
  input wire clk,
  input wire btnc,
  input wire btnu,
  input wire btnd,
  input wire [15:0] sw,
  input wire sd_cd,

  inout wire [3:0] sd_dat,

  output  logic sd_reset, 
  output  logic sd_sck, 
  output  logic sd_cmd,
  output logic [15:0] led,
  output logic ca, cb, cc, cd, ce, cf, cg,
  output logic [7:0] an
  );

    logic sys_rst;
    assign sys_rst = btnc;

    enum {IDLE, PLAY} state;

    logic clk_25mhz;
    logic clk_100mhz;
    clk_wiz_0 clocks(.clk_in1(clk), .clk_out1(clk_100mhz), .clk_out2(clk_25mhz));

    assign sd_dat[2:1] = 2'b11;
    assign sd_reset = 0;

    logic rd;                   // read enable
    logic wr;                   // write enable
    logic [7:0] din;            // data to sd card
    logic [31:0] addr;          // starting address for read/write operation

    // sd_controller outputs
    logic ready;                // high when ready for new read/write operation
    logic [7:0] dout;           // data from sd card
    logic byte_available;       // high when byte available for read
    logic ready_for_next_byte;  // high when ready for new byte to be written
    logic [4:0] status;

    logic old_byte_avail;

    // handles reading from the SD card
    sd_controller sd(.reset(sd_reset), .clk(clk_25mhz), .cs(sd_dat[3]), .mosi(sd_cmd), 
                .miso(sd_dat[0]), .sclk(sd_sck), .ready(ready), .address(addr),
                .rd(rd), .dout(dout), .byte_available(byte_available),
                .wr(wr), .din(din), .ready_for_next_byte(ready_for_next_byte), .status(status));

    logic old_btnu;

    parameter song1_start = 32'h200;
    parameter song1_frames = 1000;
    // paremeter song2_start = 32'h200 + (512 * 125);
    // parameter song2_frames = 125;
    // parameter song3_start = song2_start + (512 * song2_frames);;
    // parameter song3_frames = 125;

    logic [15:0] starting_frame_addr;
    logic [15:0] ending_frame_num;

    always_comb begin
    case(sw[1:0])
        2'b00 : begin
            starting_frame_addr = song1_start;
            ending_frame_num = song1_frames;
        end
        default : begin
            starting_frame_addr = song1_start;
            ending_frame_num = song1_frames;
        end
        // 2'b01 : begin 
        //     starting_frame_addr = song2_start;
        //     ending_frame_num = song2_frames;
        // end
        // 2'b11 : begin
        //     starting_frame_addr = song3_start;
        //     ending_frame_num = song3_frames;
        // end
    endcase
    end

    logic new_frame_flag;
    logic [31:0] read_counter;
    logic [15:0] frame_counter;

    always_ff @(posedge clk_100mhz) begin
        if(sys_rst) begin
            state <= IDLE;
        end else begin
            case(state)
                IDLE : begin
                    if (old_btnu && btnu) begin
                        state <= PLAY;
                        frame_counter <= 0;
                        addr <= starting_frame_addr;
                        read_counter <= 0;
                    end else begin
                        rd <= 0;
                        wr <= 0;
                        din <= 0;
                        addr <= 0;
                    end
                    old_btnu <= btnu;
                end
                PLAY : begin
                    if (frame_counter < ending_frame_num) begin
                        rd <= 1;
                        read_counter <= (~old_byte_avail && byte_available) ? read_counter + 1 : read_counter;
                        old_byte_avail <= byte_available;
                        // rd <= (new_frame_flag) ? 1 : 0;
                        if (read_counter == 512) begin
                            frame_counter <= frame_counter + 1;
                            addr <= addr + 512;
                            read_counter <= 0;
                        end
                    end else begin
                        rd <= 0;
                        state <= IDLE;
                    end
                    old_btnu <= btnu;
                end
            endcase
        end
    end

    assign led[15] = (state == PLAY);

    seven_segment_controller #(.COUNT_TO('d100_000)) sev_seg
                            (.clk_in(clk_100mhz),
                            .rst_in(sys_rst),
                            .val_in({frame_counter, ending_frame_num}),
                            .cat_out({cg, cf, ce, cd, cc, cb, ca}),
                            .an_out(an)
                            );



endmodule

`default_nettype wire