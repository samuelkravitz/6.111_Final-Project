import os
import numpy as np

filename = "pow_43_tab.mem"

f = lambda x: x ** (4.0/3.0)
x = list(range(1000))

y = list(map(f,x))


with open(filename, 'w') as f:
    for i,item in enumerate(y):
        if item != 0:
            a = int(np.ceil(np.log2(item)))
        else:
            a = 0
        scale = 31 - a

        y_hex_repr = hex(int(item * 2 ** scale))[2:].zfill(8)
        base_hex_repr = hex(scale)[2:].zfill(2)

        f.write("{}\n".format(base_hex_repr + y_hex_repr))
