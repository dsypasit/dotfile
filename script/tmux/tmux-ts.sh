#!/usr/bin/bash

_FZF_TS_TMUX() (
	[[ -n "$TMUX" ]] && change="switch-client" || change="attach-session"
	if [ $1 ]; then
		tmux $change -t "$1" 2>/dev/null || (tmux new-session -d -s $1 && tmux $change -t "$1")
		return
	fi
	CHANGE='become:tmux $change -t {} || :'
	tmux ls | cut -d':' -f1 | fzf --tmux 90%,90% --preview-window=30% --preview 'tmux list-windows -t{}' \
		--border-label 'switch session' \
		--header 'Press CTRL-R to reload, CTRL-A to add, CTRL-D to delete' \
		--bind 'ctrl-a:execute(tmux new -s {q} -d )+reload(tmux ls | cut -d ":" -f1)' \
		--bind 'ctrl-d:execute(tmux kill-ses -t {})+reload(tmux ls | cut -d ":" -f1)' \
		--bind 'ctrl-r:reload(tmux ls | cut -d ":" -f1)' \
		--bind 'enter:become:tmux switch-client -t {} || :'
	return 0
)
_FZF_TS_TMUX
