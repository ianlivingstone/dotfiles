Ian Livingstone's Dotfiles
========

**Requirements**

- git
- neovim
- zsh
- gpg
- tmux

**Installation**

- Clone this repository (e.g. `git clone git@github.com:ianlivingstone/dotfiles.git`)
- Initialize the submodules (e.g. `git submodule update --init --recursive`)
- Set up the appropriate symlinks:
  - `mkdir -p ~/.config`
  - `ln -s .vim ~/.config/nvim`
  - `ln -s .vimrc ~/.config/nvim/init.vim`
  - `ln -s .zprofile ~/.zprofile

