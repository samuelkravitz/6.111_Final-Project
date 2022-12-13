`timescale 1ns / 1ps
`default_nettype none


/*
STATUS: WORKING
  tested a few different ways given the 4 bytes are inputted consecutively. right now there is nothing to reset
  the internal header_byte_counter, so if it stops getting the bytes in halfway, but no rst signal is sent in,
  this shit will output data at the wrong time.
  dont know how to fix this realistically, unless we take the byte_counter as an input.
  but that method is not really sustainable for downstream stuff (cus of the CRC16 check throwing the byte count off)
  so i don't want to make that counter into some kind of global system.
  I would rather just ensure that the entire frame is loaded (ti doesn't quite reading in the frame halfway).
  If that system breaks, we have the reset button to save the system.
*/

module header(
    input wire clk,
    input wire rst,
    input wire [7:0] axiid,
    input wire axiiv,

    output logic axiov,
    output logic sync,
    output logic prot,
    output logic [8:0] bitrate,
    output logic [15:0] samp_rate,
    output logic padding,
    output logic private,
    output logic [1:0] mode,
    output logic [1:0] mode_ext,
    output logic [1:0] emphasis,
    output logic [8:0] frame_sample,
    output logic [2:0] slot_size,
    output logic [10:0] frame_size
);
    logic [31:0] header;
    logic [1:0] header_byte_counter;    //counts to 3 and then recycles...

    always_ff @(posedge clk) begin
        if (rst) begin
          header <= 0;
          header_byte_counter <= 0;
          axiov <= 0;
        end else begin
            if (axiiv) begin
              header <= {header[23:0], axiid};

                if (header_byte_counter == 2'b11) begin
                  axiov <= 1;   //this means the 4 bytes for the header have been read in now!
                  header_byte_counter <= 0;     //reset the byte counter to 0 again...
                end else begin
                  header_byte_counter <= header_byte_counter + 1;   //increment the header byte counter
                  axiov <= 0;
                end

            end else begin
              axiov <= 0;
            end
        end
    end

    always_comb begin
        case(header[15:12])
            4'b0001 : bitrate = 9'd32;
            4'b0010 : bitrate = 9'd40;
            4'b0011 : bitrate = 9'd48;
            4'b0100 : bitrate = 9'd56;
            4'b0101 : bitrate = 9'd64;
            4'b0110 : bitrate = 9'd80;
            4'b0111 : bitrate = 9'd96;
            4'b1000 : bitrate = 9'd112;
            4'b1001 : bitrate = 9'd128;
            4'b1010 : bitrate = 9'd160;
            4'b1011 : bitrate = 9'd192;
            4'b1100 : bitrate = 9'd224;
            4'b1101 : bitrate = 9'd256;
            4'b1110 : bitrate = 9'd320;
            default : bitrate = 9'd0;
        endcase
        case(header[11:10])
            2'b00 : samp_rate = 16'd44100;
            2'b01 : samp_rate = 16'd48000;
            2'b10 : samp_rate = 16'd32000;
        default samp_rate = 16'd0;
    endcase
    end

    assign sync = header[31:20];

    assign prot = header[16];

    assign padding = header[9];

    assign private = header[8];

    assign mode = header[7:6];

    assign mode_ext = header[5:4];

    assign emphasis = header[1:0];

    assign frame_sample = 9'd384;

    assign slot_size = 3'd4;

    //compute the frame size according to a look up table (so we dont have to divide by 44100):
    //note that this HAS to be done within a clock cycle because the frame parsing takes this information into account
    always_comb begin
      case(bitrate)
          9'd32   :   frame_size = padding ? (11'd104  + 1) : (11'd104) ;
          9'd40   :   frame_size = padding ? (11'd130  + 1) : (11'd130) ;
          9'd48   :   frame_size = padding ? (11'd156  + 1) : (11'd156) ;
          9'd56   :   frame_size = padding ? (11'd182  + 1) : (11'd182) ;
          9'd64   :   frame_size = padding ? (11'd208  + 1) : (11'd208) ;
          9'd80   :   frame_size = padding ? (11'd261  + 1) : (11'd261) ;
          9'd96   :   frame_size = padding ? (11'd313  + 1) : (11'd313) ;
          9'd112  :   frame_size = padding ? (11'd365  + 1) : (11'd365) ;
          9'd128  :   frame_size = padding ? (11'd417  + 1) : (11'd417) ;
          9'd160  :   frame_size = padding ? (11'd522  + 1) : (11'd522) ;
          9'd192  :   frame_size = padding ? (11'd626  + 1) : (11'd626) ;
          9'd224  :   frame_size = padding ? (11'd731  + 1) : (11'd731) ;
          9'd256  :   frame_size = padding ? (11'd835  + 1) : (11'd835) ;
          9'd320  :   frame_size = padding ? (11'd1044 + 1) : (11'd1044);
          default :   frame_size = 9'd0;
      endcase

    end

    //frame size cases compared to bitrate cases:
    /*
    bitrates    -> [0,  32,  40,  48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256,  320, 0]
    frame sizes -> [0, 104, 130, 156, 182, 208, 261, 313, 365, 417, 522, 626, 731, 835, 1044, 0]
    */
    //note that this LUT is only possible by assuming the MPEG-1 Layer III 44.1kHz stuff too.
endmodule

`default_nettype wire
