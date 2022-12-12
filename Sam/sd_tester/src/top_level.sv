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
    always_ff @(posedge clk_100mhz) begin
        if(sys_rst) begin
        rd <= 0;
        wr <= 0;
        din <= 0;
        addr <= 32'h200;
        end else if (ready && (read_counter < 512)) begin
        rd <= 1;
        end else if(ready && (~old_btnu && btnu)) begin
            rd <= 1;
            addr <= addr + 512;
        end else begin
        rd <= 0;
        wr <= 0;
        din <= 0;
        end
        //led[15] <= ready;
        old_btnu <= btnu;
    end

    logic [31:0] byte_index;
    logic [31:0] to_seven;

    logic [15:0] read_counter;
    
    always_ff @(posedge clk_100mhz) begin
        if (sys_rst) begin
        read_counter <= 0;
        end else begin
            // if (ready && (~old_btnu && btnu)) begin
            //     read_counter <= 0;
            // end else begin
        read_counter <= (~old_byte_avail && byte_available) ? read_counter + 1 : read_counter;
            // end
         old_byte_avail <= byte_available;
        // end
        end
    end

    assign to_seven = {read_counter, first};

    // logic [4095:0] sd_values;

    logic [15:0] first;
    always_ff @(posedge clk_100mhz) begin
        if (dout == 8'hFB) begin
            first <= read_counter;
        end
    end

    logic clean_down;

    logic old_clean;
    assign led[15] = byte_available;
    assign led[14:7] = dout;
    assign led[6:2] = status;
    assign led[0] = rd;
    assign led[1] = sd_sck;

    // assign led[3] = sd_dat[0]=='hZ?1:0;
    always_ff @(posedge clk_100mhz) begin
        if (sys_rst) begin
        byte_index <= 0;
        end else if (~old_clean && clean_down) begin
        byte_index <= byte_index + 1;
        end else begin
        byte_index <= byte_index;
        end
        old_clean <= clean_down;
    end

    logic [7:0] sd_ram_out;
    
    seven_segment_controller #(.COUNT_TO('d100_000)) sev_seg
                            (.clk_in(clk_100mhz),
                            .rst_in(sys_rst),
                            .val_in(to_seven),
                            .cat_out({cg, cf, ce, cd, cc, cb, ca}),
                            .an_out(an)
                            );

    

endmodule

`default_nettype wire