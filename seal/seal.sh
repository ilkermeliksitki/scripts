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

if [ -z "$MODE" ]; then
  echo "Usage: $SCRIPT_NAME {lock|unlock} [recipient]"
  exit 1
fi

if [ "$MODE" == "lock" ]; then
  # For encryption, a recipient must be provided.
  if [ -z "$2" ]; then
    echo "Error: Please provide a GPG recipient."
    echo "Usage: $SCRIPT_NAME lock recipient@example.com"
    exit 1
  fi
  RECIPIENT="$2"

  # create a temporary directory and archive in it to prevent file change error of tar
  TEMP_DIR=$(mktemp -d temp_seal_XXXXXXX)

  # move everything to the temporary directory except the script itself and existing archives
  find . -mindepth 1 ! -name "$SCRIPT_NAME" ! -name "$ENCRYPTED_ARCHIVE" ! -name $TEMP_DIR -exec mv {} "$TEMP_DIR" \;

  
  if ! tar -czf "$ARCHIVE" -C "$TEMP_DIR" .
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

elif [ "$MODE" == "unlock" ]; then
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
  
else
  echo "Error: Unknown mode '$MODE'"
  echo "Usage: $SCRIPT_NAME {lock|unlock} [recipient]"
  exit 1
fi

