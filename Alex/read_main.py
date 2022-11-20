'''
code dedicated to reading in the main info as defined by the ISO standard
this is the huffman bits etc
very tricky starting and ending place.
'''
import numpy as np

def read_main_data(bitstream, header, side_info):
    '''
    read in the scaling factors, quantized huffman codes, and ancillary bits from the main information packet
    note that this is exceedingly complicated because the start of the information
    can fall back more than one frame before. this function will assume ONLY the data is present in the bitstream
    the only real guarantee i see is that the data for a specific frame must be finished (in the bitstream)
    by the end of its frame. but it can start in the frame before (or 2 frames before, or more maybe...)

    ARGS:
        bitstream -> string of 1s and 0s, note that this is different from before. instead of the whole bitstream, this should be
                        the entire frame's bitstream (because it may be broken up among many frames, and i don't want this function to have to deal with it yet)
        header -> dictionary output of the read_header() function. contains important metadata (namely, number of channels, under the 'mode' number)
        side_info -> dictionary output of the read_side_information() function. contains important metadata:
                                                                            scalefac_compress, window_switching_flag, block_type, scfsi
    '''
    if header["mode"] == 3:
        nchannels = 1
    else:
        nchannels = 2   #assume that joint stereo, stereo, and dual channel are all 2 channels
    #define 2 2D arrays:
    scalefac_l = np.zeros(shape=(2,nchannels,21), dtype=np.uint16)        #note that the 3rd dimension may only need 8 bits depending on the window, needs all 21 if window is normal or block type is normal
    scalefac_s = np.zeros(shape=(2,nchannels,12,3), dtype=np.uint16)     #also might contain extraneous bits...

    for gr in range(2):
        for ch in range(nchannels):
            bitlength_1 = slen1[side_info["scalefac_compress"]][gr,ch]
            bitlength_2 = slen2[side_info["scalefac_compress"]][gr,ch]      #these are used for difference scalefactor bands depending on the window and block type

            if (side_info["window_switching_flag"][gr,ch] == 1) and (side_info["block_type"][gr,ch] == 2):
                if side_info["mixed_block_flag"] == 1:
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
            huffmancodebits()
    for b in range(no_ancillary_bits):
        ancillary_bit = int(bitstream[ptr: ptr + 1], 2); ptr += 1;      #i think this is just to kill bit space. manual has it overwriting itself too.

    output = {
        "scalefac_l": scalefac_l,
        "scalefac_s": scalefac_s,
        "ancillary_bit": ancillary_bit
    }
    return output, ptr

def huffmancodebits():
    '''
    supposed to emulate the huffmancodebits function defined in the ISO manual
    '''
    raise NotImplementedError

slen1 = [0,0,0,0,3,1,1,1,2,2,2,3,3,3,4,4]   #both taken from page 32 of ISO pdf
slen2 = [0,1,2,3,0,1,2,3,1,2,3,1,2,3,2,3]   #used to determine the bit size of scalefac_l and scalefac_s (long and short scalefactors)
