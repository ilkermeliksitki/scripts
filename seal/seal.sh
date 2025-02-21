#!/bin/bash
# seal.sh
#
# Usage:
#   To lock (archive & encrypt):   ./seal.sh lock recipient@example.com
#   To unlock (decrypt & extract):  ./seal.sh unlock
#
# Mode: "lock" archives and encrypts the current directory.
#       "unlock" decrypts and extracts the encrypted archive.
#
# Note: The script assumes the encrypted archive will be named "locked.tar.gz.gpg"
#       and the temporary tarball "locked.tar.gz".

MODE="$1"
ARCHIVE="locked.tar.gz"
ENCRYPTED_ARCHIVE="locked.tar.gz.gpg"
SCRIPT_NAME=$(basename "$0")
HOME_DIR="${HOME_DIR:-$HOME}"
HOME_DIR="${HOME_DIR%/}" # remove trailing slash if exists
CURRENT_DIR="${CURRENT_DIR:-$PWD}"


# security check 1: prevent running as root
if [ "$(id -u)" -eq 0 ]; then
  echo "Error: Do not run this script as root!"
  exit 1
fi

# security check 2: prevent running outside home directory
if [[ "$CURRENT_DIR" != "$HOME_DIR" && "$CURRENT_DIR" != "$HOME_DIR"/* ]]; then
  echo "Error: This script must be run inside your home directory ($HOME_DIR)."
  exit 1
fi

if [ -z "$MODE" ]; then
  echo "Usage: $SCRIPT_NAME {lock|unlock} [recipient]"
  exit 1
fi

case "$MODE" in
  lock)
    if [ -f "$ENCRYPTED_ARCHIVE" ]; then
      echo "Error: Encrypted archive '$ENCRYPTED_ARCHIVE' already exists!"
      echo "       Please unlock the repository first."
      echo "       Otherwise, it overwrites the existing encrypted archive."
      exit 1
    fi
    # For encryption, a recipient must be provided.
    if [ -z "$2" ]; then
      echo "Error: Please provide a GPG recipient."
      echo "Usage: $SCRIPT_NAME lock recipient@example.com"
      exit 1
    fi
    RECIPIENT="$2"

    # security check 3: ask yes/no confirmation before encryption
    echo "Warning: Are you sure you want to run this script?"
    echo "         It will archive and encrypt the current directory."
    echo "         Do you want to continue? (y/N)"
    read -r CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
      echo "Aborted. Wise decision!"
      exit 1
    fi

    # check if .git directory exists, if so, ask confirmation to encrypt it
    if [ -d ".git" ]; then
      # ask confirmation to encrypt .git directory
      echo "Warning: There is a .git directory in the repository."
      echo "         Do you want to include it in the encrypted archive? (y/N)"
      read -r CONFIRM_GIT
      if [[ "$CONFIRM_GIT" =~ ^[Yy]$ ]]; then
        INCLUDE_GIT=true
      else
        INCLUDE_GIT=false
      fi
    else
      INCLUDE_GIT=false
    fi

    # create a temporary directory and archive in it to prevent file change error of tar
    TEMP_DIR=$(mktemp -d temp_seal_XXXXXXX)

    # move everything to the temporary directory except the script itself
    # existing archives and git directory (by choice)
    if [ "$INCLUDE_GIT" = true ]; then
      find . -mindepth 1 -maxdepth 1 ! -name "$SCRIPT_NAME" ! -name "$ENCRYPTED_ARCHIVE" ! -name "$TEMP_DIR" \
        -exec mv {} "$TEMP_DIR" \;
    else
      find . -mindepth 1 -maxdepth 1 ! -name "$SCRIPT_NAME" ! -name "$ENCRYPTED_ARCHIVE" ! -name "$TEMP_DIR" ! -name ".git" \
        -exec mv {} "$TEMP_DIR" \;
    fi

    # archive the contents of the temporary directory at the current directory
    if ! tar -czf "$ARCHIVE" --directory "$TEMP_DIR" .
    then
      echo "Error: Failed to create the archive."
    fi

    # Encrypt the archive with GPG for the specified recipient.
    if ! gpg --yes --output "$ENCRYPTED_ARCHIVE" --encrypt --armor --recipient "$RECIPIENT" "$ARCHIVE"
    then
      echo "Error: GPG encryption failed."
      rm -rf "$TEMP_DIR"
      rm -f "$ARCHIVE"
      exit 1
    fi

    # Remove the unencrypted archive for security and temporary directory
    rm -rf "$TEMP_DIR"
    rm "$ARCHIVE"
    echo "Lock complete: Encrypted archive saved as '$ENCRYPTED_ARCHIVE'."
    ;;
  unlock)
    # Ensure the encrypted archive exists.
    if [ ! -f "$ENCRYPTED_ARCHIVE" ]; then
      echo "Error: Encrypted archive '$ENCRYPTED_ARCHIVE' not found!"
      exit 1
    fi

    # Decrypt the archive.
    if ! gpg --yes --output "$ARCHIVE" --decrypt "$ENCRYPTED_ARCHIVE"
    then
      echo "Error: GPG decryption failed."
      exit 1
    fi

    # Extract the decrypted tar.gz archive.
    if ! tar -xzf "$ARCHIVE"
    then
      echo "Error: Failed to extract the archive."
      exit 1
    fi

    # remove the temporary tar archive and the encrypted archive
    # so that the directory is clean after unlocking and turn back
    # to "clean" state without any encrypted files etc.
    rm "$ARCHIVE"
    rm "$ENCRYPTED_ARCHIVE"
    echo "Unlock complete: Repository decrypted and extracted and cleaned."
    ;;
  *)
    echo "Error: Unknown mode '$MODE'"
    echo "Usage: $SCRIPT_NAME {lock|unlock} [recipient]"
    exit 1
esac
