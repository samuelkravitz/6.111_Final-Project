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
    main_data_begin         = bitstream[ptr:ptr + 9]; ptr += 9;
    if (nchannels == 1):
        private_bits        = bitstream[ptr:ptr + 5]; ptr += 5;
    else:
        private_bits        = bitstream[ptr:ptr + 3]; ptr += 3;

    scfsi                   = [[] for i in range(nchannels)]        #2D array of bitstreams, [channel][scfsi_band], each item is 1 bit

    for ch in range(nchannels):
        for scfsi_band in range(4):
            scfsi[ch].append(bitstream[ptr]); ptr += 1;

    #create a bunch of 2d arrays (granules, nchannels) that store unsigned integers
    part2_3_length          = np.empty(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel] to index, each item is 12 bits
    big_values              = np.empty(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel]. each item is 9 bits
    global_gain             = np.empty(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel], each item is 8 bits
    mixed_block_flag        = np.empty(shape=(2,nchannels), dtype=np.uint16)         #2D array, [granule, channel], each item is 1 bit
    subblock_gain           = np.empty(shape=(2,nchannels,3), dtype=np.uint16)       #3D array, [granule, channel, window], each item is 3 bit
    window_switching_flag   = np.empty(shape=(2,nchannels), dtype=np.uint16)       #3D array, [granule, channel], each item is 1 bit

    #create a bunch of 2d arrays (granules, nchannels) that store bitstreams
    scalefac_compress       = [[],[]]     #2D array of bitstreams, [granule][channel], each item is 4 bits
    block_type              = [[],[]]     #2D array of bitstreams, [granule][channel], each item is 2 bits
    table_select            = [[[] for i in range(nchannels)],[[] for i in range(nchannels)]]     #3D array of bitstreams, [granule][channel][region], each item is 5 bits
    region0_count           = [[],[]]     #2D array of bitstreams, [granule][channel], each item is 4 bits
    region1_count           = [[],[]]     #2D array of bitstreams, [granule][channel], each item is 3 bits
    preflag                 = [[],[]]     #2D array of bitstreams, [granule][channel], each item is 1 bits
    scalefac_scale          = [[],[]]     #2D array of bitstreams, [granule][channel], each item is 1 bits
    count1table_select      = [[],[]]     #2D array of bitstreams, [granule][channel], each item is 1 bits

    for gr in range(2):
        for ch in range(nchannels):
            part2_3_length[gr,ch]       = int(bitstream[ptr: ptr + 12], 2); ptr += 12;
            big_values[gr, ch]          = int(bitstream[ptr: ptr + 9], 2); ptr += 9;
            global_gain[gr,ch]          = int(bitstream[ptr: ptr + 8], 2); ptr += 8;

            scalefac_compress[gr].append(bitstream[ptr: ptr + 4]); ptr += 4;
            window_switching_flag[gr][ch] = int(bitstream[ptr: ptr + 1],2); ptr += 1;

            if (window_switching_flag[gr][ch]):
                block_type[gr].append(bitstream[ptr: ptr + 2]); ptr += 2;
                mixed_block_flag[gr,ch] = int(bitstream[ptr: ptr + 1], 2); ptr += 1;

                for region in range(2):
                    table_select[gr][ch].append(bitstream[ptr: ptr + 5]); ptr += 5;
                for window in range(3):
                    subblock_gain[gr][ch][window] = int(bitstream[ptr: ptr + 3], 2); ptr += 3;
            else:
                for region in range(3):
                    table_select[gr][ch].append(bitstream[ptr: ptr + 5]); ptr += 5;
                region0_count[gr].append(bitstream[ptr: ptr + 4]); ptr += 4;
                region1_count[gr].append(bitstream[ptr: ptr + 3]); ptr += 3;

            preflag[gr].append(bitstream[ptr: ptr + 1]); ptr += 1;
            scalefac_scale[gr].append(bitstream[ptr: ptr + 1]); ptr += 1;
            count1table_select[gr].append(bitstream[ptr: ptr + 1]); ptr += 1;

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
        "count1table_select": count1table_select
    }

    return output, ptr


if __name__ == "__main__":
    test = "0" * 136
    lol, ptr = read_side_information(test, 0, 1)
    print(ptr)
    for key, value in lol.items():
        print(key, value)
