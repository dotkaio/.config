# Portable terminal Vim

A dependency-free Vim 8/9 setup modeled after the local VS Code workflow. It uses Vim's built-in `netrw` browser, one file-editing window, automatic saves, a command palette, project search, a bottom Problems/Terminal panel, and bundled One Dark/One Light themes.

## Install

Copy this directory to `~/.config/vim`, then activate it:

```sh
ln -s ~/.config/vim/vimrc ~/.vimrc
```

Do not replace an existing `~/.vimrc`; inspect and merge it first.

Start Vim normally from a project directory:

```sh
cd /path/to/project
vim
```

The Explorer opens automatically on the left and remains rooted at that launch directory. `vim file.txt` keeps the requested file open in the editor.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| `Ctrl+\` | Toggle Explorer |
| `Ctrl+E` | Focus Explorer |
| `Ctrl+G` | Start recursive file lookup with `:find`; use Tab to complete |
| `Ctrl+P` | Open the keyboard-filterable command palette |
| `Ctrl+F` | Search the entire project and show results in Problems |
| `Ctrl+.` | Toggle the bottom panel |
| `Ctrl+Option+Arrow` | Move between Vim windows when supported by the terminal |
| `Ctrl+W` | Close the active file while preserving Explorer |
| `Right` in Explorer | Expand a directory or open a file and return to Explorer |
| `Enter` / `Ctrl+Right` in Explorer | Open a file and focus the editor |
| `Left` in Explorer | Collapse the current tree branch |
| `Ctrl+T` in Explorer | Create a file |
| `Ctrl+N` in Explorer | Create a directory |
| `R` in Explorer | Rename the selected file or directory |
| `D` in Explorer | Delete the selected file or directory |
| `Ctrl+L` in Explorer | Refresh the listing |

`Ctrl+1` through `Ctrl+9` are intentionally absent because ordinary terminals cannot represent them reliably and this setup keeps only one file-editing window visible.

## Command palette and bottom panel

Press `Ctrl+P`, type part of an action name, use the arrow keys, and press Enter. Available actions include opening files, project search, Problems, Terminal, Explorer controls, themes, save, close, and quit.

The bottom panel uses native Vim windows:

```vim
:Problems       " Show search, :make, and quickfix results
:TerminalPanel  " Open or return to the persistent terminal
:PanelToggle    " Open or close the panel
```

Project search is dependency-free and uses `globpath()` plus `:vimgrep`. Results open in the Problems panel; press Enter on a result to open it in the single editor window. `.git`, `node_modules`, and `.vercel` are excluded.

## Automatic saves

When leaving a modified named file, Vim runs `:update` before opening the next file. A failed write displays an error and leaves the modified buffer in memory. Unnamed files are never silently discarded and retain Vim's normal confirmation behavior.

## Themes

At startup, Vim uses the terminal's `COLORFGBG` value when available:

- Light background: `one-light`
- Dark background: `one-dark`

Manual commands:

```vim
:ThemeLight
:ThemeDark
:ThemeToggle
```

Theme detection happens at startup. Use a manual command if the terminal changes appearance while Vim is already running.

## Portability notes

- This requires full Vim 8 or 9. Some systems provide only `vi`, Vim Tiny, or no Vim.
- No plugin manager, plugins, Node, Lua, Neovim, external search tool, or patched font is required.
- `Ctrl+Option+Arrow` depends on the terminal emitting distinct modified-arrow sequences.
- Dependency-free quick open uses recursive `:find` completion rather than fuzzy ranking.
- Explorer hides `.git`, `node_modules`, and `.vercel`.

## Remove

Remove only the symlink and configuration directory:

```sh
rm ~/.vimrc
rm -rf ~/.config/vim
```
