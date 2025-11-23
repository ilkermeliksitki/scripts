#!/bin/bash
# test_seal.sh
# Automated test suite for seal.sh

SEAL_SCRIPT="../seal.sh"
TEST_DIR="test_sandbox_$(date +%s)"
PASSPHRASE="testpassword"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_pass() {
  echo -e "${GREEN}[PASS]${NC} $1"
}

log_fail() {
  echo -e "${RED}[FAIL]${NC} $1"
  exit 1
}

setup() {
  echo "Setting up test sandbox..."
  mkdir "$TEST_DIR"
  cd "$TEST_DIR" || exit 1
  
  # Create dummy files
  echo "Hello World" > file1.txt
  echo "Secret Data" > file2.txt
  mkdir subdir
  echo "Sub content" > subdir/subfile.txt
  
  # Create dummy git repo
  mkdir .git
  echo "git config" > .git/config
}

teardown() {
  echo "Cleaning up..."
  cd ..
  rm -rf "$TEST_DIR"
}

test_symmetric_lock_unlock() {
  echo "---------------------------------------------------"
  echo "Test Case: Symmetric Lock and Unlock"
  echo "---------------------------------------------------"

  # 1. lock
  # we use 'yes' to answer the confirmation prompts:
  # prompt 1: "Do you want to continue?" (y/N)
  # prompt 2: "Do you want to include .git?" (y/N) -> We say yes
  # we pipe the passphrase to gpg via --passphrase-fd 0 (standard input) is tricky with the script's structure.
  # the script calls gpg interactively.
  # however, gpg usually asks for passphrase via pinentry or tty.
  # for testing, we can try to rely on gpg-agent caching or use --batch --passphrase if we modified the script.
  # but, the script doesn't support --batch arguments for gpg.
  # so this test might hang if gpg asks for a password.
  
  # WORKAROUND: We will modify the script temporarily or assume the user is watching? 
  # No, automated tests should be automated.
  # the script uses `gpg --symmetric`. This forces interactive password entry by default.
  # to make it testable, we'd need to allow passing extra gpg args or use a non-interactive mode.
  
  # since we can't easily change the script's interactive nature without more refactoring,
  # we will try to use `expect` or just warn the user.
  # OR, we can mock `gpg`!
  
  # MOCKING GPG
  # we'll create a fake gpg function/alias that just copies the file (simulating encryption)
  # this tests the *workflow* (files removed, archive created) without needing actual crypto interaction.
  
  # define a mock gpg wrapper
  gpg() {
    # parse args to find input/output
    local output=""
    local input=""
    local mode=""
    
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --output)
          output="$2"
          shift 2
          ;;
        --symmetric|--encrypt)
          mode="encrypt"
          shift
          ;;
        --decrypt)
          mode="decrypt"
          shift
          ;;
        *)
          if [[ -f "$1" ]]; then
             input="$1"
          fi
          shift
          ;;
      esac
    done
    
    # copying is used for easy switch between encryption and decryption
    # it is assumed that gpg work "perfectly"
    if [[ "$mode" == "encrypt" ]]; then
       # "encrypt" by just copying
       cp "$input" "$output"
    elif [[ "$mode" == "decrypt" ]]; then
       # "decrypt" by just copying
       cp "$input" "$output"
    fi
    return 0
  }
  
  # so that gpg is available to the subprocess ($SEAL_SCRIPT lock)
  export -f gpg
  
  # run lock
  # input: y (continue), n (don't include git)
  echo -e "y\nn" | $SEAL_SCRIPT lock -s test_archive
  
  # assertions
  if [ -f "test_archive.tar.gz.gpg" ]; then
    log_pass "Encrypted archive created."
  else
    log_fail "Encrypted archive not found."
  fi
  
  if [ -f "file1.txt" ]; then
    log_fail "Original files were NOT removed."
  else
    log_pass "Original files removed."
  fi
  
  if [ -d ".git" ]; then
    log_pass ".git directory preserved (as requested)."
  else
    log_fail ".git directory was removed!"
  fi
  
  # 2. unlock
  $SEAL_SCRIPT unlock test_archive
  
  # assertions
  if [ -f "file1.txt" ] && grep -q "Hello World" file1.txt; then
    log_pass "File1 restored successfully."
  else
    log_fail "File1 not restored or corrupted."
  fi
  
  if [ ! -f "test_archive.tar.gz.gpg" ]; then
    log_pass "Encrypted archive removed after unlock."
  else
    log_fail "Encrypted archive still exists."
  fi
}

# run tests
setup
test_symmetric_lock_unlock
teardown

echo "---------------------------------------------------"
echo -e "${GREEN}All tests passed!${NC}"
echo "---------------------------------------------------"
