'''
produce a mem file of the 3s song:
'''

from read_header import read_header, parse_frames, disp_frames
from read_frame import FIFO, get_main_data_bits, read_main
from side_info import read_side_information

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

file = open("mp3_song.mem", "w")

for i, header in enumerate(frames):
    print("reading information for frame:", i+1)
    frame_bits = binary_string[header["loc"]:header["loc"] + (8 * header["size"])]
    num_bytes = len(frame_bits) // 8
    print("frame", i, "has", num_bytes, "bytes")
    for j in range(512):
        #write a byte:
        if j < num_bytes:
            tmp = hex(int(frame_bits[j * 8: (j+1) * 8],2)).zfill(2)[2:]
        else:
            tmp = "00"
        file.write("{}\n".format(tmp))
file.close()
