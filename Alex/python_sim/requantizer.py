import numpy as np

LONG_sf_band_idx = [0, 4, 8, 12, 16, 20, 24, 30, 36, 44, 52, 62, 74, 90, 110, 134, 162, 196, 238, 288, 342, 418, 576]   #bin (of 576) indices corresponding to boundaries of sf bands
SHORT_sf_band_idx = [0, 4, 8, 12, 16, 22, 30, 40, 52, 66, 84, 106, 136, 192]
#for example, LONG band 1 goes from bin 0 to 3 (inclusive) but band 2 starts at 4.
#the short bands are a bit weirder:
#each the delta from one index to the next is the number of bins in a window,
#but each sfb has 3 windows, so the number of bins in a single sfb is 3 * the delta from oen index to the next

pretab = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 3, 3, 3, 2, 0]


def requantizer(main_data, side_info, header, verbose =False):
    '''
    main_data -> dictionary containing the IS and scalefactors
    side_info -> dictionary containing the side information
    header -> dictionary containing the header information

    STATUS: WORKING (12/6/22)
    '''
    if verbose:
        print("fuck")
    if header["mode"] == 3:
        nchannels = 1
    else:
        nchannels = 2   #assume that joint stereo, stereo, and dual channel are all 2 channels

    OUT = np.zeros(shape=(2, nchannels, 576), dtype=np.float32)

    for gr in range(2):
        for ch in range(nchannels):
            if (side_info["window_switching_flag"][gr,ch] and (side_info["block_type"][gr,ch] == 2)):
                if (side_info["mixed_block_flag"][gr,ch] != 0):
                    ## process the long bands first:
                    sfb = 0
                    for i in range(36):
                        if (i == LONG_sf_band_idx[sfb + 1]):
                            sfb += 1
                        x = main_data["IS"][gr,ch,i]

                        scalefac_multiplier = 0.5 if (side_info["scalefac_scale"][gr,ch] == 0) else 1.0
                        exp1 = 0.25 * (side_info["global_gain"][gr,ch] - 210)
                        exp2 = -(scalefac_multiplier * (main_data["scalefac_l"][gr,ch,sfb] + side_info["preflag"][gr,ch]*pretab[sfb]))

                        OUT[gr,ch,i] = np.sign(x) * (np.abs(x)**(4.0/3.0)) * (2**(exp1 + exp2))
                    #now process the short bands that come after it:
                    sfb = 3
                    i = 36
                    while i < (2 * side_info["big_values"][gr,ch]):
                        if (i == SHORT_sf_band_idx[sfb + 1] * 3):
                            sfb += 1
                        win_len = SHORT_sf_band_idx[sfb + 1] - SHORT_sf_band_idx[sfb]

                        for win in range(3):
                            for j in range(win_len):
                                x = main_data["IS"][gr,ch,i]

                                scalefac_multiplier = 0.5 if (side_info["scalefac_scale"][gr,ch] == 0) else 1.0
                                exp1 = 0.25 * (side_info["global_gain"][gr,ch] - 210 - 8*side_info["subblock_gain"][gr,ch,win])
                                exp2 = -(scalefac_multiplier * (main_data["scalefac_s"][gr,ch,sfb,win]))

                                OUT[gr,ch,i] = np.sign(x) * (np.abs(x) ** (4.0/3.0)) * (2**(exp1 + exp2))
                                i += 1
                else:
                    #mixed block flag is 0:
                    #note that there are only short blocks here
                    sfb = 0
                    i = 0
                    while i < (2 * side_info["big_values"][gr,ch]):
                        if (i == SHORT_sf_band_idx[sfb + 1] * 3):
                            sfb += 1
                        win_len = SHORT_sf_band_idx[sfb + 1] - SHORT_sf_band_idx[sfb]

                        for win in range(3):
                            for j in range(win_len):
                                x = main_data["IS"][gr,ch,i]

                                scalefac_multiplier = 0.5 if (side_info["scalefac_scale"][gr,ch] == 0) else 1.0
                                exp1 = 0.25 * (side_info["global_gain"][gr,ch] - 210 - 8*side_info["subblock_gain"][gr,ch,win])
                                exp2 = -(scalefac_multiplier * (main_data["scalefac_s"][gr,ch,sfb,win]))

                                OUT[gr,ch,i] = np.sign(x) * (np.abs(x) ** (4.0/3.0)) * (2**(exp1 + exp2))
                                i += 1
            else:
                #either win switch flag is 0 or block type is not 2:
                #note that there are only long blocks here
                sfb = 0
                for i in range(0, 2 * side_info["big_values"][gr,ch]):
                    if (i == LONG_sf_band_idx[sfb + 1]):
                        sfb += 1
                    x = main_data["IS"][gr,ch,i]

                    scalefac_multiplier = 0.5 if (side_info["scalefac_scale"][gr,ch] == 0) else 1.0
                    exp1 = 0.25 * (side_info["global_gain"][gr,ch] - 210)
                    exp2 = -(scalefac_multiplier * (main_data["scalefac_l"][gr,ch,sfb] + side_info["preflag"][gr,ch]*pretab[sfb]))
                    if ((i == 4) and verbose):
                        print("Okay here:")
                        print(np.abs(x), (np.abs(x) ** (4.0/3.0)), exp1 + exp2, main_data["scalefac_l"][gr,ch,sfb], sfb, scalefac_multiplier)
                        print(main_data["scalefac_l"][gr,ch])

                    OUT[gr,ch,i] = np.sign(x) * (np.abs(x)**(4.0/3.0)) * (2**(exp1 + exp2))


    return OUT

def reorder(IN, side_info, header):
    '''
    not totally sure what im supposed to do here, will hope for the best
    '''
    if header["mode"] == 3:
        nchannels = 1
    else:
        nchannels = 2   #assume that joint stereo, stereo, and dual channel are all 2 channels

    OUT = np.zeros(shape = (2, nchannels, 576), dtype=np.float32)

    for gr in range(2):
        for ch in range(nchannels):
            if (side_info["window_switching_flag"][gr,ch] and (side_info["block_type"][gr,ch] == 2)):
                if (side_info["mixed_block_flag"][gr,ch] != 0):
                    sfb = 3     #key here is that it starts at 3
                    j = 0
                    win = 0
                    for i in range(576):
                        if not (i < 2 * side_info["big_values"][gr,ch]):
                            OUT[gr,ch,i] = IN[gr,ch,i]
                        elif (i < 36):
                            OUT[gr,ch,i] = IN[gr,ch,i]  #no reordering for those long blongs in the beginning
                        else:
                            if i == SHORT_sf_band_idx[sfb + 1] * 3:
                                sfb += 1        #recompute these parameters for the rest of the for loop
                                j = 0
                                win = 0 #reset these because the new subband means restarting at window 0 and index 0

                            win_len = SHORT_sf_band_idx[sfb + 1] - SHORT_sf_band_idx[sfb]
                            OUT[gr,ch,SHORT_sf_band_idx[sfb] * 3 + (3*j + win)] = IN[gr,ch,i]

                            if (j + 1 == win_len):
                                win += 1        #of course if this is already 2, you want it to go to 0, but the abovce conditional already takes care of that.
                                j = 0       #reset the j, increment the window up one.
                            else:
                                win = win
                                j += 1
                else:
                    sfb = 0     #this marks the first subband that has short blocks
                    j = 0
                    win = 0
                    for i in range(576):
                        if not (i < 2 * side_info["big_values"][gr,ch]):
                            OUT[gr,ch,i] = IN[gr,ch,i]
                        else:
                            if i == SHORT_sf_band_idx[sfb + 1] * 3:
                                sfb += 1        #recompute these parameters for the rest of the for loop
                                j = 0
                                win = 0 #reset these because the new subband means restarting at window 0 and index 0

                            win_len = SHORT_sf_band_idx[sfb + 1] - SHORT_sf_band_idx[sfb]
                            OUT[gr,ch,SHORT_sf_band_idx[sfb] * 3 + (3*j + win)] = IN[gr,ch,i]

                            if (j + 1 == win_len):
                                win += 1        #of course if this is already 2, you want it to go to 0, but the abovce conditional already takes care of that.
                                j = 0       #reset the j, increment the window up one.
                            else:
                                win = win
                                j += 1

            else:
                OUT[gr,ch] = IN[gr,ch]  #just copy it over in that case
    return OUT

# ISRATIOS = [0.000000, 0.267949, 0.577350, 1.000000, 1.732051, 3.732051]
IS_L = [0, 0.21132474571138113, 0.36602529559070596, 0.5, 0.6339746219964415,0.7886751431884398, 1]
IS_R = IS_L[::-1]   #lol

def stereo(IN, main_data, side_info, header):
    '''
    IN -> the output of the reorder (or requantizer) array
    needs main_data too for its scalefactors
    '''
    print("do we use stereo or anything?",header["mode"], header["mode_ext"])
    if header["mode"] == 3:
        nchannels = 1
    else:
        nchannels = 2   #assume that joint stereo, stereo, and dual channel are all 2 channels

    if (nchannels == 1):
        return np.copy(IN)  #probably we won't worry about this case in FPGA


    OUT = np.zeros(shape = (2, nchannels, 576)) #if it gets here, there are 2 channels bruh

    for gr in range(2):
        #process for MS stereo:
        bound = 2 * max(side_info["big_values"][gr])
        print("boundary: ", bound)

        for i in range(576):
            if ((i < bound) and (header["mode"] != 3) and (header["mode_ext"] in (2,3))):
                #this means we use MS stereo for this index:
                left =  IN[gr][0][i] + IN[gr][1][i]
                right = IN[gr][0][i] - IN[gr][1][i]

                OUT[gr][0][i] = left   /   np.sqrt(2)
                OUT[gr][1][i] = right  /   np.sqrt(2)
            else:
                #otherwise don't process for stereo intensity for these indices
                OUT[gr][0][i] = IN[gr][0][i]
                OUT[gr][1][i] = IN[gr][1][i]  #copy the values over if not processing for intensity
        #note that at this point, the OUT array has all values filled in
        #however, we may need to process ore for intensity stereo as well.
        if ((header["mode"] != 3) and (header["mode_ext"] in (1,3))):
            #also uses intensity stereo:
            if ((side_info["window_switching_flag"][gr][0] == 1) and (side_info["block_type"][gr][0]==2)):
                if (side_info["mixed_block_flag"][gr][0] != 0):
                    #this means the first 2 subbands are long blocks
                    for sfb in range(8):
                        if LONG_sf_band_idx[sfb] >= side_info["big_values"][gr][1] * 2:
                            #process this subband for long intensity
                            is_pos = main_data["scalefac_l"][gr][0]
                            if is_pos < 7:
                                sfb_start = LONG_sf_band_idx[sfb]
                                sfb_stop = LONG_sf_band_idx[sfb + 1]

                                for i in range(sfb_start, sfb_stop):
                                    OUT[gr][0][i] *= IS_L[is_pos]
                                    OUT[gr][1][i] *= IS_R[is_pos]
                    #now process the remaining short blocks:
                    for sfb in range(3,12):
                        if SHORT_sf_band_idx[sfb]* 3 >= side_info["big_values"][gr][1] * 2:
                            win_len = SHORT_sf_band_idx[sfb+1] - SHORT_sf_band_idx[sfb]
                            for win in range(3):
                                is_pos = main_data["scalefac_s"][sfb][win]
                                if is_pos < 7:
                                    sfb_start = SHORT_sf_band_idx[sfb]*3 + win_len
                                    sfb_stop = SHORT_sf_band_idx[sfb + 1] * 3

                                    for i in range(sfb_start, sfb_stop):
                                        OUT[gr][0][i] *= IS_L[is_pos]
                                        OUT[gr][1][i] *= IS_R[is_pos]
                else:
                    #all blocks are short blocks:
                    for sfb in range(0,12):
                        if SHORT_sf_band_idx[sfb]* 3 >= side_info["big_values"] * 2:
                            win_len = SHORT_sf_band_idx[sfb+1] - SHORT_sf_band_idx[sfb]
                            for win in range(3):
                                is_pos = main_data["scalefac_s"][sfb][win]
                                if is_pos < 7:
                                    sfb_start = SHORT_sf_band_idx[sfb]*3 + win_len
                                    sfb_stop = SHORT_sf_band_idx[sfb + 1] * 3

                                    for i in range(sfb_start, sfb_stop):
                                        OUT[gr][0][i] *= IS_L[is_pos]
                                        OUT[gr][1][i] *= IS_R[is_pos]
            else:
                #all are long blocks:
                for sfb in range(21):
                    if LONG_sf_band_idx[sfb] >= side_info["big_values"][gr][1] * 2:
                        #process this subband for long intensity
                        is_pos = main_data["scalefac_l"][gr][0]
                        if is_pos < 7:
                            sfb_start = LONG_sf_band_idx[sfb]
                            sfb_stop = LONG_sf_band_idx[sfb + 1]

                            for i in range(sfb_start, sfb_stop):
                                OUT[gr][0][i] *= IS_L[is_pos]
                                OUT[gr][1][i] *= IS_R[is_pos]
    return OUT

def antialias(IN, side_info):
    '''
    input the array from the stereo output
    '''

    CS = [0.857493, 0.881742, 0.949629, 0.983315, 0.995518, 0.999161, 0.999899, 0.999993]
    CA = [-0.514496, -0.471732, -0.313377, -0.181913, -0.094574, -0.040966, -0.014199, -0.003700]

    OUT = np.zeros(shape(2,2,576))

    for gr in range(2):
        for ch in range(2):
            li = 0
            ui = 0  #in verilog i will init the variables like this too

            for i in range(576):
                if ( (side_info["window_switching_flag"][gr,ch]==1) and (side_info["block_type"][gr,ch]) == 2  and (side_info["mixed_block_flag"][gr,ch] == 0)):
                    OUT[gr,ch][i] = IN[gr,ch][i]    #don't do anything for short blocks
                else:
                    if ( (side_info["window_switching_flag"][gr,ch]==1) and (side_info["block_type"][gr,ch]) == 2  and (side_info["mixed_block_flag"][gr,ch] == 1)):
                        #this means there are 2 long blocks in the beginning
                        sblim = 2
                    else:
                        sblim = 32  #all blocks are long
