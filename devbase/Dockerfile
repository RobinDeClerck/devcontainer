ARG ALPINE_VERSION=3.23
FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
      bash \
      git \
      nano \
      ca-certificates \
      openssh-client \
      gum \
      ncurses-terminfo-base \
      starship \
      figlet \
      ruby && \
    gem install lolcat --no-document

# terminal/ directory (script + lib/ assets) preserved as a subdi.
COPY devbase/terminal/ /usr/local/share/devbase/terminal/
# presets in their own subdir.
COPY devbase/presets/  /usr/local/share/devbase/presets/
# starship config
COPY devbase/starship.toml /etc/starship.toml

RUN ln -s /usr/local/share/devbase/terminal/terminal.sh /usr/local/bin/terminal && \
    chmod 0755 /usr/local/share/devbase/terminal/terminal.sh && \
    chmod 0755 /usr/local/share/devbase/presets/*.sh && \
    echo 'export STARSHIP_CONFIG=/etc/starship.toml'  >> /etc/bash/bashrc && \
    echo 'eval "$(starship init bash)"'              >> /etc/bash/bashrc

ENV SHELL=/bin/bash
CMD ["/bin/bash"]