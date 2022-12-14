### you can assume now that the file is MPEG 1 Layer 3
### because that is the definition of a .mp3 file apparently...
### this saves some casework i think

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

def mpg_get_frame_size(header):
    '''
    idk some stolen code from stack overflow, check shit.c
    somehow picks up a 0 sample rate and then the divide fails...
    this should be prevented by the validity check in the beginning, right?
    check this later!!!
    '''

    #validity check:
    if  (   (hex(int(header[0:11],2)) != '0x7ff') or
            (header[11:13] == '01') or
            (header[13:15] == '00') or
            (header[16:20] == '1111') or
            (header[20:22] == '11') ):
        return 0, None, None, None, None, None, None        #this means something is wrong about the header or we cant interpret it!

    #collect data from header:
    sync    =   int(header[0:11],2)
    version =   int(header[11:13],2)
    layer   =   int(header[13:15],2)
    pad     =   int(header[22],2)
    brx     =   int(header[16:20],2)
    srx     =   int(header[20:22],2)
    prot    =   (int(header[15],2) != 1)       ###Here a prot_bit == 1 means there is no checksum

    if (mpeg_versions[version] != 1) or (mpeg_layers[layer] != 3) or (srx != 0):
        return 0, None, None, None, None, None, None

    bitrate     =   mpeg_bitrates[version][layer][brx]
    samprate    =   mpeg_srates[version][srx]
    samples     =   mpeg_frame_samples[version][layer]
    slot_size   =   mpeg_slot_size[layer]

    bps = samples / 8.0
    try:
        fsize = (( (bps * bitrate * 1000) / samprate ) + (pad * slot_size))         #without multiplying by 8, it is the number of bytes!
    except:
        print("FAILED: DIAGNOSTIC:")
        print("version:",mpeg_versions[version], "layer:",mpeg_layers[layer], "samprate:",samprate)
        print(version, layer, pad, brx, srx)
        raise ValueError
    return int(fsize), mpeg_versions[version], mpeg_layers[layer], bitrate, samprate, prot, pad

def sift_frames(mp3_bits):
    '''
    if the predicted frame size is greater than 0, that means the frame starting at 'start' is a valid mpeg-1 layer III frame
    the protection bit adds 16 bits to the end of the frame.
    '''
    print("sifting frames...")
    end = len(mp3_bits)
    start = 0

    num_frames = 0

    while (start < end):
        header = mp3_bits[start:start + 32]

        fsize, version, layer, bitrate, samprate, prot, pad = mpg_get_frame_size(header)

        if fsize > 0:
            num_frames += 1
            print("version:",version, "layer:",layer, "bitrate:",bitrate, "samprate:",samprate, "frame size:",fsize, "protected:", prot, "padded:", pad)
            start += 32 + (fsize * 8) + (16 * prot)     #fsize output is in bytes, 16 bit checksums may exist too.
        else:
            start += 1

    print("final number of frames:", num_frames)
    print('estimated sound time:', num_frames * 26/1000)


if __name__ == "__main__":
    file = "sample-3s.mp3"

    from mutagen.mp3 import MP3
    print('ground truth:')
    f = MP3(file)
    print(vars(f.info))

    binary_data = []
    with open(file, 'rb') as f:
        for c in f.read():
            binary_data.append(bin(c)[2:])

    print("the data is of length:", len(binary_data))

    binary_string = ""
    for thing in binary_data:
        binary_string += "0" * (8 - len(thing)) + thing

    sift_frames(binary_string)
