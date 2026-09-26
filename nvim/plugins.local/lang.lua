-- tsdev — TypeScript language wiring for Neovim.
-- SPDX-License-Identifier: Apache-2.0 OR MIT
--
-- Dropped into the user's dotfiles' Neovim config at build time via its
-- `plugins.local` convention (auto-imported). The LSP servers and linters
-- are installed at BUILD time into /opt/langdev/toolchain and are on PATH:
--   * vtsls -> type checking, completion, refactoring, navigation
--   * biome -> fast linting and formatting
return {
  -- Treesitter grammars
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "typescript", "tsx", "javascript", "json", "jsonc" })
    end,
  },

  -- LSP: vtsls + biome
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
          },
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = "always" },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
        },
        biome = {},
      },
    },
  },
}
