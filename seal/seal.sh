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
  
  # Create a tar.gz archive of the current directory.
  # Exclude the archive files (if they exist) and the script itself.
  tar --exclude="$ARCHIVE" --exclude="$ENCRYPTED_ARCHIVE" --exclude="$SCRIPT_NAME" -czf "$ARCHIVE" .
  if [ $? -ne 0 ]; then
    echo "Error: Failed to create the archive."
    exit 1
  fi

  # Encrypt the archive with GPG for the specified recipient.
  gpg --yes --output "$ENCRYPTED_ARCHIVE" --encrypt --armor --recipient "$RECIPIENT" "$ARCHIVE"
  if [ $? -ne 0 ]; then
    echo "Error: GPG encryption failed."
    exit 1
  fi
  
  # Remove the unencrypted archive for security.
  rm "$ARCHIVE"
  echo "Lock complete: Encrypted archive saved as '$ENCRYPTED_ARCHIVE'."

elif [ "$MODE" == "unlock" ]; then
  # Ensure the encrypted archive exists.
  if [ ! -f "$ENCRYPTED_ARCHIVE" ]; then
    echo "Error: Encrypted archive '$ENCRYPTED_ARCHIVE' not found!"
    exit 1
  fi
  
  # Decrypt the archive.
  gpg --yes --output "$ARCHIVE" --decrypt "$ENCRYPTED_ARCHIVE"
  if [ $? -ne 0 ]; then
    echo "Error: GPG decryption failed."
    exit 1
  fi
  
  # Extract the decrypted tar.gz archive.
  tar -xzf "$ARCHIVE"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to extract the archive."
    exit 1
  fi
  
  # Optionally, remove the temporary tar archive.
  rm "$ARCHIVE"
  echo "Unlock complete: Repository decrypted and extracted."
  
else
  echo "Error: Unknown mode '$MODE'"
  echo "Usage: $SCRIPT_NAME {lock|unlock} [recipient]"
  exit 1
fi

