#!/usr/bin/env python3

from datetime import datetime, timedelta

SESSION_PER_ROUND = 4
FOCUS_LENGTH = 60
SHORT_BREAK_LENGTH = 10
LONG_BREAK_LENGTH = 30

YEAR = 2025

def add_line(line_starting_moment, session_name_, duration):
    temp = ",".join(
        [
            line_starting_moment.strftime("%d-%b-%Y %H:%M:00"),
            (line_starting_moment + timedelta(minutes=duration)).strftime("%d-%b-%Y %H:%M:00"),
            session_name_
        ]
    )
    return temp


inp = input("Enter number of sessions, day, month, hour, minute: ")
input_ls = inp.split()
number_of_focus = int(input_ls[0])
day = int(input_ls[1])
month = int(input_ls[2])
hour = int(input_ls[3])
minute = int(input_ls[4])

starting_moment = datetime(year=YEAR, month=month, day=day, hour=hour, minute=minute)
file_name = f"{starting_moment.strftime('%Y_%m_%d')}.txt"
with open(file=file_name, mode="w") as data_file:
    data_file.write("Start Time,Finish Time,Current Status\n")

focus_count = 0
for i in range(1, 2 * number_of_focus + 1):
    if i % (2 * SESSION_PER_ROUND) == 0:
        session_name = "long break\n"
        line = add_line(starting_moment, session_name, duration=LONG_BREAK_LENGTH)
        starting_moment += timedelta(minutes=LONG_BREAK_LENGTH)
    elif i % 2 == 0:
        session_name = "short break\n"
        line = add_line(starting_moment, session_name, duration=SHORT_BREAK_LENGTH)
        starting_moment += timedelta(minutes=SHORT_BREAK_LENGTH)
    else:
        focus_count += 1
        if focus_count == number_of_focus:
            session_name = "finish study\n"
            line = add_line(starting_moment, session_name, duration=FOCUS_LENGTH)
        else:
            session_name = "focus\n"
            line = add_line(starting_moment, session_name, duration=FOCUS_LENGTH)
            starting_moment += timedelta(minutes=FOCUS_LENGTH)

    with open(file=file_name, mode="a") as data_file:
        data_file.write(line)
    if focus_count == number_of_focus:
        break
