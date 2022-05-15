
bt_activate() { 

    venv_path="${HOME}/.local/pipx/venvs/${core}/bin/activate" >/dev/null 2>&1
    echo -e  "${GREEN}activating${NC} BT space..."
    source ${venv_path}
    echo -ne "${GREEN} done${NC}."
}

# TODOs:
#  verify source path
#  #[[ -z "${PATH}" ]] 
#  #SRC_PATH="$(head -n 1 ${PTR})"
#  echo SRC_PATH: ${SRC_PATH}

# 
#  # TODO:  match only 1 package per tool.
#  SANITY="$(cat "${PTH}" | wc -l)"
#  [[ "${SANITY}" -ne 1 ]] && { 
#      echo "FATAL: ${SANITY} pkgs matched."
#      return 1
#  } 

function join_by { local IFS="$1"; shift; echo "$*"; }

function bt_() { 
    export BT="${HOME}/.bt" 
    source ${BT}/settings
    bt_local &
    autologin
    echo -e "${GREEN}bt${NC} is ready! "
} | true 

# function generator
# -------------------
# Each toolshed (i.e. b2 package) should have three functions: 
# <tool>_complete
# <tool>_generate
# <tool>_local
# finally, tool_local should be aliased to '<tool>'. 
#
#
generate_bridge_functions() { 

  BT="${HOME}/.bt"

  pkg_path=${2}
  toolshed=${1}
  tool="$(echo "${toolshed}" | perl -pe 's/^b2//')"

  [[ -z "${toolshed}" || -z "${pkg_path}" ]] && { 
    echo -e "${RED}FATAL${NC}: Failed to write bridge function."
    return
  }

  echo -e "# declare bridge functions: ${tool}"
  declare -a toolset=( "${tool}_local" "${tool}_complete"  "${tool}_generate" )
  #echo ${f=##*/} 
 
  { 
    echo -ne "\nbt_${tool}_complete() { \n"
    echo -ne "    source ${pkg_path}/${toolshed}/${tool}_complete\n"
    echo -ne "} \n\n"    
    
    echo -ne "\nbt_${tool}_generate() { \n"
    echo -ne "    ${pkg_path}/${toolshed}/${tool}_generate\n"
    echo -ne "} \n\n"    
   
    echo -ne "\nbt_${tool}_local() { \n"
    echo -ne "    ${pkg_path}/${toolshed}/${tool}_local \$\{1\}\n"
    echo -ne "} \n\n"   

    echo alias "${tool}=\"bt_${tool}_local \""
    echo alias "${tool}_complete=\"bt_${tool}_complete \""
    echo alias "${tool}_generate=\"bt_${tool}_generate \""

    echo alias "${tool}=\"${tool}_local\""
 
    echo "bt_${tool}_complete" 
  } > ${BT}/lib/bridge_"${tool}".bash 

  echo -e "loaded ${CYAN}${funcs}${NC} functions for bin2ools: ${tools[@]}"  
  PROMPT_COMMAND='(bt);'$PROMPT_COMMAND

} || true




# toggle bt venv on or off. 
#
function bt_toggle() {
  ret="$?"
  if [[ -v BT_MANUAL ]]; then
    return $ret
  fi
  if find_in_devops pyproject.toml &> /dev/null; then
    if [[ ! -v VIRTUAL_ENV ]]; then
      if BASE="$(poetry env info --path)"; then
        # alter prompt
        PROMPT_COMMAND='\(\b\t\)';"$PROMPT_COMMAND"
        PS1=""
      else
        BT_MANUAL=1
      fi
    fi
  elif [[ -v VIRTUAL_ENV ]]; then
    deactivate
  fi
  return $ret
} || true

#activate() {
#
#  export BT="${HOME}/.bt"
#  if [[ -v VIRTUAL_ENV ]]; then
#    deactivate
#  else
#    . "$(poetry env info --path)/bin/activate"
#  fi
#}


#PKG="${1}" # pass in package name (devops-sso-util).

# locate devops-sso-util dir.
# in: nothing (default)
bt_local() { 
  #export BT_DEBUG="bt_"

  # find the installed core pkg in our homedir.
  core="${1:-"devops-sso-util"}"
  to_debug bt_ && echo core package: ${core}
  srch_path="${HOME}/.local/pipx/venvs/${core}/lib"

  # find all injected packages and add to path.
  declare -a b2=()
  for p in $(ls -1 "${srch_path}"); do
    to_debug bt_ && echo pth_path: "find ${srch_path}/${p}/site-packages -name '*pth'"
    ls_core_pth="ls -1 ${srch_path}/${p}/site-packages/*pth"
    to_debug bt_ && echo "ls_core_pth: $ls_core_pth"

    for pth in "$( ${ls_core_pth} )"; do
      to_debug bt_ && echo "pth: $pth"
      target="$(cat "${pth}")"
      to_debug bt_ && echo "target: $target"
      
      ls_pkg_dirs="ls -1d ${srch_path}/${p}/site-packages/b2*"
      to_debug bt_ && echo "cmd: $ls_pkg_dirs"
      declare -a tools=()
      for pkg_dir in $( ${ls_pkg_dirs} ); do
        to_debug bt_ && echo pkg_dir: $pkg_dir
        tool="$(echo "${pkg_dir}" | perl -pe 's/.*\.dist-info//g;')"
      done
      to_debug bt_ && echo got "${#b2[@]}" elements.
      to_debug bt_ && echo Adding ${GREEN}${#b2[@]}${NC} tools to path. 
    done
  done
  # update path
  source <(echo "$("${BT}"/utils/path -s 2>/dev/null)" )
  to_debug bt_ && echo PATH: "$(join_by : ${b2[@]} ${PATH})"
  #echo export PATH="$(join_by : ${b2[@]} ${PATH})"
  echo "export PATH=$(join_by : ${b2[@]} ${PATH})" > "${BT}/cache/path_info"
  source "${BT}/cache/path_info"
 
  [[ ! "${PATH}" =~ "${core}" ]] && { 
    echo -e "${RED}"FATAL"${NC}": Path not updated.
    exit 1
  }

  # get short names for root paths.
  pkg_path=""
  declare -a toolsheds=()
  for pkg in ${b2[@]}; do 
      pkg_path="$(dirname ${pkg})"
      toolshed="$(basename ${pkg})"
      #debug_to bt_ && echo pkg_path: "${pkg_path}"
      #debug_to bt_ && echo toolshed: "${toolshed}"
      toolsheds+=( ${toolshed} )
  done

  i=0
  for toolshed in ${toolsheds[@]}; do
    tool="$(echo "${toolshed}" | perl -pe 's/^b2//')"
    ls_cmd="ls -1 ${pkg_path}/${toolshed}/${tool}[\.\_]*"
    to_debug bt_ && echo ls_cmd: ${ls_cmd}
    declare -a toolset 
    for tool_path in $(${ls_cmd}); do
      tool="$(basename ${tool_path})"
      to_debug bt_ && echo path: ${pkg_path}
      to_debug bt_ && echo toolshed: "${toolshed}"
      to_debug bt_ && echo tool: "${tool}"
    done
  done

    for tool in ${tools[@]}; do  
      generate_bridge_functions "${toolshed}" "${pkg_path}" || return
    done
    # TODO: check that path is present for each.
    funcs="$(declare -F                                                  | \
      perl -lne "print if 'm/.*bt_([\w\-]+)_(complete|local|generate)/'" | \
      wc -l)"
    return  
  
} || true


#loadx() { 
    
    # The new multi-threaded loader. 
    # FEATURES: 
    #  * Fast (multithreaded)
    #  * Loads based on globbing, or regex.
    #  * comes with execution threads (callx, loadx)
    loader_addpath -name "${BT}/@(lib|src|utils|gen)"
    loader_flag "aws"

    . "${BT}/lib/bt.bash" >/dev/null 2>&1
    . "${BT}/lib/utils.bash" >/dev/null 2>&1
    . "${BT}/lib/env.bash" >/dev/null 2>&1
    . "${BT}/lib/api.bash" >/dev/null 2>&1
    . "${BT}/lib/rdslib.bash" >/dev/null 2>&1
    . "${BT}/lib/bt_sourcer.bash" >/dev/null 2>&1

} 

legacy() { 

    # Static libs.  No globbing.  Anything else was too brittle. 
      
    . "${BT}/lib/bt.bash" >/dev/null 2>&1
    . "${BT}/lib/utils.bash" >/dev/null 2>&1
    . "${BT}/lib/env.bash" >/dev/null 2>&1
    . "${BT}/lib/api.bash" >/dev/null 2>&1
    . "${BT}/lib/bridge.bash" >/dev/null 2>&1
    . "${BT}/lib/rdslib.bash" >/dev/null 2>&1
    . "${BT}/lib/bt_sourcer.bash" >/dev/null 2>&1
 
}

bt_load() { 

    [[ "${LOADER}" == "legacy" ]] && { legacy ;} || { loadx ;} 

    {
      funcs="$(declare -F | wc -l)"
      echo -en "${GREEN}success${NC} - "

      if ! $(declare -F | grep bt_src >/dev/null 2>&1); then
        echo -e "Loaded ${CYAN}$(declare -F | wc -l)${NC} functions."
        return  
      fi

} || true


# sanity check.  Generates bash code. 
cat  <<-'HERE_BE_DOCS' 

  [[ "${#BT_PATHS[@]}" -lt 1 ]] && { 
      echo -e "${RED}FATAL${NC}: pipx paths not present."
      return 1
  } 

HERE_BE_DOCS

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
} || true



