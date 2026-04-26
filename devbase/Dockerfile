ARG ALPINE_VERSION=3.23
FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
      bash \
      ca-certificates \
      gum \
      ncurses-terminfo-base

# terminal script + helpers (sysinfo, motd, ascii/) at the root.
COPY devbase/terminal/ /usr/local/share/devbase/
# presets in their own subdir.
COPY devbase/presets/  /usr/local/share/devbase/presets/

RUN ln -s /usr/local/share/devbase/terminal /usr/local/bin/terminal && \
    chmod 0755 /usr/local/share/devbase/terminal && \
    chmod 0755 /usr/local/share/devbase/presets/*.sh

ENV SHELL=/bin/bash
CMD ["/bin/bash"]