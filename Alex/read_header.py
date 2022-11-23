'''
simplified codes to read in the header
limit scope to MPEG-1, Layer III, 44,100 hz fs
most is copied over from mp3_reader.py, but reformatted to work with the rest of hte code

STATUS: WORKING!
'''

def read_header(bitstream, ptr):
    '''
    blah blah
    INPUT:
        bitstream -> string of bits
        ptr -> integer, where the sync word supposedly starts
    OUTPUT:
        output -> dictionary mapping terms to their values
    '''
    orig_ptr_loc = ptr
    #collect data from header:
    sync    =   int(bitstream[ptr: ptr + 12], 2); ptr += 12;
    version =   int(bitstream[ptr: ptr + 1 ], 2); ptr += 1 ;
    layer   =   int(bitstream[ptr: ptr + 2 ], 2); ptr += 2 ;
    prot    =   int(bitstream[ptr: ptr + 1 ], 2); ptr += 1 ;
    brx     =   int(bitstream[ptr: ptr + 4 ], 2); ptr += 4 ;
    srx     =   int(bitstream[ptr: ptr + 2 ], 2); ptr += 2 ;
    pad     =   int(bitstream[ptr: ptr + 1 ], 2); ptr += 1 ;
    priv    =   int(bitstream[ptr: ptr + 1 ], 2); ptr += 1 ;
    mode    =   int(bitstream[ptr: ptr + 2 ], 2); ptr += 2 ;
    mode_ext=   int(bitstream[ptr: ptr + 2 ], 2); ptr += 2 ;
    copy    =   int(bitstream[ptr: ptr + 1 ], 2); ptr += 1 ;
    orig    =   int(bitstream[ptr: ptr + 1 ], 2); ptr += 1 ;
    emph    =   int(bitstream[ptr: ptr + 2 ], 2); ptr += 2 ;


    output = {
        "sync": sync,
        "version": mpeg_versions[2 + version],
        "layer": mpeg_layers[layer],
        "prot": prot,
        "bitrate": mpeg_bitrates[2 + version][layer][brx],
        "f_s": mpeg_srates[2 + version][srx],
        "pad": pad,
        "priv": priv,
        "mode": mode,
        "mode_ext": mode_ext,
        "copy": copy,
        "orig": orig,
        "emph": emph,
        "samples": mpeg_frame_samples[2 + version][layer],
        "slot": mpeg_slot_size[layer],
        "loc": orig_ptr_loc
    }

    return output

def parse_frames(bitstream):
    '''
    find the starts and frame sizes for all headers
    this seems to work perfectly now
    note that the frame size is all encompassing (the header, CRC, padding etc), just add the number to the current pointer
    also works now that we ensure another sync word shows up after the current frame
    gets exact timing
    '''
    frames = []
    start = 0
    while start < (len(bitstream) - 32):
        header_info = read_header(bitstream, start)

        if (header_info["sync"] == 4095) and (header_info["version"] == 1) and (header_info["layer"] == 3) and (header_info["f_s"] == 44100) and (header_info["bitrate"] != 0):
            bps = header_info["samples"] / 8.0
            bitrate = header_info["bitrate"]
            f_s = header_info["f_s"]
            slot_size = header_info["slot"]
            pad = header_info["pad"]
            prot = (header_info["prot"] != 1)

            fsize = int( ( (bps * bitrate * 1000) / f_s ) + (pad * slot_size) )
            header_info["size"] = fsize
            next = start + (fsize * 8)

            if next < (len(bitstream) - 32):
                next_header = read_header(bitstream, next)
            else:
                next_header = header_info   #shortcut, cant verify next frame if there is no space!
            if (next_header["sync"] == 4095):
                frames.append(header_info)
                start = next
            else:
                start += 1
        else:
            start += 1
    return frames

def disp_frames(frames):
    '''
    just helper function to print out the frames found by parse_frames()
    '''
    print("number of valid frames:", len(frames), "with estimated music time:", len(frames) * 26/1000,"s")
    for frame in frames:
        print("MPEG-", frame["version"], ", layer", frame["layer"], "bitrate:", frame["bitrate"], "size:", frame["size"])
        break
    return

#use [version]
mpeg_versions = [25, 0, 2, 1]

# [layer]
mpeg_layers = [0,3,2,1]

#use [version][layer][bitrate]
mpeg_bitrates = [
    [
        [0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0, 0 ],
        [0,   8,  16,  24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160, 0 ],
        [0,   8,  16,  24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160, 0 ],
        [0,  32,  48,  56,  64,  80,  96, 112, 128, 144, 160, 176, 192, 224, 256, 0 ]
    ],
    [
        [0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0, 0 ],
        [0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0, 0 ],
        [0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0, 0 ],
        [0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0, 0 ]
    ],
    [
        [0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0, 0 ],
        [0,   8,  16,  24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160, 0 ],
        [0,   8,  16,  24,  32,  40,  48,  56,  64,  80,  96, 112, 128, 144, 160, 0 ],
        [0,  32,  48,  56,  64,  80,  96, 112, 128, 144, 160, 176, 192, 224, 256, 0 ]
    ],
    [
        [0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0, 0 ],
        [0,  32,  40,  48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 0 ],
        [0,  32,  48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 384, 0 ],
        [0,  32,  64,  96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 0 ]
    ]
]

#user [version][srate]
mpeg_srates = [
    [11025, 12000, 8000, 0],
    [0, 0, 0, 0],
    [22050, 24000, 16000, 0],
    [44100, 48000, 32000, 0]
]

#use [version][layer]
mpeg_frame_samples = [
    [0, 576, 1152, 384],
    [0,   0,    0,   0],
    [0, 576, 1152, 384],
    [0, 1152, 1152, 384]
]

#use [layer]
mpeg_slot_size = [0, 1, 1, 4]


if __name__ == "__main__":
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
    disp_frames(frames)
    print("completed!")
