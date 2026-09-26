# syntax=docker/dockerfile:1.9
# tsdev Containerfile — OCI, builds with Docker AND Podman.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# Multi-stage, hardened, ultra-small TypeScript dev image built on the langdev
# foundation. The developer environment (shell, editor, tmux) is the USER'S
# OWN chezmoi-managed dotfiles, cloned + applied at build time (latest by
# default; pin with DOTFILES_REF). langdev provides only the hardened base +
# the TypeScript toolchain + a single nvim/plugins.local/lang.lua LSP drop-in.

ARG ALPINE_VERSION=3.22
# renovate: datasource=docker depName=alpine
ARG ALPINE_DIGEST=sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# Dotfiles source — "always the latest" by default; pin a tag/commit for
# reproducible builds.
ARG DOTFILES_REPO=https://github.com/sebastienrousseau/dotfiles.git
ARG DOTFILES_REF=main

###############################################################################
# Stage: toolchain  (LANGUAGE-SPECIFIC — Node.js 22 LTS + TypeScript tooling)
#   Installs Node.js 22 and packages the pinned TypeScript toolchain:
#   pnpm, tsc, vtsls (LSP), biome, eslint, prettier, vitest, and tsx.
#   Everything lands under a relocatable prefix (/opt/langdev/toolchain).
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS toolchain

# Pinned toolchain versions
ARG PNPM_VERSION=10.6.1
ARG TYPESCRIPT_VERSION=5.8.2
ARG VTSLS_VERSION=0.2.6
ARG BIOME_VERSION=1.9.4
ARG ESLINT_VERSION=9.21.0
ARG PRETTIER_VERSION=3.5.3
ARG VITEST_VERSION=3.0.7
ARG TSX_VERSION=4.19.3

ENV PREFIX=/opt/langdev/toolchain \
    PATH=/opt/langdev/toolchain/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      nodejs \
      npm \
 && update-ca-certificates

RUN mkdir -p /opt/langdev/toolchain \
 && npm config set prefix /opt/langdev/toolchain \
 && npm install -g \
      pnpm@${PNPM_VERSION} \
      typescript@${TYPESCRIPT_VERSION} \
      @vtsls/language-server@${VTSLS_VERSION} \
      @biomejs/biome@${BIOME_VERSION} \
      eslint@${ESLINT_VERSION} \
      prettier@${PRETTIER_VERSION} \
      vitest@${VITEST_VERSION} \
      tsx@${TSX_VERSION} \
 && rm -rf /root/.npm /tmp/*

###############################################################################
# Stage: env-build  (COMMON — apply the user's dotfiles + bake nvim plugins)
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS env-build
ARG USERNAME USER_UID USER_GID DOTFILES_REPO DOTFILES_REF
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash ca-certificates chezmoi curl git \
      neovim ripgrep fd fzf bat \
      build-base cmake
RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"
COPY --chown=${USER_UID}:${USER_GID} common/bootstrap-dotfiles.sh /usr/local/bin/langdev-bootstrap-dotfiles
RUN chmod 0755 /usr/local/bin/langdev-bootstrap-dotfiles
USER ${USERNAME}
ENV HOME=/home/${USERNAME}
# 1) Clone + chezmoi-apply the user's dotfiles (brings bashrc, tmux, nvim…).
RUN DOTFILES_REPO="${DOTFILES_REPO}" DOTFILES_REF="${DOTFILES_REF}" \
      langdev-bootstrap-dotfiles
# 2) Drop the TypeScript LSP spec into the dotfiles' nvim
COPY --chown=${USER_UID}:${USER_GID} nvim/plugins.local/ /home/${USERNAME}/.config/nvim/lua/plugins.local/
RUN nvim --headless "+Lazy! restore" +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+Lazy! sync"    +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+TSUpdateSync"  +qa 2>&1 | tail -n 5 || true

###############################################################################
#                              COMMON BASE
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS base
ARG USERNAME USER_UID USER_GID

LABEL org.opencontainers.image.title="tsdev" \
      org.opencontainers.image.licenses="Apache-2.0 OR MIT" \
      org.opencontainers.image.vendor="Sebastien Rousseau"

# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash \
      bat \
      ca-certificates \
      chezmoi \
      curl \
      fd \
      fzf \
      git \
      less \
      mosh-server \
      neovim \
      nodejs \
      npm \
      ripgrep \
      tini \
      tmux \
      ttyd \
      tzdata \
      zoxide \
 && update-ca-certificates

RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"

COPY --from=env-build --chown=${USER_UID}:${USER_GID} /home/${USERNAME} /home/${USERNAME}

# Entrypoint & IDE tooling (tmux-loading, strict-mode, AI & MCP).
COPY common/entrypoint.sh /usr/local/bin/langdev-entrypoint
COPY common/tmux-ide.sh /usr/local/bin/tmux-ide
COPY common/muxtree.sh /usr/local/bin/muxtree
COPY common/doctor.sh /usr/local/bin/langdev-doctor
COPY common/mcp-server.sh /usr/local/bin/mcp-server
COPY common/ai-pack.sh /usr/local/bin/ai-pack
COPY common/explorer.sh /usr/local/bin/langdev-explorer
COPY common/mcp.json /etc/langdev-mcp.json
COPY common/tmux.conf /etc/tmux.conf
RUN chmod 0755 /usr/local/bin/langdev-entrypoint /usr/local/bin/tmux-ide /usr/local/bin/muxtree \
               /usr/local/bin/langdev-doctor /usr/local/bin/mcp-server /usr/local/bin/ai-pack \
               /usr/local/bin/langdev-explorer \
 && chmod 0644 /etc/tmux.conf /etc/langdev-mcp.json \
 && mkdir -p /usr/local/lib/langdev

# --- Hardening ---------------------------------------------------------------
RUN chmod 1777 /tmp \
 && find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -exec chmod -s {} + 2>/dev/null || true

USER ${USERNAME}
WORKDIR /work
ENV HOME=/home/${USERNAME} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    EDITOR=nvim \
    XDG_CONFIG_HOME=/home/${USERNAME}/.config \
    XDG_DATA_HOME=/home/${USERNAME}/.local/share \
    XDG_STATE_HOME=/home/${USERNAME}/.local/state \
    XDG_CACHE_HOME=/home/${USERNAME}/.cache

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD nvim --version >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/langdev-entrypoint"]

###############################################################################
# Stage: final  (TypeScript runtime — hardened, unprivileged)
###############################################################################
FROM base AS final

COPY --from=toolchain --chown=1000:1000 /opt/langdev/toolchain /opt/langdev/toolchain

COPY dotfiles.d/typescript.sh /etc/profile.d/typescript.sh

ENV PNPM_HOME=/home/dev/.local/share/pnpm \
    NODE_PATH=/opt/langdev/toolchain/lib/node_modules \
    NODE_ENV=development \
    PATH=/opt/langdev/toolchain/bin:/home/dev/.local/share/pnpm:/home/dev/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
