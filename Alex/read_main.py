'''
code dedicated to reading in the main info as defined by the ISO standard
this is the huffman bits etc
very tricky starting and ending place.
'''
import numpy as np

def read_main_data(bitstream, header, side_info):
    '''
    read in the quantized huffman codes from the main information packet
    note that this is exceedingly complicated because the start of the information
    can fall back more than one frame before.
    the only real guarantee i see is that the data for a specific frame must be finished (in the bitstream)
    by the end of its frame. but it can start in the frame before (or 2 frames before, or more maybe...)
    '''
    
    raise NotImplementedError
