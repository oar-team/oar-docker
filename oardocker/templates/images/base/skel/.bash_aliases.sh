#!/bin/bash

# Super-User operations.
# When using sudo, use alias expansion (otherwise sudo ignores your aliases)
alias sudo="sudo -E "
alias _='sudo'

for __cmd in apt-get aptitude yum service systemctl pacman; do
  eval "alias $__cmd='_ $__cmd'"
done ; unset __cmd

alias apt="aptitude"
alias ap="apt update && apt upgrade -y && sudo apt safe-upgrade -y && apt autoclean -y"
alias la='ls -alhFt --color=auto'
alias ll='ls -halF --color=tty'
alias ls='ls --color=tty'

alias pycclean='find . -name "*.pyc" | xargs -I {} rm -v "{}"'

alias gitclean='git clean -fd'
alias myip="dig +short myip.opendns.com @resolver1.opendns.com"

alias ssh-x='ssh -X'

## TMUX
alias tmux='tmux -2'

# Quick commands access.
alias g='git'

# emacs
alias e="emacsclient -t"
# Open Vim tabs for each argument.
alias v='vim -p'

alias ggrep='git grep --color -n -P';
alias xs='cd'
alias vf='cd'
# Basic directory operations.
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias ......='cd ../../../../../'
alias u="cd .. && ls"
# size/storage
alias du='du -h --max-depth=1'
alias dusort='du -h --max-depth=1 | sort -h'
alias df='df -h'
alias chown='chown -h'
alias process='ps aux | grep'
# Date
alias ntpupdate='ntpdate fr.pool.ntp.org'
alias memrss='while read command percent rss; do if [[ "${command}" != "COMMAND" ]]; then rss="$(bc <<< "scale=2;${rss}/1024")"; fi; printf "%-26s%-8s%s\n" "${command}" "${percent}" "${rss}"; done < <(ps -A --sort -rss -o comm,pmem,rss | head -n 11)'

alias fast_rsync="rsync -aHAXxv --numeric-ids --delete --progress -e \"ssh -T -c arcfour -o Compression=no -x\""

# Copy SSH public key
alias cbssh="cbf $HOME/.ssh/id_rsa.pub"
# Copy current working directory
alias cbwd="pwd | cb"
# Copy most recent command in bash history
alias cbhs="cat $HISTFILE | tail -n 1 | cb"
