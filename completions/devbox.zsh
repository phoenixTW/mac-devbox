#compdef devbox

# Zsh completion for devbox
# Supports: --config, subcommands, and basic argument hints.

local -a _subcmds
_subcmds=(
  'bootstrap:Full setup (safe to re-run)'
  'brew:Install all from config or a single package'
  'asdf:Install all from config or a single tool@version'
  'shell:Configure zsh/oh-my-zsh/agnoster'
  'apps:First-launch registrations'
  'doctor:Show detected versions vs config'
  'update:Update devbox CLI to latest version'
  'version:Show version information'
  'help:Show usage'
)

_arguments -C \
  '--config[Path to config dir]:dir:_files -/' \
  '1: :->subcmd' \
  '*:: :->args'

case $state in
  subcmd)
    _describe 'command' _subcmds
  ;;
  args)
    case $words[2] in
      brew)
        if (( CURRENT == 3 )); then
          _message "package (formula or cask)"
        fi
      ;;
      asdf)
        if (( CURRENT == 3 )); then
          _values 'tool' nodejs golang
        elif (( CURRENT == 4 )); then
          _message "version (e.g., latest or 1.22.5)"
        fi
      ;;
      doctor)
        _values 'flags' --dry-run
      ;;
    esac
  ;;
esac
