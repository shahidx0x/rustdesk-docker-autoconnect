#!/bin/bash
sleep 12
# Set proper environment
export DISPLAY=:1
export XAUTHORITY=/home/kasm-user/.Xauthority

echo "Starting panel hide process..."

# Method 1: Set panel to autohide using xfconf-query
echo "Setting panel to autohide..."
su - kasm-user -c "xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -s 1" 2>/dev/null || echo "xfconf-query failed"
su - kasm-user -c "xfconf-query -c xfce4-panel -p /panels/panel-1/length -s 1" 2>/dev/null || echo "xfconf-query length failed"

# Method 2: Try to minimize/hide panel using xdotool
sleep 2
echo "Trying xdotool method..."
PANEL_WINDOW=$(xdotool search --class "Xfce4-panel" 2>/dev/null | head -1)
if [ ! -z "$PANEL_WINDOW" ]; then
  echo "Found panel window: $PANEL_WINDOW"
  # Try to minimize the panel
  xdotool windowminimize $PANEL_WINDOW 2>/dev/null || echo "Minimize failed"
  # Alternative: try to move it off-screen
  xdotool windowmove $PANEL_WINDOW 0 -50 2>/dev/null || echo "Move failed"
else
  echo "Panel window not found"
fi

# Method 3: Kill and restart panel with autohide settings
sleep 1
echo "Restarting panel..."
pkill -f "xfce4-panel" 2>/dev/null || echo "Kill failed"
sleep 2
su - kasm-user -c "xfce4-panel &" 2>/dev/null || echo "Restart failed"

echo "Panel hide process completed"