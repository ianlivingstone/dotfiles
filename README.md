# Ian Livingstone's Dotfiles

My personal development setup — Zsh, Neovim, Tmux, and Git — built to work cleanly
across multiple machines with different identities and keys. Secure by default, quick
to set up, and easy to share without leaking anything personal.

## ✨ What you get

- **Zsh + Starship** — a fast shell with a prompt that shows git status, language
  versions, and context (Docker/Kubernetes/AWS) only when it's relevant.
- **Neovim** — LSP, autocompletion, fuzzy finding, and treesitter highlighting, with
  plugins pinned for reproducible installs.
- **Tmux** — terminal multiplexing with sessions that auto-save and survive restarts.
- **Git** — handy aliases and GPG-signed commits out of the box.
- **Multi-machine by design** — your name, email, SSH keys, and signing key are set
  per machine and kept out of the repo, so you can safely share your fork.

## 🚀 Quick start

```bash
git clone https://github.com/ianlivingstone/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./dotfiles.sh install     # installs Homebrew packages, links configs, sets up keys
exec zsh                  # restart your shell
```

The installer checks your dependencies, installs everything in the [`Brewfile`](Brewfile),
and walks you through choosing your Git identity, SSH keys, and GPG signing key for this
machine. If a version manager it doesn't manage (nvm, gvm, rustup) is missing, it prints
the exact command to install it.

## 🛠️ Everyday commands

```bash
./dotfiles.sh status      # is everything installed and up to date?
./dotfiles.sh update      # update language versions + Homebrew packages
./dotfiles.sh reinstall   # re-link after changing configs
./dotfiles.sh uninstall   # remove all symlinks
./dotfiles.sh help        # list commands
```

Shell helper: `clear-caches` (try `clear-caches --help`) clears shell/completion caches
if a completion ever looks stale.

## ⌨️ Editor & terminal

- **Neovim plugins** are managed by [lazy.nvim](https://lazy.folke.io/) and pinned in
  `lazy-lock.json` — update on your terms with `:Lazy sync`; nothing auto-updates.
- **Tmux sessions** auto-save every 15 minutes and restore on launch (resurrect +
  continuum), keeping pane contents across restarts.

Handy keys: `<Space>ff` find files · `<Space>fg` grep · `<Space>e` file explorer ·
`Ctrl-a Ctrl-s` / `Ctrl-a Ctrl-r` save/restore a tmux session.

## 📁 What gets linked

| Config | Location |
|--------|----------|
| Shell | `~/.zshrc`, `~/.zprofile` |
| Git | `~/.gitconfig` (+ machine-specific include) |
| SSH | `~/.ssh/config` (+ machine-specific include) |
| Tmux | `~/.tmux.conf` |
| Neovim | `~/.config/nvim/` |
| Starship | `~/.config/starship.toml` |

Personal, machine-specific settings live in `~/.config/git/` and `~/.config/ssh/` and
are **never** committed to the repo.

Every new shell greets you with a one-line summary:

```
🏠 user@host ~/directory | 📦 main ✓ | 🔋 100% | 🕐 14:32
```

## 🔒 Security

- **GPG-signed** commits and tags, required by default.
- **Per-machine** SSH and GPG keys; private data stays in your XDG config, never the repo.
- **HTTPS-only** network operations and secure `600`/`700` permissions on config files —
  the shell warns you on startup if anything drifts.

## 🤝 Make it yours

Add any tool's config in three steps:

```bash
mkdir mytool                  # add your config files here (mirroring their target paths)
echo "mytool" >> packages.config
./dotfiles.sh reinstall
```

That's it — your configs are now managed alongside everything else.

---

Curious how it works under the hood? See [ARCHITECTURE.md](ARCHITECTURE.md). Contributor
and tooling notes live in [CLAUDE.md](CLAUDE.md) and [docs/](docs/).
