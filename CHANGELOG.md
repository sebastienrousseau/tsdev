<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1] - 2026-09-26

### Added

- Initial release of `tsdev`: Portable, hardened TypeScript development container.
- Hardened Alpine Linux 3.22 OCI container base with unprivileged user `dev` (UID 1000).
- Toolchain: Node.js 22 LTS, pnpm, tsc, vtsls (LSP), Biome, ESLint, Prettier, Vitest, and tsx.
- 4-pane TMUX IDE (`Prefix + i`) with project explorer, Neovim LSP, bash terminal, and AI agent terminal.
- Model Context Protocol (MCP) JSON-RPC 2.0 stdio server (`/usr/local/bin/mcp-server`).
- Parallel AI Git worktrees via `muxtree` (`Prefix + m`).
- Mobile & WebTTY remote access via `ttyd` and Mosh roaming shell.
- Chezmoi-managed dotfiles bootstrap integrated at build time.
- Diagnostic health checks (`make doctor` / `common/doctor.sh`).
- Full BATS unit test suite with kcov coverage reporting.
