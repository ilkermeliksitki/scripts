#! /usr/bin/env python3

import subprocess
from longman_wotd import get_wotd

word_of_the_day = get_wotd()
word = word_of_the_day["title"]
definition = word_of_the_day["definition"]

subprocess.run(
    [
        "./anki_csv.sh",
        f"{word}",
        f"{definition}",
        "longman",
    ]
)
