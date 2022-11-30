module header(
    input wire clk,
    input wire [7:0] axiid,
    input wire axiiv,
    input wire [31:0] counter,

    output logic scfsi [1:0][3:0],
    output logic [11:0] part2_3_length [1:0][1:0],
    output logic [8:0] big_values [1:0][1:0],
    output logic [7:0] global_gain [1:0][1:0],
    output logic mixed_block_flag [1:0][1:0],
    output logic [2:0] subblock_gain [1:0][1:0],
    output logic window_switching_flag [1:0][1:0],
    output logic [1:0] block_type [1:0][1:0],
    output logic [3:0] scalefac_compress [1:0][1:0],
    output logic [4:0] table_select [1:0][1:0][2:0],
    output logic [7:0] region0_count [1:0][1:0],
    output logic [7:0] region1_count [1:0][1:0],
    output logic preflag [1:0][1:0],
    output logic scalefac_scale [1:0][1:0],
    output logic count1table_select [1:0][1:0],
    output logic axiov
);
    logic [255:0] side_info;

    always_ff @(posedge clk) begin
        if(counter >= 4 && counter < 36) begin
            axiov <= 0;
            side_info <= (axiiv) ? {side_info[135:8], axiid} : side_info;
        end
        else begin
            axiov <= 1;
        end
    end

    always_comb begin
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

endmodule