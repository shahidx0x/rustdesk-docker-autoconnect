#!/bin/bash

# Configuration variables - easily adjustable coordinates
REMOTE_ID_X=271
REMOTE_ID_Y=165
CONNECT_BUTTON_X=472
CONNECT_BUTTON_Y=218
PASSWORD_X=614
PASSWORD_Y=408
OK_BUTTON_X=730
OK_BUTTON_Y=509

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
    xdotool mousemove $REMOTE_ID_X $REMOTE_ID_Y
    xdotool click 1
    sleep 1
    # Type the Remote ID
    xdotool type --delay 50 "$REMOTE_ID"
    sleep 1
    # Click Connect button
    xdotool mousemove $CONNECT_BUTTON_X $CONNECT_BUTTON_Y
    xdotool click 1
    sleep 1
    echo "Remote ID entered and Connect clicked"
    sleep 2
    # Check if REMOTE_PASS is provided
    if [ ! -z "$REMOTE_PASS" ]; then
      echo "Entering remote password: $REMOTE_PASS"
      sleep 2
      # Click on password input field
      xdotool mousemove $PASSWORD_X $PASSWORD_Y
      xdotool click 1
      sleep 1
      # Type the password
      xdotool type --delay 50 "$REMOTE_PASS"
      sleep 1
      # Click OK button
      xdotool mousemove $OK_BUTTON_X $OK_BUTTON_Y
      xdotool click 1
      echo "Password entered and OK clicked"
    fi
    echo "Connection process completed"
  else
    echo "RustDesk window not found"
  fi
fi