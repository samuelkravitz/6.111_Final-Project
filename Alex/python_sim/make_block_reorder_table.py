'''
some code to create 3 .mem files, one for each case of block type
the mem files will map 0-575 -> 0-575, where the output is the new address
this is used in the reorder.sv module
note that the reorder module also has to look at the big values input
to determine where the cutoff threshold is. once they are in the count1 region,
there never is any reordering...
'''

LONG_sf_band_idx = [0, 4, 8, 12, 16, 20, 24, 30, 36, 44, 52, 62, 74, 90, 110, 134, 162, 196, 238, 288, 342, 418, 576]   #bin (of 576) indices corresponding to boundaries of sf bands
SHORT_sf_band_idx = [0, 4, 8, 12, 16, 22, 30, 40, 52, 66, 84, 106, 136, 192]

window_switching_flag = 1
block_type = 2
mixed_block_flag = 1

##### FIRST CASE: mixed type of block ###########
# OUT = []
# sfb = 3
# j = 0
# win = 0
# for i in range(576):
#     if (i < 36):
#         OUT.append(i)
#         # OUT[gr,ch,i] = IN[gr,ch,i]  #no reordering for those long blongs in the beginning
#     else:
#         if i == SHORT_sf_band_idx[sfb + 1] * 3:
#             sfb += 1        #recompute these parameters for the rest of the for loop
#             j = 0
#             win = 0 #reset these because the new subband means restarting at window 0 and index 0
#
#         win_len = SHORT_sf_band_idx[sfb + 1] - SHORT_sf_band_idx[sfb]
#         # OUT[gr,ch,SHORT_sf_band_idx[sfb] * 3 + (3*j + win)] = IN[gr,ch,i]
#
#         OUT.append(SHORT_sf_band_idx[sfb] * 3 + (3*j + win))
#
#         if (j + 1 == win_len):
#             win += 1        #of course if this is already 2, you want it to go to 0, but the abovce conditional already takes care of that.
#             j = 0       #reset the j, increment the window up one.
#         else:
#             win = win
#             j += 1
#
# with open("REORDER_TB_1.mem", 'w') as f:
#     for item in OUT:
#         tmp = hex(item)[2:].zfill(3)
#         f.write("{}\n".format(tmp))


##### SECOND CASE: all short blocks i think... ############
# OUT = []
# sfb = 0
# j = 0
# win = 0
# for i in range(576):
#     if i == SHORT_sf_band_idx[sfb + 1] * 3:
#         sfb += 1        #recompute these parameters for the rest of the for loop
#         j = 0
#         win = 0 #reset these because the new subband means restarting at window 0 and index 0
#     win_len = SHORT_sf_band_idx[sfb + 1] - SHORT_sf_band_idx[sfb]
#
#     OUT.append(SHORT_sf_band_idx[sfb] * 3 + (3*j + win))
#
#     if (j + 1 == win_len):
#         win += 1        #of course if this is already 2, you want it to go to 0, but the abovce conditional already takes care of that.
#         j = 0       #reset the j, increment the window up one.
#     else:
#         win = win
#         j += 1
# # print(OUT)
# with open("REORDER_TB_2.mem", 'w') as f:
#     for item in OUT:
#         tmp = hex(item)[2:].zfill(3)
#         f.write("{}\n".format(tmp))


### THIRD CASE: ALL LONG BLOCKS: NO REORDERING NECESSARY ###############
with open("REORDER_TB_3.mem", "w") as f:
    for item in range(576):
        tmp = hex(item)[2:].zfill(3)
        f.write("{}\n".format(tmp))
