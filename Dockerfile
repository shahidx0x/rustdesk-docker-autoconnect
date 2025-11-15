FROM docker.io/kasmweb/core-ubuntu-noble:1.18.0-rolling-daily
USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
ENV INST_SCRIPTS=$STARTUPDIR/install
# ENV VNC_SSL=0
# Remove SSL certificates to force HTTP-only mode
# Certificate locations that may exist depending on KasmVNC version:
# - /etc/ssl/certs/ssl-cert-snakeoil.pem (public cert)
# - /etc/ssl/private/ssl-cert-snakeoil.key (private key)
# - /etc/ssl/private/kasmvnc.pem (older versions - combined cert/key)
# - /opt/kasm/current/certs/kasm_nginx.crt (Kasm nginx cert)
# - /opt/kasm/current/certs/kasm_nginx.key (Kasm nginx key)
# To use custom certificates, you can pass -cert and -key arguments to vncserver:
# vncserver -cert /path/to/cert.pem -key /path/to/key.pem
# RUN rm -f /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/private/ssl-cert-snakeoil.key 2>/dev/null || true \
#     && rm -f /etc/ssl/private/kasmvnc.pem 2>/dev/null || true \
#     && rm -f /opt/kasm/current/certs/kasm_nginx.crt /opt/kasm/current/certs/kasm_nginx.key 2>/dev/null || true
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

# Copy KasmVNC configuration (certificates will be bind-mounted at runtime)
COPY kasmvnc.yaml /etc/kasmvnc/kasmvnc.yaml

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
    && echo '    echo "Remote ID entered successfully"' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    # Click Connect button' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    xdotool mousemove 470 216' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    xdotool click 1' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    sleep 2' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    # Check if REMOTE_PASS is provided' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    if [ ! -z "$REMOTE_PASS" ]; then' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      echo "Entering remote password: $REMOTE_PASS"' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      sleep 2' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      # Click on password input field' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      xdotool mousemove 614 408' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      xdotool click 1' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      sleep 1' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      # Type the password' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      xdotool type --delay 50 "$REMOTE_PASS"' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      sleep 1' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      # Click OK button' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      xdotool mousemove 730 509' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      xdotool click 1' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '      echo "Password entered and OK clicked"' >> /usr/local/bin/rustdesk-autoconnect.sh \
    && echo '    fi' >> /usr/local/bin/rustdesk-autoconnect.sh \
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

# Create script to hide XFCE panel after desktop loads
# RUN echo '#!/bin/bash' > /usr/local/bin/hide-panel.sh \
#     && echo 'sleep 8' >> /usr/local/bin/hide-panel.sh \
#     && echo '# Try to hide XFCE panel using xfconf-query' >> /usr/local/bin/hide-panel.sh \
#     && echo 'export DISPLAY=:1' >> /usr/local/bin/hide-panel.sh \
#     && echo 'export XAUTHORITY=/home/kasm-user/.Xauthority' >> /usr/local/bin/hide-panel.sh \
#     && echo 'su - kasm-user -c "xfconf-query -c xfce4-panel -p /panels/panel-1/autohide-behavior -s 1" 2>/dev/null || true' >> /usr/local/bin/hide-panel.sh \
#     && echo '# Alternative: try to kill and remove panel' >> /usr/local/bin/hide-panel.sh \
#     && echo 'pkill -f "xfce4-panel" 2>/dev/null || true' >> /usr/local/bin/hide-panel.sh \
#     && echo 'sleep 1' >> /usr/local/bin/hide-panel.sh \
#     && echo '# Hide any remaining panels using xdotool' >> /usr/local/bin/hide-panel.sh \
#     && echo 'WINDOW=$(xdotool search --class "Xfce4-panel" 2>/dev/null | head -1)' >> /usr/local/bin/hide-panel.sh \
#     && echo 'if [ ! -z "$WINDOW" ]; then' >> /usr/local/bin/hide-panel.sh \
#     && echo '  xdotool windowunmap $WINDOW 2>/dev/null || true' >> /usr/local/bin/hide-panel.sh \
#     && echo 'fi' >> /usr/local/bin/hide-panel.sh \
#     && chmod +x /usr/local/bin/hide-panel.sh

# Add panel hiding script to autostart
# RUN echo '[Desktop Entry]' >> $HOME/.config/autostart/hide-panel.desktop \
#     && echo 'Type=Application' >> $HOME/.config/autostart/hide-panel.desktop \
#     && echo 'Exec=/usr/local/bin/hide-panel.sh' >> $HOME/.config/autostart/hide-panel.desktop \
#     && echo 'Hidden=false' >> $HOME/.config/autostart/hide-panel.desktop \
#     && echo 'NoDisplay=false' >> $HOME/.config/autostart/hide-panel.desktop \
#     && echo 'X-GNOME-Autostart-enabled=true' >> $HOME/.config/autostart/hide-panel.desktop \
#     && echo 'Name=Hide Panel' >> $HOME/.config/autostart/hide-panel.desktop

RUN chown -R 1000:0 $HOME/.config $HOME