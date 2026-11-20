# dotfile

Works on macOS, Ubuntu and Arch.

```sh
git clone https://github.com/Dsypasit/dotfile.git ~/dotfile
cd ~/dotfile
./install.sh
```

On Linux it asks whether you want a window manager (none, i3, or hyprland on Arch).
On macOS it skips that question, since the WM tools are Linux only.

Options:

```sh
./install.sh --wm none|i3|hyprland   # skip the question
./install.sh --dry-run               # print every command, change nothing
DOTFILE_OS=ubuntu ./install.sh --dry-run   # preview another OS
```

## What it does

1. Installs CLI tools with brew, pacman (plus yay/paru for AUR) or apt.
2. With a WM: installs its tools (polybar, picom, dunst, nitrogen, sxiv, ...) and writes the choice to `~/.config/dotfile-wm`. `alias` loads `alias.wm` only when that file exists.
3. Installs oh-my-zsh on Linux, clones the zsh plugins into `~/.zsh-custom`, and sets zsh as the default shell.
4. Symlinks the configs into `$HOME`. Anything already there is moved to `<name>.bak.<timestamp>`.
5. Initialises the `nvim` submodule and links it to `~/.config/nvim`.

Safe to re-run.

## Ubuntu notes

apt is missing or too old for a few tools, so the script installs these another way:
starship and mise (official installers), lazygit (GitHub release), fzf (from source, because `.zshrc` needs `fzf --zsh`), and neovim and yazi (snap).
`fd` and `bat` are symlinked into `~/.local/bin` because Ubuntu names them `fdfind` and `batcat`.

## Files

| File | Purpose |
| --- | --- |
| `alias` | Shared aliases and fzf helpers, sourced by `.zshrc`, `.zshrc.mac` and `.bashrc` |
| `alias.wm` | Wallpaper and image-viewer aliases, loaded only with a WM |
| `.zshrc` | Linux zsh config (Arch-only pacman helpers are guarded) |
| `.zshrc.mac` | macOS zsh config |
