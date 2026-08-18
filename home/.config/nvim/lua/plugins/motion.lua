return {
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {},
    -- Bare `s` is free here: every mapping in keys.lua is leader-prefixed.
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash jump' },
      { 'S', mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end, desc = 'Flash treesitter' },
      { 'r', mode = 'o', function() require('flash').remote() end, desc = 'Remote flash' },
    },
  },
}
