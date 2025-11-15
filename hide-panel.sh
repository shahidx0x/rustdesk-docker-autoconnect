#!/bin/bash
sleep 8
# Try to hide XFCE panel using xfconf-query
export DISPLAY=:1
export XAUTHORITY=/home/kasm-user/.Xauthority
su - kasm-user -c "xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -s 1" 2>/dev/null || true
# Alternative: try to kill and remove panel
pkill -f "xfce4-panel" 2>/dev/null || true
sleep 1
# Hide any remaining panels using xdotool
WINDOW=$(xdotool search --class "Xfce4-panel" 2>/dev/null | head -1)
if [ ! -z "$WINDOW" ]; then
  xdotool windowunmap $WINDOW 2>/dev/null || true
fi