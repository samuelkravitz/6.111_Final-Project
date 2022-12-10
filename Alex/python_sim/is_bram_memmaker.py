'''
i need an easy way in verilog to go from IS_pos to sfb when computing the intensity
stereo stuff.
plan it to slap all three cases on brams once again.
'''

LONG_sf_band_idx = [0, 4, 8, 12, 16, 20, 24, 30, 36, 44, 52, 62, 74, 90, 110, 134, 162, 196, 238, 288, 342, 418, 576]   #bin (of 576) indices corresponding to boundaries of sf bands
SHORT_sf_band_idx = [0, 4, 8, 12, 16, 22, 30, 40, 52, 66, 84, 106, 136, 192]

############ CASE 1: MIXED BLOCKS ######################
OUT = []

for sfb in range(8):
    sfb_start = LONG_sf_band_idx[sfb]
    sfb_stop = LONG_sf_band_idx[sfb + 1]
    for i in range(sfb_start,sfb_stop):
        OUT.append((sfb,0,1))

for sfb in range(3,12):
    win_len = SHORT_sf_band_idx[sfb + 1] - SHORT_sf_band_idx[sfb]
    for win in range(3):
        sfb_start = SHORT_sf_band_idx[sfb]* 3 + win_len* win
        sfb_stop = sfb_start + win_len

        for i in range(sfb_start, sfb_stop):
            OUT.append((sfb,win,0))

with open('IS_stereo_sfb_idx_1.mem', 'w') as f:
    for sfb, win, bt in OUT:
        sfb_hex = hex(int(sfb))[2:].zfill(2)
        bt_hex = hex(int(bt))[2:].zfill(1)
        win_hex = hex(int(win))[2:].zfill(1)

        f.write("{}{}{}\n".format(sfb_hex, win_hex, bt_hex))

print("done")



########### CASE 2: ALL SHORT BLOCKS #################################

OUT = []


for sfb in range(0,12):
    win_len = SHORT_sf_band_idx[sfb + 1] - SHORT_sf_band_idx[sfb]
    for win in range(3):
        sfb_start = SHORT_sf_band_idx[sfb]* 3 + win_len* win
        sfb_stop = sfb_start + win_len

        for i in range(sfb_start, sfb_stop):
            OUT.append((sfb,win, 0))

with open('IS_stereo_sfb_idx_2.mem', 'w') as f:
    for sfb, win, bt in OUT:
        sfb_hex = hex(int(sfb))[2:].zfill(2)
        bt_hex = hex(int(bt))[2:].zfill(1)
        win_hex = hex(int(win))[2:].zfill(1)

        f.write("{}{}{}\n".format(sfb_hex, win_hex, bt_hex))
# print(OUT)
print("done")


########### CASE 3: ALL LONG BLOCKS #####################################
OUT = []

for sfb in range(21):
    sfb_start = LONG_sf_band_idx[sfb]
    sfb_stop = LONG_sf_band_idx[sfb + 1]
    for i in range(sfb_start,sfb_stop):
        OUT.append((sfb,0,1))

with open('IS_stereo_sfb_idx_3.mem', 'w') as f:
    for sfb, win, bt in OUT:
        sfb_hex = hex(int(sfb))[2:].zfill(2)
        bt_hex = hex(int(bt))[2:].zfill(1)
        win_hex = hex(int(win))[2:].zfill(1)

        f.write("{}{}{}\n".format(sfb_hex, win_hex, bt_hex))

print("done")
