'''
attempt number 2 at extracting the huffman codes and scalefactors from
data.

STATUS: Working???
'''

from huffman_LUT import main_tables, table_A, table_B, table_linbits
import numpy as np

def integer(str_in, base):
    '''
    defaults on the empty string to 0 because this is giving me trouble...
    '''
    if len(str_in) == 0:
        return 0
    return int(str_in, base)


def print_in_bytes(in_str):
    assert len(in_str) % 8 == 0

    out = "["
    for i in range(len(in_str) // 8):
        tmp = in_str[i*8:(i+1)*8]
        out += str(int(tmp,2)) + " "
    print(out + "]")

def print_array_without_commas(array):
    a = array.flatten()
    out = "["
    for item in a:
        out += str(item) + " "
    return out + "]"

class FIFO():
    def __init__(self):
        '''
        buffer is structured so the first item in the list is the first thing ever put in
        the last item in the list is the last thing ever put in
        '''
        self.buffer = ""
        self.buffer_size = 0

    def add(self, bits):
        '''
        bits is a string of 1s and 0s
        '''
        self.buffer += bits
        self.buffer_size += len(bits)

    def get(self, numbits):
        '''
        extracts the number of bits specified from the buffer
        '''
        if numbits > self.buffer_size:
            raise ValueError("requested more bits than available from buffer")
        elif numbits < 0:
            raise ValueError("requested negative number of bits")
        output = self.buffer[0:numbits]
        self.buffer = self.buffer[numbits:]
        self.buffer_size -= numbits
        return output

def get_main_data_bits(bitstream, header, side_info, fifo_buffer):
    '''
    uses a FIFO buffer (class implemented above) to retrieve the right number of main_data bits
    '''
    side_info_size = 17 if header["mode"] == 3 else 32
    crc_prot_size = 0 if header["prot"] == 1 else 2

    #assemble this frame's main data:
    #first, remove all bits that come before the offset from the fifo buffer...
    num_main_data_bits = np.sum(side_info["part2_3_length"])
    num_discard_bits = fifo_buffer.buffer_size - (side_info["main_data_begin"] * 8)     #safe to discard any bits in buffer before the offset

    discard_bits = fifo_buffer.get(num_discard_bits)

    frame_data_start = header["loc"] + 8 *(4 + side_info_size + crc_prot_size)
    frame_data_end = header["loc"] + (8 * header["size"])

    frame_data = bitstream[frame_data_start: frame_data_end]
    fifo_buffer.add(frame_data)

    OUT = fifo_buffer.get(num_main_data_bits)
    return OUT


def read_main(main_data_bitstream, header, side_info):
    '''
    slightly modified from the last version (in read_main.py)
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
            data_length     = side_info["part2_3_length"][gr,ch]    #number of bits used for this granule and channel
            bitstream       = main_data_bitstream[ptr_start:ptr_start + data_length]      #constructs the bitstream specific to the granule and channel

            bitlength_1 = slen1[side_info["scalefac_compress"][gr,ch]]
            bitlength_2 = slen2[side_info["scalefac_compress"][gr,ch]]      #these are used for difference scalefactor bands depending on the window and block type

            ptr = 0
            if (side_info["window_switching_flag"][gr,ch] == 1) and (side_info["block_type"][gr,ch] == 2):
                if side_info["mixed_block_flag"][gr,ch] == 1:
                    for sfb in range(8):
                        scalefac_l[gr,ch,sfb]                       = integer(bitstream[ptr: ptr + bitlength_1], 2); ptr += bitlength_1;
                    for sfb in range(3,12):
                        for window in range(3):
                            if sfb < 6:
                                scalefac_s[gr,ch,sfb,window]        = integer(bitstream[ptr: ptr + bitlength_1], 2); ptr += bitlength_1;
                            else:
                                scalefac_s[gr,ch,sfb,window]        = integer(bitstream[ptr: ptr + bitlength_2], 2); ptr += bitlength_2;
                else:
                    #this means the mixed_block_flag is 0, so the bitlengths are different and only scalefac_s is used (pg 24)
                    for sfb in range(12):
                        for window in range(3):
                            if sfb < 6:
                                scalefac_s[gr,ch,sfb,window]        = integer(bitstream[ptr: ptr + bitlength_1], 2); ptr += bitlength_1;
                            else:
                                scalefac_s[gr,ch,sfb,window]        = integer(bitstream[ptr: ptr + bitlength_2], 2); ptr += bitlength_2;
            else:
                if   (side_info["scfsi"][ch][0] == 0) or (gr == 0):
                    for sfb in range(6):
                        scalefac_l[gr,ch,sfb]                       = integer(bitstream[ptr: ptr + bitlength_1], 2); ptr += bitlength_1;
                elif (side_info["scfsi"][ch][0] == 1) and (gr == 1):
                    for sfb in range(6):
                        scalefac_l[1,ch,sfb]                       = scalefac_l[0,ch,sfb]       #copy the scalefactors over

                if   (side_info["scfsi"][ch][1] == 0) or (gr == 0):
                    for sfb in range(6,11):
                        scalefac_l[gr,ch,sfb]                      = integer(bitstream[ptr: ptr + bitlength_1], 2); ptr += bitlength_1;
                elif (side_info["scfsi"][ch][1] == 1) and (gr == 1):
                    for sfb in range(6,11):
                        scalefac_l[1,ch,sfb]                       = scalefac_l[0,ch,sfb]       #copy the scalefactors over

                if   (side_info["scfsi"][ch][2] == 0) or (gr == 0):
                    for sfb in range(11,16):
                        scalefac_l[gr,ch,sfb]                       = integer(bitstream[ptr: ptr + bitlength_2], 2); ptr += bitlength_2;
                elif (side_info["scfsi"][ch][2] == 1) and (gr == 1):
                    for sfb in range(11,16):
                        scalefac_l[1,ch,sfb]                       = scalefac_l[0,ch,sfb]       #copy the scalefactors over

                if   (side_info["scfsi"][ch][3] == 0) or (gr == 0):
                    for sfb in range(16,21):
                        scalefac_l[gr,ch,sfb]                      = integer(bitstream[ptr: ptr + bitlength_2], 2); ptr += bitlength_2;
                elif (side_info["scfsi"][ch][3] == 1) and (gr == 1):
                    for sfb in range(16,21):
                        scalefac_l[1,ch,sfb]                       = scalefac_l[0,ch,sfb]       #copy the scalefactors over

            IS[gr,ch,:] = huffmancodebits(bitstream[ptr:ptr_start + data_length], 0, gr, ch, header, side_info)     ####NOTE: now this only passes in the data for a granule and channel, no more. ptr for it is set to 0
            
            if ptr > ptr_start + data_length:
                raise ValueError("somehow exceeded the number of bits alloted to this shit...")
            else:
                ptr_start += data_length #this makes sure we skip any extra ancillary bits at the end!!!

    output = {
        "scalefac_l": scalefac_l,
        "scalefac_s": scalefac_s,
        "IS" : IS
    }
    return output, ptr

def huffmancodebits(bitstream, ptr, gr, ch, header, side_info):
    '''
    another revised version of the function from read_main.py
    taken from the PDMP3 library (in C)
    '''
    OUT = np.zeros(shape=(576,), dtype=np.int)

    if side_info["part2_3_length"][gr,ch] == 0:
        return OUT      #just return all 0s in the case where there is no data...

    #determine the region boundaries
    if (side_info["window_switching_flag"][gr,ch] == 1) and (side_info["block_type"][gr,ch] == 2):
        region_1_start = 36
        region_2_start = 576
    else:
        region_1_start = g_sf_band_indices_l[side_info["region0_count"][gr,ch] + 1                                  ]
        region_2_start = g_sf_band_indices_l[side_info["region0_count"][gr,ch] + 1 + side_info["region1_count"][gr,ch] + 1   ]

    #read big values according to the region_x_start:
    for is_pos in range(0, side_info["big_values"][gr,ch] * 2, 2):
        if (is_pos < region_1_start):
            table_num = side_info["table_select"][gr,ch][0]
        elif (is_pos < region_2_start):
            table_num = side_info["table_select"][gr,ch][1]
        else:
            table_num = side_info["table_select"][gr,ch][2]

        try:
            x, y, ptr = huffman_decode_bigvalues(bitstream, ptr, table_num)
        except:
            print("big value decoding failed at is_pos = ", is_pos)
            print("table number: {}, is_pos: {}, gr: {}, ch: {}".format(table_num, is_pos, gr, ch))
            print("current OUT buffer:")
            print(print_array_without_commas(OUT[0:is_pos]))
            raise IndexError

        OUT[is_pos] = x
        OUT[is_pos + 1] = y

    #read count1 region values...
    table_num = side_info["count1table_select"][gr,ch]          ##for some reason this line was missing, but i can't find the difference it makes in my test cases.
    for is_pos in range(side_info["big_values"][gr,ch] * 2, 576, 4):
        try:
            v,w,x,y,ptr     = huffman_decode_count1_values(bitstream, ptr, table_num)

            OUT[is_pos    ] = v
            OUT[is_pos + 1] = w
            OUT[is_pos + 2] = x
            OUT[is_pos + 3] = y
        except:
            break       #we don't need to expect all values to be accounted for here... in fact, it is abnormal for all values to be accounted for
    return OUT

def huffman_decode_bigvalues(bitstream, ptr, table_num):
    huffman_table = main_tables[table_num]
    num_linbits = table_linbits[table_num]

    #### now increment the pointer until you reach a valid word...
    word = ""
    max_word_length = max(huffman_table.keys())     #note that the keys here are word lengths

    ### find the x value using the huffman codes:
    word_found = False
    for n in range(1,max_word_length+1):
        word += bitstream[ptr]; ptr += 1;
        if n in huffman_table:
            if word in huffman_table[n]:
                x_abs, y_abs = huffman_table[n][word]
                word_found = True       #a way to tell that the bitstream exists in the huffman table...
        if word_found:
            break
    if not word_found:
        print("failed to find a huffman table code...")
        print("(big values) table number:",table_num)
        print("current word:", word)
        raise ValueError("the bitstream has no huffman table code...")

    #check if x exceeds 15, then make it the value described by the linbits next bits:
    if x_abs == 15:
        x_abs = 15 + integer(bitstream[ptr: ptr + num_linbits], 2); ptr += num_linbits;
    #now check if x is nonzero. if so, the next bit gives you a sign (0 means positive, 1 means negative)
    if x_abs != 0:
        x_sign = int(bitstream[ptr: ptr + 1], 2); ptr += 1;
    else:
        x_sign = 0      #default, positive case... doesn't matter cus x is zero anyway
    x = x_abs * (-1 if x_sign == 1 else 1)

    ### find the y linbits and sign:
    if y_abs == 15:
        y_abs = 15 + integer(bitstream[ptr: ptr + num_linbits], 2); ptr += num_linbits;
    if y_abs != 0:
        y_sign = int(bitstream[ptr: ptr + 1], 2); ptr += 1;
    else:
        y_sign = 0
    y = y_abs * (-1 if y_sign == 1 else 1)

    return x, y, ptr

def huffman_decode_count1_values(bitstream, ptr, table_num):
    '''
    helper code to decode huffman values for the count1 region
    table_num -> either 0 or 1, corresponds to table A or table B
    returns 5 values -- (v,w,x,y) and the pointer (location in given bitstream).
    note that we also halfway expect this to throw an error, because most of the time the entire
    spectrum is not coded for.
    '''
    assert table_num in (0,1)
    huffman_table = table_B if table_num == 1 else table_A
    max_word_length = max(huffman_table.keys())

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

    v = v_abs * (-1 if v_sign == 1 else 1)
    w = w_abs * (-1 if w_sign == 1 else 1)
    x = x_abs * (-1 if x_sign == 1 else 1)
    y = y_abs * (-1 if y_sign == 1 else 1)

    return v,w,x,y,ptr


slen1 = [0,0,0,0,3,1,1,1,2,2,2,3,3,3,4,4]   #both taken from page 32 of ISO pdf
slen2 = [0,1,2,3,0,1,2,3,1,2,3,1,2,3,2,3]   #used to determine the bit size of scalefac_l and scalefac_s (long and short scalefactors)

g_sf_band_indices_l = [0,4,8,12,16,20,24,30,36,44,52,62,74,90,110,134,162,196,238,288,342,418,576]
g_sf_band_indices_s = [0,4,8,12,16,22,30,40,52,66,84,106,136,192]
