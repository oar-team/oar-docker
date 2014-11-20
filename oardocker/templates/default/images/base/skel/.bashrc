# If not running interactively, don't do anything
[ -z "$PS1" ] && return

export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"
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

# a clean bash history
export HISTIGNORE="cd:ls:[bf]g:clear"

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
