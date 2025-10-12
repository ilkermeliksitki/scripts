import subprocess
from wotd import get_wotd

word_of_the_day = get_wotd()
word = word_of_the_day["title"]
definition = word_of_the_day["definition"]

subprocess.run(
    [
        "anki_csv", 
        f"{word}",
        f"{definition}",
        "english",
    ]
)
