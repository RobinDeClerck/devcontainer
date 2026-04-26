ARG ALPINE_VERSION=3.23
FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
      bash \
      ca-certificates \
      openssh-client \
      gum \
      ncurses-terminfo-base \
      starship \
      figlet \
      ruby && \
    gem install lolcat --no-document

# terminal script + helpers (sysinfo, motd, ascii/) at the root.
COPY devbase/terminal/ /usr/local/share/devbase/
# presets in their own subdir.
COPY devbase/presets/  /usr/local/share/devbase/presets/
# starship config
COPY devbase/starship.toml /etc/starship.toml

RUN ln -s /usr/local/share/devbase/terminal /usr/local/bin/terminal && \
    chmod 0755 /usr/local/share/devbase/terminal && \
    chmod 0755 /usr/local/share/devbase/presets/*.sh && \
    echo 'export STARSHIP_CONFIG=/etc/starship.toml'  >> /etc/bash/bashrc && \
    echo 'eval "$(starship init bash)"'              >> /etc/bash/bashrc

ENV SHELL=/bin/bash
CMD ["/bin/bash"]