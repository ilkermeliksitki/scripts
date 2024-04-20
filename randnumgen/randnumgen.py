#!/usr/bin/python3

import random

seed = input("Enter a seed number: ")
random.seed(seed)


nums = '0123456789'
for _ in range(100):
    for _ in range(6):
        print(random.choice(nums), end='')
    print()
