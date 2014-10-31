HOSTNAME=$(hostname)

# Colors
# Reset
ResetColor="\[\033[0m\]"

# Regular Colors
Red="\[\033[0;31m\]"
LightRed="\[\033[1;31m\]"
Yellow="\[\033[0;33m\]"
LightYellow="\[\033[1;33m\]"
Blue="\[\033[0;34m\]"
LightBlue="\[\033[1;34m\]"
Green="\[\033[0;32m\]"
BGreen="\[\033[1;32m\]"
IBlack="\[\033[0;90m\]"
Magenta="\[\033[0;35m\]"

test ! -f /etc/hostname.color || source /etc/hostname.color

if [ "$COLOR" == "red" ]; then
    HOST_COLOR="$Red"
elif [ "$COLOR" == "yellow" ]; then
    HOST_COLOR="$Yellow"
elif [ "$COLOR" == "blue" ]; then
    HOST_COLOR="$Blue"
elif [ "$COLOR" == "green" ]; then
    HOST_COLOR="$Green"
elif [ "$COLOR" == "bgreen" ]; then
    HOST_COLOR="$BGreen"
elif [ "$COLOR" == "iblack" ]; then
    HOST_COLOR="$IBlack"
elif [ "$COLOR" == "magenta" ]; then
    HOST_COLOR="$Magenta"
else
    HOST_COLOR="$Green"
fi


USER_COLOR=$HOST_COLOR
if [ "$(whoami)" == "root"  ]; then
   USER_COLOR=$Red
fi


# Various variables you might want for your PS1 prompt instead
Time24a=""
PathShort="\w"

# Default values for the appearance of the prompt. Configure at will.
GIT_PROMPT_PREFIX="("
GIT_PROMPT_SUFFIX=")"
GIT_PROMPT_SEPARATOR="|"
GIT_PROMPT_BRANCH="${Magenta}"
GIT_PROMPT_STAGED="${Yellow}✚ "
GIT_PROMPT_CONFLICTS="${Red}✖ "
GIT_PROMPT_CHANGED="${Red}● "
GIT_PROMPT_REMOTE=" "
GIT_PROMPT_UNTRACKED="…"
GIT_PROMPT_CLEAN="${BGreen}✔"


# Determine active Python virtualenv details.
function set_virtualenv () {
  if test -z "$VIRTUAL_ENV" ; then
      PYTHON_VIRTUALENV=""
  else
      PYTHON_VIRTUALENV="${BLUE}[`basename \"$VIRTUAL_ENV\"`]${COLOR_NONE} "
  fi
}


function update_current_git_vars() {
    unset __CURRENT_GIT_STATUS
    local gitstatus="$HOME/.gitstatus.py"

    _GIT_STATUS=$(/usr/bin/python2 $gitstatus)
    __CURRENT_GIT_STATUS=($_GIT_STATUS)
    GIT_BRANCH=${__CURRENT_GIT_STATUS[0]}
    GIT_REMOTE=${__CURRENT_GIT_STATUS[1]}
    if [[ "." == "$GIT_REMOTE" ]]; then
        unset GIT_REMOTE
    fi
    GIT_STAGED=${__CURRENT_GIT_STATUS[2]}
    GIT_CONFLICTS=${__CURRENT_GIT_STATUS[3]}
    GIT_CHANGED=${__CURRENT_GIT_STATUS[4]}
    GIT_UNTRACKED=${__CURRENT_GIT_STATUS[5]}
    GIT_CLEAN=${__CURRENT_GIT_STATUS[6]}
}


function set_prompt () {

if test $? -eq 0 ; then
  PROMPT_SYMBOL="\$"
else
  PROMPT_SYMBOL="$LightRed\$$ResetColor"
fi

set_virtualenv

PROMPT_START="$Blue$PYTHON_VIRTUALENV$IBlack$Time24a$ResetColor$USER_COLOR\u$HOST_COLOR@\h $ResetColor$Yellow$PathShort$ResetColor"
PROMPT_END="
${PROMPT_SYMBOL} "

update_current_git_vars

if [ -n "$__CURRENT_GIT_STATUS" ]; then
    STATUS=" $GIT_PROMPT_PREFIX$GIT_PROMPT_BRANCH$GIT_BRANCH$ResetColor"

    if [ -n "$GIT_REMOTE" ]; then
        STATUS="$STATUS$GIT_PROMPT_REMOTE$GIT_REMOTE$ResetColor"
    fi

    STATUS="$STATUS$GIT_PROMPT_SEPARATOR"
    if [ "$GIT_STAGED" -ne "0" ]; then
        STATUS="$STATUS$GIT_PROMPT_STAGED$GIT_STAGED$ResetColor"
    fi

    if [ "$GIT_CONFLICTS" -ne "0" ]; then
        STATUS="$STATUS$GIT_PROMPT_CONFLICTS$GIT_CONFLICTS$ResetColor"
    fi
    if [ "$GIT_CHANGED" -ne "0" ]; then
        STATUS="$STATUS$GIT_PROMPT_CHANGED$GIT_CHANGED$ResetColor"
    fi
    if [ "$GIT_UNTRACKED" -ne "0" ]; then
        STATUS="$STATUS$GIT_PROMPT_UNTRACKED$GIT_UNTRACKED$ResetColor"
    fi
    if [ "$GIT_CLEAN" -eq "1" ]; then
        STATUS="$STATUS$GIT_PROMPT_CLEAN"
    fi
    STATUS="$STATUS$ResetColor$GIT_PROMPT_SUFFIX"

    PS1="$PROMPT_START$STATUS$PROMPT_END"
else
    PS1="$PROMPT_START$PROMPT_END"
fi
}
