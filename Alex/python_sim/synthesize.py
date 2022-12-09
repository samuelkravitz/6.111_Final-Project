'''
pretend code to put all the modules together
'''

from read_header import read_header, parse_frames, disp_frames
from read_frame import FIFO, get_main_data_bits, read_main
from side_info import read_side_information
from requantizer import requantizer, reorder, stereo

import numpy as np

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
print("number of frames:", len(frames))

buffer = FIFO()

for i, header in enumerate(frames[0:2]):
    print("reading information for frame:", i+1)
    nchannels = 1 if header["mode"] == 3 else 2
    side_info_start = header["loc"] + 32 + (16 if header["prot"] == 0 else 0)
    side_info, end_ptr = read_side_information(binary_string, side_info_start, nchannels)
    main_data_bits = get_main_data_bits(binary_string, header, side_info, buffer)
    main_data, ptr = read_main(main_data_bits, header, side_info, verbose=False)
    requantized_output = requantizer(main_data, side_info, header)
    reordered_output = reorder(requantized_output, side_info, header)
    stereo_output = stereo(reordered_output, main_data, side_info, header)
    print("\n\n\n")
    for gr in range(2):
        for ch in range(2):
            print("gr={}, ch={}:".format(gr,ch))
            print("stereo output:")
            lmao = "["
            for item in stereo_output[gr,ch]:
                lmao += str(item) + " "
            lmao += "]"
            print(lmao)
