'''
okay, manufacturing the 2s complement of an integer in python is not easy, so this
has to be its own file. rip
'''
import numpy as np

CS = [0.857493, 0.881742, 0.949629, 0.983315, 0.995518, 0.999161, 0.999899, 0.999993]
CA = [-0.514496, -0.471732, -0.313377, -0.181913, -0.094574, -0.040966, -0.014199, -0.003700]

print("making Q2_30 binary bits for CS:")
for cs in CS:
    tmp = bin(int(cs * 2 ** 30))[2:].zfill(32)
    print(cs, tmp)


print("\n\nmaking Q2_30 binary bits for CA:")
for i, ca in enumerate(CA):
    tmp = bin((1 << 32) - int(2 ** 30 * np.abs(ca)))[2:].zfill(32)
    print(i, ca, "\t", tmp)
