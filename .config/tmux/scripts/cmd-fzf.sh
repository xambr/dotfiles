#!/bin/sh
# Fuzzy-pick a tmux command, then run it with optional args.
cmd=$(tmux list-commands -F '#{command_list_name}' \
  | fzf --prompt='tmux> ' \
        --preview 'tmux list-commands {} 2>/dev/null' \
        --preview-window=up,3,wrap) || exit 0
[ -z "$cmd" ] && exit 0
printf 'args for "%s" (empty=none): ' "$cmd"
read -r args
# shellcheck disable=SC2086
tmux "$cmd" $args
