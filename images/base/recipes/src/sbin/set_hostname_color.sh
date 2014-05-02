#!/bin/bash
set -e

# Regular Colors
red="\[\033[0;31m\]"
yellow="\[\033[0;33m\]"
blue="\[\033[0;34m\]"
green="\[\033[0;32m\]"
bgreen="\[\033[1;32m\]"
iblack="\[\033[0;90m\]"
magenta="\[\033[0;35m\]"

if [ "$COLOR" == "red" ]; then
    HOST_COLOR="$red"
elif [ "$COLOR" == "yellow" ]; then
    HOST_COLOR="$yellow"
elif [ "$COLOR" == "blue" ]; then
    HOST_COLOR="$blue"
elif [ "$COLOR" == "green" ]; then
    HOST_COLOR="$green"
elif [ "$COLOR" == "bgreen" ]; then
    HOST_COLOR="$bgreen"
elif [ "$COLOR" == "iblack" ]; then
    HOST_COLOR="$iblack"
elif [ "$COLOR" == "magenta" ]; then
    HOST_COLOR="$magenta"
else
    HOST_COLOR="$green"
fi

echo "$HOST_COLOR" > /etc/hostname.color
