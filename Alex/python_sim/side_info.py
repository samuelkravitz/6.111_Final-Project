'''
code to read in the data contained in a valid frame.
taken directly from the ISO standards pg 23 (section 2.4.1.7)
'''
import numpy as np

def read_side_information(bitstream, ptr, nchannels):
    '''
    ARGS:
        bitstream -> string of bits from the file. this expects the entire bitstream
        pter -> integer, marks the start of the frame data (after the header and CRC)
        nchannels -> number of audio channels encoded by the file (2 or 1, determined in the header)
    OUTPUT:
        output -> dictionary extracting all the relevant side information
                    note that if the audio is single channel, it reads through 17 bytes (136 bits)
                    if the audio is dual channel, it reads through 32 bytes (256 bits)
        ptr -> location of the main_data information (first bit after all the side information)
    '''
    main_data_begin         = int(bitstream[ptr:ptr + 9], 2); ptr += 9;
    if (nchannels == 1):
        private_bits        = int(bitstream[ptr:ptr + 5], 2); ptr += 5;
    else:
        private_bits        = int(bitstream[ptr:ptr + 3], 2); ptr += 3;


    #create a bunch of 2d arrays (granules, nchannels) that store unsigned integers
    scfsi                   = np.zeros(shape=(2,        4), dtype=np.uint16)         #2D array of bitstreams, [channel][scfsi_band], each item is 1 bit
    part2_3_length          = np.zeros(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel] to index, each item is 12 bits
    big_values              = np.zeros(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel]. each item is 9 bits
    global_gain             = np.zeros(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel], each item is 8 bits
    mixed_block_flag        = np.zeros(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel], each item is 1 bit
    subblock_gain           = np.zeros(shape=(2,nchannels,3), dtype=np.uint16)       #3D array, [granule, channel, window], each item is 3 bit
    window_switching_flag   = np.zeros(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel], each item is 1 bit
    block_type              = np.zeros(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel], each item is 2 bits
    scalefac_compress       = np.zeros(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel], each item is 4 bits
    table_select            = np.zeros(shape=(2,nchannels,3), dtype=np.uint16)       #3D array, [granule, channel, region], each item is 5 bits, region may span 2 or 3
    region0_count           = np.zeros(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel] to index, each item is 4 bits
    region1_count           = np.zeros(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel] to index, each item is 3 bits
    preflag                 = np.zeros(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel] to index, each item is 1 bit
    scalefac_scale          = np.zeros(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel] to index, each item is 1 bit
    count1table_select      = np.zeros(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel] to index, each item is 1 bit
    # switch_point_l          = np.zeros(shape=(2,nchannels), dtype=np.uint16)
    # switch_point_s          = np.zeros(shape=(2,nchannels), dtype=np.uint16)

    for ch in range(nchannels):
        for scfsi_band in range(4):
            scfsi[ch, scfsi_band]       = int(bitstream[ptr], 2); ptr += 1;

    for gr in range(2):
        for ch in range(nchannels):
            part2_3_length[gr,ch]           = int(bitstream[ptr: ptr + 12], 2); ptr += 12;
            big_values[gr, ch]              = int(bitstream[ptr: ptr + 9 ], 2); ptr += 9;
            global_gain[gr,ch]              = int(bitstream[ptr: ptr + 8 ], 2); ptr += 8;

            scalefac_compress[gr,ch]        = int(bitstream[ptr: ptr + 4 ], 2); ptr += 4;
            window_switching_flag[gr][ch]   = int(bitstream[ptr: ptr + 1 ], 2); ptr += 1;

            if (window_switching_flag[gr][ch]):
                block_type[gr,ch]           = int(bitstream[ptr: ptr + 2], 2); ptr += 2;
                mixed_block_flag[gr,ch]     = int(bitstream[ptr: ptr + 1], 2); ptr += 1;

                # ### found in the mp3-decoder c library...
                # if (mixed_block_flag[gr,ch] == 1):
                #     switch_point_l[gr,ch] = 8
                #     switch_point_s[gr,ch] = 3
                # else:
                #     switch_point_l[gr,ch] = 0
                #     switch_point_s[gr,ch] = 0

                for region in range(2):
                    table_select[gr,ch,region]      = int(bitstream[ptr: ptr + 5], 2); ptr += 5;
                for window in range(3):
                    subblock_gain[gr,ch,window]     = int(bitstream[ptr: ptr + 3], 2); ptr += 3;

                #### DEFAULT VALUES FOR REGION COUNT: (pg 32 of ISO manual)
                if (block_type[gr,ch] == 2) and (mixed_block_flag[gr,ch] == 0):
                    region0_count[gr,ch]            = 8
                else:
                    region0_count[gr,ch]            = 7
                region1_count[gr,ch]                = 20 - region0_count[gr,ch]       #### i have since changed this to what i found in the PDMP3 C library... they made an explicit note, i will take it
            else:
                for region in range(3):
                    table_select[gr,ch,region]      = int(bitstream[ptr: ptr + 5], 2); ptr += 5;

                region0_count[gr,ch]                = int(bitstream[ptr: ptr + 4], 2); ptr += 4;
                region1_count[gr,ch]                = int(bitstream[ptr: ptr + 3], 2); ptr += 3;
                block_type[gr,ch]                   = 0     #implicit, i added this after seeing it in the PDMP3 C library (line 1191)

            preflag[gr,ch]                          = int(bitstream[ptr: ptr + 1], 2); ptr += 1;
            scalefac_scale[gr,ch]                   = int(bitstream[ptr: ptr + 1], 2); ptr += 1;
            count1table_select[gr,ch]               = int(bitstream[ptr: ptr + 1], 2); ptr += 1;

    output = {
        "main_data_begin": main_data_begin,
        "private_bits": private_bits,
        "scfsi": scfsi,
        "part2_3_length": part2_3_length,
        "big_values": big_values,
        "global_gain": global_gain,
        "mixed_block_flag": mixed_block_flag,
        "subblock_gain": subblock_gain,
        "scalefac_scale": scalefac_scale,
        "scalefac_compress": scalefac_compress,
        "window_switching_flag": window_switching_flag,
        "block_type": block_type,
        "table_select": table_select,
        "region0_count": region0_count,
        "region1_count": region1_count,
        "preflag": preflag,
        "count1table_select": count1table_select,
        # "switch_point_l": switch_point_l,
        # "switch_point_s": switch_point_s
    }

    return output, ptr


if __name__ == "__main__":
    test = "0" * 136
    lol, ptr = read_side_information(test, 0, 1)
    print(ptr)
    for key, value in lol.items():
        print(key, value)
