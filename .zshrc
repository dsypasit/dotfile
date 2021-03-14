# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
#neofetch
#figlet Welcom  Dsy
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export TERMINAL=/usr/bin/alacritty
export ZSH="/home/dsy/.oh-my-zsh"
export EDITOR=/usr/bin/nvim
export VISUAL=/usr/bin/nvim

export DOWNGRADE_FROM_ALA=1
# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

#ZSH_THEME="powerlevel10k/powerlevel10k"
eval "$(starship init zsh)"

plugins=(
	zsh-syntax-highlighting
	git
	#zsh-autosuggestions
	autojump
)


source $ZSH/oh-my-zsh.sh

ZSH_AUTOSUGGEST_STRATEGY=(history completion)

bindkey "^k" autosuggest-accept

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Example aliases
alias z="clear;zsh"
alias vz="nvim ~/.zshrc"
alias vv="nvim ~/.config/nvim/init.vim"
alias v='nvim'
alias vim='nvim'
alias pac="sudo pacman"
alias vf="vifm"
alias ju="jupyter notebook"

alias cl='clear'
alias rh='cd $PWD;python3 -m http.server --cgi 8080'
alias cf='fc-list'
alias ct="source ~/my_linux_env/bash_script/timeout.sh"
alias fp="fzf --preview 'bat --color "always" {}'"
alias mb="~/my_linux_env/backup"
alias vb="~/scripts/nvim_backup"
alias w='feh --bg-fill --randomize ~/wallpapers'

alias weather='clear && curl wttr.in'
alias fetch='clear && neofetch'
alias mw="(mv ~/Downloads/*.png ~/wallpapers/ 2>/dev/null | mv ~/Downloads/*.jpg ~/wallpapers/ 2>/dev/null) 2>/dev/null && echo 'move wallpaper file success!!'"

alias aa="~/coding/python_project/scraping/add_anime.py $1 $2"
alias chapter="~/coding/python_project/scraping/anime_chapters.py $1 $2"
alias sa="~/coding/python_project/scraping/showanime.py; less ~/coding/python_project/scraping/anime_name.txt"

fk(){du -a ~/coding | awk '{print $2}' | fzf | xargs -o nvim}
html(){touch index.html script.js style.css}

scr()
{
	cd ~/scripts/$1
}


stenv()
{
	op=$1
	name="env"
	if [[ $op == 'mk' ]]; then
		if [[ -n $2  ]]; then name=$2;fi
		python3 -m venv $name
		echo "create $name enveroment success! "
	else
		if [[ -n $op  ]]; then name=$op;fi
		source $name/bin/activate 2>/dev/null
		if [ $? -eq 0 ]; then
			echo 'Activate Success!!'
		else
			echo "Error: ${name} is not env name" 
		fi
	fi
}

coding()
{
	if [[ $1 == 'md' ]]; then
		find ~/Coding/$2 2>/dev/null
		if [[ $? -ne 1 ]]; then
			echo "Error : can't create folder $2. Please try again."
		else
			mkdir ~/Coding/$2
			cd ~/Coding/$2
		fi
	elif [[ $1 == 'll' ]]; then
		ll ~/Coding/$2
	else
		if [[ $1 == 'p' ]]; then
			cd ~/Coding/play_ground
		else
			cd ~/Coding/$1
		echo $PWD
		fi
	fi
}

#[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
