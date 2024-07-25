#!/usr/bin/python3

import string
import secrets

digits = string.digits

count = 0
while True:
    password = ''.join(secrets.choice(digits) for i in range(6))
    print(password)
    count += 1
    if count == 10:
        break
