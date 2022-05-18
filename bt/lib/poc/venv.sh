
# toggle bt venv on or off. 
#
#function bt_venv() {
#  ret="$?"
#  if [[ -v BT_MANUAL ]]; then
#    return $ret
#  fi
#  if find_in_devops pyproject.toml &> /dev/null; then
#    if [[ ! -v VIRTUAL_ENV ]]; then
#      if BASE="$(poetry env info --path)"; then
#	    . "$BASE/bin/activate"
#        PS1=""
#      else
#        BT_MANUAL=1
#      fi
#    fi
#  elif [[ -v VIRTUAL_ENV ]]; then
#    deactivate
#  fi
#  return $ret
#} || true



#bt() { 
#  BT_MANUAL=1
#  if [[ -v VIRTUAL_ENV ]]; then
#    deactivate
#  else
#    . "$(poetry env info --path)/bin/activate"
#  fi
#  PROMPT_COMMAND="(bt);$PROMPT_COMMAND"
#} 

#activate() {
#
#  export BT="${HOME}/.bt"
#  if [[ -v VIRTUAL_ENV ]]; then
#    deactivate
#  else
#    . "$(poetry env info --path)/bin/activate"
#  fi
#}

