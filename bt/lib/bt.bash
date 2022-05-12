#!/usr/bin/env /usr/local/bin/bash
# shellcheck shell=bash disable=SC2148


# debugging func
to_debug() { [[ "${BT_DEBUG}" = *$1* ]] && >&2 "${@:2}" ;}
to_debug flow sleep 0.5 && echo "bt:to_debug"

bt_settings() { [[ "${BT_SETTINGS}" = *$1* ]] && >&2 "${@:2}" ;}

stat() { 
    aws sts get-caller-identity                | \
    jq .Arn                                    | \
    perl -pe 's/.*:://; s/qv-gbl//; s/\/boto.*//;'
}

export BT="${HOME}/.bt"
to_debug flow echo BT: "${BT}"


bt_load() { 

  [[ -z ${LOADER_ACTIVE} ]] && { 
    export LOADER_ACTIVE=false 
  }
  echo LDR: "|${LOADER_ACTIVE}|"    
  if ! ${LOADER_ACTIVE}; then 

    to_debug flow && sleep 0.5 && echo "stgs:loader"
  
    # script loader (runs exactly once)
    . "${BT}/lib/bt_loader.bash" #>/dev/null 2>&1
  
    to_debug flow && sleep 0.5 && echo "stgs:addpath"
    loader_addpath "${BT}/lib"
  
    to_debug flow && sleep 0.5 && echo "stgs:includex"
    shopt -s extglob
    includex 'bt.bash' >/dev/null 2>&1
    includex 'utils.bash' >/dev/null 2>&1
    includex 'env.bash' >/dev/null 2>&1
    includex 'rdslib.bash' >/dev/null 2>&1
    includex 'data.bash' >/dev/null 2>&1
    includex 'api.bash' >/dev/null 2>&1
    includex -name 'bridge_*.bash' >/dev/null 2>&1
  
    {
      funcs="$(declare -F | wc -l)"
      echo -en "${GREEN}Success${NC} - "
      echo -e  "Loaded ${CYAN}$(declare -F | wc -l)${NC} functions."
      if ! $(declare -F | grep bt_activate >/dev/null 2>&1); then
        echo -e "Loader ${RED}failed${NC}." && return 1
      fi
    }

 fi
}

function join_by { local IFS="$1"; shift; echo "$*"; }

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
        PROMPT_COMMAND="(${GREEN}bt${NC});$PROMPT_COMMAND"
        PS1=""
      else
        BT_MANUAL=1
      fi
    fi
  elif [[ -v VIRTUAL_ENV ]]; then
    deactivate
  fi
  return $ret
}

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


#PKG="${1}" # pass in package name (devops-sso-util).

# locate devops-sso-util dir.
# in: nothing (default)
# out: assumes venv 
bt_local() { 
  export BT_DEBUG="bt"

  # find the installed core pkg in our homedir.
  core="${1:-"devops-sso-util"}"
  to_debug bt && echo core package: ${core}
  srch_path="${HOME}/.local/pipx/venvs/${core}/lib"

  # find all injected packages and add to path.
  declare -a b2=()
  for p in $(ls -1 "${srch_path}"); do
    to_debug bt && echo pth_path: "find ${srch_path}/${p}/site-packages -name '*pth'"
    ls_core_pth="ls -1 ${srch_path}/${p}/site-packages/*pth"
    to_debug bt && echo "ls_core_pth: $ls_core_pth"

    for pth in "$( ${ls_core_pth} )"; do
      to_debug bt && echo "pth: $pth"
      target="$(cat "${pth}")"
      to_debug "" && echo "target: $target"
      
      ls_pkg_dirs="ls -1d ${srch_path}/${p}/site-packages/b2*"
      to_debug bt && echo "cmd: $ls_pkg_dirs"
      declare -a tools=()
      for pkg_dir in $( ${ls_pkg_dirs} ); do
        to_debug bt && echo pkg_dir: $pkg_dir
        tool="$(echo "${pkg_dir}" | perl -pe 's/.*\.dist-info//g;')"
        to_debug bt && echo pkg: $pkg
        b2+=( $tool )
      done
      echo got "${#b2[@]}" elements.
      to_debug bt && echo Adding ${GREEN}${#b2[@]}${NC} tools to path. 
    done
  done
  # update path
  source <( echo $(path -s) 2>/dev/null )
  to_debug bt && echo PATH: "$(join_by : ${b2[@]} ${PATH})"
  export PATH="$(join_by : ${b2[@]} ${PATH})"
   
  # get short names for root paths.
  pkg_path=""
  declare -a toolsheds=()
  for pkg in ${b2[@]}; do 
      pkg_path="$(dirname ${pkg})"
      toolshed="$(basename ${pkg})"
      echo toolshed: "${toolshed}"
      echo pkg_path: "${pkg_path}"
      #to_debug bt && echo toolshed: "${toolshed}"
      toolsheds+=( ${toolshed} )
  done
  #to_debug bt && echo "${toolshed[@]}"
  echo all_toolsheds: "${toolsheds[@]}"
  i=0
  for toolshed in ${toolsheds[@]}; do
    tool="$(echo "${toolshed}" | perl -pe 's/^b2//')"
    ls_cmd="ls -1 ${pkg_path}/${toolshed}/${tool}[\.\_]*"
    to_debug bt && echo ls_cmd: ${ls_cmd}
    declare -a toolset 
    for tool_path in $(${ls_cmd}); do
      tool="$(basename ${tool_path})"
      to_debug bt && echo path: ${pkg_path}
      to_debug bt && echo toolshed: "${toolshed}"
      to_debug bt && echo tool: "${tool}"
    done
  
    generate_bridge_functions "${tool}" "${pkg_path}" 

    . ${BT}/settings
    # TODO: check that path is present for each.
    funcs="$(declare -F                                                  | \
      perl -lne "print if 'm/.*bt_([\w\-]+)_(complete|local|generate)/'" | \
      wc -l)"
    echo -e "loaded ${CYAN}${funcs}${NC} functions for tools: ${tools[@]}"  
  done
  
}

function bt() { 
    export BT="${HOME}/.bt" 
    bt_load 
    echo -e ${GREEN}bt${NC} is ready! 
} 

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
    exit
  }

  echo "# declare bridge functions: ${tool}"
  declare -a toolset=( "${tool}_local" "${tool}_complete"  "${tool}_generate" )
  #echo ${f=##*/} 
 
  { 
    echo -ne "\nbt_${tool}_complete\(\) \{ \n"
    echo -ne "    source ${pkg_path}/${toolshed}/${tool}_complete\n"
    echo -ne "\} \n\n"    
    
    echo -ne "\nbt_${tool}_generate\(\) \{ \n"
    echo -ne "    ${pkg_path}/${toolshed}/${tool}_generate\n"
    echo -ne "\} \n\n"    
   
    echo -ne "\nbt_${tool}_local\(\) \{ \n"
    echo -ne "    ${pkg_path}/${toolshed}/${tool}_local \$\{1\}\n"
    echo -ne "\} \n\n"   

    echo alias "${tool}=\"bt_${tool}_local \""
    echo alias "${tool}_complete=\"bt_${tool}_complete \""
    echo alias "${tool}_generate=\"bt_${tool}_generate \""
  } > ${BT}/lib/bridge_"${tool}".bash

  echo -e  "${GREEN}activating${NC} BT space..."
  echo -ne "${GREEN} done${NC}."
  venv_path="${HOME}/.local/pipx/venvs/${core}/bin/activate" >/dev/null 2>&1
  . ${venv_path}
  PROMPT_COMMAND="(${GREEN}bt${NC});$PROMPT_COMMAND"
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

# Takes a packaged virtual env, devops-sso-util, 
# by default, and finds all the tools installed 
# as sub-projects. It then looks for a standard
# set of entrypoints, and creates the necessary 
# functions and aliases to complete the 'bt' 
# activation process. 
# 
get_tool_list() { 
    env=${1:-"devops-sso-util"}
}


generate_tool_aliases() { 
  
  # Use poe to list the tools. Alias each tool.
  declare -a tools=()
  alias ${tool}="poe --root \"${PKG_PATH}\" "
  #TOOLS=( ssm rds )

  ./pipx/venvs/devops-sso-util/lib/python3.10/site-packages/b2rds-0.6.8.dist-info
}

  #for TOOL in ${TOOLS[*]}; do
  #  echo completes...
#  CMPL=( alias "${TOOL}_cmpl=\"source ${PKG_PATH}/${PKG_NAME}/${TOOL}.cmpl\"" )
#  echo CMPL: "${CMPL[*]}"
#  cmpl="${CMPL[*]}"
#  ${TOOL}_cmpl
#
#  echo tools...
#  THIS_TOOL=( alias "${TOOL}=\"${PKG_PATH}/${PKG_NAME}/${TOOL}\"" )
#  echo TOOL: "${THIS_TOOL[*]}"
#  ${THIS_TOOL[*]}
#done



bt_activate() { 
  : 
} 


# -----------------------------------------------------------------
# PATH SETTINGS
# -----------------------------------------------------------------

to_debug flow && echo "utils:script_info"

# Get info about the running script. 
script_info() {
  SRC=${1:-"${BASH_SOURCE[0]}"}
  THIS_SCRIPT="$(greadlink -f "${SRC}")"
  BT_LAUNCH_DIR="$(dirname "${THIS_SCRIPT}")"
  BT_PKG_DIR="$(dirname "${BT_LAUNCH_DIR}")"
  export BT_LAUNCH_DIR="${BT_LAUNCH_DIR}" BT_PKG_DIR="${BT_PKG_DIR}"
} 

cluster_info() { 

  BT_CLUSTER="${1:-"${BT_CLUSTER}"}"
  [[ -z "${BT_CLUSTER}" ]] && { 
    echo "FATAL: No BT_CLUSTER set." && exit
  }

} 

instance_info() { 
    :   # ssm target
} 

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

function join { local IFS="$1"; shift; echo "$*"; }

to_debug flow && sleep 0.5 && echo "utils:end"

