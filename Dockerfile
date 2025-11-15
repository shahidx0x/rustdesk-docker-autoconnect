FROM docker.io/kasmweb/core-ubuntu-noble:1.18.0-rolling-daily
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

# Don't autostart RustDesk automatically - let our script control it
# RUN ln -s /rustdesk.desktop $HOME/.config/autostart/rustdesk.desktop

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

# Copy and setup auto-connect script
COPY rustdesk-autoconnect.sh /usr/local/bin/rustdesk-autoconnect.sh
RUN chmod +x /usr/local/bin/rustdesk-autoconnect.sh

# Create startup script that runs after desktop loads
RUN mkdir -p /dockerstartup/custom \
    && echo '#!/bin/bash' > /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'echo "Starting RustDesk automation..."' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'export DISPLAY=:1' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'export XAUTHORITY=/home/kasm-user/.Xauthority' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'sleep 5' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'echo "Launching RustDesk..."' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'su - kasm-user -c "rustdesk" &' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'sleep 10' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'echo "Running panel hiding script..."' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'su - kasm-user -c "/usr/local/bin/hide-panel.sh" &' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'sleep 2' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'echo "Running automation script..."' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'su - kasm-user -c "/usr/local/bin/rustdesk-autoconnect.sh" &' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && echo 'echo "RustDesk automation setup complete"' >> /dockerstartup/custom/rustdesk-autostart.sh \
    && chmod +x /dockerstartup/custom/rustdesk-autostart.sh

# Copy and setup panel hiding script
COPY hide-panel.sh /usr/local/bin/hide-panel.sh
RUN chmod +x /usr/local/bin/hide-panel.sh

RUN chown -R 1000:0 $HOME/.config $HOME