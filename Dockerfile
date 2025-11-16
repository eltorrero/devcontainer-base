# https://hub.docker.com/_/debian
FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

# ---- Base packages ----
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       git \
       tar \
       sudo \
       tmux \
    && rm -rf /var/lib/apt/lists/*

# ---- Non-root user ----
ARG USERNAME=moo
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && mkdir -p /workspace \
    && chown ${USERNAME}:${USER_GID} /workspace \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

USER ${USERNAME}
WORKDIR /workspace

ENV XDG_CONFIG_HOME=/home/${USERNAME}/.config

# ---- Install Neovim from latest GitHub release ----
RUN curl -L "https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz" -o /tmp/nvim.tar.gz \
    && tar -C /opt -xzf /tmp/nvim.tar.gz \
    && ln -sfn /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim \
    && rm /tmp/nvim.tar.gz

