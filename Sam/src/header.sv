

module header(
    input wire clk,
    input wire [7:0] axiid,
    input wire axiiv,
    input wire [31:0] counter,

    output axiov,
    output logic prot,
    output logic [8:0] bitrate,
    output logic [15:0] samp_rate,
    output logic padding,
    output logic private,
    output logic [1:0] mode,
    output logic [1:0] mode_ext,
    output logic [1:0] emphasis,
    output logic [8:0]frame_sample, 
    output logic [2:0] slot size
);
    logic [31:0] header;

    always_ff @(posedge clk) begin
        if(counter < 4) begin
            axiov <= 0;
            header <= (axiiv) ? {header[31:8], axiid} : header;
        end
        else begin
            axiov <= 1;
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
    
    assign prot = header[16];

    assign padding = header[9];

    assign private = header[8];

    assign mode = header[7:6];

    assign mode_ext = header[5:4];

    assign emphasis = header[1:0];

    assign frame_sample = 9'd384;

    assign slot_size = 3'd4;

endmodule