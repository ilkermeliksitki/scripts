# Script Collection Repository

This repository contains some scripts and tools designed to automate and simplify my personal tasks. Below is an overview of the scripts and their functionality.

## Repository Structure

```plaintext
scripts/
├── anki_csv/
│   ├── anki_csv.sh                  # Script for generating CSV files for Anki flashcards.
├── back-up/
│   └── documents-backup.sh          # Script to back up important documents.
├── battery-check/
│   └── battery_check.sh             # Monitors battery level and sends notifications.
├── find_corrupt_csv/
│   └── find_corrupt_csv.sh          # Finds and reports corrupt CSV files.
├── firefox-check/
│   └── firefox-checker.sh           # Checks if firefox is up-to-date or not
├── knock/
│   └── knock
├── koreader2anki/
│   └── koreader2anki.py             # Converts KOReader annotations to Anki flashcards.
├── one-time/
│   └── course-calendar-automation/
│       ├── README.md                # README for course calendar automation scripts.
│       └── tum_calendar_sync.py     # Syncs course dates and times to google calendar.
├── pomodoro/
│   ├── pomodoro.sh                  # Command-line Pomodoro timer.
│   └── pomodoro_document_maker.py   # Generates session logs for Pomodoro.
├── rand/
│   ├── randnumgen.py                # Generates random numbers.
│   └── randpassgen.py               # Generates random passwords.
├── rfv/
│   └── rfv.sh                       # Script for quickly finding the key words in files
├── screen_recorder/
│   ├── screen_recorder_start.sh       # Records the screen with optional save (-s flag)
│   └── screen_recorder_stop.sh        # Stops screen recording
├── to_pdf/
│   └── picture_to_pdf_converter.py  # Converts images to PDF files.
├── ventilation/
│   ├── window_close.sh              # Automates window closing.
│   └── window_open.sh               # Automates window opening.
├── vpn/
│   └── wg-safe/
│       ├── main.sh                  # Secure WireGuard VPN manager with kill switch
│       └── README.md                # Documentation for VPN kill switch functionality
├── wallpaper/
│   └── wallpaper-changer.sh         # Changes wallpapers randomly.
└── youtube/
    └── youtube-cli.py               # Command-line tool for YouTube interactions.
```

## Key Scripts

### Screen Recorder (`screen_recorder/`)
A flexible screen recording tool with optional save functionality to avoid unnecessary file storage.

**Features:**
- **Optional Save**: Use `-s` flag to save recordings, otherwise records without permanent storage
- **Area Selection**: Interactive area selection using slop
- **Duration Control**: Set recording duration via popup dialog
- **Audio Recording**: Captures both screen and system audio

**Usage:**
```bash
./screen_recorder/screen_recorder_start.sh      # Record without saving (temporary)
./screen_recorder/screen_recorder_start.sh -s   # Record and save to ~/Videos/screencasts/
./screen_recorder/screen_recorder_start.sh -h   # Show help
./screen_recorder/screen_recorder_stop.sh       # Stop active recording
```

### VPN Kill Switch (`vpn/wg-safe/`)
A secure WireGuard VPN manager with built-in kill switch functionality to prevent IP leaks when VPN connections drop unexpectedly.

**Features:**
- **Kill Switch Protection**: Automatically blocks all internet traffic when VPN connection is lost
- **IPv6 Leak Prevention**: Disables IPv6 during VPN connection to prevent leaks  
- **Connection Monitoring**: Continuously monitors VPN status and maintains firewall rules
- **Emergency Recovery**: Manual firewall restore function

**Usage:**
```bash
sudo vpn/wg-safe/main.sh up <profile>      # Connect with kill switch
sudo vpn/wg-safe/main.sh monitor <profile> # Monitor connection status
sudo vpn/wg-safe/main.sh down <profile>    # Disconnect safely
sudo vpn/wg-safe/main.sh restore-firewall  # Emergency restore
```

See `vpn/wg-safe/README.md` for detailed documentation.
