#!/usr/bin/python3

import string
import secrets

symbols = "!?.,"
source = string.ascii_letters + string.digits + symbols

count = 0
while True:
    password = ''.join(secrets.choice(source) for i in range(15))
    if (any(c.isupper()  for c in password)            # at least one upper letter
        and sum(c.isdigit()  for c in password) >= 4   # at least 4 digit
        and sum(c.islower()  for c in password) >= 4   # at least 4 lower letter
        and sum(c in symbols for c in password) >= 2): # at least 2 symbols
        print(password)
        count += 1
    if count == 10:
        break
