return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',  -- master is frozen; new parsers only land on main
    build = ':TSUpdate',
    lazy = false,
    config = function()
      require('nvim-treesitter').install({
        'bash', 'c', 'cpp', 'css', 'diff', 'gitcommit', 'html', 'javascript',
        'json', 'lua', 'markdown', 'markdown_inline', 'nix', 'python', 'query',
        'toml', 'tsx', 'typescript', 'vim', 'vimdoc', 'yaml',
      })

      -- Unlike the master branch, main doesn't turn highlighting on for you.
      vim.api.nvim_create_autocmd('FileType', {
        desc = 'Start treesitter highlighting when a parser exists',
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if lang then
            pcall(vim.treesitter.start, args.buf, lang)
          end
        end,
      })
    end,
  },
}
