#!/usr/bin/env python3

import sys
import numpy as np
from numpy import linalg as LA
import pandas as pd

mat1 = sys.argv[1]
mat2 = sys.argv[2]

l1 = []
with open(mat1) as f:
    for line in f: #sys.stdin:
        t = line.split("\t")
        l1.append(pd.to_numeric(t, errors='coerce'))

l2 = []
with open(mat2) as f:
    for line in f: #sys.stdin:
        t = line.split("\t")
        l2.append(pd.to_numeric(t, errors='coerce'))

arr1 = np.nan_to_num(np.array(l1))  # replace np.nan with 0 for norm calculation
arr2 = np.nan_to_num(np.array(l2))
f_arr1 = LA.norm(arr1)
f_arr2 = LA.norm(arr2)

f_diff = abs(f_arr1 - f_arr2)
f_min = min(f_arr1, f_arr2)
f_pcnt = 100 * (f_diff / f_min)

print("arr1 norm: %.2f" % f_arr1)
print("arr2 norm: %.2f" % f_arr2)
if f_pcnt <= 5.0:
    print("PASS: percent difference (%.2f) is <= 5.0" % f_pcnt)
else:
    print("FAIL: percent difference (%.2f) is > 5.0" % f_pcnt)
