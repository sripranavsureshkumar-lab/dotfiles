return {
  -- cs"' to change surrounding quotes, ds( to delete brackets, ys<motion> to add
  {
    'echasnovski/mini.surround',
    event = 'BufReadPost',
    opts = {},
  },

  -- Treesitter-aware af/if (function) and ac/ic (class) text objects.
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',  -- match nvim-treesitter's branch
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {},
    keys = {
      {
        'af',
        function() require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects') end,
        mode = { 'x', 'o' },
        desc = 'a function',
      },
      {
        'if',
        function() require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects') end,
        mode = { 'x', 'o' },
        desc = 'inner function',
      },
      {
        'ac',
        function() require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects') end,
        mode = { 'x', 'o' },
        desc = 'a class',
      },
      {
        'ic',
        function() require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects') end,
        mode = { 'x', 'o' },
        desc = 'inner class',
      },
    },
  },

  -- Extra a/i text objects: aa arguments, aq quotes, ab brackets, at tags.
  {
    'echasnovski/mini.ai',
    event = 'BufReadPost',
    opts = {
      -- mini.ai's own `f` means "function call"; leave af/if to the
      -- treesitter text objects above so the two don't fight over the mapping.
      custom_textobjects = { f = false },
    },
  },

  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },
}
