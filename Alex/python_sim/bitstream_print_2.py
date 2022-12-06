from read_header import read_header, parse_frames, disp_frames
from read_frame import FIFO, get_main_data_bits, read_main
from side_info import read_side_information

import numpy as np

side_info_key_sizes = {
    "scfsi": 1,
    "part2_3_length": 12,
    "big_values": 9,
    "global_gain": 8,
    "mixed_block_flag": 1,
    "subblock_gain": 3,
    "scalefac_scale": 1,
    "scalefac_compress": 4,
    "window_switching_flag": 1,
    "block_type": 2,
    "table_select": 5,
    "region0_count": 4,
    "region1_count": 4,
    "preflag": 1,
    "count1table_select": 1
}       #this is the number of verilog bits dedicated to em

def array2hex(array, size):
    word = []
    for item in array.flatten():
        tmp = bin(item)[2:].zfill(size)
        word.append(tmp)
    inverted_word = "".join(word[::-1])
    num = hex(int(inverted_word,2))[2:]
    return num


####################### LOAD IN THE DATA ###########################################

file = "sample-3s.mp3"
binary_data = []
with open(file, 'rb') as f:
    for c in f.read():
        binary_data.append(bin(c)[2:])

print("the data is of length:", len(binary_data))

binary_string = ""
for thing in binary_data:
    binary_string += "0" * (8 - len(thing)) + thing

frames = parse_frames(binary_string)
print("first frame metadata:")
disp_frames(frames[0:1])

################## EXAMPLE CASE FOR THE FIFO_MUXER.sv MODULE  ########################################
# buffer = FIFO()
# for i, header in enumerate(frames):
#     # print("reading information for frame:", i+1)
#     nchannels = 1 if header["mode"] == 3 else 2
#     side_info_start = header["loc"] + 32 + (16 if header["prot"] == 0 else 0)
#     side_info, end_ptr = read_side_information(binary_string, side_info_start, nchannels)
#     main_data_bits = get_main_data_bits(binary_string, header, side_info, buffer)
#     output, ptr = read_main(main_data_bits, header, side_info, verbose = i ==241)
#
#     if i == 241:
#         for key in side_info:
#             try:
#                 print(key, side_info[key][0][0])
#             except TypeError:
#                 print(key, side_info[key])
#
#         # print("scalefact_l[0][0]:", array2hex(output["scalefac_l"][0][0], 4))
#         # print("scalefact_s[0][0]:", array2hex(output["scalefac_s"][0][0], 4))
#         # print()
#         # print("scalefact_l[0][1]:", array2hex(output["scalefac_l"][0][1], 4))
#         # print("scalefact_s[0][1]:", array2hex(output["scalefac_s"][0][1], 4))
#
#         # bits = main_data_bits
#         # hex_code = '{:0{}X}'.format(int(bits, 2), len(bits) // 4)
#         # print("main data bits (length={}):".format(len(bits)),hex_code)
#         #
#         # print('main data bits for gr=0 ch=1')
#         # bits = main_data_bits[side_info["part2_3_length"][0][0]:side_info["part2_3_length"][0][0] + side_info["part2_3_length"][0][1]]
#         # print(bits)
#         # print(len(bits))
#
#         for key in side_info:
#             if key in side_info_key_sizes:
#                 print(key, array2hex(side_info[key], side_info_key_sizes[key]))
#             else:
#                 print(key, side_info[key])
#
#         break

################## HUFFMAN DECODING TESTING ###########################
# lmao = np.array([0,4,8,12,16,20,24,30,36,44,52,62,74,90,110,134,162,196,238,288,342,418,576])
# print(lmao.shape[0] * 10)
# print("gband indices word:", array2hex(lmao, 10))
#
# lmao = np.array([0,4,8,12,16,22,30,40,52,66,84,106,136,192])
# print(lmao.shape[0] * 10)
# print("gband indices word:", array2hex(lmao, 10))


################## HUFFMAN MULTIPLEXER TESTING ########################
buffer = FIFO()
for i, header in enumerate(frames):
    nchannels = 1 if header["mode"] == 3 else 2
    side_info_start = header["loc"] + 32 + (16 if header["prot"] == 0 else 0)
    side_info, end_ptr = read_side_information(binary_string, side_info_start, nchannels)
    main_data_bits = get_main_data_bits(binary_string, header, side_info, buffer)
    output, ptr = read_main(main_data_bits, header, side_info, verbose = i == 81)

    if i == 81:
        print("\n\nside information for gr=0, ch=0")
        for key in side_info:
            try:
                print(key, side_info[key][0][0])
            except TypeError:
                print(key, side_info[key])

        print('\n\nhex values of total side information:')
        for key in side_info:
            if key in side_info_key_sizes:
                print(key, array2hex(side_info[key], side_info_key_sizes[key]))
            else:
                print(key, side_info[key])

        break
