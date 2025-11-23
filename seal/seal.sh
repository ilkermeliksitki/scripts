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

# ==============================================================================
# Constants & Configuration
# ==============================================================================
SCRIPT_NAME=$(basename "$0")
HOME_DIR="${HOME_DIR:-$HOME}"
HOME_DIR="${HOME_DIR%/}" # remove trailing slash if exists
CURRENT_DIR="${CURRENT_DIR:-$PWD}"
DEFAULT_NAME=$(basename "$PWD")

# Global variables for cleanup
TEMP_DIR=""
ARCHIVE=""

# ==============================================================================
# Helper Functions
# ==============================================================================

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

log_info() {
  echo "$@"
}

log_error() {
  echo "Error: $*" >&2
}

log_warn() {
  echo "Warning: $*" >&2
}

# function for cleanup in the case of error
cleanup() {
  # Only print if we are actually cleaning something up to avoid noise
  if [ -d "$TEMP_DIR" ] || [ -f "$ARCHIVE" ]; then
    log_info "Cleaning up temporary files..."
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    [ -f "$ARCHIVE" ] && rm -f "$ARCHIVE"
  fi
}

# Set trap for cleanup
trap cleanup EXIT

# Ask for confirmation (y/N)
confirm() {
  local prompt="$1"
  echo "$prompt (y/N)"
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    return 1
  fi
  return 0
}

# ==============================================================================
# Security Checks
# ==============================================================================

check_root() {
  if [ "$(id -u)" -eq 0 ]; then
    log_error "Do not run this script as root!"
    exit 1
  fi
}

check_location() {
  if [[ "$CURRENT_DIR" != "$HOME_DIR" && "$CURRENT_DIR" != "$HOME_DIR"/* ]]; then
    log_error "This script must be run inside your home directory ($HOME_DIR)."
    exit 1
  fi
}

# ==============================================================================
# Lock (Encrypt) Logic
# ==============================================================================

cmd_lock() {
  local recipient=""
  local symmetric=false
  local OPTIND

  # Parse arguments specific to lock command
  while getopts ":r:s" opt; do
    case ${opt} in
      r )
        recipient="$OPTARG"
        if [ "$symmetric" = true ]; then
          log_error "-r and -s options are mutually exclusive."
          show_usage
          exit 1
        fi
        ;;
      s )
        symmetric=true
        if [ -n "$recipient" ]; then
          log_error "-r and -s options are mutually exclusive."
          show_usage
          exit 1
        fi
        ;;
      \? )
        log_error "Invalid option: -$OPTARG"
        show_usage
        exit 1
        ;;
      : )
        log_error "Option -$OPTARG requires an argument."
        show_usage
        exit 1
        ;;
    esac
  done
  shift $((OPTIND -1))

  local archive_name="${1:-$DEFAULT_NAME}"
  ARCHIVE="${archive_name}.tar.gz"
  local encrypted_archive="${archive_name}.tar.gz.gpg"

  # Validate encryption method
  if [ -z "$recipient" ] && [ "$symmetric" = false ]; then
    log_error "Please specify encryption method (-r recipient or -s for symmetric)."
    show_usage
    exit 1
  fi

  if [ -f "$encrypted_archive" ]; then
    log_error "Encrypted archive '$encrypted_archive' already exists!"
    log_info "       Please unlock the repository first."
    log_info "       Otherwise, it overwrites the existing encrypted archive."
    exit 1
  fi

  # Confirmation
  log_warn "Are you sure you want to run this script?"
  log_info "         It will archive and encrypt the current directory."
  log_info "         Output will be saved as: $encrypted_archive"
  if [ "$symmetric" = true ]; then
    log_info "         Encryption: Symmetric (password-based)"
  else
    log_info "         Encryption: Asymmetric for recipient $recipient"
  fi

  if ! confirm "         Do you want to continue?"; then
    log_info "Aborted. Wise decision!"
    exit 1
  fi

  # Git inclusion check
  local include_git=false
  if [ -d ".git" ]; then
    log_warn "There is a .git directory in the repository."
    if confirm "         Do you want to include it in the encrypted archive?"; then
      include_git=true
    else
      include_git=false
    fi
  fi

  # Create temp directory
  TEMP_DIR=$(mktemp -d temp_seal_XXXXXXX)

  # Copy files
  # Construct find command arguments for exclusion
  local excludes=(! -name "$SCRIPT_NAME" ! -name "$encrypted_archive" ! -name "$TEMP_DIR")
  if [ "$include_git" = false ]; then
    excludes+=(! -name ".git")
  fi

  if ! find . -mindepth 1 -maxdepth 1 "${excludes[@]}" -exec cp -r {} "$TEMP_DIR" \; ; then
    log_error "Failed to copy files."
    exit 1
  fi

  # Archive
  log_info "Creating archive..."
  if ! tar -czf "$ARCHIVE" --directory "$TEMP_DIR" .; then
    log_error "Failed to create the archive."
    exit 1
  fi

  # Encrypt
  log_info "Encrypting archive..."
  if [ "$symmetric" = true ]; then
    if ! gpg --yes --output "$encrypted_archive" --symmetric --armor "$ARCHIVE"; then
      log_error "GPG symmetric encryption failed."
      exit 1
    fi
  else
    if ! gpg --yes --output "$encrypted_archive" --encrypt --armor --recipient "$recipient" "$ARCHIVE"; then
      log_error "GPG asymmetric encryption failed."
      exit 1
    fi
  fi

  # Verify encryption output
  if [ ! -f "$encrypted_archive" ] || [ ! -s "$encrypted_archive" ]; then
    log_error "Encryption failed or produced an empty file."
    exit 1
  fi

  log_info "Encryption successful. Removing original files..."

  # Remove original files
  if ! find . -mindepth 1 -maxdepth 1 "${excludes[@]}" -exec rm -rf {} \; ; then
    log_warn "Some files could not be removed."
  fi

  # Cleanup handled by trap, but we can explicitly clear vars if we want to avoid double cleanup message
  # though trap handles it safely.

  log_info "Lock complete: Encrypted archive saved as '$encrypted_archive' ✅"
}

# ==============================================================================
# Unlock (Decrypt) Logic
# ==============================================================================

cmd_unlock() {
  local archive_name="${1:-$DEFAULT_NAME}"
  ARCHIVE="${archive_name}.tar.gz"
  local encrypted_archive="${archive_name}.tar.gz.gpg"
  local backup_file="${encrypted_archive}.bak"

  if [ ! -f "$encrypted_archive" ]; then
    log_error "Encrypted archive '$encrypted_archive' not found!"
    exit 1
  fi

  log_info "Creating backup of encrypted archive as $backup_file"
  if ! cp "$encrypted_archive" "$backup_file"; then
    log_error "Failed to create backup of encrypted file."
    exit 1
  fi

  log_info "Decrypting archive..."
  if ! gpg --yes --output "$ARCHIVE" --decrypt "$encrypted_archive"; then
    log_error "GPG decryption failed."
    log_info "Your original encrypted archive is preserved as $backup_file"
    exit 1
  fi

  if [ ! -f "$ARCHIVE" ] || [ ! -s "$ARCHIVE" ]; then
    log_error "Decryption failed or produced an empty archive."
    log_info "Your original encrypted archive is preserved as $backup_file"
    exit 1
  fi

  log_info "Extracting archive..."
  if ! tar -xzf "$ARCHIVE"; then
    log_error "Failed to extract the archive."
    log_info "Your archive file is preserved as $ARCHIVE"
    log_info "Your original encrypted archive is preserved as $backup_file"
    exit 1
  fi

  log_info "Cleanup temporary files..."
  rm -f "$ARCHIVE"
  rm -f "$encrypted_archive"
  rm -f "$backup_file"

  # Clear global ARCHIVE variable so trap doesn't try to remove it again (though rm -f is safe)
  ARCHIVE=""

  log_info "Unlock complete: Repository decrypted and extracted and cleaned ✅"
}

# ==============================================================================
# Main Execution
# ==============================================================================

main() {
  check_root
  check_location

  if [ $# -lt 1 ]; then
    show_usage
    exit 1
  fi

  local mode="$1"
  shift

  case "$mode" in
    lock)
      cmd_lock "$@"
      ;;
    unlock)
      cmd_unlock "$@"
      ;;
    *)
      log_error "Unknown mode '$mode'"
      show_usage
      exit 1
      ;;
  esac
}

# Run main
main "$@"
