Igit
=============
![Neovim](https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white)

[![CI Status](https://github.com/ipod825/igit.nvim/workflows/CI/badge.svg?branch=main)](https://github.com/ipod825/igit.nvim/actions)

## Dependency
1. [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
2. [libp.nvim](https://github.com/ipod825/libp.nvim)

## Installation
------------

Use you preferred package manager. Below we use [packer.nvim](https://github.com/wbthomason/packer.nvim) as an example.

```lua
use {'nvim-lua/plenary.nvim'}
use {'ipod825/libp.nvim'}
use {'ipod825/igit.nvim'}
```
or

```lua
use {'ipod825/igit.nvim', requires={'nvim-lua/plenary.nvim', 'ipod825/libp.nvim'}}
```

## Usage
```vim
:IGit status            " Opens the status page (defaults with -s argument.)
:IGit status --long     " Opens customized status page. 
:IGit log               " Opens the log page (defaults with  "--oneline --branches --graph --decorate=short")
:IGit log --pretty="format:%h%x09%an%x09%ad%x09%s" " Opens Customized log page
:IGit branch            " Opens the branch page (defaults with -v argument.)
:IGit branch --abrev    " Opens customized branch page.

:belowright IGit status " Opens pages with modifier

:IGit push              " Execute arbitrary git command
```

## Page Mappings
See `:help igit-mappings`. 

Highlights:
- Interactive staging with vim diff window.
- Rebase chains of commits in branch or log pages.
- Add/Remove/Rename branches in branch pages just like editing files.

## Customization
See `igit-customization`.

Highlights:
- Default command name `IGit` is customizable.
- Pages open command is customizable.
- Mappings handlers takes lua functions.


## Screen Shot
![branch](https://raw.githubusercontent.com/ipod825/igit.nvim/main/screenshots/branch.gif)
![log](https://raw.githubusercontent.com/ipod825/igit.nvim/main/screenshots/log.gif)
![status](https://raw.githubusercontent.com/ipod825/igit.nvim/main/screenshots/status.gif)
