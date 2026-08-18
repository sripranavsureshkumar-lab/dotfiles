#!/usr/bin/env bash
# Self-test for the Neovim config.
#
# Runs this repo's nvim config under an isolated NVIM_APPNAME, so your real
# ~/.config/nvim and ~/.local/share/nvim are never touched. Everything it
# creates is removed on exit.
#
# Run ./rebuild.sh first: the language servers, the formatters and the
# tree-sitter CLI all come from home.nix, and section 3 checks for them.
#
# Usage:  ./test-nvim.sh          (host label defaults to "mac")
#         HOST_LABEL=foo ./test-nvim.sh
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
NVIM_CONFIG_DIR="$DIR/home/.config/nvim"
APPNAME="nvim-selftest"
CFG_LINK="$HOME/.config/$APPNAME"
HOST_LABEL="${HOST_LABEL:-mac}"

PASS=0
FAIL=0
RESULT="$(mktemp)"

ok()      { printf '  ok    %s\n' "$1"; PASS=$((PASS + 1)); }
bad()     { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }
section() { printf '\n==> %s\n' "$1"; }

cleanup() {
  rm -f "$CFG_LINK" "$RESULT"
  rm -rf "$HOME/.local/share/$APPNAME" "$HOME/.local/state/$APPNAME" "$HOME/.cache/$APPNAME"
}
trap cleanup EXIT

# Never clobber a real config directory that happens to share the name.
if [ -e "$CFG_LINK" ] && [ ! -L "$CFG_LINK" ]; then
  echo "Refusing to run: $CFG_LINK exists and is not a symlink." >&2
  exit 1
fi
if ! command -v nvim >/dev/null 2>&1; then
  echo "Refusing to run: nvim is not on PATH." >&2
  exit 1
fi

# Run nvim against the sandboxed config. Assertions write their answer to
# $RESULT rather than stdout, so lazy.nvim's progress output can't be mistaken
# for a test result.
nvim_sandbox() {
  NVIM_APPNAME="$APPNAME" nvim --headless "$@" -c qa >/dev/null 2>&1
}

section "1. nix config evaluates against the pinned nixpkgs"
# An unknown package attribute aborts evaluation here, which is what catches a
# typo'd or renamed package before ./rebuild.sh ever runs.
if nix build --no-link --dry-run "$DIR#darwinConfigurations.$HOST_LABEL.system" >/dev/null 2>&1; then
  ok "darwinConfigurations.$HOST_LABEL.system evaluates"
else
  bad "nix evaluation failed - see: nix build --dry-run .#darwinConfigurations.$HOST_LABEL.system"
fi

section "2. every lua file parses"
SYNTAX_OK=1
while IFS= read -r f; do
  if ! nvim --headless -c "lua assert(loadfile('$f'))" -c qa >/dev/null 2>&1; then
    bad "syntax error: ${f#"$DIR"/}"
    SYNTAX_OK=0
  fi
done < <(find "$NVIM_CONFIG_DIR" -name '*.lua')
[ "$SYNTAX_OK" -eq 1 ] && ok "all lua files parse"

section "3. tooling declared in home.nix is on PATH"
# tree-sitter is first on purpose: nvim-treesitter's main branch shells out to
# it to build parsers. Without it, parsers fail silently while lua and markdown
# still highlight from Neovim's bundled ones.
for tool in tree-sitter lua-language-server nixd vtsls basedpyright clangd stylua nixfmt prettierd ruff; do
  if command -v "$tool" >/dev/null 2>&1; then
    ok "$tool"
  else
    bad "$tool is missing - run ./rebuild.sh"
  fi
done

section "4. plugins install"
ln -sfn "$NVIM_CONFIG_DIR" "$CFG_LINK"
nvim_sandbox "+Lazy! sync"
nvim_sandbox -c "lua local bad={} for _,p in ipairs(require('lazy').plugins()) do if not p._.installed then table.insert(bad,p.name) end end local f=io.open('$RESULT','w') f:write(table.concat(bad,' ')) f:close()"
MISSING="$(cat "$RESULT")"
if [ -z "$MISSING" ]; then
  ok "every declared plugin is installed"
else
  bad "plugins failed to install: $MISSING"
fi

section "5. treesitter parsers compile"
nvim_sandbox -c "lua require('nvim-treesitter').install({'nix','python','cpp','typescript'}):wait(600000)"
PARSER_DIR="$HOME/.local/share/$APPNAME/site/parser"
for lang in nix python cpp typescript; do
  if [ -f "$PARSER_DIR/$lang.so" ]; then
    ok "parser built: $lang"
  else
    bad "parser missing: $lang"
  fi
done

section "6. highlighting attaches to a non-bundled language"
# Checked on flake.nix, not a lua file: Neovim bundles parsers for lua, c,
# markdown, vim and query, so a lua buffer highlights even when every compiled
# parser is missing. Nix is only highlighted if section 5 really worked.
nvim_sandbox "$DIR/flake.nix" -c "lua vim.wait(3000) local b=vim.api.nvim_get_current_buf() local f=io.open('$RESULT','w') f:write(vim.bo[b].filetype..' '..tostring(vim.treesitter.highlighter.active[b]~=nil)) f:close()"
if [ "$(cat "$RESULT")" = "nix true" ]; then
  ok "treesitter highlights flake.nix"
else
  bad "treesitter did not attach to flake.nix (got: $(cat "$RESULT"))"
fi

section "7. every enabled LSP server config resolves"
# Server names are read back out of lsp.lua so this can't drift from the config.
# Guards against a silent typo such as ruff vs ruff_lsp, which disables a
# server without any error.
SERVERS="$(awk '/vim\.lsp\.enable\(\{/,/\}\)/' "$NVIM_CONFIG_DIR/lua/plugins/lsp.lua" | grep -oE "'[a-z_]+'" | tr -d "'" | tr '\n' ' ')"
if [ -z "$SERVERS" ]; then
  bad "could not read server names out of lsp.lua"
else
  # read -r -a rather than mapfile: macOS ships bash 3.2, which has no mapfile.
  read -r -a SERVER_ARR <<< "$SERVERS"
  LUA_LIST="$(printf "'%s'," "${SERVER_ARR[@]}")"
  nvim_sandbox -c "lua local names={$LUA_LIST} local bad={} for _,n in ipairs(names) do local got,c=pcall(function() return vim.lsp.config[n] end) if not (got and c and c.cmd) then table.insert(bad,n) end end local f=io.open('$RESULT','w') f:write(table.concat(bad,' ')) f:close()"
  UNRESOLVED="$(cat "$RESULT")"
  if [ -z "$UNRESOLVED" ]; then
    ok "all configs resolve:$(printf ' %s' "${SERVER_ARR[@]}")"
  else
    bad "no config found for: $UNRESOLVED"
  fi
fi

printf '\n==> %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
