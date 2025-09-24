# Bash completion for devbox

_devbox_complete() {
  local cur prev subcmds
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  subcmds="bootstrap brew asdf shell apps doctor update version help --config"

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "$subcmds" -- "$cur") )
    return 0
  fi

  case "${COMP_WORDS[1]}" in
    brew)
      if [[ $COMP_CWORD -eq 2 ]]; then
        COMPREPLY=( $(compgen -W "" -- "$cur") )
      fi
      ;;
    asdf)
      if [[ $COMP_CWORD -eq 2 ]]; then
        COMPREPLY=( $(compgen -W "nodejs golang" -- "$cur") )
      elif [[ $COMP_CWORD -eq 3 ]]; then
        COMPREPLY=( $(compgen -W "latest" -- "$cur") )
      fi
      ;;
    doctor)
      COMPREPLY=( $(compgen -W "--dry-run" -- "$cur") )
      ;;
  esac
}
complete -F _devbox_complete devbox
