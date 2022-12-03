'''
taken from ISO manual page 69 (table B.8b), the scalefactor band's respective indices (in the 576 freqeuncy vector)
for 44.1kHz sampling
note that these are used for the big value regions i believe...
'''

import numpy as np

#note that these are the band widths, so band one is from [0-3] inclusive (first four entries of the 576 frequency vector)
LONG_BLOCKS = [4,4,4,4,4,4,6,6,8,8,10,12,16,20,24,28,34,42,50,54,76]    #there are 21 bands

SHORT_BLOCKS = [4,4,4,4,6,8,10,12,14,18,22,30]      #thre are 12 bands
