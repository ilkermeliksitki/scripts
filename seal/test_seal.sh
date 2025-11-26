#!/bin/bash
# test_seal.sh
# Automated test suite for seal.sh

SEAL_SCRIPT="../seal.sh"
TEST_DIR="test_sandbox_$(date +%s)"
PASSPHRASE="testpassword"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
RED_BG_WHITE_TEXT='\033[41;97m'  # Red background, white text
NC='\033[0m' # No Color

# Counters for summary
TESTS_PASSED=0
TESTS_FAILED=0

log_pass() {
  ((TESTS_PASSED++))
  if [[ "$VERBOSE" = true ]]; then
    echo -e "${GREEN}[PASS]${NC} $1"
  fi
}

log_fail() {
  ((TESTS_FAILED++))
  echo -e "${RED_BG_WHITE_TEXT}[FAIL]${NC} $1"
  # don't exit immediately, continue running other tests
}

log_test_header() {
  if [[ "$VERBOSE" = true ]]; then
    echo "---------------------------------------------------"
    echo "test case: $1"
    echo "---------------------------------------------------"
  fi
}

setup() {
  if [[ "$VERBOSE" = true ]]; then
    echo "Setting up test sandbox..."
  fi
  mkdir "$TEST_DIR"
  cd "$TEST_DIR" || exit 1

  # create dummy files
  echo "Hello World" > file1.txt
  echo "Secret Data" > file2.txt
  mkdir subdir
  echo "Sub content" > subdir/subfile.txt

  # create dummy git repo
  mkdir .git
  echo "git config" > .git/config
}

teardown() {
  if [[ "$VERBOSE" = true ]]; then
    echo "Cleaning up test sandbox..."
  fi
  cd ..
  rm -rf "$TEST_DIR"
}

# mock gpg function
setup_gpg_mock() {
  gpg() {
    local output=""
    local input=""
    local mode=""
    
    while [[ $# > 0 ]]; do
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
    
    if [[ "$mode" == "encrypt" ]]; then
       cp "$input" "$output"
    elif [[ "$mode" == "decrypt" ]]; then
       cp "$input" "$output"
    fi
    return 0
  }
  export -f gpg
}

test_symmetric_lock_unlock() {
  log_test_header "symmetric lock and unlock"

  setup_gpg_mock

  # run lock (suppress output)
  echo -e "y\nn" | $SEAL_SCRIPT lock -s test_archive > /dev/null 2>&1
  
  # assertions
  if [[ -f "test_archive.tar.gz.gpg" ]]; then
    log_pass "Encrypted archive created."
  else
    log_fail "Encrypted archive not found."
  fi
  
  if [[ -f "file1.txt" ]]; then
    log_fail "Original files were NOT removed."
  else
    log_pass "Original files removed."
  fi
  
  if [[ -d ".git" ]]; then
    log_pass ". git directory preserved (as requested)."
  else
    log_fail ".git directory was removed!"
  fi
  
  # unlock (suppress output)
  $SEAL_SCRIPT unlock test_archive > /dev/null 2>&1
  
  # assertions
  if [[ -f "file1.txt" ]] && grep -q "Hello World" file1.txt; then
    log_pass "File1 restored successfully."
  else
    log_fail "File1 not restored or corrupted."
  fi
  
  if [[ !  -f "test_archive.tar.gz.gpg" ]]; then
    log_pass "Encrypted archive removed after unlock."
  else
    log_fail "Encrypted archive still exists."
  fi
}

test_ignore_flag() {
  log_test_header "ignore flag (-i)"

  setup_gpg_mock

  # setup specific for this test
  echo "I should be ignored" > ignore_me.txt
  echo "I should be encrypted" > include_me.txt

  # run lock with -i (suppress output)
  echo -e "y\nn" | $SEAL_SCRIPT lock -s -i "ignore_me.txt" test_ignore > /dev/null 2>&1

  # assertions
  if [[ -f "ignore_me.txt" ]]; then
    log_pass "Ignored file 'ignore_me.txt' was preserved."
  else
    log_fail "Ignored file 'ignore_me.txt' was DELETED!"
  fi

  if [[ !  -f "include_me.txt" ]]; then
    log_pass "Included file 'include_me.txt' was removed (as expected)."
  else
    log_fail "Included file 'include_me. txt' was NOT removed."
  fi

  # verify archive content (since we mock GPG, the . gpg file is just a tar.gz)
  if tar -tf test_ignore.tar.gz.gpg 2>/dev/null | grep -q "ignore_me.txt"; then
    log_fail "Ignored file found INSIDE the archive!"
  else
    log_pass "Ignored file is NOT in the archive."
  fi

  # cleanup for this test
  rm -f ignore_me.txt test_ignore.tar.gz.gpg
}

test_ignore_folder_with_trailing_slash() {
  log_test_header "ignore folder with trailing slash (-i folder/)"

  setup_gpg_mock

  # setup specific for this test
  mkdir ignore_folder
  echo "I should be ignored" > ignore_folder/secret.txt
  echo "I should be encrypted" > include_me.txt

  # run lock with -i and trailing slash (suppress output)
  echo -e "y\nn" | $SEAL_SCRIPT lock -s -i "ignore_folder/" test_trailing > /dev/null 2>&1

  # assertions
  if [ -d "ignore_folder" ]; then
    log_pass "Ignored folder 'ignore_folder/' was preserved."
  else
    log_fail "Ignored folder 'ignore_folder/' was DELETED!"
  fi

  if [ -f "ignore_folder/secret.txt" ]; then
    log_pass "Contents of ignored folder preserved."
  else
    log_fail "Contents of ignored folder were DELETED!"
  fi

  if [ ! -f "include_me. txt" ]; then
    log_pass "Included file 'include_me. txt' was removed (as expected)."
  else
    log_fail "Included file 'include_me.txt' was NOT removed."
  fi

  # verify archive content
  if tar -tf test_trailing.tar.gz.gpg 2>/dev/null | grep -q "ignore_folder"; then
    log_fail "Ignored folder found INSIDE the archive!"
  else
    log_pass "Ignored folder is NOT in the archive."
  fi

  # cleanup for this test
  rm -rf ignore_folder test_trailing.tar.gz. gpg
}

test_ignore_folder_without_trailing_slash() {
  log_test_header "ignore folder without trailing slash (-i folder)"

  setup_gpg_mock

  # setup specific for this test
  mkdir ignore_folder
  echo "I should be ignored" > ignore_folder/secret.txt
  echo "I should be encrypted" > include_me.txt

  # run lock with -i WITHOUT trailing slash (suppress output)
  echo -e "y\nn" | $SEAL_SCRIPT lock -s -i "ignore_folder" test_no_trailing > /dev/null 2>&1

  # assertions
  if [ -d "ignore_folder" ]; then
    log_pass "Ignored folder 'ignore_folder' was preserved."
  else
    log_fail "Ignored folder 'ignore_folder' was DELETED!"
  fi

  if [ -f "ignore_folder/secret.txt" ]; then
    log_pass "Contents of ignored folder preserved."
  else
    log_fail "Contents of ignored folder were DELETED!"
  fi

  if [ ! -f "include_me. txt" ]; then
    log_pass "Included file 'include_me. txt' was removed (as expected)."
  else
    log_fail "Included file 'include_me.txt' was NOT removed."
  fi

  # verify archive content
  if tar -tf test_no_trailing.tar.gz.gpg 2>/dev/null | grep -q "ignore_folder"; then
    log_fail "Ignored folder found INSIDE the archive!"
  else
    log_pass "Ignored folder is NOT in the archive."
  fi

  # cleanup for this test
  rm -rf ignore_folder test_no_trailing.tar. gz.gpg
}

test_ignore_file_and_folder_together() {
    log_test_header "ignore file and folder together (-i file -i folder/)"

    setup_gpg_mock

    # setup specific for this test
    mkdir ignore_folder
    echo "I should be ignored" > ignore_folder/secret.txt
    echo "I should also be ignored" > ignore_me.txt
    echo "I should be encrypted" > include_me.txt

    # run lock with -i for both file and folder (suppress output)
    # input: yes (y) for encryption, no (n) for git preservation
    echo -e "y\nn" | $SEAL_SCRIPT lock -s -i "ignore_folder/" -i "ignore_me.txt" test_both > /dev/null 2>&1

    # assertions
    if [[ -d "ignore_folder" ]]; then
      log_pass "Ignored folder 'ignore_folder/' was preserved."
    else
      log_fail "Ignored folder 'ignore_folder/' was DELETED!"
    fi

    if [[ -f "ignore_folder/secret.txt" ]]; then
      log_pass "Contents of ignored folder preserved."
    else
      log_fail "Contents of ignored folder were DELETED!"
    fi

    if [[ -f "ignore_me.txt" ]]; then
      log_pass "Ignored file 'ignore_me.txt' was preserved."
    else
      log_fail "Ignored file 'ignore_me.txt' was DELETED!"
    fi

    if [[ ! -f "include_me.txt" ]]; then
      log_pass "Included file 'include_me.txt' was removed (as expected)."
    else
      log_fail "Included file 'include_me.txt' was NOT removed."
    fi

    # verify archive content
    if tar -tf test_both.tar.gz.gpg 2>/dev/null | grep -q -e "ignore_folder" -e "ignore_me.txt"; then
      log_fail "Ignored file or folder found INSIDE the archive!"
    else
      log_pass "Ignored file and folder are NOT in the archive."
    fi
}


print_summary() {
  echo "---------------------------------------------------"
  echo "Test Summary"
  echo "---------------------------------------------------"
  echo -e "Passed: ${GREEN}${TESTS_PASSED}${NC}"
  if [[ "$TESTS_FAILED" > 0 ]]; then
    echo -e "Failed: ${RED_BG_WHITE_TEXT}${TESTS_FAILED}${NC}"
    echo "---------------------------------------------------"
    exit 1
  else
    echo -e "Failed: ${TESTS_FAILED}"
    echo "---------------------------------------------------"
    echo -e "${GREEN}All tests passed! ${NC}"
  fi
}

# parse args
VERBOSE=false
while getopts "v" opt; do
  case $opt in
    v)
      VERBOSE=true
      ;;
    *)
      ;;
  esac
done

# run tests
setup
test_symmetric_lock_unlock
test_ignore_flag
test_ignore_folder_with_trailing_slash
test_ignore_folder_without_trailing_slash
test_ignore_file_and_folder_together
teardown

print_summary
