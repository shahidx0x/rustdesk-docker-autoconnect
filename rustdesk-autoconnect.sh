#!/bin/bash
sleep 5
if [ ! -z "$REMOTE_ID" ]; then
  echo "Auto-filling Remote ID: $REMOTE_ID"
  # Wait for RustDesk to fully load
  for i in {1..5}; do
    WINDOW=$(xdotool search --name "RustDesk" 2>/dev/null | head -1)
    if [ ! -z "$WINDOW" ]; then
      break
    fi
    sleep 1
  done
  if [ ! -z "$WINDOW" ]; then
    echo "Found RustDesk window: $WINDOW"
    xdotool windowactivate $WINDOW
    sleep 1
    # Click on Remote ID input field
    xdotool mousemove 271 165
    xdotool click 1
    sleep 1
    # Type the Remote ID
    xdotool type --delay 50 "$REMOTE_ID"
    sleep 1
    echo "Remote ID entered successfully"
    sleep 2
    # Check if REMOTE_PASS is provided
    if [ ! -z "$REMOTE_PASS" ]; then
      echo "Entering remote password: $REMOTE_PASS"
      sleep 2
      # Click on password input field
      xdotool mousemove 614 408
      xdotool click 1
      sleep 1
      # Type the password
      xdotool type --delay 50 "$REMOTE_PASS"
      sleep 1
      # Click OK button
      xdotool mousemove 730 509
      xdotool click 1
      echo "Password entered and OK clicked"
    fi
    echo "Remote ID entered and Connect clicked"
  else
    echo "RustDesk window not found"
  fi
fi