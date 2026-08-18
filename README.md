# dotfiles

Watch the walkthrough: https://youtu.be/5N-okeDdIuI

My personal Mac setup, managed with nix-darwin and home-manager.
One repo, one command, and a fresh Mac ends up configured the same way every time.

## Contributing / Using This Repo

These are my personal dotfiles, shared publicly so people can read them, learn from them, and fork them freely.
Feature requests and pull requests are not accepted here, and PRs are auto-closed.
If you find a bug, please open a GitHub Issue using the bug report template.

## What you get

Running the switch builds:

- System settings (dark mode, key repeat, dock, Finder, trackpad)
- Homebrew apps (casks and CLI tools)
- Nix user packages (ripgrep, fd, fzf, jq, lazygit, Neovim, Hack Nerd Font)
- Shell (zsh, aliases, starship prompt)
- Editor (Neovim config with the rose-pine moon theme)
- Terminal (WezTerm config with the rose-pine moon theme and dimmed unfocused windows)
- Agent configs (Claude, Codex, opencode all share one AGENTS.md)

## Prerequisites

- Apple Silicon Mac, by default.
- Intel Mac: change one line.
  In `configuration.nix`, set `nixpkgs.hostPlatform = "x86_64-darwin";` (the comment right there tells you the same thing).

## Fresh-machine setup

On a brand new Mac, from a bare clone of this repo:

```sh
git clone https://github.com/sripranavsureshkumar-lab/dotfiles.git
cd dotfiles
```

Before you run it: review "Make it yours" below.
Change the host label or CPU architecture if needed, and read the Homebrew cleanup warning.
`bootstrap.sh` applies the config to your machine, so do this first.

```sh
./bootstrap.sh
```

`bootstrap.sh` does four things, in order:

1. Installs Determinate Nix, if it isn't already installed.
2. Symlinks this repo to `~/.dotfiles`.
   This has to happen before the first build, because `home.nix` points at config files through `~/.dotfiles`.
3. Checks the `user` configured in `flake.nix` against your actual macOS username, and offers to fix it for you if they differ.
4. Runs the first `darwin-rebuild switch`.
   It fetches the `darwin-rebuild` tool from the nix-darwin 26.05 release branch, then applies this repo's locked flake config.

After that, `darwin-rebuild` exists and you're on the normal workflow below.

### Validate without applying

Once Nix is installed (`bootstrap.sh` step 1 handles that), you can check that the config builds without touching your system - handy when you have edited something:

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

If you renamed the host label in "Make it yours", substitute your label for `mac` in these commands.

### Test the Neovim config

```sh
./test-nvim.sh
```

Checks that the Nix config evaluates, every Lua file parses, all plugins install, Treesitter parsers actually compile, and every enabled LSP server has a config.
It runs nvim under a throwaway `NVIM_APPNAME`, so your real `~/.config/nvim` and `~/.local/share/nvim` are untouched, and it cleans up after itself.

Run `./rebuild.sh` first: the language servers, formatters, and the `tree-sitter` CLI all come from `home.nix`, and the script checks they are on `PATH`.

## Daily use

Edit the config files in place, then apply:

```sh
./rebuild.sh
```

That's it.
No separate build-and-copy step.

## Make it yours

This repo is mine.
If you clone it, review these before you run `bootstrap.sh`:

- **Username**: run `./bootstrap.sh` (it detects your macOS username and offers to set it) OR change the single `user = "sripranavsureshkumar"` line in `flake.nix`.
  Everything else (`configuration.nix`, `home.nix`, home directory paths) is threaded from that one variable.
- **Host label** `"mac"`, in three places: `flake.nix` (the `darwinConfigurations."mac"` name), `rebuild.sh:5` (the `#mac` at the end of the flake reference), and `bootstrap.sh`'s first-switch command (also `#mac`).
  All three have to match.
- **CPU architecture**, `hostPlatform` in `configuration.nix` (see Prerequisites above).

**Git identity:** this config deliberately does not set your git name or email.
Git will stop your first commit and tell you to set them (`git config --global user.name "Your Name"` and `git config --global user.email you@example.com`).
If you'd rather manage that declaratively, add this back to `home.nix` with your own identity:

```nix
programs.git = {
  enable = true;
  settings.user = {
    name = "Your Name";
    email = "you@example.com";
  };
};
```

**Homebrew cleanup warning:** `configuration.nix` sets `homebrew.onActivation.cleanup = "zap"`.
That means every time you switch, Homebrew removes any package or cask on your machine that isn't listed in the `brews` and `casks` arrays in `configuration.nix`.
If you already have Homebrew stuff installed that isn't in that list, the first switch will uninstall it.
Read through `brews` and `casks` before you run `bootstrap.sh` or `rebuild.sh` for the first time, and add anything you want to keep.

**About `herdr`:** it's in the `brews` list.
It's a real public Homebrew formula (`brew info herdr` finds it in homebrew-core, no tap needed), so it will install fine.
If you don't use it, just remove it from `brews` in your copy.

**Heads-up:**

- `home/AGENTS.md` is my personal agent policy, and `home.nix` installs it for Claude, Codex, and opencode.
  If you clone this repo, you'd silently inherit my agent instructions - edit or delete `home/AGENTS.md` if you don't want that.
- The `cc` and `co` shell aliases in `home.nix` are high-agency shortcuts: `claude --dangerously-skip-permissions` and `codex --full-auto`.
  They're convenient for me, but know what they do before you use them.

## Repo tour

- `flake.nix` - the entry point.
  Wires up nixpkgs, nix-darwin, home-manager, and nix-homebrew, and declares the `mac` machine.
- `configuration.nix` - system-level config: macOS defaults, Homebrew.
- `home.nix` - user-level config: shell, packages, prompt, and the symlinks described below.
- `rebuild.sh` - re-applies the config after the first switch.
  Run this every time you make a change.
- `test-nvim.sh` - self-test for the Neovim config, run in a throwaway sandbox.
- `home/` - the actual config files that get symlinked into place (Neovim, WezTerm, herdr, Claude settings, the shared `AGENTS.md`).

## How the symlinks work

The files under `home/` are the real files - editing them here is editing your live config, no rebuild needed to see the change in your editor.
`home.nix` uses `mkOutOfStoreSymlink` to point paths like `~/.config/nvim` straight at `home/.config/nvim` in this repo, so the two never drift out of sync.
You only run `./rebuild.sh` when you change something that isn't just a symlinked file, like a package list or a system default.

## Keybindings

Three layers stack here, each with its own prefix, so they mostly stay out of each other's way:
WezTerm owns `Cmd` and `Ctrl-Shift`, herdr owns `Ctrl-B`, and Neovim owns `Space` (the leader key).

Everything marked **custom** is set by this repo.
Everything marked **default** ships with the tool and is listed because it is worth knowing, not because it is configured here.

### Shell (zsh)

| Key | Action |
| --- | --- |
| `Ctrl-F` | Accept the greyed-out autosuggestion |

Custom, set in `home.nix` via `bindkey '^f' autosuggest-accept`.

### WezTerm

`wezterm.lua` sets no key assignments, so these are all WezTerm defaults.
On macOS `SUPER` is `Cmd`.
Run `wezterm show-keys` for the complete list.

| Key | Action |
| --- | --- |
| `Cmd-C` / `Cmd-V` | Copy / paste |
| `Cmd-T` / `Cmd-W` | New tab / close tab |
| `Cmd-N` | New window |
| `Cmd-1` .. `Cmd-9` | Jump to tab 1-9 (`Cmd-9` is the last tab) |
| `Cmd-{` / `Cmd-}` | Previous / next tab |
| `Ctrl-Tab` / `Ctrl-Shift-Tab` | Next / previous tab |
| `Cmd-F` | Search scrollback |
| `Cmd-K` | Clear scrollback |
| `Cmd-R` | Reload config |
| `Cmd-H` / `Cmd-M` | Hide / minimize |
| `Cmd-Q` | Quit |
| `Cmd-+` / `Cmd--` / `Cmd-0` | Font bigger / smaller / reset |
| `Alt-Enter` | Toggle fullscreen |
| `Shift-PageUp` / `Shift-PageDown` | Scroll by page |
| `Ctrl-Shift-P` | Command palette |
| `Ctrl-Shift-U` | Character / emoji picker |
| `Ctrl-Shift-Space` | Quick select (hint and copy text on screen) |
| `Ctrl-Shift-X` | Enter copy mode |
| `Ctrl-Shift-Z` | Zoom pane |
| `Ctrl-Shift-Alt-"` / `Ctrl-Shift-Alt-%` | Split vertical / horizontal |
| `Ctrl-Shift-Arrow` | Focus pane in that direction |
| `Ctrl-Shift-Alt-Arrow` | Resize pane in that direction |
| `Ctrl-Shift-L` | Debug overlay |

WezTerm copy mode (`Ctrl-Shift-X`) is vim-like: `h/j/k/l` move, `w`/`b`/`e` by word, `g`/`G` top/bottom of scrollback, `0`/`$` line ends, `v` start a selection, `V` line select, `Ctrl-V` block select, `o` jump to the other end, `y` copy and exit, `Esc`/`q`/`Ctrl-C` cancel, `Ctrl-B`/`Ctrl-F` page up/down.

In practice you will mostly use herdr's panes rather than WezTerm's, since herdr runs inside a single WezTerm window.

### Herdr

Prefix is `Ctrl-B`: press it, release, then press the next key.
All of these are **custom**, set in `home/.config/herdr/config.toml`.

| Key | Action |
| --- | --- |
| `Ctrl-B` `h` / `j` / `k` / `l` | Focus pane left / down / up / right |
| `Ctrl-B` `"` | Split horizontally |
| `Ctrl-B` `%` | Split vertically |
| `Ctrl-B` `c` | New tab |
| `Ctrl-B` `&` | Close tab |
| `Ctrl-B` `w` | Workspace picker |
| `Ctrl-B` `g` | Goto |
| `Ctrl-B` `y` | Enter copy mode |

Copy mode's own keys are fixed by herdr and cannot be rebound: `v` or `Space` starts a selection, `y` or `Enter` copies, `q` or `Esc` cancels.

Any binding not listed above is a herdr default this repo does not override.
`herdr config reset-keys` backs up `config.toml` and drops the custom bindings.

### Neovim

Leader is `Space`.
`which-key` pops up after the leader key, so you can discover most of this without leaving the editor.

#### General (custom)

| Key | Mode | Action |
| --- | --- | --- |
| `jk` | insert | Exit insert mode |
| `Ctrl-A` | normal | Select all |

#### Windows and tabs (custom)

| Key | Action |
| --- | --- |
| `<leader>sv` / `<leader>sh` | Split vertically / horizontally |
| `<leader>se` | Make splits equal size |
| `<leader>sx` | Close current split |
| `<leader>h` / `<leader>j` / `<leader>k` / `<leader>l` | Move focus left / down / up / right |
| `<leader>to` / `<leader>tx` | Open / close tab |
| `<leader>tn` / `<leader>tp` | Next / previous tab |
| `<leader>tf` | Open current buffer in a new tab |

#### Find, files and diagnostics (custom)

| Key | Action |
| --- | --- |
| `<leader>ff` | Find files (Telescope, via `fd`) |
| `<leader>fg` | Live grep (via `ripgrep`) |
| `<leader>fb` | Open buffers |
| `<leader>fh` | Help tags |
| `<leader>fd` | Diagnostics |
| `<leader>fr` | Resume the last picker |
| `<leader>ft` | Find TODO comments |
| `<leader>ee` | Toggle file explorer |
| `<leader>ef` | Toggle explorer on the current file |
| `<leader>ec` / `<leader>er` | Collapse / refresh explorer |
| `<leader>g` | Neogit |
| `<leader>xx` | Diagnostics list (Trouble) |
| `<leader>xd` | Diagnostics for this buffer only |
| `<leader>xq` | Quickfix list (Trouble) |
| `<leader>cf` | Format buffer now |

#### Motion and text objects (custom)

| Key | Mode | Action |
| --- | --- | --- |
| `s` | normal, visual, operator | Flash jump |
| `S` | normal, visual, operator | Flash treesitter select |
| `r` | operator | Remote flash (act on a distant target) |
| `af` / `if` | visual, operator | A function / inside a function |
| `ac` / `ic` | visual, operator | A class / inside a class |
| `gsa` | normal, visual | Add a surrounding |
| `gsd` | normal | Delete a surrounding |
| `gsr` | normal | Replace a surrounding |
| `gsf` / `gsF` | normal | Find surrounding right / left |
| `gsh` | normal | Highlight a surrounding |
| `an` / `in` | visual, operator | Around / inside the *next* text object |

mini.surround uses a `gs` prefix rather than its stock `s`, because `s` belongs to flash here.
Append `n` or `l` to reach the next or previous match, for example `gsdn` deletes the next surrounding.

#### LSP and diagnostics (Neovim defaults)

These ship with Neovim 0.11+ and are **not** redefined by this repo.

| Key | Action |
| --- | --- |
| `K` | Hover documentation |
| `grn` | Rename symbol |
| `gra` | Code action |
| `grr` | Find references |
| `gri` | Go to implementation |
| `grt` | Go to type definition |
| `grx` | Run code lens |
| `gO` | Document symbols |
| `Ctrl-S` | Signature help (insert and visual) |
| `]d` / `[d` | Next / previous diagnostic |
| `]D` / `[D` | Last / first diagnostic in the buffer |
| `Ctrl-W d` | Show diagnostics under the cursor |

#### Other Neovim defaults worth knowing

| Key | Action |
| --- | --- |
| `gcc` / `gc{motion}` | Toggle comment |
| `gx` | Open the file path or URL under the cursor |
| `]q` / `[q` | Next / previous quickfix item |
| `]b` / `[b` | Next / previous buffer |
| `]t` / `[t` | Next / previous tab |
| `]l` / `[l` | Next / previous location list item |
| `]a` / `[a` | Next / previous argument list file |
| `]<Space>` / `[<Space>` | Add a blank line below / above |
| `]n` / `[n` | Next / previous treesitter node (visual) |

#### Completion (blink.cmp defaults)

| Key | Action |
| --- | --- |
| `Ctrl-Space` | Show menu, then show / hide documentation |
| `Ctrl-N` / `Ctrl-P` | Next / previous item |
| `Down` / `Up` | Next / previous item |
| `Ctrl-Y` | Accept the selected item |
| `Ctrl-E` | Cancel |
| `Ctrl-B` / `Ctrl-F` | Scroll documentation up / down |
| `Ctrl-K` | Toggle signature help |
| `Tab` / `Shift-Tab` | Jump forward / back through snippet placeholders |

#### File explorer (nvim-tree defaults)

Press `g?` inside the tree for the full list.

| Key | Action |
| --- | --- |
| `Enter` / `o` | Open |
| `Tab` | Open preview |
| `Ctrl-V` / `Ctrl-X` / `Ctrl-T` | Open in vertical split / horizontal split / new tab |
| `a` | Create file or directory (end with `/` for a directory) |
| `d` / `D` | Delete / trash |
| `r` / `e` | Rename / rename basename only |
| `c` / `x` / `p` | Copy / cut / paste |
| `y` / `Y` / `gy` | Copy name / relative path / absolute path |
| `R` | Refresh |
| `H` | Toggle hidden (dotfiles) |
| `I` | Toggle git-ignored files |
| `E` / `W` | Expand all / collapse all |
| `f` / `F` | Start / clear live filter |
| `S` | Search |
| `P` | Jump to parent directory |
| `<` / `>` | Previous / next sibling |
| `J` / `K` | Last / first sibling |
| `-` | Go up a directory |
| `Backspace` | Close directory |
| `]c` / `[c` | Next / previous git change |
| `]e` / `[e` | Next / previous diagnostic |
| `m` | Toggle bookmark |
| `q` | Close the tree |

#### Telescope (defaults, inside a picker)

Press `Ctrl-/` in insert mode or `?` in normal mode for the full list.

| Key | Action |
| --- | --- |
| `Ctrl-N` / `Ctrl-P` | Next / previous result |
| `j` / `k` | Next / previous result (normal mode) |
| `Enter` | Open |
| `Ctrl-V` / `Ctrl-X` / `Ctrl-T` | Open in vertical split / horizontal split / new tab |
| `Ctrl-U` / `Ctrl-D` | Scroll the preview up / down |
| `Tab` / `Shift-Tab` | Toggle selection and move down / up |
| `Ctrl-Q` | Send all results to the quickfix list |
| `Alt-Q` | Send selected results to the quickfix list |
| `Ctrl-C` / `Esc` | Close |

#### Trouble (defaults, inside the list)

| Key | Action |
| --- | --- |
| `Enter` | Jump to the item |
| `o` | Jump and close the list |
| `Ctrl-V` / `Ctrl-S` | Jump in a vertical / horizontal split |
| `p` / `P` | Preview / toggle auto preview |
| `}` or `]]` / `{` or `[[` | Next / previous item |
| `r` / `R` | Refresh / toggle auto refresh |
| `dd` | Delete the item from the list |
| `q` / `Esc` | Close / cancel |
| `?` | Help |

#### Git

Neogit opens with `<leader>g` and is driven by its own popups; press `?` inside it for the full list.
gitsigns adds no keybindings here - it shows inline blame for the current line automatically.

#### A note on shadowed keys

`an` and `in` come from mini.ai (around / inside the *next* text object) and shadow Neovim 0.12's built-in treesitter node selection, which used the same keys.
Node navigation is still available on `]n` and `[n` in visual mode.
If you would rather keep the built-ins, remove mini.ai from `home/.config/nvim/lua/plugins/editing.lua`.

## Notes

The first time you launch `nvim`, it bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) by cloning plugins from GitHub.
That needs network access once; after that it's offline.
Neovim and WezTerm both use the rose-pine moon theme.
Neovim keeps italics off and uses a transparent background on macOS, Windows, and WSL so it matches the terminal setup.

## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
