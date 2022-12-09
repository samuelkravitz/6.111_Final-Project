'''
use this for the requantizer modules:
    given some IS_pos, it will index into
    {sfb, win, SHORT/LONG} -> SHORT == 0, LONG == 1
'''
LONG_sf_band_idx = [0, 4, 8, 12, 16, 20, 24, 30, 36, 44, 52, 62, 74, 90, 110, 134, 162, 196, 238, 288, 342, 418, 576]   #bin (of 576) indices corresponding to boundaries of sf bands
SHORT_sf_band_idx = [0, 4, 8, 12, 16, 22, 30, 40, 52, 66, 84, 106, 136, 192]


##### CASE 1: LONG AND SHORT BlOCKS: ############
# OUT = []
# sfb = 0
# win = 0
#
# for i in range(36):
#     if (i == LONG_sf_band_idx[sfb + 1]):
#         sfb += 1
#     OUT.append((sfb, win, 1))
#
# sfb = 3
# i=36
# while i < 576:
#     if (i == SHORT_sf_band_idx[sfb + 1] * 3):
#         sfb += 1
#     win_len = SHORT_sf_band_idx[sfb + 1] - SHORT_sf_band_idx[sfb]
#     for win in range(3):
#         for j in range(win_len):
#             OUT.append((sfb, win, 0))
#             i += 1
# with open("FULL_WIN_SFB_TB_1.mem", 'w') as f:
#     for sfb, win, block_type in OUT:
#         sfb_hex = hex(int(sfb))[2:].zfill(3)
#         win_hex = hex(int(win))[2:].zfill(1)
#         block_type_hex = hex(int(block_type))[2:].zfill(1)
#
#         f.write("{}{}{}\n".format(sfb_hex, win_hex, block_type_hex))
#
# print("done")


##### CASE 2: short blocks only! ########################
# OUT = []
# sfb = 0
# win = 0
#
# i=0
# while i < 576:
#     if (i == SHORT_sf_band_idx[sfb + 1] * 3):
#         sfb += 1
#     win_len = SHORT_sf_band_idx[sfb + 1] - SHORT_sf_band_idx[sfb]
#     for win in range(3):
#         for j in range(win_len):
#             OUT.append((sfb, win, 0))
#             i += 1
#
# # print(OUT)
# with open("FULL_WIN_SFB_TB_2.mem", 'w') as f:
#     for sfb, win, block_type in OUT:
#         sfb_hex = hex(int(sfb))[2:].zfill(3)
#         win_hex = hex(int(win))[2:].zfill(1)
#         block_type_hex = hex(int(block_type))[2:].zfill(1)
#
#         f.write("{}{}{}\n".format(sfb_hex, win_hex, block_type_hex))
#
# print("done")



#### CASE 3: LONG BLOCKS ONLY ##############################
# OUT = []
# sfb = 0
# win = 0
#
# for i in range(576):
#     if (i == LONG_sf_band_idx[sfb + 1]):
#         sfb += 1
#     OUT.append((sfb, win, 1))
# with open("FULL_WIN_SFB_TB_3.mem", 'w') as f:
#     for sfb, win, block_type in OUT:
#         sfb_hex = hex(int(sfb))[2:].zfill(3)
#         win_hex = hex(int(win))[2:].zfill(1)
#         block_type_hex = hex(int(block_type))[2:].zfill(1)
#
#         f.write("{}{}{}\n".format(sfb_hex, win_hex, block_type_hex))
#
# print("done")
