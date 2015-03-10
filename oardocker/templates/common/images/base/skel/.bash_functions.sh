#!/bin/bash

export _SYSTEMCTL_BIN_PATH="$(which systemctl)"

function include () {
    [[ -f "$1" ]] && source "$1" > /dev/null
}

function cdtemp {
    local tmpdir=${1:-$(date +%Y-%m-%d-%H-%M-%S)}
    cd `mktemp -d --tmpdir ${tmpdir}_XXXXXXXX`
}

function listcontains() {
  for word in $1; do
    [[ $word = $2 ]] && return 0
  done
  return 1
}

function killbill {
    BAK=$IFS
    IFS=$'\n'
    for id in $(ps aux | grep -P -i $1 | grep -v "grep" | awk '{printf $2" "; for (i=11; i<NF; i++) printf $i" "; print $NF}'); do
        service=$(echo $id | cut -d " " -f 1)
        if [[ $2 == "-t" ]]; then
            echo $service "$(echo $id | cut -d " " -f 2-)" "would be killed"
        else

            echo $service "$(echo $id | cut -d " " -f 2-)" "killed"
            kill -9 $service
        fi
    done
    IFS=$BAK
}

loop() { while true ; do clear; "$@" ; sleep 1; done }

repeat() {
    "$@"
    while [ $? -ne 0 ]; do
        sleep 2;
        "$@"
    done
}

listcontains() {
  for word in $1; do
    [[ $word = $2 ]] && return 0
  done
  return 1
}

tm() {
    local projects
    tmux_session="${1:-${HOSTNAME}}"
    tmux has -t "$tmux_session" 2> /dev/null && tmux attach -t "$tmux_session" || tmux new -s "$tmux_session"
}

# Xcopy
# A shortcut function that simplifies usage of xclip.
# - Accepts input from either stdin (pipe), or params.
# ------------------------------------------------
cb() {
  local _scs_col="\e[0;32m"; local _wrn_col='\e[1;31m'; local _trn_col='\e[0;33m'
  # Check that xclip is installed.
  if ! type xclip > /dev/null 2>&1; then
    echo -e "$_wrn_col""You must have the 'xclip' program installed.\e[0m"
  # Check user is not root (root doesn't have access to user xorg server)
  elif [[ "$USER" == "root" ]]; then
    echo -e "$_wrn_col""Must be regular user (not root) to copy a file to the clipboard.\e[0m"
  else
    # If no tty, data should be available on stdin
    if ! [[ "$( tty )" == /dev/* ]]; then
      input="$(< /dev/stdin)"
    # Else, fetch input from params
    else
      input="$*"
    fi
    if [ -z "$input" ]; then  # If no input, print usage message.
      echo "Copies a string to the clipboard."
      echo "Usage: cb <string>"
      echo "       echo <string> | cb"
    else
      # Copy input to clipboard
      echo -n "$input" | xclip -selection c
      # Truncate text for status
      if [ ${#input} -gt 80 ]; then input="$(echo $input | cut -c1-80)$_trn_col...\e[0m"; fi
      # Print status.
      echo -e "$_scs_col""Copied to clipboard:\e[0m $input"
    fi
  fi
}

# Aliases / functions leveraging the cb() function
# ------------------------------------------------
# Copy contents of a file
function cbf() { cat "$1" | cb; }

function sprunge  () {
    if [ "$*" ]; then
        local prompt="$(PS1="$PS1" bash -i <<<$'\nexit' 2>&1 | head -n1)"
        ( echo "$(sed 's/\o033\[[0-9]*;[0-9]*m//g'  <<<"$prompt")$@"; exec $@; )
    else
        cat
    fi | curl -F 'sprunge=<-' http://sprunge.us
}

function before_exec_hook_invoke () {
    [ -n "$COMP_LINE" ] && return  # do nothing if completing
    [ "$BASH_COMMAND" = "$PROMPT_COMMAND" ] && return # don't cause a preexec for $PROMPT_COMMAND
    local this_command=`history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//g"`;
    before_exec_hook "$this_command"
}
