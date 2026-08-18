return {
  {
    'nvim-telescope/telescope.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',  -- neogit already pulls this in; listed so lazy orders it
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',  -- native sorter; needs make + cc, both stock on macOS
      },
    },
    keys = {
      { '<leader>ff', function() require('telescope.builtin').find_files() end, desc = 'Find files' },
      { '<leader>fg', function() require('telescope.builtin').live_grep() end, desc = 'Live grep' },
      { '<leader>fb', function() require('telescope.builtin').buffers() end, desc = 'Buffers' },
      { '<leader>fh', function() require('telescope.builtin').help_tags() end, desc = 'Help tags' },
      { '<leader>fd', function() require('telescope.builtin').diagnostics() end, desc = 'Diagnostics' },
      { '<leader>fr', function() require('telescope.builtin').resume() end, desc = 'Resume last picker' },
    },
    config = function()
      local telescope = require('telescope')

      telescope.setup({
        defaults = {
          -- rg and fd are already in home.nix, so use them instead of the slow fallbacks
          vimgrep_arguments = {
            'rg', '--color=never', '--no-heading', '--with-filename',
            '--line-number', '--column', '--smart-case',
          },
          path_display = { 'truncate' },
        },
        pickers = {
          find_files = {
            find_command = { 'fd', '--type', 'f', '--hidden', '--exclude', '.git' },
          },
        },
      })

      telescope.load_extension('fzf')
    end,
  },
}
