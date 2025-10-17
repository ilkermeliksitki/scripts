#!/bin/bash
# seal.sh
#
# Usage:
#   To lock (archive & encrypt):
#     ./seal.sh lock -r recipient@example.com [name]  # asymmetric encryption
#     ./seal.sh lock -s [name]                        # symmetric encryption
#   To unlock (decrypt & extract):
#     ./seal.sh unlock [name]
#
# Mode: "lock" archives and encrypts the current directory.
#       "unlock" decrypts and extracts the encrypted archive.
#       (GPG automatically determines the decryption method)
#
# Name: Optional parameter for the archive name (without extension)
#       Default is the current directory name

SCRIPT_NAME=$(basename "$0")
HOME_DIR="${HOME_DIR:-$HOME}"
HOME_DIR="${HOME_DIR%/}" # remove trailing slash if exists
CURRENT_DIR="${CURRENT_DIR:-$PWD}"
DEFAULT_NAME=$(basename "$PWD")

show_usage() {
  echo "Usage: $SCRIPT_NAME {lock|unlock} [options] [name]"
  echo "Options for lock mode:"
  echo "  -r RECIPIENT    Use asymmetric encryption with recipient's key"
  echo "  -s              Use symmetric encryption (password-based)"
  echo "  name            Optional archive name (default: current directory name)"
  echo
  echo "Usage for unlock mode:"
  echo "  $SCRIPT_NAME unlock [name]"
  echo "  (GPG automatically determines whether the file was encrypted symmetrically"
  echo "   or asymmetrically and handles decryption accordingly)"
}

# function for cleanup in the case of error
cleanup() {
  echo "Cleaning up temporary files..."
  [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
  [ -f "$ARCHIVE" ] && rm -f "$ARCHIVE"
  exit 1
}

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

# check if the mode argument is provided
if [ $# -lt 1 ]; then
  show_usage
  exit 1
fi

# get the mode (first argument)
MODE="$1"
shift

# process remaining arguments based on mode
case "$MODE" in
  lock)
    RECIPIENT=""
    SYMMETRIC=false

    # parse options
    while getopts ":r:s" opt; do
      case ${opt} in
        r )
          RECIPIENT="$OPTARG"
          if [ "$SYMMETRIC" = true ]; then
            echo "Error: -r and -s options are mutually exclusive."
            show_usage
            exit 1
          fi
          ;;
        s )
          SYMMETRIC=true
          if [ -n "$RECIPIENT" ]; then
            echo "Error: -r and -s options are mutually exclusive."
            show_usage
            exit 1
          fi
          ;;
        \? )
          echo "Invalid option: -$OPTARG"
          show_usage
          exit 1
          ;;
        : )
          echo "Option -$OPTARG requires an argument."
          show_usage
          exit 1
          ;;
      esac
    done
    shift $((OPTIND -1))

    ARCHIVE_NAME="${1:-$DEFAULT_NAME}"
    ARCHIVE="${ARCHIVE_NAME}.tar.gz"
    ENCRYPTED_ARCHIVE="${ARCHIVE_NAME}.tar.gz.gpg"

    # validate encryption method is specified
    if [ -z "$RECIPIENT" ] && [ "$SYMMETRIC" = false ]; then
      echo "Error: Please specify encryption method (-r recipient or -s for symmetric)."
      show_usage
      exit 1
    fi

    if [ -f "$ENCRYPTED_ARCHIVE" ]; then
      echo "Error: Encrypted archive '$ENCRYPTED_ARCHIVE' already exists!"
      echo "       Please unlock the repository first."
      echo "       Otherwise, it overwrites the existing encrypted archive."
      exit 1
    fi

    # security check 3: ask yes/no confirmation before encryption
    echo "Warning: Are you sure you want to run this script?"
    echo "         It will archive and encrypt the current directory."
    echo "         Output will be saved as: $ENCRYPTED_ARCHIVE"
    if [ "$SYMMETRIC" = true ]; then
      echo "         Encryption: Symmetric (password-based)"
    else
      echo "         Encryption: Asymmetric for recipient $RECIPIENT"
    fi
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

    # create a temporary directory for the copy
    TEMP_DIR=$(mktemp -d temp_seal_XXXXXXX)

    # copy files to temporary directory, which is more robust in the case of failure
    if [ "$INCLUDE_GIT" = true ]; then
      find . -mindepth 1 -maxdepth 1 ! -name "$SCRIPT_NAME" ! -name "$ENCRYPTED_ARCHIVE" ! -name "$TEMP_DIR" \
        -exec cp -r {} "$TEMP_DIR" \; || { echo "Error: Failed to copy files."; cleanup; }
    else
      find . -mindepth 1 -maxdepth 1 ! -name "$SCRIPT_NAME" ! -name "$ENCRYPTED_ARCHIVE" ! -name "$TEMP_DIR" ! -name ".git" \
        -exec cp -r {} "$TEMP_DIR" \; || { echo "Error: Failed to copy files."; cleanup; }
    fi

    # archive the contents of the temporary directory
    echo "Creating archive..."
    if ! tar -czf "$ARCHIVE" --directory "$TEMP_DIR" .
    then
      echo "Error: Failed to create the archive."
      cleanup
    fi

    # encrypt the archive with gpg based on encryption method
    echo "Encrypting archive..."
    if [ "$SYMMETRIC" = true ]; then
      # use symmetric encryption (password-based)
      if ! gpg --yes --output "$ENCRYPTED_ARCHIVE" --symmetric --armor "$ARCHIVE"
      then
        echo "Error: GPG symmetric encryption failed."
        cleanup
      fi
    else
      # use asymmetric encryption with recipient
      if ! gpg --yes --output "$ENCRYPTED_ARCHIVE" --encrypt --armor --recipient "$RECIPIENT" "$ARCHIVE"
      then
        echo "Error: GPG asymmetric encryption failed."
        cleanup
      fi
    fi

    # verify that encrypted file exists and has content
    if [ ! -f "$ENCRYPTED_ARCHIVE" ] || [ ! -s "$ENCRYPTED_ARCHIVE" ]; then
      echo "Error: Encryption failed or produced an empty file."
      cleanup
    fi

    echo "Encryption successful. Removing original files..."

    # only after successful encryption, remove original files
    if [ "$INCLUDE_GIT" = true ]; then
      find . -mindepth 1 -maxdepth 1 ! -name "$SCRIPT_NAME" ! -name "$ENCRYPTED_ARCHIVE" ! -name "$TEMP_DIR" \
        -exec rm -rf {} \; || echo "Warning: Some files could not be removed."
    else
      find . -mindepth 1 -maxdepth 1 ! -name "$SCRIPT_NAME" ! -name "$ENCRYPTED_ARCHIVE" ! -name "$TEMP_DIR" ! -name ".git" \
        -exec rm -rf {} \; || echo "Warning: Some files could not be removed."
    fi

    # remove the temporary directory and unencrypted archive
    rm -rf "$TEMP_DIR"
    rm -f "$ARCHIVE"
    echo "Lock complete: Encrypted archive saved as '$ENCRYPTED_ARCHIVE' ✅"
    ;;

  unlock)
    ARCHIVE_NAME="${1:-$DEFAULT_NAME}"
    ARCHIVE="${ARCHIVE_NAME}.tar.gz"
    ENCRYPTED_ARCHIVE="${ARCHIVE_NAME}.tar.gz.gpg"

    # ensure the encrypted archive exists.
    if [ ! -f "$ENCRYPTED_ARCHIVE" ]; then
      echo "Error: Encrypted archive '$ENCRYPTED_ARCHIVE' not found!"
      exit 1
    fi

    # create a backup of the encrypted archive before attempting decryption
    BACKUP_FILE="${ENCRYPTED_ARCHIVE}.bak"
    echo "Creating backup of encrypted archive as $BACKUP_FILE"
    cp "$ENCRYPTED_ARCHIVE" "$BACKUP_FILE" || {
      echo "Error: Failed to create backup of encrypted file."
      exit 1
    }

    # decrypt the archive.
    echo "Decrypting archive..."
    if ! gpg --yes --output "$ARCHIVE" --decrypt "$ENCRYPTED_ARCHIVE"
    then
      echo "Error: GPG decryption failed."
      echo "Your original encrypted archive is preserved as $BACKUP_FILE"
      exit 1
    fi

    # check if archive was successfully decrypted
    if [ ! -f "$ARCHIVE" ] || [ ! -s "$ARCHIVE" ]; then
      echo "Error: Decryption failed or produced an empty archive."
      echo "Your original encrypted archive is preserved as $BACKUP_FILE"
      exit 1
    fi

    # extract the decrypted tar.gz archive.
    echo "Extracting archive..."
    if ! tar -xzf "$ARCHIVE"
    then
      echo "Error: Failed to extract the archive."
      echo "Your archive file is preserved as $ARCHIVE"
      echo "Your original encrypted archive is preserved as $BACKUP_FILE"
      exit 1
    fi

    # if everything is successful, clean up
    echo "Cleanup temporary files..."
    rm -f "$ARCHIVE"
    rm -f "$ENCRYPTED_ARCHIVE"
    rm -f "$BACKUP_FILE"
    echo "Unlock complete: Repository decrypted and extracted and cleaned ✅"
    ;;

  *)
    echo "Error: Unknown mode '$MODE'"
    show_usage
    exit 1
esac
