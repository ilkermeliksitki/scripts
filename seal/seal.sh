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

# global variables for cleanup
TEMP_DIR=""
ARCHIVE=""

# ==============================================================================
# helper functions
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

# cleanup function to be called on exit or error
cleanup() {
  # only print if we are actually cleaning something up to avoid noise
  if [ -d "$TEMP_DIR" ] || [ -f "$ARCHIVE" ]; then
    log_info "cleaning up temporary files..."
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    [ -f "$ARCHIVE" ] && rm -f "$ARCHIVE"
  fi
}

# set trap for cleanup
trap cleanup EXIT

# ask for confirmation (y/n)
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
# security checks
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
# core abstractions (tools & file ops)
# ==============================================================================

# copy files from current dir to destination, optionally including .git
util_copy_files() {
  local dest_dir="$1"
  local encrypted_archive_name="$2" # Needed to exclude it
  shift 2
  local excludes_array=("$@")

  # construct find command arguments for exclusion
  local find_args=(! -name "$SCRIPT_NAME" ! -name "$encrypted_archive_name" ! -name "$dest_dir")

  for pattern in "${excludes_array[@]}"; do
    find_args+=(! -name "$pattern")
  done

  if ! find . -mindepth 1 -maxdepth 1 "${find_args[@]}" -exec cp -r {} "$dest_dir" \; ; then
    log_error "Failed to copy files."
    return 1
  fi
  return 0
}

# remove files from current dir, optionally including .git
# ideally use his only after successful encryption
util_remove_files() {
  local encrypted_archive_name="$1" # Needed to exclude it
  local temp_dir_name="$2" # Needed to exclude it
  shift 2
  local excludes_array=("$@")

  local find_args=(! -name "$SCRIPT_NAME" ! -name "$encrypted_archive_name" ! -name "$temp_dir_name")

  for pattern in "${excludes_array[@]}"; do
    find_args+=(! -name "$pattern")
  done

  if ! find . -mindepth 1 -maxdepth 1 "${find_args[@]}" -exec rm -rf {} \; ; then
    log_warn "Some files could not be removed."
  fi
}

core_archive() {
  local output_file="$1"
  local source_dir="$2"
 
  log_info "Creating archive..."
  if ! tar -czf "$output_file" --directory "$source_dir" .; then
    log_error "Failed to create the archive."
    return 1
  fi
  return 0
}

core_extract() {
  local archive_file="$1"
  
  log_info "Extracting archive..."
  if ! tar -xzf "$archive_file"; then
    log_error "Failed to extract the archive."
    return 1
  fi
  return 0
}

core_encrypt_symmetric() {
  local input_file="$1"
  local output_file="$2"

  log_info "Encrypting archive (Symmetric)..."
  if ! gpg --yes --output "$output_file" --symmetric --armor "$input_file"; then
    log_error "GPG symmetric encryption failed."
    return 1
  fi
  return 0
}

core_encrypt_asymmetric() {
  local input_file="$1"
  local output_file="$2"
  local recipient="$3"

  log_info "Encrypting archive (Asymmetric for $recipient)..."
  if ! gpg --yes --output "$output_file" --encrypt --armor --recipient "$recipient" "$input_file"; then
    log_error "GPG asymmetric encryption failed."
    return 1
  fi
  return 0
}

core_decrypt() {
  local input_file="$1"
  local output_file="$2"

  log_info "Decrypting archive..."
  if ! gpg --yes --output "$output_file" --decrypt "$input_file"; then
    log_error "GPG decryption failed."
    return 1
  fi
  return 0
}

# parse arguments for lock command
# relies on dynamic scoping for variables: recipient, symmetric, excludes
parse_lock_args() {
  local OPTIND
  # ":r:si:" means r: requires an argument, s: doesn't require an argument, i: requires an argument
  while getopts ":r:si:" opt; do
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
      i )
        excludes+=("${OPTARG%/}")
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
  return $((OPTIND - 1))
}

validate_lock_preconditions() {
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
}

confirm_lock_action() {
  # confirmation
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
}

check_git_inclusion() {
  # git inclusion check
  if [ -d ".git" ]; then
    log_warn "There is a .git directory in the repository."
    if confirm "         Do you want to include it in the encrypted archive?"; then
      # remove .git from excludes
      # we rebuild the array excluding ".git"
      local new_excludes=()
      for item in "${excludes[@]}"; do
        if [ "$item" != ".git" ]; then
          new_excludes+=("$item")
        fi
      done
      excludes=("${new_excludes[@]}")
    fi
  fi
}

# ==============================================================================
# lock (encrypt) logic
# ==============================================================================

cmd_lock() {
  local recipient=""
  local symmetric=false
  local excludes=(".git") # default excludes

  # parse arguments
  parse_lock_args "$@"
  local args_processed=$?
  shift "$args_processed"

  local archive_name="${1:-$DEFAULT_NAME}"
  ARCHIVE="${archive_name}.tar.gz"
  local encrypted_archive="${archive_name}.tar.gz.gpg"

  validate_lock_preconditions
  confirm_lock_action
  check_git_inclusion

  # create temp directory
  TEMP_DIR=$(mktemp -d temp_seal_XXXXXXX)

  # 1. copy files
  if ! util_copy_files "$TEMP_DIR" "$encrypted_archive" "${excludes[@]}"; then
    exit 1
  fi

  # 2. archive
  if ! core_archive "$ARCHIVE" "$TEMP_DIR"; then
    exit 1
  fi

  # 3. encrypt
  if [ "$symmetric" = true ]; then
    if ! core_encrypt_symmetric "$ARCHIVE" "$encrypted_archive"; then
      exit 1
    fi
  else
    if ! core_encrypt_asymmetric "$ARCHIVE" "$encrypted_archive" "$recipient"; then
      exit 1
    fi
  fi

  # verify encryption output
  if [ ! -f "$encrypted_archive" ] || [ ! -s "$encrypted_archive" ]; then
    log_error "Encryption failed or produced an empty file."
    exit 1
  fi

  log_info "Encryption successful. Removing original files..."

  # 4. remove original files
  util_remove_files "$encrypted_archive" "$TEMP_DIR" "${excludes[@]}"

  log_info "Lock complete: Encrypted archive saved as '$encrypted_archive' ✅"
}

# ==============================================================================
# unlock (decrypt) logic
# ==============================================================================

validate_unlock_preconditions() {
  if [ ! -f "$encrypted_archive" ]; then
    log_error "Encrypted archive '$encrypted_archive' not found!"
    exit 1
  fi
}

backup_encrypted_archive() {
  log_info "Creating backup of encrypted archive as $backup_file"
  if ! cp "$encrypted_archive" "$backup_file"; then
    log_error "Failed to create backup of encrypted file."
    exit 1
  fi
}

cmd_unlock() {
  local archive_name="${1:-$DEFAULT_NAME}"
  ARCHIVE="${archive_name}.tar.gz"
  local encrypted_archive="${archive_name}.tar.gz.gpg"
  local backup_file="${encrypted_archive}.bak"

  validate_unlock_preconditions
  backup_encrypted_archive

  # 1. decrypt
  if ! core_decrypt "$encrypted_archive" "$ARCHIVE"; then
    log_info "Your original encrypted archive is preserved as $backup_file"
    exit 1
  fi

  if [ ! -f "$ARCHIVE" ] || [ ! -s "$ARCHIVE" ]; then
    log_error "Decryption failed or produced an empty archive."
    log_info "Your original encrypted archive is preserved as $backup_file"
    exit 1
  fi

  # 2. extract
  if ! core_extract "$ARCHIVE"; then
    log_info "Your archive file is preserved as $ARCHIVE"
    log_info "Your original encrypted archive is preserved as $backup_file"
    exit 1
  fi

  log_info "cleanup temporary files..."
  rm -f "$ARCHIVE"
  rm -f "$encrypted_archive"
  rm -f "$backup_file"

  # clear global ARCHIVE variable so trap doesn't try to remove it again (though rm -f is safe)
  ARCHIVE=""

  log_info "unlock complete: repository decrypted and extracted and cleaned ✅"
}

# ==============================================================================
# main execution
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

main "$@"
