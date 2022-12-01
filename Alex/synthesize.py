'''
pretend code to put all the modules together
'''

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

buffer = FIFO()

for i, header in enumerate(frames):
    print("reading information for frame:", i+1)
    nchannels = 1 if header["mode"] == 3 else 2
    side_info_start = header["loc"] + 32 + (16 if header["prot"] == 0 else 0)
    side_info, end_ptr = read_side_information(binary_string, side_info_start, nchannels)
    main_data_bits = get_main_data_bits(binary_string, header, side_info, buffer)
    read_main(main_data_bits, header, side_info)
