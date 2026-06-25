FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=22
ARG PNPM_VERSION=10.13.1
ARG UV_VERSION=0.7.13

ENV LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    EDITOR=vim \
    COREPACK_HOME=/opt/corepack \
    PIPX_HOME=/opt/pipx \
    PIPX_BIN_DIR=/usr/local/bin

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
      locales && \
    sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list && \
    curl -fsSL https://download.docker.com/linux/debian/gpg \
      | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable" \
      > /etc/apt/sources.list.d/docker.list && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      bash \
      build-essential \
      docker-ce-cli \
      docker-compose-plugin \
      fd-find \
      fzf \
      git \
      jq \
      nano \
      nodejs \
      openjdk-17-jdk-headless \
      openssh-client \
      openssh-server \
      pipx \
      python3 \
      python3-pip \
      python3-venv \
      ripgrep \
      rsync \
      sshfs \
      tini \
      tmux \
      unzip \
      vim \
      wget \
      xz-utils \
      zsh && \
    npm install -g "npm@latest" && \
    corepack enable && \
    corepack prepare "pnpm@${PNPM_VERSION}" --activate && \
    pipx install "uv==${UV_VERSION}" && \
    ln -s /usr/bin/fdfind /usr/local/bin/fd && \
    chsh -s /bin/zsh root && \
    mkdir -p /workspace/projects /var/run/sshd && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's@#AuthorizedKeysFile.*@AuthorizedKeysFile .ssh/authorized_keys@' /etc/ssh/sshd_config

COPY bin/devbox-entrypoint /usr/local/bin/devbox-entrypoint
COPY bin/devbox-bootstrap-dotfiles /usr/local/bin/devbox-bootstrap-dotfiles
RUN chmod +x \
      /usr/local/bin/devbox-entrypoint \
      /usr/local/bin/devbox-bootstrap-dotfiles

WORKDIR /workspace
EXPOSE 22
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/devbox-entrypoint"]
