from read_header import read_header, parse_frames, disp_frames
from read_frame import FIFO, get_main_data_bits, read_main
from side_info import read_side_information

import numpy as np

file = "file_example_MP3_1MG.mp3"
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

header = frames[4]


##################### PRINT OUT A HEADER FOR TESTING!
# frame_bits = binary_string[header["loc"]: header["loc"] + 32]
# print("binary code of header: \n",frame_bits, "\ncoming in at length", len(frame_bits))
# print(header)


################### PRINT OUT AN ENTIRE FRAME IN HEX FOR TESTING
# frame_bits = binary_string[header["loc"]: header["loc"] + 8*(header["size"])]
# frame_bytes = ""
# for i in range(header["size"]):
#     tmp = frame_bits[8*i:8*(i+1)]
#     frame_bytes += str(hex(int(tmp,2))[2:]).zfill(2)
# print("hex code of frame:\n", frame_bytes, "\ncoming in at length", len(frame_bytes))
# print(header)



#################### PRINT OUT SIDE INFORMATION IN HEX FOR TESTING
# nchannels = 1 if header["mode"] == 3 else 2
# side_info_start = header["loc"] + 32 + (16 if header["prot"] == 0 else 0)
# side_info, end_ptr = read_side_information(binary_string, side_info_start, nchannels)
# side_info_bits = binary_string[side_info_start: side_info_start + 8 * (17 if nchannels == 1 else 32)]
#
# frame_bytes = ""
# for i in range((17 if nchannels == 1 else 32)):
#     tmp = side_info_bits[8*i:8*(i+1)]
#     frame_bytes += str(hex(int(tmp,2))[2:]).zfill(2)
# print("hex code of side info:\n", frame_bytes, "\ncoming in at length", len(frame_bytes))
#
# side_info_key_sizes = {
#     "scfsi": 1,
#     "part2_3_length": 12,
#     "big_values": 9,
#     "global_gain": 8,
#     "mixed_block_flag": 1,
#     "subblock_gain": 3,
#     "scalefac_scale": 1,
#     "scalefac_compress": 4,
#     "window_switching_flag": 1,
#     "block_type": 2,
#     "table_select": 5,
#     "region0_count": 4,
#     "region1_count": 4,
#     "preflag": 1,
#     "count1table_select": 1
# }       #this is the number of verilog bits dedicated to em
# for key in sorted(side_info.keys()):
#     #now reconstruct the information as backward hex values:
#     if not isinstance(side_info[key], int):
#         size = side_info_key_sizes[key]
#         array_shape = side_info[key].shape
#         dims = list(range(len(array_shape)))[::-1]  #invert the order of the dimensions too
#         word = []
#
#         for item in side_info[key].flatten():
#             tmp = bin(item)[2:].zfill(size)
#             word.append(tmp)
#         inverted_word = "".join(word[::-1])
#         num = hex(int(inverted_word,2))[2:]
#         print(key, num)
#     else:
#         print(key, hex(side_info[key])[2:])



################## PRINT OUT EXAMPLE SCALEFACTOR CODES WITH THEIR METADATA ########
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
    print(word,"what is this?")
    inverted_word = "".join(word[::-1])
    num = hex(int(inverted_word,2))[2:]
    return num

# buffer = FIFO()
# for i, header in enumerate(frames):
#     print("reading information for frame:", i+1)
#     nchannels = 1 if header["mode"] == 3 else 2
#     side_info_start = header["loc"] + 32 + (16 if header["prot"] == 0 else 0)
#     side_info, end_ptr = read_side_information(binary_string, side_info_start, nchannels)
#     main_data_bits = get_main_data_bits(binary_string, header, side_info, buffer)
#     output, ptr = read_main(main_data_bits, header, side_info)
#
#     if (side_info["window_switching_flag"][0][0] == 1) and (side_info["block_type"][0][0] == 2) and (side_info["mixed_block_flag"][0][0] == 0) and (side_info["scalefac_compress"][0][0] > 0):
#
#         for key in side_info:
#             try:
#                 print(key, side_info[key][0][0])
#             except TypeError:
#                 print(key, side_info[key])
#
#         print("scalefact_l:", array2hex(output["scalefac_l"][0][0], 4))
#         print("scalefact_s:", array2hex(output["scalefac_s"][0][0], 4))
#
#         # print("scalefact_l:", output["scalefac_l"][0][0])
#         # print("scalefact_s:", output["scalefac_s"][0][0])
#         bits = main_data_bits[:side_info["part2_3_length"][0][0]]
#         print(bits)
#         print(len(bits))
#
#         break

buffer = FIFO()
for i, header in enumerate(frames):
    print("reading information for frame:", i+1)
    nchannels = 1 if header["mode"] == 3 else 2
    side_info_start = header["loc"] + 32 + (16 if header["prot"] == 0 else 0)
    side_info, end_ptr = read_side_information(binary_string, side_info_start, nchannels)
    main_data_bits = get_main_data_bits(binary_string, header, side_info, buffer)
    output, ptr = read_main(main_data_bits, header, side_info)

    if (side_info["window_switching_flag"][0][0] == 1) and (side_info["block_type"][0][0] == 2) and (side_info["mixed_block_flag"][0][0] == 1) and (side_info["scalefac_compress"][0][0] > 0):

        for key in side_info:
            try:
                print(key, side_info[key][0][0])
            except TypeError:
                print(key, side_info[key])

        print("scalefact_l:", array2hex(output["scalefac_l"][0][0], 4))
        print("scalefact_s:", array2hex(output["scalefac_s"][0][0], 4))

        # print("scalefact_l:", output["scalefac_l"][0][0])
        # print("scalefact_s:", output["scalefac_s"][0][0])
        bits = main_data_bits[:side_info["part2_3_length"][0][0]]
        print(bits)
        print(len(bits))

        break
