-- Neovim 0.11+ has the LSP client config API built in, so nvim-lspconfig is
-- only here to supply each server's defaults from its lsp/ runtime directory.
-- Server binaries come from home.nix, never from mason.
--
-- No keymaps here on purpose: 0.11+ already binds grn (rename), gra (code
-- action), grr (references), gri (implementation), gO (symbols) and K (hover).
return {
  {
    'neovim/nvim-lspconfig',
    lazy = false,  -- must run before the first FileType fires, or nothing attaches
    dependencies = { 'saghen/blink.cmp' },
    config = function()
      -- Advertise blink's completion capabilities to every server.
      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities({}, false),
      })

      -- Editing this repo's own Lua shouldn't flag `vim` as undefined.
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            diagnostics = { globals = { 'vim' } },
            workspace = { checkThirdParty = false },
          },
        },
      })

      vim.lsp.enable({
        'lua_ls',
        'nixd',
        'vtsls',
        'html',
        'cssls',
        'jsonls',
        'basedpyright',
        'ruff',
        'clangd',
      })

      vim.diagnostic.config({
        virtual_text = true,
        severity_sort = true,
        float = { border = 'rounded' },
      })
    end,
  },
}
