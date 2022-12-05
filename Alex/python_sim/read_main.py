'''
code dedicated to reading in the main info as defined by the ISO standard
this is the huffman bits etc
very tricky starting and ending place.
'''
import numpy as np
from huffman_LUT import main_tables, table_A, table_B, table_linbits
from scalefactor_tables import LONG_BLOCKS, SHORT_BLOCKS


slen1 = [0,0,0,0,3,1,1,1,2,2,2,3,3,3,4,4]   #both taken from page 32 of ISO pdf
slen2 = [0,1,2,3,0,1,2,3,1,2,3,1,2,3,2,3]   #used to determine the bit size of scalefac_l and scalefac_s (long and short scalefactors)

class MainDataFinder():
    def __init__(self):
        self.last_loc = None
        self.header_loc_memory = np.zeros((4,), dtype=np.uint16)        #integer locations of the last 4 headers
        self.header_size_memory = np.zeros((4,), dtype=np.uint16)       #integer sizes (in bits) of the last 4 headers, depends on number of channels

    def get_main_data_bits(self, bitstream, header, side_info):
        '''
        ARGS:
            bitstream -> full bitstream...
            header -> header dictionary of current frame
            side_info -> side info dictionary of current frame
        '''
        full_data_length = np.sum(side_info["part2_3_length"])

        #shift the header loc and size stuff over and accomodate the new header and side information
        self.header_loc_memory[0:3] = self.header_loc_memory[1:4]
        self.header_loc_memory[3]   = header["loc"]

        self.header_size_memory[0:3] = self.header_size_memory[1:4]
        self.header_size_memory[3]  = 8 * (21 if header["mode"] == 3 else 36) + 8 * (2 if header["prot"] == 0 else 0)   #size of side information is different if there are 2 channels vs 1

        #construct the output bitstream:
        output = ""
        ptr = header["loc"] - (side_info["main_data_begin"] * 8)        #main_data_begin is in bytes, not bits!
        for i in range(full_data_length):
            for j in range(4):
                if (ptr > self.header_loc_memory[j]) and (ptr < self.header_loc_memory[j] + self.header_size_memory[j]):
                    ptr = self.header_loc_memory[j] + self.header_size_memory[j]    #set the pointer to the end of the side information...
            if ptr > header["loc"] + header["size"] * 8:
                raise ValueError("for some reason the pointer for reading out main data travelled into the next frame...")
            output += bitstream[ptr: ptr + 1]; ptr += 1
        return output

def integer(str_in, base):
    '''
    defaults on the empty string to 0 because this is giving me trouble...
    '''
    if len(str_in) == 0:
        return 0
    return int(str_in, base)

def read_main_data(main_data_bitstream, header, side_info):
    '''
    read in the scaling factors, quantized huffman codes, and ancillary bits from the main information packet
    note that this is exceedingly complicated because the start of the information
    can fall back more than one frame before. this function will assume ONLY the data is present in the bitstream
    the only real guarantee i see is that the data for a specific frame must be finished (in the bitstream)
    by the end of its frame. but it can start in the frame before (or 2 frames before, or more maybe...)

    ARGS:
        main_data_bitstream -> string of 1s and 0s, note that this is different from before. instead of the whole bitstream, this should be
                        the entire frame's bitstream (because it may be broken up among many frames, and i don't want this function to have to deal with it yet)
                        it is further segmented into the different granules and channels below
        header -> dictionary output of the read_header() function. contains important metadata (namely, number of channels, under the 'mode' number)
        side_info -> dictionary output of the read_side_information() function. contains important metadata:
                                                                            scalefac_compress, window_switching_flag, block_type, scfsi
    '''
    if header["mode"] == 3:
        nchannels = 1
    else:
        nchannels = 2   #assume that joint stereo, stereo, and dual channel are all 2 channels
    #define 2 2D arrays:
    scalefac_l = np.zeros(shape=(2, nchannels, 21   ), dtype=np.uint16)        #note that the 3rd dimension may only need 8 bits depending on the window, needs all 21 if window is normal or block type is normal
    scalefac_s = np.zeros(shape=(2, nchannels, 12, 3), dtype=np.uint16)     #also might contain extraneous bits...
    IS         = np.zeros(shape=(2, nchannels, 576  ), dtype=np.int)    #these are the decoded huffman values,

    ptr_start = 0           #add the part2_3_length to this value every segment
    for gr in range(2):
        for ch in range(nchannels):
            ptr=0

            data_length = side_info["part2_3_length"][gr,ch]    #number of bits used for this granule and channel
            bitstream = main_data_bitstream[ptr_start:ptr_start + data_length]      #constructs the bitstream specific to the granule and channel

            if data_length == 0:
                continue        #if there is no data for this granule and channel, just skip it. causes downstream errrors oetherwise

            bitlength_1 = slen1[side_info["scalefac_compress"][gr,ch]]
            bitlength_2 = slen2[side_info["scalefac_compress"][gr,ch]]      #these are used for difference scalefactor bands depending on the window and block type

            if (side_info["window_switching_flag"][gr,ch] == 1) and (side_info["block_type"][gr,ch] == 2):
                if side_info["mixed_block_flag"][gr,ch] == 1:
                    for sfb in range(8):
                        scalefac_l[gr,ch,sfb]                       = int(bitstream[ptr: ptr + bitlength_1], 2); ptr += bitlength_1;
                    for sfb in range(3,12):
                        for window in range(3):
                            if sfb < 6:
                                scalefac_s[gr,ch,sfb,window]        = int(bitstream[ptr: ptr + bitlength_1], 2); ptr += bitlength_1;
                            else:
                                scalefac_s[gr,ch,sfb,window]        = int(bitstream[ptr: ptr + bitlength_2], 2); ptr += bitlength_2;
                else:
                    #this means the mixed_block_flag is 0, so the bitlengths are different and only scalefac_s is used (pg 24)
                    for sfb in range(12):
                        for window in range(3):
                            if sfb < 6:
                                scalefac_s[gr,ch,sfb,window]        = int(bitstream[ptr: ptr + bitlength_1], 2); ptr += bitlength_1;
                            else:
                                scalefac_s[gr,ch,sfb,window]        = int(bitstream[ptr: ptr + bitlength_2], 2); ptr += bitlength_2;
            else:
                if   (side_info["scfsi"][ch][0] == 0) and (gr == 0):
                    for sfb in range(6):
                        scalefac_l[gr,ch,sfb]                       = int(bitstream[ptr: ptr + bitlength_1], 2); ptr += bitlength_1;
                elif (side_info["scfsi"][ch][1] == 0) and (gr == 0):
                    for sfb in range(6,11):
                        scalefac_l[gr,ch,sfb]                       = int(bitstream[ptr: ptr + bitlength_1], 2); ptr += bitlength_1;
                elif (side_info["scfsi"][ch][2] == 0) and (gr == 0):
                    for sfb in range(11,16):
                        scalefac_l[gr,ch,sfb]                       = int(bitstream[ptr: ptr + bitlength_2], 2); ptr += bitlength_2;
                elif (side_info["scfsi"][ch][3] == 0) and (gr == 0):
                    for sfb in range(16,21):
                        scalefac_l[gr,ch,sfb]                       = int(bitstream[ptr: ptr + bitlength_2], 2); ptr += bitlength_2;
            IS[gr,ch,:] = huffmancodebits(bitstream, ptr, gr, ch, header, side_info)     ####TODO: modify this to only give the remaining part2_3_length bits used in this granule and channel
            if ptr > ptr_start + data_length:
                raise ValueError("somehow exceeded the number of bits alloted to this shit...")
            else:
                ptr = ptr_start + data_length   #this makes sure we skip any extra ancillary bits at the end!!!

    output = {
        "scalefac_l": scalefac_l,
        "scalefac_s": scalefac_s,
        "IS" : IS
    }
    return output, ptr

def huffmancodebits(bitstream, ptr, gr, ch, header, side_info):
    '''
    supposed to emulate the huffmancodebits function defined in the ISO manual
    first decode the big values, then decode the count1 values (higher frequencies)
    oh god
    IMPORTANT: block_type==2 is not accounted for yet, cus the manual is confusing to udnerstand. page 35
                i don't know what order the frequencies are outputted here...
                if block_type != 2, then they can be read out in terms of increasing frequency.

    ARGS:
        bitstream -> string of 1s and 0s, note that this is the frame's main data only (for a single granule and channel too),
                        nothing else. so you are free to parse it with the ptr
        ptr -> integer, index of where to start in the bitstream
        gr -> integer, granule (0 or 1)
        ch -> integer, channel (0, or 1)
        header -> dictionary output of read_header()
        side_info -> dictionary output of read_side_information()

    OUTPUT:
        OUT -> vector, (576,) containing the decoded values per frequency band
        prt -> integer, new pointer location in the bitstream
    '''
    print(side_info)
    big_values = side_info["big_values"][gr,ch]
    print(big_values)

    OUT = np.zeros(shape=(576,), dtype=np.int)

    ##### BIG VALUES FIRST!!! ############################################33
    region_band_idxs = [
        side_info["region0_count"][gr,ch],
        side_info["region1_count"][gr,ch],
    ]

    if side_info["block_type"][gr,ch] != 2:
        region_boundaries = [
            np.sum(LONG_BLOCKS[:side_info["region0_count"][gr,ch] + 1]),
            np.sum(LONG_BLOCKS[:side_info["region1_count"][gr,ch] + 1]),
        ]
    else:
        raise ValueError("have not coded region boundaries for block type 2 yet..")

    for i in range(0, big_values):
        #first, determine what region it is in:
        if i < region_boundaries[0]:
            region = 0
        elif i < region_boundaries[1]:
            region = 1
        else:
            region = 2      #if there are big values which exceed the boundary for region 1, they are assumed to be region 2

        huffman_table = main_tables[side_info["table_select"][gr,ch,region]]
        num_linbits = table_linbits[side_info["table_select"][gr,ch,region]]

        #### now increment the pointer until you reach a valid word...
        word = ""
        max_word_length = max(huffman_table.keys())     #note that the keys here are word lengths

        ### find the x value using the huffman codes:
        word_found = False
        for n in range(1,max_word_length+1):
            try:
                word += bitstream[ptr]; ptr += 1;
            except:
                print("failed at i={}, n={}, with word={}, ptr={}".format(i,n,word, ptr))
                print(side_info["table_select"][gr,ch,region])
                raise ValueError
            if n in huffman_table:
                if word in huffman_table[n]:
                    x_abs, y_abs = huffman_table[n][word]
                    word_found = True       #a way to tell that the bitstream exists in the huffman table...
            if word_found:
                break
        if not word_found:
            raise ValueError("the bitstream has no huffman table code...")

        #check if x exceeds 15, then make it the value described by the linbits next bits:
        if x_abs == 15:
            x_abs = int(bitstream[ptr: ptr + num_linbits], 2); ptr += num_linbits;
        #now check if x is nonzero. if so, the next bit gives you a sign (0 means positive, 1 means negative)
        if x_abs != 0:
            x_sign = int(bitstream[ptr: ptr + 1], 2); ptr += 1;
        else:
            x_sign = 0      #default, positive case... doesn't matter cus x is zero anyway
        x = x_abs * (-1 if x_sign == 1 else 1)

        ### find the y linbits and sign:
        if y_abs == 15:
            y_abs = int(bitstream[ptr: ptr + num_linbits], 2); ptr += num_linbits;
        if y_abs != 0:
            y_sign = int(bitstream[ptr: ptr + 1], 2); ptr += 1;
        else:
            y_sign = 0
        y = y_abs * (-1 if y_sign == 1 else 1)

        ### add the x and y values into the vector sequentially:
        OUT[i*2]        = x
        OUT[i*2 + 1]    = y
    ################################ BIG VALUES COMPLETED! #######################
    ################################ count1 region start: ########################

    huffman_table = table_B if side_info["count1table_select"][gr,ch] == 1 else table_A
    max_word_length = max(huffman_table.keys())

    for i in range( int((576-big_values*2) / 4) ):
        try:
            word_found = False
            word = ""
            for n in range(1,max_word_length+1):
                word += bitstream[ptr]; ptr += 1;
                if n in huffman_table:
                    if word in huffman_table[n]:
                        v_abs, w_abs, x_abs, y_abs = huffman_table[n][word]
                        word_found = True       #a way to tell that the bitstream exists in the huffman table...
                if word_found:
                    break
            if not word_found:
                raise ValueError("the bitstream has no huffman table code... was searching for i={} and current word={}".format(i, word))

            if v_abs != 0:
                v_sign = int(bitstream[ptr:ptr+1], 2); ptr += 1;
            else:
                v_sign = 0

            if w_abs != 0:
                w_sign = int(bitstream[ptr:ptr+1], 2); ptr += 1;
            else:
                w_sign = 0

            if x_abs != 0:
                x_sign = int(bitstream[ptr:ptr+1], 2); ptr += 1;
            else:
                x_sign = 0

            if y_abs != 0:
                y_sign = int(bitstream[ptr:ptr+1], 2); ptr += 1;
            else:
                y_sign = 0

            OUT[big_values*2 + i*4    ]     = v_abs * (-1 if v_sign else 1)
            OUT[big_values*2 + i*4 + 1]     = w_abs * (-1 if w_sign else 1)
            OUT[big_values*2 + i*4 + 2]     = x_abs * (-1 if x_sign else 1)
            OUT[big_values*2 + i*4 + 3]     = y_abs * (-1 if y_sign else 1)
        except IndexError:
            break       #this is probably the really common case where not the entire 576 table is coded in...

    ############################## finished with count1 region ########################

    return OUT
