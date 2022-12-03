`default_nettype none
`timescale 1ns / 1ps

module side_info_1ch(
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

    logic [135:0] side_info;

    always_ff @(posedge clk) begin
        if(counter >= 4 && counter < 21) begin
            axiov <= 0;
            side_info <= (axiiv) ? {side_info[135:8], axiid} : side_info;
        end
        else begin
            axiov <= 1;
        end
    end

    always_comb begin
        scfsi[0][0] = side_info[241-120];
        scfsi[0][1] = side_info[240-120];
        scfsi[0][2] = side_info[239-120];
        scfsi[0][3] = side_info[238-120];

        //GRANULE 0

        part2_3_length[0][0] = side_info[237-120:226-120];
        big_values[0][0] = side_info[225-120:217-120];
        global_gain[0][0] = side_info[216-120:209-120];
        scalefac_compress[0][0] = side_info[208-120:205-120];
        window_switching_flag[0][0] = side_info[204-120];

        if(window_switching_flag[0][0]) begin
            block_type[0][0] = side_info[203-120:202-120];
            mixed_block_flag[0][0] = side_info[201-120];

            table_select[0][0][0] = side_info[200-120:196-120];
            table_select[0][0][1] = side_info[195-120:191-120];

            subblock_gain[0][0][0] = side_info[190-120:188-120];
            subblock_gain[0][0][1] = side_info[187-120:185-120];
            subblock_gain[0][0][2] = side_info[184-120:182-120];

            if ((block_type[0][0] == 1 || block_type[0][0] == 2)) || ((block_type[0][0]==2) && (mixed_block_flag[0][0]==1)) begin
                region0_count[0][0] = 8'd7;
            end else begin
                region0_count[0][0] = 8'd8;
            end
            region1_count[0][0] = 8'd26;
        end else begin
            table_select[0][0][0] = side_info[203-120:199-120];
            table_select[0][0][1] = side_info[198-120:194-120];
            table_select[0][0][2] = side_info[193-120:189-120];

            region0_count[0][0] = side_info[188-120:185-120];
            region1_count[0][0] = side_info[184-120:182-120];
        end
        preflag[0][0] = side_info[181-120];
        scalefac_scale[0][0] = side_info[180-120];
        count1table_select[0][0] = side_info[179-120];

        //GRANULE 1

        part2_3_length[1][0] = side_info[237-59-120:226-59-120];
        big_values[1][0] = side_info[225-59-120:217-59-120];
        global_gain[1][0] = side_info[216-59-120:209-59-120];
        scalefac_compress[1][0] = side_info[208-59-120:205-59-120];
        window_switching_flag[1][0] = side_info[204-59-120];

        if(window_switching_flag[1][0]) begin
            block_type[1][0] = side_info[203-59-120:202-59-120];
            mixed_block_flag[1][0] = side_info[201-59-120];

            table_select[1][0][0] = side_info[200-59-120:196-59-120];
            table_select[1][0][1] = side_info[195-59-120:191-59-120];

            subblock_gain[1][0][0] = side_info[190-59-120:188-59-120];
            subblock_gain[1][0][1] = side_info[187-59-120:185-59-120];
            subblock_gain[1][0][2] = side_info[184-59-120:182-59-120];

            if ((block_type[1][0] == 1 || block_type[1][0] == 2)) || ((block_type[1][0]==2) && (mixed_block_flag[1][0]==1)) begin
                region0_count[1][0] = 8'd7;
            end else begin
                region0_count[1][0] = 8'd8;
            end
            region1_count[1][0] = 8'd26;
        end else begin
            table_select[1][0][0] = side_info[203-59-120:199-59-120];
            table_select[1][0][1] = side_info[198-59-120:194-59-120];
            table_select[1][0][2] = side_info[193-59-120:189-59-120];

            region0_count[1][0] = side_info[188-59-120:185-59-120];
            region1_count[1][0] = side_info[184-59-120:182-59-120];
        end

        preflag[1][0] = side_info[181-59-120];
        scalefac_scale[1][0] = side_info[180-59-120];
        count1table_select[1][0] = side_info[179-59-120];
    end

endmodule

`default_nettype wire
