#!/bin/bash
# test_pomodoro.sh
# Automated test suite for pomodoro.sh

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

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
MOCK_HOUR=10

log_pass() {
  TESTS_PASSED=$((TESTS_PASSED+1))
  if [[ "$VERBOSE" = true ]]; then
    echo -e "${GREEN}[PASS]${NC} $1"
  fi
}

log_fail() {
  TESTS_FAILED=$((TESTS_FAILED+1))
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

  # mock sleep to speed up tests
  sleep() {
    return 0
  }
  export -f sleep
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

test_seconds_to_minutes() {
  log_test_header "seconds_to_minutes"

  # Test rounding up (30s -> 1m)
  local result=$(seconds_to_minutes 30)
  if [[ "$result" -eq 1 ]]; then
    log_pass "30 seconds rounded up to 1 minute."
  else
    log_fail "30 seconds conversion failed. Got: $result"
  fi

  # Test rounding down (29s -> 0m)
  result=$(seconds_to_minutes 29)
  if [[ "$result" -eq 0 ]]; then
    log_pass "29 seconds rounded down to 0 minutes."
  else
    log_fail "29 seconds conversion failed. Got: $result"
  fi

  # Test exact minute (60s -> 1m)
  result=$(seconds_to_minutes 60)
  if [[ "$result" -eq 1 ]]; then
    log_pass "60 seconds converted to 1 minute."
  else
    log_fail "60 seconds conversion failed. Got: $result"
  fi

  # Test rounding (90s -> 2m)
  result=$(seconds_to_minutes 90)
  if [[ "$result" -eq 2 ]]; then
    log_pass "90 seconds rounded to 2 minutes."
  else
    log_fail "90 seconds conversion failed. Got: $result"
  fi
}

test_get_phase_suggestion() {
  log_test_header "get_phase_suggestion"

  # mock date
  # we only care about date +%h for the script logic
  date() {
      if [[ "$1" == "+%H" ]]; then
        echo "$MOCK_HOUR"
      else
        command date "$@"
      fi
  }
  export -f date

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
  # Priority 3 is Slump Protection.
  # Priority 4 is Standard Ramp-up.
  # So Slump Protection overrides Standard Ramp-up.
  read focus break phase <<< $(get_phase_suggestion 0 3)
  if [[ "$focus" -eq 25 ]] && [[ "$break" -eq 5 ]] && [[ "$phase" == *"Afternoon_Slump"* ]]; then
    log_pass "Afternoon Slump suggestion correct (25/5 Slump Protection)."
  else
    log_fail "Afternoon Slump suggestion failed. Got: $focus/$break $phase"
  fi
  
  # reset mock_hour to safe time
  MOCK_HOUR=10
}

test_countdown() {
  log_test_header "countdown"

  setup_mocks

  # run countdown for 2 seconds
  # capture output to avoid cluttering test log
  local output=$(countdown 2)

  # check if it ran (exit code 0)
  if [[ $? -eq 0 ]]; then
     log_pass "Countdown ran successfully."
  else
     log_fail "Countdown failed to run."
  fi

  # check for expected output strings
  if [[ "$output" == *"remaining"* ]]; then
     log_pass "Countdown output contains 'remaining'."
  else
     log_fail "Countdown output missing 'remaining'. Output: $output"
  fi
}

test_get_input() {
  log_test_header "get_input"

  setup_mocks

  # test case 1: explicit input
  echo "test_value" | (
    get_input "Enter value" "default" result
    if [[ "$result" == "test_value" ]]; then
       exit 0
    else
       exit 1
    fi
  )

  if [[ $? -eq 0 ]]; then
     log_pass "Explicit input accepted."
  else
     log_fail "Explicit input failed."
  fi

  # test case 2: default value
  echo "" | (
    get_input "Enter value" "default_val" result
    if [[ "$result" == "default_val" ]]; then
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

test_log_session() {
  log_test_header "log_session"

  # Override SESSION_LOG for testing
  SESSION_LOG="test_session.log"

  log_session "Focus" "Test Goal" "25" "4" "Deep_Work" "50" "10"

  if [[ -f "$SESSION_LOG" ]]; then
    log_pass "Log file created."
  else
    log_fail "Log file NOT created."
    return
  fi

  # Verify full log format
  local expected="Type: Focus | Description: Test Goal | Duration: 25m | Energy: 4 | Phase: Deep_Work | Suggested: 50m/10m"
  if grep -q "$expected" "$SESSION_LOG"; then
    log_pass "Log entry content correct."
  else
    log_fail "Log entry content incorrect."
    echo "Expected: $expected"
    echo "Actual:   $(cat "$SESSION_LOG")"
  fi
}

test_log_session_break() {
  log_test_header "log_session (Break)"

  # Override SESSION_LOG for testing
  SESSION_LOG="test_session_break.log"

  log_session "Break" "Coffee" "5" "3" "Deep_Work" "50" "10"

  if [[ -f "$SESSION_LOG" ]]; then
    log_pass "Break Log file created."
  else
    log_fail "Break Log file NOT created."
    return
  fi

  # Verify full log format
  local expected="Type: Break | Description: Coffee | Duration: 5m | Energy: 3 | Phase: Deep_Work | Suggested: 50m/10m"
  if grep -q "$expected" "$SESSION_LOG"; then
    log_pass "Break Log entry content correct."
  else
    log_fail "Break Log entry content incorrect."
    echo "Expected: $expected"
    echo "Actual:   $(cat "$SESSION_LOG")"
  fi
}

test_calculate_daily_total() {
  log_test_header "calculate_daily_total"

  # Override SESSION_LOG for testing
  SESSION_LOG="test_calc_session.log"
  rm -f "$SESSION_LOG"

  # Test with non-existent file
  local result=$(calculate_daily_total "Focus")
  if [[ "$result" -eq 0 ]]; then
    log_pass "calculate_daily_total returns 0 when log file does not exist."
  else
    log_fail "calculate_daily_total failed on non-existent file. Got: $result"
  fi

  # Create mock log entries
  local today=$(command date "+%Y-%m-%d")

  echo "$today 10:00:00 | Type: Focus | Description: Task 1 | Duration: 25m" > "$SESSION_LOG"
  echo "$today 11:00:00 | Type: Focus | Description: Task 2 | Duration: 50m" >> "$SESSION_LOG"
  echo "$today 12:00:00 | Type: Break | Description: Lunch | Duration: 15m" >> "$SESSION_LOG"
  echo "2020-01-01 10:00:00 | Type: Focus | Description: Old Task | Duration: 60m" >> "$SESSION_LOG"

  # Test Focus calculation for today
  result=$(calculate_daily_total "Focus")
  if [[ "$result" -eq 75 ]]; then
    log_pass "calculate_daily_total correctly sums focus duration (75m)."
  else
    log_fail "calculate_daily_total focus sum failed. Expected 75, got: $result"
  fi

  # Test Break calculation for today
  result=$(calculate_daily_total "Break")
  if [[ "$result" -eq 15 ]]; then
    log_pass "calculate_daily_total correctly sums break duration (15m)."
  else
    log_fail "calculate_daily_total break sum failed. Expected 15, got: $result"
  fi

  rm -f "$SESSION_LOG"
}

test_get_valid_number() {
  log_test_header "get_valid_number"

  setup_mocks

  # mock input using a file redirection or pipe
  # we need to simulate user input.
  # get_valid_number uses 'read -e -p ...' inside 'get_input'

  # test valid input
  # we pipe "42" to the function
  echo "42" | (
    # we need to source again inside subshell or export functions,
    # but since we are in the same script and functions are defined, it should work if we just call it.
    # however, 'read' reads from stdin.
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

  # test default value (empty input)
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

test_format_phase() {
  log_test_header "format_phase"

  local result=$(format_phase "The_Reset_(Burnout_Prev)")
  if [[ "$result" == "The Reset (Burnout Prev)" ]]; then
    log_pass "Phase formatting correct."
  else
    log_fail "Phase formatting failed. Got: $result"
  fi
}

test_get_energy_level() {
  log_test_header "get_energy_level"
  setup_mocks

  # Mock input "4"
  echo "4" | (
    get_energy_level energy_val
    if [[ "$energy_val" -eq 4 ]]; then
       exit 0
    else
       exit 1
    fi
  )

  if [[ $? -eq 0 ]]; then
     log_pass "Energy level input accepted."
  else
     log_fail "Energy level input failed."
  fi
}

test_get_goal() {
  log_test_header "get_goal"
  setup_mocks

  # Mock input "short" then "long_enough_goal"
  # We need to simulate the loop.
  # get_goal calls get_input.
  # We can pipe multiple lines.

  (echo "short"; echo "long_enough_goal") | (
    get_goal "Prompt" "prev" goal_val "true" > /dev/null
    if [[ "$goal_val" == "long_enough_goal" ]]; then
       exit 0
    else
       exit 1
    fi
  )

  if [[ $? -eq 0 ]]; then
     log_pass "Goal validation accepted valid goal."
  else
     log_fail "Goal validation failed."
  fi
}

test_print_final_status() {
  log_test_header "print_final_status"

  # Capture output
  local output=$(print_final_status "Focus" "My Goal" "25")

  if [[ "$output" == *">>>"* ]] && [[ "$output" == *"Focus"* ]] && [[ "$output" == *"My Goal"* ]] && [[ "$output" == *"25 min"* ]]; then
    log_pass "Focus status printed correctly."
  else
    log_fail "Focus status output incorrect. Got: $output"
  fi

  output=$(print_final_status "Break" "Coffee" "5")
  if [[ "$output" == *">>>"* ]] && [[ "$output" == *"Break"* ]] && [[ "$output" == *"Coffee"* ]] && [[ "$output" == *"5 min"* ]]; then
    log_pass "Break status printed correctly."
  else
    log_fail "Break status output incorrect. Got: $output"
  fi
}

test_notify() {
  log_test_header "notify"

  local notify_args=""
  notify-send() {
    notify_args="$*"
    return 0
  }
  export -f notify-send

  # test notify with urgency "normal" and a message
  notify "normal" "Test message"

  if [[ "$notify_args" == "-u normal Pomodoro Test message" ]]; then
    log_pass "notify calls notify-send with specified urgency and message."
  else
    log_fail "notify failed with urgency and message. Got: '$notify_args'"
  fi

  # test notify with single argument defaulting to normal
  notify "Default message"
  if [[ "$notify_args" == "-u normal Pomodoro Default message" ]]; then
    log_pass "notify defaults to normal urgency when only message is provided."
  else
    log_fail "notify default urgency failed. Got: '$notify_args'"
  fi
}

test_notify_sound() {
  log_test_header "notify_sound"

  local args_file="paplay_args_test.tmp"
  rm -f "$args_file"

  paplay() {
    echo "$*" > "paplay_args_test.tmp"
    return 0
  }
  # export function to make it available to subshells.
  export -f paplay

  # Test without volume parameter
  notify_sound "test_sound.wav"

  # wait for background process to complete
  wait

  local captured=""
  [[ -f "$args_file" ]] && captured=$(cat "$args_file")
  if [[ "$captured" == "test_sound.wav" ]]; then
    log_pass "notify_sound plays sound without volume option when not specified."
  else
    log_fail "notify_sound failed without volume. Got: '$captured'"
  fi

  rm -f "$args_file"

  # Test with volume parameter
  notify_sound "test_sound.wav" 16384
  wait
  captured=""
  [[ -f "$args_file" ]] && captured=$(cat "$args_file")
  if [[ "$captured" == "--volume=16384 test_sound.wav" ]]; then
    log_pass "notify_sound plays sound with --volume option when volume is specified."
  else
    log_fail "notify_sound failed with volume. Got: '$captured'"
  fi

  rm -f "$args_file"
}

test_run_focus() {
  log_test_header "run_focus"
  setup_mocks

  # mock dependencies specific to run_focus
  countdown() { return 0; }
  export -f countdown
  local notify_sound_args=""
  notify_sound() {
    notify_sound_args="$*"
    return 0
  }
  export -f notify_sound
  local notify_calls=()
  notify() {
    notify_calls+=("$*")
    return 0
  }
  export -f notify

  # mock used functions by overriding them
  get_goal() {
    local -n _goal_ref="$3"
    _goal_ref="Final Goal"
  }
  export -f get_goal

  LOG_CALLED=false
  log_session() {
    LOG_CALLED=true
  }
  export -f log_session

  # test execution
  local elapsed_time=100

  # run_focus "goal" "duration" "energy" "phase" "s_focus" "s_break" "__elapsed_ref" "__goal_ref"

  # clean up state file if exists
  rm -f date_call_count

  # mock date to return start time, then end time (start + 1500s = 25m)
  # date +%s is called twice: start_time and end_time.
  date() {
    if [[ "$1" == "+%s" ]]; then
       # state file to track calls
       if [[ ! -f "date_call_count" ]]; then
         echo 10000 > date_call_count
         echo 10000
       else
         # second call, return 10000 + 1500 (25 min)
         echo 11500
       fi
    else
       command date "$@"
    fi
  }
  export -f date

  # clean up the used state file
  rm -f date_call_count

  local current_goal="Test Goal"
  run_focus "$current_goal" "25" "5" "Flow" "60" "10" elapsed_time current_goal > /dev/null

  # verify elapsed time updated (100 + 25 = 125)
  if [[ "$elapsed_time" -eq 125 ]]; then
    log_pass "Elapsed time updated correctly."
  else
    log_fail "Elapsed time update failed. Expected 125, got $elapsed_time"
  fi

  # verify goal updated
  if [[ "$current_goal" == "Final Goal" ]]; then
    log_pass "Goal reference updated correctly to 'Final Goal'."
  else
    log_fail "Goal reference update failed. Expected 'Final Goal', got '$current_goal'"
  fi

  # verify log_session called
  if [[ "$LOG_CALLED" == "true" ]]; then
    log_pass "Session logged."
  else
    log_fail "Session NOT logged."
  fi

  # verify notify_sound was called with FOCUS_END_SOUND and FOCUS_END_VOLUME
  if [[ "$notify_sound_args" == "$FOCUS_END_SOUND $FOCUS_END_VOLUME" ]]; then
    log_pass "Focus sound called with reduced volume ($FOCUS_END_VOLUME)."
  else
    log_fail "Focus sound not called with expected args. Expected '$FOCUS_END_SOUND $FOCUS_END_VOLUME', got '$notify_sound_args'"
  fi

  # verify all focus session notifications used normal urgency (preventing sticky alerts)
  local all_notifications_normal=true
  for call in "${notify_calls[@]}"; do
    if [[ "$call" != *"normal"* ]]; then
      all_notifications_normal=false
    fi
  done
  if [[ "$all_notifications_normal" == "true" ]]; then
    log_pass "All focus notifications used normal urgency."
  else
    log_fail "Non-normal notification sent during focus: ${notify_calls[*]}"
  fi

  rm -f date_call_count
}

test_run_break() {
  log_test_header "run_break"
  setup_mocks

  # mock dependencies
  countdown() { return 0; }
  export -f countdown
  notify_sound() { return 0; }
  export -f notify_sound

  local notify_break_calls=()
  notify() {
    notify_break_calls+=("$*")
    return 0
  }
  export -f notify

  # mock inputs
  get_input() {
    local -n _input_ref="$3"
    _input_ref="Resting"
  }
  export -f get_input

  get_valid_number() {
    local -n _num_ref="$3"
    _num_ref="5"
  }
  export -f get_valid_number

  LOG_CALLED=false
  log_session() {
    LOG_CALLED=true
  }
  export -f log_session

  # clean up state file if exists
  rm -f date_call_count_break

  # mock date for duration calc (5 min = 300s)
  date() {
    if [[ "$1" == "+%s" ]]; then
       if [[ ! -f "date_call_count_break" ]]; then
         echo 20000 > date_call_count_break
         echo 20000
       else
         echo 20300
       fi
    else
       command date "$@"
    fi
  }
  export -f date
  rm -f date_call_count_break

  run_break "5" "3" "Phase" "25" > /dev/null

  if [[ "$LOG_CALLED" == "true" ]]; then
    log_pass "Break session logged."
  else
    log_fail "Break session NOT logged."
  fi

  # verify all break session notifications used normal urgency (preventing sticky alerts)
  local all_notifications_normal=true
  for call in "${notify_break_calls[@]}"; do
    if [[ "$call" != *"normal"* ]]; then
      all_notifications_normal=false
    fi
  done
  if [[ "$all_notifications_normal" == "true" ]]; then
    log_pass "All break notifications used normal urgency."
  else
    log_fail "Non-normal notification sent during break: ${notify_break_calls[*]}"
  fi

  rm -f date_call_count_break
}

test_countdown_interrupted() {
  log_test_header "countdown_interrupted"
  setup_mocks

  local exit_code=0
  (
    # store the child pid
    sub_pid=$BASHPID
    (
      # send SIGINT to the child after 0.2 seconds from grandchild process
      sleep 0.2 && kill -INT "$sub_pid"
    # should run in the background so that SIGINT should be caught by countdown.
    ) &

    countdown 10 > /dev/null
  ) || exit_code=$?

  if [[ "$exit_code" -eq 130 ]]; then
    log_pass "Countdown returned 130 on SIGINT interrupt."
  else
    log_fail "Countdown did not return 130 on SIGINT. Got: $exit_code"
  fi
}

test_handle_session_interruption() {
  log_test_header "handle_session_interruption"
  setup_mocks

  local action=""

  # Test default (empty input -> finish)
  echo "" | (
    handle_session_interruption "Focus" 14 25 action > /dev/null
    if [[ "$action" == "finish" ]]; then exit 0; else exit 1; fi
  )
  if [[ $? -eq 0 ]]; then
    log_pass "Default choice selects finish."
  else
    log_fail "Default choice failed to select finish."
  fi

  # Test choice 2 -> discard
  echo "2" | (
    handle_session_interruption "Focus" 14 25 action > /dev/null
    if [[ "$action" == "discard" ]]; then exit 0; else exit 1; fi
  )
  if [[ $? -eq 0 ]]; then
    log_pass "Choice 2 selects discard."
  else
    log_fail "Choice 2 failed to select discard."
  fi

  # Test choice 3 -> save_exit
  echo "3" | (
    handle_session_interruption "Focus" 14 25 action > /dev/null
    if [[ "$action" == "save_exit" ]]; then exit 0; else exit 1; fi
  )
  if [[ $? -eq 0 ]]; then
    log_pass "Choice 3 selects save_exit."
  else
    log_fail "Choice 3 failed to select save_exit."
  fi

  # Test choice 4 -> abort_exit
  echo "4" | (
    handle_session_interruption "Focus" 14 25 action > /dev/null
    if [[ "$action" == "abort_exit" ]]; then exit 0; else exit 1; fi
  )
  if [[ $? -eq 0 ]]; then
    log_pass "Choice 4 selects abort_exit."
  else
    log_fail "Choice 4 failed to select abort_exit."
  fi

  # Test break session options display
  local break_output
  break_output=$(echo "1" | handle_session_interruption "Break" 2 5 action)
  if [[ "$break_output" == *"End break early"* ]] && [[ "$break_output" == *"Skip break"* ]]; then
    log_pass "Break interruption menu displays break-specific options."
  else
    log_fail "Break interruption menu missing break-specific options."
  fi
}

test_run_focus_interrupted_finish() {
  log_test_header "run_focus_interrupted_finish"
  setup_mocks

  countdown() { return 130; }
  export -f countdown
  notify() { return 0; }
  export -f notify
  notify_sound() { return 0; }
  export -f notify_sound

  get_goal() {
    local -n _g_ref="$3"
    _g_ref="Interrupted Goal"
  }
  export -f get_goal

  local logged=false
  log_session() {
    logged=true
  }
  export -f log_session

  rm -f date_call_count_focus_int
  date() {
    if [[ "$1" == "+%s" ]]; then
       if [[ ! -f "date_call_count_focus_int" ]]; then
         echo 10000 > date_call_count_focus_int
         echo 10000
       else
         echo 10600
       fi
    else
       command date "$@"
    fi
  }
  export -f date

  local elapsed=50
  local current_goal="Test Goal"

  # User chooses 1 (finish early)
  run_focus "$current_goal" 25 3 "High_Urgency" 25 5 elapsed current_goal <<< "1" > /dev/null

  rm -f date_call_count_focus_int

  if [[ "$logged" == "true" ]]; then
    log_pass "Interrupted focus was logged when choosing finish early."
  else
    log_fail "Interrupted focus was NOT logged."
  fi

  if [[ "$elapsed" -eq 60 ]]; then
    log_pass "Elapsed focus time updated with actual 10m (50 -> 60)."
  else
    log_fail "Elapsed focus time incorrect. Expected 60, got: $elapsed"
  fi
}

test_run_focus_interrupted_discard() {
  log_test_header "run_focus_interrupted_discard"
  setup_mocks

  countdown() { return 130; }
  export -f countdown
  notify() { return 0; }
  export -f notify
  notify_sound() { return 0; }
  export -f notify_sound

  local logged=false
  log_session() {
    logged=true
  }
  export -f log_session

  rm -f date_call_count_focus_disc
  date() {
    if [[ "$1" == "+%s" ]]; then
       if [[ ! -f "date_call_count_focus_disc" ]]; then
         echo 10000 > date_call_count_focus_disc
         echo 10000
       else
         echo 10600
       fi
    else
       command date "$@"
    fi
  }
  export -f date

  local elapsed=50
  local current_goal="Test Goal"

  # User chooses 2 (discard session)
  run_focus "$current_goal" 25 3 "High_Urgency" 25 5 elapsed current_goal <<< "2" > /dev/null

  rm -f date_call_count_focus_disc

  if [[ "$logged" == "false" ]]; then
    log_pass "Discarded focus was NOT logged."
  else
    log_fail "Discarded focus was logged."
  fi

  if [[ "$elapsed" -eq 50 ]]; then
    log_pass "Elapsed focus time remained unchanged (50)."
  else
    log_fail "Elapsed focus time changed unexpectedly. Expected 50, got: $elapsed"
  fi
}

test_run_break_interrupted_finish() {
  log_test_header "run_break_interrupted_finish"
  setup_mocks

  countdown() { return 130; }
  export -f countdown
  notify() { return 0; }
  export -f notify
  notify_sound() { return 0; }
  export -f notify_sound

  get_input() {
    local -n _i_ref="$3"
    _i_ref="Short Rest"
  }
  export -f get_input

  get_valid_number() {
    local -n _n_ref="$3"
    _n_ref="5"
  }
  export -f get_valid_number

  local logged=false
  local logged_type=""
  log_session() {
    logged=true
    logged_type="$1"
  }
  export -f log_session

  rm -f date_call_count_break_int
  date() {
    if [[ "$1" == "+%s" ]]; then
       if [[ ! -f "date_call_count_break_int" ]]; then
         echo 20000 > date_call_count_break_int
         echo 20000
       else
         echo 20120  # 120s = 2m
       fi
    else
       command date "$@"
    fi
  }
  export -f date

  # User chooses 1 (End break early)
  run_break 5 3 "Phase" 25 <<< "1" > /dev/null

  rm -f date_call_count_break_int

  if [[ "$logged" == "true" ]] && [[ "$logged_type" == "Break" ]]; then
    log_pass "Interrupted break was logged when choosing finish early."
  else
    log_fail "Interrupted break was NOT logged."
  fi
}

test_run_break_interrupted_discard() {
  log_test_header "run_break_interrupted_discard"
  setup_mocks

  countdown() { return 130; }
  export -f countdown
  notify() { return 0; }
  export -f notify
  notify_sound() { return 0; }
  export -f notify_sound

  get_input() {
    local -n _i_ref="$3"
    _i_ref="Short Rest"
  }
  export -f get_input

  get_valid_number() {
    local -n _n_ref="$3"
    _n_ref="5"
  }
  export -f get_valid_number

  local logged=false
  log_session() {
    logged=true
  }
  export -f log_session

  rm -f date_call_count_break_disc
  date() {
    if [[ "$1" == "+%s" ]]; then
       if [[ ! -f "date_call_count_break_disc" ]]; then
         echo 20000 > date_call_count_break_disc
         echo 20000
       else
         echo 20120
       fi
    else
       command date "$@"
    fi
  }
  export -f date

  # User chooses 2 (Skip break)
  run_break 5 3 "Phase" 25 <<< "2" > /dev/null

  rm -f date_call_count_break_disc

  if [[ "$logged" == "false" ]]; then
    log_pass "Discarded break was NOT logged."
  else
    log_fail "Discarded break was logged."
  fi
}

test_run_break_activity_preservation() {
  log_test_header "run_break_activity_preservation"
  setup_mocks

  countdown() { return 0; }
  export -f countdown
  notify_sound() { return 0; }
  export -f notify_sound
  notify() { return 0; }
  export -f notify
  get_valid_number() {
    local -n _num_ref="$3"
    _num_ref="5"
  }
  export -f get_valid_number

  local captured_defaults=()
  get_input() {
    local prompt="$1"
    local default="$2"
    local -n _input_ref="$3"
    captured_defaults+=("$default")
    if [[ "$prompt" == "Break Activity" ]]; then
      if [[ -n "$default" ]]; then
        _input_ref="$default"
      else
        _input_ref="reading: emile by jean-jacques rousseau"
      fi
    else
      _input_ref="$default"
    fi
  }
  export -f get_input

  log_session() { return 0; }
  export -f log_session

  # Session 1: initial empty previous_break
  local previous_break=""
  run_break 5 3 "Phase" 25 previous_break > /dev/null

  if [[ "$previous_break" == "reading: emile by jean-jacques rousseau" ]]; then
    log_pass "First break sets previous_break activity."
  else
    log_fail "First break failed to set previous_break. Got: '$previous_break'"
  fi

  if [[ "${captured_defaults[0]}" == "" ]]; then
    log_pass "First break had no default value initially."
  else
    log_fail "First break default was not empty. Got: '${captured_defaults[0]}'"
  fi

  # Session 2: uses preserved previous_break as default
  run_break 5 3 "Phase" 25 previous_break > /dev/null

  if [[ "${captured_defaults[2]}" == "reading: emile by jean-jacques rousseau" ]]; then
    log_pass "Second break used preserved activity as default value."
  else
    log_fail "Second break did not use preserved activity. Got: '${captured_defaults[2]}'"
  fi
}

test_run_break_surpassed_duration() {
  log_test_header "run_break_surpassed_duration"
  setup_mocks

  countdown() { return 0; }
  export -f countdown
  notify_sound() { return 0; }
  export -f notify_sound
  notify() { return 0; }
  export -f notify

  get_input() {
    local -n _input_ref="$3"
    _input_ref="preparing coffee"
  }
  export -f get_input

  get_valid_number() {
    local -n _num_ref="$3"
    _num_ref="10"
  }
  export -f get_valid_number

  local logged_duration=""
  log_session() {
    logged_duration="$3"
  }
  export -f log_session

  rm -f date_call_count_break_surpassed
  # Start time: 20000, End time: 20900 (15 min elapsed for 10 min suggested break)
  date() {
    if [[ "$1" == "+%s" ]]; then
       if [[ ! -f "date_call_count_break_surpassed" ]]; then
         echo 20000 > date_call_count_break_surpassed
         echo 20000
       else
         echo 20900
       fi
    else
       command date "$@"
    fi
  }
  export -f date

  run_break "10" "3" "Phase" "25" > /dev/null

  rm -f date_call_count_break_surpassed

  if [[ "$logged_duration" == "15" ]]; then
    log_pass "Break session logged actual elapsed duration (15m) when surpassing suggested 10m."
  else
    log_fail "Break session failed to log actual elapsed duration. Expected 15, got: $logged_duration"
  fi
}

test_run_focus_surpassed_duration() {
  log_test_header "run_focus_surpassed_duration"
  setup_mocks

  countdown() { return 0; }
  export -f countdown
  notify_sound() { return 0; }
  export -f notify_sound
  notify() { return 0; }
  export -f notify

  get_goal() {
    local -n _goal_ref="$3"
    _goal_ref="Extended Focus Goal"
  }
  export -f get_goal

  local logged_duration=""
  log_session() {
    logged_duration="$3"
  }
  export -f log_session

  rm -f date_call_count_focus_surpassed
  # Start time: 10000, End time: 12100 (35 min elapsed for 25 min planned focus)
  date() {
    if [[ "$1" == "+%s" ]]; then
       if [[ ! -f "date_call_count_focus_surpassed" ]]; then
         echo 10000 > date_call_count_focus_surpassed
         echo 10000
       else
         echo 12100
       fi
    else
       command date "$@"
    fi
  }
  export -f date

  local elapsed=50
  local current_goal="Test Goal"
  run_focus "$current_goal" "25" "3" "Phase" "25" "5" elapsed current_goal > /dev/null

  rm -f date_call_count_focus_surpassed

  if [[ "$logged_duration" == "35" ]]; then
    log_pass "Focus session logged actual elapsed duration (35m) when surpassing planned 25m."
  else
    log_fail "Focus session failed to log actual elapsed duration. Expected 35, got: $logged_duration"
  fi

  if [[ "$elapsed" -eq 85 ]]; then
    log_pass "Elapsed focus time updated with actual 35m (50 -> 85)."
  else
    log_fail "Elapsed focus time incorrect. Expected 85, got: $elapsed"
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
test_seconds_to_minutes
test_get_phase_suggestion
test_log_session
test_log_session_break
test_calculate_daily_total
test_get_valid_number
test_countdown
test_countdown_interrupted
test_handle_session_interruption
test_get_input
test_format_phase
test_get_energy_level
test_get_goal
test_print_final_status
test_notify
test_notify_sound
test_run_focus
test_run_focus_interrupted_finish
test_run_focus_interrupted_discard
test_run_focus_surpassed_duration
test_run_break
test_run_break_interrupted_finish
test_run_break_interrupted_discard
test_run_break_activity_preservation
test_run_break_surpassed_duration
teardown

print_summary
