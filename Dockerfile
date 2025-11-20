# Inspired by https://github.com/ublue-os/image-template

# A pure file stage for build scripts which won't be present in the final image
FROM scratch AS ctx
COPY build_files /

ARG DEBIAN_CODENAME=trixie

# Real build stage - https://hub.docker.com/_/debian
FROM debian:${DEBIAN_CODENAME}-slim

# Re-declare DEBIAN_CODENAME inside this stage to use it
ARG DEBIAN_CODENAME

# Non-root user
ARG USERNAME=moo

# env variables will be available in the RUN and therefore in the build script
ENV USERNAME=${USERNAME}
ENV DEBIAN_CODENAME=${DEBIAN_CODENAME}

# Mount the build scripts, caches, and temp space only for this build step,
# so it will not bloat the final image
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/lib/apt/lists \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    --mount=type=secret,id=github_token \
    /ctx/build.sh

# Set user and working directory for the following instructions in case
# this image is used as a base to build upon
USER ${USERNAME}
WORKDIR /workspace

# Set user config path
ENV XDG_CONFIG_HOME=/home/${USERNAME}/.config

