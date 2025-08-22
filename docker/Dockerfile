FROM mcr.microsoft.com/vscode/devcontainers/base:alpine-3.21 AS builder

# build dependencies only in builder
RUN apk add --no-cache cmake build-base

# bring in the stub sources
COPY docker/glibc-wrappers /tmp/wrappers
WORKDIR /tmp/wrappers

# build the shared lib
RUN cmake -B build . && \
    cmake --build build --config Release


FROM mcr.microsoft.com/vscode/devcontainers/base:alpine-3.21

ENV PIP_BREAK_SYSTEM_PACKAGES=1

# terminal prerequisites
RUN apk add --no-cache \
    -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    lolcat figlet

# pycharm devcontainer prerequisites
RUN apk add --no-cache \
    curl \
    unzip \
    procps \
    gcompat \
    libxext \
    libxrender \
    libxtst \
    libxi \
    freetype

# install FiraCode Nerd Font
RUN apk add --no-cache fontconfig wget tar && \
    mkdir -p /usr/share/fonts/nerd-fonts && \
    wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip -O /tmp/FiraCode.zip && \
    unzip -q /tmp/FiraCode.zip -d /usr/share/fonts/nerd-fonts && \
    rm /tmp/FiraCode.zip && \
    fc-cache -fv

# copy only the built stub (no build tools)
COPY --from=builder /tmp/wrappers/build/libwrapper64_glibc.so /lib/x64_libwrapper64_glibc.so

# ensure preload for all shells / processes
RUN echo "export LD_PRELOAD=/lib/x64_libwrapper64_glibc.so" >> /etc/profile && \
    echo "export LD_PRELOAD=/lib/x64_libwrapper64_glibc.so" >> /etc/profile.d/remote-dev.sh

# safe default working dir
WORKDIR /
