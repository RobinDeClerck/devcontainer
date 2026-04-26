ARG ALPINE_VERSION=3.23
FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache \
      bash \
      ca-certificates \
      gum \
      ncurses-terminfo-base

# terminal + put `terminal` on PATH.
COPY devbase/terminal/  /usr/local/share/devbase/
RUN ln -s /usr/local/share/devbase/terminal /usr/local/bin/terminal && \
    chmod 0755 /usr/local/share/devbase/terminal

ENV SHELL=/bin/bash
CMD ["/bin/bash"]