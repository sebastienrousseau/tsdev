#!/usr/bin/env bash
# /etc/profile.d/typescript.sh — tsdev language fragment (sourced by login
# shells via /etc/profile). Kept OUT of the user's chezmoi dotfiles so those
# stay pristine and langdev-agnostic.
# SPDX-License-Identifier: Apache-2.0 OR MIT

export PNPM_HOME="/home/dev/.local/share/pnpm"
export NODE_PATH="/opt/langdev/toolchain/lib/node_modules"

case ":${PATH}:" in
  *":/opt/langdev/toolchain/bin:"*) ;;
  *) PATH="/opt/langdev/toolchain/bin:${PNPM_HOME}:${PATH}" ;;
esac
export PATH

# Environment defaults
export NODE_ENV="development"

# Aliases
alias ts='tsx'
alias tsc='tsc'
alias pnpm='pnpm'
alias lint='biome check'
alias fmt='biome format --write'
alias typecheck='tsc --noEmit'
alias test='vitest run'
alias cov='vitest run --coverage'

tshelp() {
  cat <<'EOF'
tsdev — installed TypeScript toolchain (all in /opt/langdev/toolchain):
  node             Node.js 22 LTS
  npm / npx        Node Package Manager
  pnpm / pnpx      Fast, disk space efficient package manager
  tsc / tsserver   TypeScript compiler & language server
  vtsls            Vim/Neovim TypeScript Language Server
  biome            Biome fast linter and formatter (lint / fmt)
  eslint           Pluggable JavaScript/TypeScript linter
  prettier         Opinionated code formatter
  vitest           Vite-native testing framework (test / cov)
  tsx              TypeScript Execute (ts script.ts)
LSP (Neovim, baked): vtsls + biome.
EOF
}
