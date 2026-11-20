#!/usr/bin/env bash
# Dotfile installer for macOS, Ubuntu and Arch.
#
#   ./install.sh                  interactive (asks about a window manager on Linux)
#   ./install.sh --wm none|i3|hyprland
#   ./install.sh --dry-run        print what would run, change nothing
#
# Safe to re-run. Existing files are moved to <name>.bak.<timestamp>, never deleted.
# Works with macOS's bash 3.2: no mapfile, no associative arrays.

set -u

DOTFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WM=""
DRY=0
TS="$(date +%Y%m%d%H%M%S)"

while [ $# -gt 0 ]; do
	case "$1" in
	--wm) WM="${2:-}"; shift ;;
	--dry-run) DRY=1 ;;
	-h | --help) sed -n 2,9p "$0"; exit 0 ;;
	*) echo "Unknown option: $1" >&2; exit 1 ;;
	esac
	shift
done

say() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }
run() {
	if [ "$DRY" = 1 ]; then printf '[dry-run] %s\n' "$*"; else "$@"; fi
}
have() { command -v "$1" >/dev/null 2>&1; }

# ---------- detect OS ----------
# DOTFILE_OS=macos|ubuntu|arch overrides detection (useful with --dry-run).
detect_os() {
	if [ -n "${DOTFILE_OS:-}" ]; then echo "$DOTFILE_OS"; return; fi
	case "$(uname -s)" in
	Darwin) echo macos ;;
	Linux)
		if [ -f /etc/os-release ]; then
			# shellcheck disable=SC1091
			. /etc/os-release
			case "${ID:-} ${ID_LIKE:-}" in
			*arch* | *manjaro*) echo arch ;;
			*ubuntu* | *debian*) echo ubuntu ;;
			*) echo unsupported ;;
			esac
		else
			echo unsupported
		fi
		;;
	*) echo unsupported ;;
	esac
}

OS="$(detect_os)"
if [ "$OS" = unsupported ]; then
	echo "Unsupported OS. This script covers macOS, Ubuntu (Debian-based) and Arch." >&2
	exit 1
fi
say "Detected: $OS"

# ---------- ask about window manager ----------
choose_wm() {
	if [ "$OS" = macos ]; then
		echo "none"
		return
	fi
	if [ -n "$WM" ]; then echo "$WM"; return; fi
	if [ ! -t 0 ]; then echo "none"; return; fi

	{
		echo
		echo "Do you want a window manager? It adds tools like polybar, picom, dunst,"
		echo "nitrogen/swww, sxiv that only make sense on a WM desktop."
		echo "  1) none      terminal tools only (servers, WSL, GNOME/KDE desktops)"
		echo "  2) i3        X11 tiling WM"
		if [ "$OS" = arch ]; then
			echo "  3) hyprland  Wayland tiling WM (Arch only)"
		fi
	} >&2
	printf 'Choose [1]: ' >&2
	read -r ans
	case "$ans" in
	2) echo i3 ;;
	3) if [ "$OS" = arch ]; then echo hyprland; else echo none; fi ;;
	*) echo none ;;
	esac
}

if [ "$OS" = macos ] && [ -n "$WM" ] && [ "$WM" != none ]; then
	warn "Window manager packages are Linux only. Ignoring --wm $WM on macOS."
fi
WM="$(choose_wm)"
case "$WM" in
none | i3 | hyprland) ;;
*) echo "Invalid --wm '$WM' (use none, i3 or hyprland)" >&2; exit 1 ;;
esac
if [ "$WM" = hyprland ] && [ "$OS" != arch ]; then
	warn "Hyprland is only supported on Arch here. Falling back to i3."
	WM=i3
fi
say "Window manager: $WM"

# ---------- package installers ----------
AUR_HELPER=""
have yay && AUR_HELPER=yay
[ -z "$AUR_HELPER" ] && have paru && AUR_HELPER=paru

# Install packages with pacman, falling back to the AUR helper for non-repo ones.
arch_install() {
	local pkg repo="" aur=""
	for pkg in "$@"; do
		if [ "$DRY" = 1 ] || pacman -Si "$pkg" >/dev/null 2>&1; then
			repo="$repo $pkg"
		else
			aur="$aur $pkg"
		fi
	done
	# shellcheck disable=SC2086
	[ -n "$repo" ] && run sudo pacman -S --needed --noconfirm $repo
	if [ -n "$aur" ]; then
		if [ -n "$AUR_HELPER" ]; then
			# shellcheck disable=SC2086
			run "$AUR_HELPER" -S --needed --noconfirm $aur
		else
			warn "Not in repos and no yay/paru found, install by hand:$aur"
		fi
	fi
}

apt_install() { run sudo apt-get install -y "$@"; }

install_base_macos() {
	if ! have brew; then
		say "Installing Homebrew"
		run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	fi
	run brew install git zsh tmux neovim fzf fd bat eza ripgrep zoxide starship \
		lazygit gh jq yazi ranger btop fastfetch mise lazydocker lsd difftastic git-lfs
	run brew install --cask font-hack-nerd-font
}

install_base_arch() {
	run sudo pacman -Syu --noconfirm
	arch_install base-devel git zsh tmux neovim fzf fd bat eza ripgrep zoxide starship \
		lazygit github-cli jq yazi ranger btop fastfetch mise lazydocker difftastic \
		git-lfs curl unzip
}

install_base_ubuntu() {
	run sudo apt-get update
	apt_install build-essential git zsh tmux fzf fd-find bat ripgrep zoxide jq gh \
		ranger btop curl unzip fontconfig git-lfs
	# Newer than apt where it matters. Each is best-effort so one failure does not stop the rest.
	apt_install eza || warn "eza not in apt on this release. Install it by hand."
	apt_install fastfetch || warn "fastfetch not in apt on this release. Skipping."
	have snap && { run sudo snap install nvim --classic || true; run sudo snap install yazi --classic || true; }
	have nvim || apt_install neovim
	ubuntu_extras
}

# Things apt lacks or ships too old: starship, mise, lazygit, fzf >= 0.48, fd/bat names.
ubuntu_extras() {
	run mkdir -p "$HOME/.local/bin"
	have fdfind && [ ! -e "$HOME/.local/bin/fd" ] && run ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
	have batcat && [ ! -e "$HOME/.local/bin/bat" ] && run ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"

	have starship || run sh -c 'curl -sS https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$HOME/.local/bin"'
	have mise || run sh -c 'curl -fsSL https://mise.run | sh'

	# .zshrc uses `fzf --zsh`, which needs fzf 0.48+. apt on Ubuntu LTS is older.
	local fzf_ver
	fzf_ver="$(fzf --version 2>/dev/null | awk '{print $1}')"
	if [ "$DRY" = 1 ] || [ -z "$fzf_ver" ] || [ "$(printf '%s\n0.48.0\n' "$fzf_ver" | sort -V | head -n1)" != "0.48.0" ]; then
		say "Installing fzf from source (apt version is too old)"
		[ -d "$HOME/.fzf" ] || run git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
		run "$HOME/.fzf/install" --bin --no-update-rc --no-key-bindings --no-completion
		run ln -sf "$HOME/.fzf/bin/fzf" "$HOME/.local/bin/fzf"
	fi

	if ! have lazygit; then
		say "Installing lazygit"
		run sh -c '
			set -e
			v=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -Po "\"tag_name\": *\"v\K[^\"]*")
			arch=$(uname -m); [ "$arch" = aarch64 ] && arch=arm64
			curl -fLo /tmp/lazygit.tgz "https://github.com/jesseduffield/lazygit/releases/download/v${v}/lazygit_${v}_Linux_${arch}.tar.gz"
			tar -xf /tmp/lazygit.tgz -C /tmp lazygit
			install /tmp/lazygit "$HOME/.local/bin/lazygit"
		' || warn "lazygit install failed. Install it by hand."
	fi
}

install_wm() {
	case "$OS:$WM" in
	*:none) return ;;
	arch:i3)
		arch_install i3-wm i3status polybar dunst picom nitrogen feh sxiv vifm kitty alacritty rofi
		;;
	arch:hyprland)
		arch_install hyprland waybar wofi mako swaylock wlogout swww kitty hyprpaper
		;;
	ubuntu:i3)
		apt_install i3 polybar dunst picom nitrogen feh sxiv vifm kitty alacritty rofi
		;;
	esac
	# alias loads alias.wm only when this marker exists.
	run mkdir -p "$HOME/.config"
	if [ "$DRY" = 1 ]; then echo "[dry-run] echo $WM > ~/.config/dotfile-wm"; else echo "$WM" >"$HOME/.config/dotfile-wm"; fi
}

# ---------- shell: oh-my-zsh + plugins ----------
install_shell() {
	if [ "$OS" != macos ] && [ ! -d /usr/share/oh-my-zsh ] && [ ! -d "$HOME/.oh-my-zsh" ]; then
		say "Installing oh-my-zsh"
		run env RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
			"$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	fi
	# Plugins named in .zshrc, cloned where ZSH_CUSTOM points.
	local name url dest
	for entry in \
		"zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions" \
		"zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting" \
		"zsh-256color https://github.com/chrissicool/zsh-256color"; do
		name="${entry%% *}"
		url="${entry#* }"
		dest="$HOME/.zsh-custom/plugins/$name"
		[ -d "$dest" ] || run git clone --depth 1 "$url" "$dest"
	done

	if [ "$(basename "${SHELL:-}")" != zsh ] && have zsh; then
		say "Setting zsh as default shell"
		run chsh -s "$(command -v zsh)" || warn "chsh failed. Run: chsh -s $(command -v zsh)"
	fi
}

# ---------- link dotfiles ----------
link() {
	local src="$1" dst="$2"
	if [ ! -e "$src" ]; then warn "Missing in repo, skipped: $src"; return; fi
	if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then return; fi
	run mkdir -p "$(dirname "$dst")"
	if [ -e "$dst" ] || [ -L "$dst" ]; then
		echo "backup: $dst -> $dst.bak.$TS"
		run mv "$dst" "$dst.bak.$TS"
	fi
	run ln -s "$src" "$dst"
	echo "linked: $dst"
}

link_dotfiles() {
	if [ "$OS" = macos ]; then
		link "$DOTFILE/.zshrc.mac" "$HOME/.zshrc"
	else
		link "$DOTFILE/.zshrc" "$HOME/.zshrc"
	fi
	link "$DOTFILE/.tmux.conf" "$HOME/.tmux.conf"
	link "$DOTFILE/.tmux.reset.conf" "$HOME/.tmux.reset.conf"
	link "$DOTFILE/.gitconfig" "$HOME/.gitconfig"
	link "$DOTFILE/catppuccin.gitconfig" "$HOME/catppuccin.gitconfig"

	local d
	for d in bat btop lazygit yazi ranger kitty alacritty fontconfig; do
		link "$DOTFILE/.config/$d" "$HOME/.config/$d"
	done
	link "$DOTFILE/.config/starship.toml" "$HOME/.config/starship.toml"

	# nvim config is a git submodule of this repo.
	if [ ! -e "$DOTFILE/nvim/init.lua" ] && [ ! -e "$DOTFILE/nvim/init.vim" ]; then
		run git -C "$DOTFILE" submodule update --init nvim
	fi
	link "$DOTFILE/nvim" "$HOME/.config/nvim"

	case "$WM" in
	i3)
		link "$DOTFILE/.i3" "$HOME/.i3"
		for d in polybar picom dunst feh sxiv vifm; do link "$DOTFILE/.config/$d" "$HOME/.config/$d"; done
		;;
	hyprland)
		link "$DOTFILE/.config/hypr" "$HOME/.config/hypr"
		for d in waybar wofi mako swaylock wlogout; do link "$DOTFILE/HyprV/$d" "$HOME/.config/$d"; done
		;;
	esac
	run mkdir -p "$HOME/wallpapers"
}

install_fonts() {
	# macOS gets the Nerd Font from brew. Linux uses the repo's Hack installer.
	[ "$OS" = macos ] && return
	run bash "$DOTFILE/install-font"
}

# ---------- main ----------
case "$OS" in
macos) install_base_macos ;;
arch) install_base_arch ;;
ubuntu) install_base_ubuntu ;;
esac
install_wm
install_shell
install_fonts
link_dotfiles

say "Done. Open a new terminal (or run: exec zsh)."
[ "$DRY" = 1 ] && echo "That was a dry run. Nothing was changed."
exit 0
