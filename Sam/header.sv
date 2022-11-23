
module header(
    #Input 36 byte thing with header+side info

    #Output Actual corresponding values to stuff
);

endmodule
logic [31:0] header;
logic [255:0] side_info;
//parameter [8:0] bitrates [15:0] = {0,  32,  48,  56,  64,  80,  96, 112, 128, 144, 160, 176, 192, 224, 256, 0};

logic prot;
assign prot = header[16];

logic [8:0] bitrate;
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

logic [15:0] samp_rate;
case(header[11:10])
    2'b00 : samp_rate = 16'd44100;
    2'b01 : samp_rate = 16'd48000;
    2'b10 : samp_rate = 16'd32000;
    default samp_rate = 16'd0;
endcase

logic padding;
assign padding = header[9];

logic private;
assign private = header[8];

logic [1:0] mode;
assign mode = header[7:6];

logic [1:0] mode_ext;
assign mode_ext = header[5:4];

logic [1:0] emphasis;
assign emphasis = header[1:0];

logic [8:0] frame_sample;
assign frame_sample = 9'd384;

logic [2:0] slot_size;
assign slot_size = 3'd4;

logic [8:0] main_data_ptr;
assign main_data_ptr = side_info[255:247];

logic channel;

case(mode)
    2'b11 : channel = 1'b0;
    default : channel = 1'b1;
endcase

logic scfsi [1:0][3:0];
logic [11:0] part2_3_length [1:0][1:0];
logic [8:0] big_values [1:0][1:0];
logic [7:0] global_gain [1:0][1:0];
logic mixed_block_flag [1:0][1:0];
logic [2:0] subblock_gain [1:0][1:0];
logic window_switching_flag [1:0][1:0];
logic [1:0] block_type [1:0][1:0];
logic [3:0] scalefac_compress [1:0][1:0];
logic [4:0] table_select [1:0][1:0][2:0];
logic [7:0] region0_count [1:0][1:0];
logic [7:0] region1_count [1:0][1:0];
logic preflag [1:0][1:0];
logic scalefac_scale [1:0][1:0];
logic count1table_select [1:0][1:0];

integer i;

case (channel)
    //1 CHANNEL
    1'b0 : begin
        scfsi[0][0] = side_info[241];
        scfsi[0][1] = side_info[240];
        scfsi[0][2] = side_info[239];
        scfsi[0][3] = side_info[238];

        //GRANULE 0

        part2_3_length[0][0] = side_info[237:226];
        big_values[0][0] = side_info[225:217];
        global_gain[0][0] = side_info[216:209];
        scalefac_compress[0][0] = side_info[208:205];
        window_switching_flag[0][0] = side_info[204];

        if(window_switching_flag[0][0]) begin
            block_type[0][0] = side_info[203:202];
            mixed_block_flag[0][0] = side_info[201];

            table_select[0][0][0] = side_info[200:196];
            table_select[0][0][1] = side_info[195:191];

            subblock_gain[0][0][0] = side_info[190:188];
            subblock_gain[0][0][1] = side_info[187:185];
            subblock_gain[0][0][2] = side_info[184:182];

            if ((block_type[0][0] == 1 || block_type[0][0] == 2)) || ((block_type[0][0]==2) && (mixed_block_flag[0][0]==1)) begin
                region0_count[0][0] = 8'd7;
            end else begin
                region0_count[0][0] = 8'd8;
            end
            region1_count[0][0] = 8'd26;
        end else begin
            table_select[0][0][0] = side_info[203:199];
            table_select[0][0][1] = side_info[198:194];
            table_select[0][0][2] = side_info[193:189];

            region0_count[0][0] = side_info[188:185];
            region1_count[0][0] = side_info[184:182];
        end
        preflag[0][0] = side_info[181];
        scalefac_scale[0][0] = side_info[180];
        count1table_select[0][0] = side_info[179];

        //GRANULE 1

        part2_3_length[1][0] = side_info[237-59:226-59];
        big_values[1][0] = side_info[225-59:217-59];
        global_gain[1][0] = side_info[216-59:209-59];
        scalefac_compress[1][0] = side_info[208-59:205-59];
        window_switching_flag[1][0] = side_info[204-59];

        if(window_switching_flag[1][0]) begin
            block_type[1][0] = side_info[203-59:202-59];
            mixed_block_flag[1][0] = side_info[201-59];
 
            table_select[1][0][0] = side_info[200-59:196-59];
            table_select[1][0][1] = side_info[195-59:191-59];
 
            subblock_gain[1][0][0] = side_info[190-59:188-59];
            subblock_gain[1][0][1] = side_info[187-59:185-59];
            subblock_gain[1][0][2] = side_info[184-59:182-59];
 
            if ((block_type[1][0] == 1 || block_type[1][0] == 2)) || ((block_type[1][0]==2) && (mixed_block_flag[1][0]==1)) begin
                region0_count[1][0] = 8'd7;
            end else begin
                region0_count[1][0] = 8'd8;
            end
            region1_count[1][0] = 8'd26;
        end else begin
            table_select[1][0][0] = side_info[203-59:199-59];
            table_select[1][0][1] = side_info[198-59:194-59];
            table_select[1][0][2] = side_info[193-59:189-59];
 
            region0_count[1][0] = side_info[188-59:185-59];
            region1_count[1][0] = side_info[184-59:182-59];
        end

        preflag[1][0] = side_info[181-59];
        scalefac_scale[1][0] = side_info[180-59];
        count1table_select[1][0] = side_info[179-59];
    end
    //2 CHANNEL
    default : begin
        scfsi[0][0] = side_info[241+2];
        scfsi[0][1] = side_info[240+2];
        scfsi[0][2] = side_info[239+2];
        scfsi[0][3] = side_info[238+2];

        scfsi[1][0] = side_info[241-4+2];
        scfsi[1][1] = side_info[240-4+2];
        scfsi[1][2] = side_info[239-4+2];
        scfsi[1][3] = side_info[238-4+2];

    //GRANULE 0
        //CHANNEL 0
        part2_3_length[0][0] = side_info[237-2:226-2];
        big_values[0][0] = side_info[225-2:217-2];
        global_gain[0][0] = side_info[216-2:209-2];
        scalefac_compress[0][0] = side_info[208-2:205-2];
        window_switching_flag[0][0] = side_info[204-2];
 
        if(window_switching_flag[0][0]) begin
            block_type[0][0] = side_info[203-2:202-2];
            mixed_block_flag[0][0] = side_info[201-2];
 
            table_select[0][0][0] = side_info[200-2:196-2];
            table_select[0][0][1] = side_info[195-2:191-2];

            subblock_gain[0][0][0] = side_info[190-2:188-2];
            subblock_gain[0][0][1] = side_info[187-2:185-2];
            subblock_gain[0][0][2] = side_info[184-2:182-2];

            if ((block_type[0][0] == 1 || block_type[0][0] == 2)) || ((block_type[0][0]==2) && (mixed_block_flag[0][0]==1)) begin
                region0_count[0][0] = 8'd7;
            end else begin
                region0_count[0][0] = 8'd8;
            end
            region1_count[0][0] = 8'd26;

        end else begin
            table_select[0][0][0] = side_info[203-2:199-2];
            table_select[0][0][1] = side_info[198-2:194-2];
            table_select[0][0][2] = side_info[193-2:189-2];

            region0_count[0][0] = side_info[188-2:185-2];
            region1_count[0][0] = side_info[184-2:182-2];
        end
        preflag[0][0] = side_info[181-2];
        scalefac_scale[0][0] = side_info[180-2];
        count1table_select[0][0] = side_info[179-2];
 
        //CHANNEL 1
 
        part2_3_length[0][1] = side_info[237-59-2:226-59-2];
        big_values[0][1] = side_info[225-59-2:217-59-2];
        global_gain[0][1] = side_info[216-59-2:209-59-2];
        scalefac_compress[0][1] = side_info[208-59-2:205-59-2];
        window_switching_flag[0][1] = side_info[204-59-2];
 
        if(window_switching_flag[0][1]) begin
            block_type[0][1] = side_info[203-59-2:202-59-2];
            mixed_block_flag[0][1] = side_info[201-59-2];
 
            table_select[0][1][0] = side_info[200-59-2:196-59-2];
            table_select[0][1][1] = side_info[195-59-2:191-59-2];
            subblock_gain[0][1][0] = side_info[190-59-2:188-59-2];
            subblock_gain[0][1][1] = side_info[187-59-2:185-59-2];
            subblock_gain[0][1][2] = side_info[184-59-2:182-59-2];

            if ((block_type[0][1] == 1 || block_type[0][1] == 2)) || ((block_type[0][1]==2) && (mixed_block_flag[0][1]==1)) begin
                region0_count[0][1] = 8'd7;
            end else begin
                region0_count[0][1] = 8'd8;
            end
            region1_count[0][1] = 8'd26;
        end else begin
            table_select[0][1][0] = side_info[203-59-2:199-59-2];
            table_select[0][1][1] = 1ide_info[198-59-2:194-59-2];
            table_select[0][1][2] = side_info[193-59-2:189-59-2];
            region0_count[0][1] = side_info[188-59-2:185-59-2];
            region1_count[0][1] = side_info[184-59-2:182-59-2];
        end
        preflag[0][1] = side_info[181-59-2];
        scalefac_scale[0][1] = side_info[180-59-2];
        count1table_select[0][1] = side_info[179-59-2];
 
    //GRANULE 1
        //CHANNEL 0
        part2_3_length[1][0] = side_info[237-(2*59)-2:226-(2*59)-2];
        big_values[1][0] = side_info[225-(2*59)-2:217-(2*59)-2];
        global_gain[1][0] = side_info[216-(2*59)-2:209-(2*59)-2];
        scalefac_compress[1][0] = side_info[208-(2*59)-2:205-(2*59)-2];
        window_switching_flag[1][0] = side_info[204-(2*59)-2];
 
        if(window_switching_flag[1][0]) begin
            block_type[1][0] = side_info[203-(2*59)-2:202-(2*59)-2];
            mixed_block_flag[1][0] = side_info[201-(2*59)-2];
 
            table_select[1][0][0] = side_info[200-(2*59)-2:196-(2*59)-2];
            table_select[1][0][1] = side_info[195-(2*59)-2:191-(2*59)-2];
            subblock_gain[1][0][0] = side_info[190-(2*59)-2:188-(2*59)-2];
            subblock_gain[1][0][1] = side_info[187-(2*59)-2:185-(2*59)-2];
            subblock_gain[1][0][2] = side_info[184-(2*59)-2:182-(2*59)-2];

            if ((block_type[1][0] == 1 || block_type[1][0] == 2)) || ((block_type[1][0]==2) && (mixed_block_flag[1][0]==1)) begin
                region0_count[1][0] = 8'd7;
            end else begin
                region0_count[1][0] = 8'd8;
            end
            region1_count[1][0] = 8'd26;
        end else begin
            table_select[1][0][0] = side_info[203-(2*59)-2:199-(2*59)-2];
            table_select[1][0][1] = 1ide_info[198-(2*59)-2:194-(2*59)-2];
            table_select[1][0][2] = side_info[193-(2*59)-2:189-(2*59)-2];

            region0_count[1][0] = side_info[188-(2*59)-2:185-(2*59)-2];
            region1_count[1][0] = side_info[184-(2*59)-2:182-(2*59)-2];
        end
        preflag[1][0] = side_info[181-(2*59)-2];
        scalefac_scale[1][0] = side_info[180-(2*59)-2];
        count1table_select[1][0] = side_info[179-(2*59)-2];

        //CHANNEL 1
        part2_3_length[1][1] = side_info[237-(3*59)-2:226-(3*59)-2];
        big_values[1][1] = side_info[225-(3*59)-2:217-(3*59)-2];
        global_gain[1][1] = side_info[216-(3*59)-2:209-(3*59)-2];
        scalefac_compress[1][1] = side_info[208-(3*59)-2:205-(3*59)-2];
        window_switching_flag[1][1] = side_info[204-(3*59)-2];
 
        if(window_switching_flag[1][1]) begin
            block_type[1][1] = side_info[203-(3*59)-2:202-(3*59)-2];
            mixed_block_flag[1][1] = side_info[201-(3*59)-2];
 
            table_select[1][1][0] = side_info[200-(3*59)-2:196-(3*59)-2];
            table_select[1][1][1] = side_info[195-(3*59)-2:191-(3*59)-2];
            subblock_gain[1][1][0] = side_info[190-(3*59)-2:188-(3*59)-2];
            subblock_gain[1][1][1] = side_info[187-(3*59)-2:185-(3*59)-2];
            subblock_gain[1][1][2] = side_info[184-(3*59)-2:182-(3*59)-2];

             if ((block_type[1][1] == 1 || block_type[1][1] == 2)) || ((block_type[1][1]==2) && (mixed_block_flag[1][1]==1)) begin
                region0_count[1][1] = 8'd7;
            end else begin
                region0_count[1][1] = 8'd8;
            end
            region1_count[1][1] = 8'd26;
        end else begin
            table_select[1][1][0] = side_info[203-(3*59)-2:199-(3*59)-2];
            table_select[1][1][1] = 1ide_info[198-(3*59)-2:194-(3*59)-2];
            table_select[1][1][2] = side_info[193-(3*59)-2:189-(3*59)-2];

            region0_count[1][1] = side_in-59fo[188-(3*59)-2:185-(3*59)-2];
            region1_count[1][1] = side_info[184-(3*59)-2:182-(3*59)-2];
        end
        preflag[1][1] = side_info[181-(3*59)-2];
        scalefac_scale[1][1] = side_info[180-(3*59)-2];
        count1table_select[1][1] = side_info[179-(3*59)-2];
    end
endcase
