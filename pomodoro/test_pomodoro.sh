#!/bin/bash
# test_pomodoro.sh
# Automated test suite for pomodoro.sh

POMODORO_SCRIPT="../pomodoro.sh"
TEST_DIR="test_sandbox_$(date +%s)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
RED_BG_WHITE_TEXT='\033[41;97m'  # Red background, white text
NC='\033[0m' # No Color

# Counters for summary
TESTS_PASSED=0
TESTS_FAILED=0

# Mock variables
MOCK_HOUR=10 # Default to 10 AM (safe time)

log_pass() {
  ((TESTS_PASSED++))
  if [[ "$VERBOSE" = true ]]; then
    echo -e "${GREEN}[PASS]${NC} $1"
  fi
}

log_fail() {
  ((TESTS_FAILED++))
  echo -e "${RED_BG_WHITE_TEXT}[FAIL]${NC} $1"
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
  
  # source the script to test functions
  # the guard is added to prevent the script from running when sourced
  source "$POMODORO_SCRIPT"
}

teardown() {
  if [[ "$VERBOSE" = true ]]; then
    echo "Cleaning up test sandbox..."
  fi
  cd ..
  rm -rf "$TEST_DIR"
}

# Mock external dependencies
setup_mocks() {
  # Mock paplay
  paplay() {
    return 0
  }
  export -f paplay

  # Mock notify-send
  notify-send() {
    return 0
  }
  export -f notify-send

  # Mock date
  # We only care about date +%H for the script logic
  date() {
    local format=""
    # Check if arguments contain +%H
    for arg in "$@"; do
        if [[ "$arg" == "+%H" ]]; then
            echo "$MOCK_HOUR"
            return 0
        fi
        # If it's the full date format used in logging or countdown, we can let it pass or mock it too.
        # The script uses:
        # 1. date +%H (get_phase_suggestion)
        # 2. date "+%Y-%m-%d %H:%M:%S" (log_session)
        # 3. date -u --date @$seconds +%H:%M:%S (countdown)
    done
    
    # For other cases, call real date. 
    # Since we are shadowing 'date', we need to call the binary directly.
    /bin/date "$@"
  }
  export -f date
}

test_minutes_to_seconds() {
  log_test_header "minutes_to_seconds"

  local result=$(minutes_to_seconds 5)
  if [[ "$result" -eq 300 ]]; then
    log_pass "5 minutes converted to 300 seconds."
  else
    log_fail "5 minutes conversion failed. Got: $result"
  fi

  result=$(minutes_to_seconds 0)
  if [[ "$result" -eq 0 ]]; then
    log_pass "0 minutes converted to 0 seconds."
  else
    log_fail "0 minutes conversion failed. Got: $result"
  fi
}

test_get_phase_suggestion() {
  log_test_header "get_phase_suggestion"

  # Test Case 1: High Urgency (Low elapsed, normal energy)
  # elapsed=0, energy=3
  read focus break phase <<< $(get_phase_suggestion 0 3)
  if [[ "$focus" -eq 25 ]] && [[ "$break" -eq 5 ]]; then
    log_pass "High Urgency suggestion correct (25/5)."
  else
    log_fail "High Urgency suggestion failed. Got: $focus/$break"
  fi

  # Test Case 2: Flow State (Energy=5)
  # elapsed=100, energy=5
  read focus break phase <<< $(get_phase_suggestion 100 5)
  if [[ "$focus" -eq 60 ]] && [[ "$break" -eq 10 ]]; then
    log_pass "Flow State suggestion correct (60/10)."
  else
    log_fail "Flow State suggestion failed. Got: $focus/$break"
  fi

  # Test Case 3: Survival Mode (Energy=1)
  # elapsed=100, energy=1
  read focus break phase <<< $(get_phase_suggestion 100 1)
  if [[ "$focus" -eq 15 ]] && [[ "$break" -eq 5 ]]; then
    log_pass "Survival Mode suggestion correct (15/5)."
  else
    log_fail "Survival Mode suggestion failed. Got: $focus/$break"
  fi

  # Test Case 4: Burnout Prevention (Elapsed > 240, Energy <= 2)
  # elapsed=300, energy=1
  read focus break phase <<< $(get_phase_suggestion 300 1)
  if [[ "$focus" -eq 0 ]] && [[ "$break" -eq 30 ]]; then
    log_pass "Burnout Prevention suggestion correct (0/30)."
  else
    log_fail "Burnout Prevention suggestion failed. Got: $focus/$break"
  fi

  # Test Case 5: Afternoon Slump (14:00 - 16:00)
  # Set mock time to 15:00 (3 PM)
  MOCK_HOUR=15
  # elapsed=0, energy=3 (would normally be High Urgency 25/5, but slump protection should kick in)
  # Wait... looking at logic:
  # Priority 3 is Slump Protection. Priority 4 is Standard Ramp-up.
  # So Slump Protection overrides Standard Ramp-up.
  read focus break phase <<< $(get_phase_suggestion 0 3)
  if [[ "$focus" -eq 25 ]] && [[ "$break" -eq 5 ]] && [[ "$phase" == *"Afternoon_Slump"* ]]; then
    log_pass "Afternoon Slump suggestion correct (25/5 Slump Protection)."
  else
    log_fail "Afternoon Slump suggestion failed. Got: $focus/$break $phase"
  fi
  
  # Reset MOCK_HOUR to safe time
  MOCK_HOUR=10
}

test_log_session() {
  log_test_header "log_session"

  # Override SESSION_LOG for testing
  SESSION_LOG="test_session.log"

  log_session "Focus" "Test Goal" "25"

  if [[ -f "$SESSION_LOG" ]]; then
    log_pass "Log file created."
  else
    log_fail "Log file NOT created."
    return
  fi

  if grep -q "Type: Focus | Description: Test Goal | Duration: 25m" "$SESSION_LOG"; then
    log_pass "Log entry content correct."
  else
    log_fail "Log entry content incorrect."
    cat "$SESSION_LOG"
  fi
}

test_get_valid_number() {
  log_test_header "get_valid_number"
  
  setup_mocks

  # Mock input using a file redirection or pipe
  # We need to simulate user input. 
  # get_valid_number uses 'read -e -p ...' inside 'get_input'
  
  # Test valid input
  # We pipe "42" to the function
  echo "42" | (
    # We need to source again inside subshell or export functions, 
    # but since we are in the same script and functions are defined, it should work if we just call it.
    # However, 'read' reads from stdin.
    get_valid_number "Enter number" "10" result 1 100
    if [[ "$result" -eq 42 ]]; then
       exit 0
    else
       exit 1
    fi
  )
  
  if [[ $? -eq 0 ]]; then
     log_pass "Valid number input accepted."
  else
     log_fail "Valid number input failed."
  fi

  # Test default value (empty input)
  echo "" | (
    get_valid_number "Enter number" "10" result 1 100
    if [[ "$result" -eq 10 ]]; then
       exit 0
    else
       exit 1
    fi
  )

  if [[ $? -eq 0 ]]; then
     log_pass "Default value accepted."
  else
     log_fail "Default value failed."
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
    echo -e "${GREEN}All tests passed!${NC}"
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
setup_mocks
test_minutes_to_seconds
test_get_phase_suggestion
test_log_session
test_get_valid_number
teardown

print_summary
