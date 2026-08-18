return {
  {
    'saghen/blink.cmp',
    -- Pin to a release tag: tagged versions ship a prebuilt fuzzy-matcher binary.
    -- Tracking main would build it with cargo, which isn't installed.
    version = '1.*',
    opts = {
      keymap = { preset = 'default' },  -- <C-space> open, <C-n>/<C-p> cycle, <C-y> accept
      appearance = { nerd_font_variant = 'mono' },
      sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
      signature = { enabled = true },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
    },
  },
}
