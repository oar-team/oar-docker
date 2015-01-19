_fab() {
    local cur
    COMPREPLY=()
    # Variable to hold the current word
    cur="${COMP_WORDS[COMP_CWORD]}"

    # Build a list of the available tasks using the command 'fab -l'
    local tags=$(fab -l 2>/dev/null | grep "^ " | awk '{print $1;}')

    # Generate possible matches and store them in the
    # array variable COMPREPLY
    COMPREPLY=($(compgen -W "${tags}" $cur))
}

# Assign the auto-completion function _fab for our command fab.
complete -F _fab fab

_tm() {
    local cur
    COMPREPLY=()
    # Variable to hold the current word
    cur="${COMP_WORDS[COMP_CWORD]}"

    # Build a list of the available tasks using the command 'fab -l'
    local tags=$(tmux list-sessions 2> /dev/null | pyp "p.split(':')[1]")
    local projects="$(tmuxinator completions start)"

    # Generate possible matches and store them in the
    # array variable COMPREPLY
    COMPREPLY=($(compgen -W "${tags} ${projects}" $cur))
}
complete -F _tm tm

_tmuxinator() {
    COMPREPLY=()
    local word="${COMP_WORDS[COMP_CWORD]}"

    if [ "$COMP_CWORD" -eq 1 ]; then
local commands="$(compgen -W "$(tmuxinator commands)" -- "$word")"
        local projects="$(compgen -W "$(tmuxinator completions start)" -- "$word")"

        COMPREPLY=( $commands $projects )
    else
local words=("${COMP_WORDS[@]}")
        unset words[0]
        unset words[$COMP_CWORD]
        local completions=$(tmuxinator completions "${words[@]}")
        COMPREPLY=( $(compgen -W "$completions" -- "$word") )
    fi
}

complete -F _tmuxinator tmuxinator mux

complete -cf sudo
# Git autocompletion
include $HOME/.git_completion.sh


__pwdln() {
   pwdmod="${PWD}/"
   itr=0
   until [[ -z "$pwdmod" ]];do
      itr=$(($itr+1))
      pwdmod="${pwdmod#*/}"
   done
   echo -n $(($itr-1))
}

__vagrantinvestigate() {
    if [ -f "${PWD}/.vagrant" -o -d "${PWD}/.vagrant" ];then
      echo "${PWD}/.vagrant"
      return 0
   else
      pwdmod2="${PWD}"
      for (( i=2; i<=$(__pwdln); i++ ));do
         pwdmod2="${pwdmod2%/*}"
         if [ -f "${pwdmod2}/.vagrant" -o -d "${pwdmod2}/.vagrant" ];then
            echo "${pwdmod2}/.vagrant"
            return 0
         fi
      done
   fi
   return 1
}

_vagrant() {
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    commands="box connect destroy docker-logs docker-run global-status halt help init list-commands login package plugin provision rdp reload resume rsync rsync-auto share ssh ssh-config status suspend up version"	

    if [ $COMP_CWORD == 1 ]
    then
      COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
      return 0
    fi

    if [ $COMP_CWORD == 2 ]
    then
        case "$prev" in
            "init")
              local box_list=$(find $HOME/.vagrant.d/boxes -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
              COMPREPLY=($(compgen -W "${box_list}" -- ${cur}))
              return 0
            ;;
            "up")
              local up_commands="--no-provision"
              COMPREPLY=($(compgen -W "${up_commands}" -- ${cur}))
              return 0
            ;;
            "ssh"|"provision"|"reload"|"halt"|"suspend"|"resume"|"ssh-config")
              vagrant_state_file=$(__vagrantinvestigate) || return 1
      	      if [[ -f $vagrant_state_file ]]
              then
		            running_vm_list=$(grep 'active' $vagrant_state_file | sed -e 's/"active"://' | tr ',' '\n' | cut -d '"' -f 2 | tr '\n' ' ')
      	      else
		            running_vm_list=$(find $vagrant_state_file -type f -name "id" | awk -F"/" '{print $(NF-2)}')
      	      fi
              COMPREPLY=($(compgen -W "${running_vm_list}" -- ${cur}))
              return 0
            ;;
            "box")
              box_commands="add help list remove repackage"
              COMPREPLY=($(compgen -W "${box_commands}" -- ${cur}))
              return 0
            ;;
            "plugin")
              plugin_commands="install license list uninstall update"
              COMPREPLY=($(compgen -W "${plugin_commands}" -- ${cur}))
              return 0
            ;;
            "help")
              COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
              return 0
            ;;
            *)
            ;;
        esac
    fi

    if [ $COMP_CWORD == 3 ]
    then
      action="${COMP_WORDS[COMP_CWORD-2]}"
      if [ $action == 'box' ]
      then
        case "$prev" in
            "remove"|"repackage")
              local box_list=$(find $HOME/.vagrant.d/boxes -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
              COMPREPLY=($(compgen -W "${box_list}" -- ${cur}))
              return 0
              ;;
            *)
            ;;
        esac
      fi
    fi

}
complete -F _vagrant vagrant

function _ssh_completion() {

perl -ne 'print "$1 " if /^Host (.+)$/' ~/.ssh/config

}

complete -W "$(_ssh_completion)" ssh