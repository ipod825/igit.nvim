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
use {
	"ipod825/libp.nvim",
	config = function()
		require("libp").setup()
	end,
}
use {
	"ipod825/igit.nvim",
	config = function()
		require("igit").setup()
	end,
}
```

## Usage
```vim
:IGit status            " Opens the status page (defaults with -s argument.)
:IGit status --long     " Opens customized status page.
:IGit log               " Opens the log page (defaults with  "--oneline --branches --graph --decorate=short")
:IGit log --pretty="format:%h%x09%an%x09%ad%x09%s" " Opens Customized log page
:IGit branch            " Opens the branch page (defaults with -v argument.)
:IGit branch --abrev    " Opens customized branch page.

:belowright IGit status " Opens pages with modifier.
:IGit log | tabmove -1  " Execut commands after opening the page.

:IGit push              " Execute common git commands (missing commands can be added. See :help igit-customization)
```

## Page Mappings
See `:help igit-mappings`.

Highlights:
- Interactive staging with vim diff window.
- Rebase chains of commits in branch or log pages.
- Add/Remove/Rename branches in branch pages just like editing files.

## Customization
See `:help igit-customization`.

Highlights:
- Default command name `IGit` is customizable.
- Pages open command is customizable.
- Mappings handlers takes lua functions.


## Screen Shot
![branch](https://user-images.githubusercontent.com/1246394/164836705-b78a09b4-0707-4009-80ab-67a3f15626ed.png)
![log](https://user-images.githubusercontent.com/1246394/164836708-4f0fe4c5-846b-437b-8427-ec2d0462a5f2.png)
![status](https://user-images.githubusercontent.com/1246394/164836709-5782ea27-36b7-44d6-bb32-30ff9c720e56.png)
