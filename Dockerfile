FROM docker.io/kasmweb/core-ubuntu-noble:1.16.1
USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
ENV INST_SCRIPTS=$STARTUPDIR/install
WORKDIR $HOME



RUN add-apt-repository ppa:pipewire-debian/pipewire-upstream \
    && apt update \
    && apt install -f libxcb-randr0 libxdo3 gstreamer1.0-pipewire -y \
    && LATESTURL="$(curl -f -L https://github.com/rustdesk/rustdesk/releases/latest | grep -Eo 'https://[a-zA-Z0-9#~.*,/!?=+&_%:-]*-'$(arch)'.deb')" \
    && curl -L -o /rustdesk.deb $LATESTURL \
    && dpkg -i /rustdesk.deb \
    && apt install -f -y \
    && rm -rf /rustdesk.deb /var/lib/apt/lists/*

RUN mkdir -p $HOME/.local/share/applications

COPY rustdesk.desktop /rustdesk.desktop
# COPY rustdesk.png /rustdesk.png
# COPY wallpaper.png /usr/share/backgrounds/bg_default.png

RUN mkdir -p $HOME/.local/share/applications $HOME/Desktop $HOME/.config/autostart \
    && ln -s /rustdesk.desktop $HOME/Desktop/rustdesk.desktop \
    && ln -s /rustdesk.desktop $HOME/.local/share/applications/rustdesk.desktop \
    && ln -s /rustdesk.desktop $HOME/.config/autostart/rustdesk.desktop

######### End Customizations ###########

RUN chown 1000:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME

ENV HOME=/home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

# Set fixed password for kasm-user and add to sudo group
RUN echo "kasm-user:121212" | chpasswd \
    && usermod -aG sudo kasm-user

# Copy RustDesk configuration files
RUN mkdir -p $HOME/.config/rustdesk $HOME/.config/autostart
COPY --chown=1000:0 RustDesk2.toml $HOME/.config/rustdesk/RustDesk2.toml
COPY --chown=1000:0 Rustdesk_local.toml $HOME/.config/rustdesk/RustDesk_local.toml

# Install xdotool for GUI automation
RUN apt-get update && apt-get install -y xdotool && rm -rf /var/lib/apt/lists/*

# Create auto-connect script
RUN echo '#!/bin/bash' > /usr/local/bin/rustdesk-autoconnect.sh \
    && echo 'sleep 5' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo 'if [ ! -z "$REMOTE_ID" ]; then' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '  echo "Auto-filling Remote ID: $REMOTE_ID"' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '  # Wait for RustDesk to fully load' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '  for i in {1..5}; do' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    WINDOW=$(xdotool search --name "RustDesk" 2>/dev/null | head -1)' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    if [ ! -z "$WINDOW" ]; then' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      break' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    fi' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    sleep 1' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '  done' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '  if [ ! -z "$WINDOW" ]; then' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    echo "Found RustDesk window: $WINDOW"' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    xdotool windowactivate $WINDOW' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    sleep 1' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    # Click on Remote ID input field' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    xdotool mousemove 271 165' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    xdotool click 1' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    sleep 1' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    # Type the Remote ID' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    xdotool type --delay 50 "$REMOTE_ID"' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    sleep 1' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    # Click Connect button' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    xdotool mousemove 472 218' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    xdotool click 1' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    echo "Remote ID entered and Connect clicked"' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '  else' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    echo "RustDesk window not found"' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '  fi' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo 'fi' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && chmod +x /usr/local/bin/rustdesk-autoconnect.sh

# Add auto-connect script to autostart
RUN echo '[Desktop Entry]' > $HOME/.config/autostart/rustdesk-autoconnect.desktop \
    && echo 'Type=Application' >> $HOME/.config/autostart/rustdesk-autoconnect.desktop \
    && echo 'Exec=/usr/local/bin/rustdesk-autoconnect.sh' >> $HOME/.config/autostart/rustdesk-autoconnect.desktop \
    && echo 'Hidden=false' >> $HOME/.config/autostart/rustdesk-autoconnect.desktop \
    && echo 'NoDisplay=false' >> $HOME/.config/autostart/rustdesk-autoconnect.desktop \
    && echo 'X-GNOME-Autostart-enabled=true' >> $HOME/.config/autostart/rustdesk-autoconnect.desktop \
    && echo 'Name=RustDesk Auto Connect' >> $HOME/.config/autostart/rustdesk-autoconnect.desktop

RUN chown -R 1000:0 $HOME/.config $HOME