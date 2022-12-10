'''
useful LUT that maps 288 different inputs (from 0-287)
into two different addresses from 0-575 as well as a flag
telling it whether or not to compute the aliasing factor between them
this is the easiest alternative to some giant state machine
that keeps track of which items to add and subtract.
I don't want to deal with a rotating buffer.

LUT -> (is_pos_1, is_pos_2, FLAG, c_idx, sfb)
    FLAG -> 0 means dont compute antialias, just return the values themselves
    c_idx -> some value from 0 to 7 (inclusive), used to index into CA and CS (antialias computation)
    sfb -> 1-31 inclusive, the scale factor band. used downstream to verify that aliasing should be done
'''
OUT = []

for i in range(5):
    OUT.append((i*2, i*2 + 1, 0, 0, 0))

for sb in range(1,32):
    for i in range(8):
        li = 18 * sb - 1 - i
        ui = 18 * sb + i
        OUT.append((li, ui, 1, i, sb))
    OUT.append((ui+1, ui+2, 0, 0, sb))

for i in range(568, 576,2):
    OUT.append((i, i+1, 0, 0, 31))

print("proving that every is_pos is in here once only:")
lol = []
for item in OUT:
    lol.append(item[0])
    lol.append(item[1])

lol.sort()

for i in range(0, 575):
    assert i == lol[i]

print("it worked!")
print(len(OUT))

with open("aliasing_LUT.mem", 'w') as f:
    for li, ui, flag, i, sb in OUT:
        li_hex = hex(int(li))[2:].zfill(3)
        ui_hex = hex(int(ui))[2:].zfill(3)
        flag_hex = hex(int(flag))[2:].zfill(1)
        i_hex = hex(int(i))[2:].zfill(1)
        sb_hex = hex(int(sb))[2:].zfill(2)
        f.write("{}{}{}{}{}\n".format(li_hex, ui_hex, flag_hex, i_hex, sb_hex))
print('done')
