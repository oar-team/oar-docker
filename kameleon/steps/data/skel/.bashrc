# If not running interactively, don't do anything
[ -z "$PS1" ] && return

export LC_CTYPE=fr_FR.UTF-8
export LANG=fr_FR.UTF-8
export LC_ALL=fr_FR.UTF-8


export OPT_BIN_PATH="$(find /opt -maxdepth 2 -type d | grep bin | paste -s -d ':')"
export PATH="$OPT_BIN_PATH:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"
export GIT_EDITOR=vim
export EDITOR=vim
export PYTHONSTARTUP=$HOME/.pythonrc.py
# ruby
export GEM_HOME="$HOME/.gems/ruby"

# Functions
source $HOME/.bash_functions.sh

# Aliases
include $HOME/.bash_aliases.sh

# Autocomplete
include $HOME/.autocomplete.sh

# Prompt
include $HOME/.git_prompt.sh
include $HOME/.bash_prompt.sh

# python + pip
export PIP_DOWNLOAD_CACHE="$HOME/.pip/cache"
# set where virutal environments will live
export WORKON_HOME=$HOME/.virtualenvs
# ensure all new environments are isolated from the site-packages directory
export VIRTUALENVWRAPPER_VIRTUALENV_ARGS='--no-site-packages'
# use the same directory for virtualenvs as virtualenvwrapper
export PIP_VIRTUALENV_BASE=$WORKON_HOME
# makes pip detect an active virtualenv and install to it
export PIP_RESPECT_VIRTUALENV=true
# virtualenv wrapper
include /usr/bin/virtualenvwrapper.sh
include /usr/local/bin/virtualenvwrapper.sh

stty werase undef
bind '\C-w:unix-filename-rubout'

# Hook
function after_exec_hook () {
    set_prompt
    history -a
}

function before_exec_hook () {
    :;
}

PROMPT_COMMAND=after_exec_hook
trap 'before_exec_hook_invoke' DEBUG

# Ne pas garder les trucs inutiles dans les logs (attention peut casser certaines habitudes)
export HISTIGNORE="cd:ls:[bf]g:clear"
# Correct dir spellings
shopt -q -s cdspell
 # Make sure display get updated when terminal window get resized
shopt -q -s checkwinsize
 # Turn on the extended pattern matching features 
shopt -q -s extglob
 # Append rather than overwrite history on exit
shopt -q -s histappend
 # Make multi-line commandsline in history
shopt -q -s cmdhist
shopt -q -s lithist
