#!/usr/bin/env /usr/local/bin/bash
# shellcheck shell=bash disable=SC2148

# debugging func
to_debug() { [[ "${BT_DEBUG}" = *$1* ]] && >&2 "${@:2}" ;}

# Uncomment for debugging output across all libs.
# Define specific tags in BT_DEBUG for less noise.
#export BT_DEBUG="stng flow lgin util data rds rdsc cche qv dg prmt"

# important global vars.
export BT="${HOME}/.bt" BT_SETTINGS=quiet

to_debug flow echo BT: "${BT}"
to_debug flow sleep 0.5 && echo "utils:to_debug"
to_debug flow echo "utils:ansi_color"

rds() { 
 :   
}

ssm() { 
 :  
} 

bt_activate() {
  PKG=${1}
  [[ "${PKG}" =~ b2 ]] || PKG_NAME="b2${PKG}" 
  echo PKG_NAME: ${PKG_NAME}
  PTR="$(find ${HOME}/.local/pipx -name "${PKG_NAME}.pth")" 
  SANITY="$(cat ${PTR} | wc -l)"
  [[ "${SANITY}" -ne 1 ]] && { 
      echo "FATAL: ${SANITY} pkgs matched."
      return 1
  } 
  PKG_PATH="$(cat ${PTR} | head -n 1)"
  echo -e "${GREEN}activating${NC} bt venv."
  venv="${PKG_PATH}/.venv/bin/activate"
  source ${venv} 
  echo "PKG_PATH: ${PKG_PATH}"
  alias ssm="poe --root \"${PKG_PATH}\" ssm "
  #TOOLS=( ssm rds )

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

}


bt_loader() { 
  [[ ! "${LOADER_ACTIVE}" = true ]] && {
  
    to_debug flow && sleep 0.5 && echo "stgs:loader"
  
    # script loader (runs exactly once)
    . "${BT}/lib/_loader.bash" #>/dev/null 2>&1
  
    to_debug flow && sleep 0.5 && echo "stgs:addpath"
    loader_addpath "${BT}/lib"
    loader_addpath "${BT}/src"
  
    to_debug flow && sleep 0.5 && echo "stgs:includex"
    includex -name '[^_]*.bash' >/dev/null 2>&1
  
    {
      funcs="$(declare -F | wc -l)"
      echo -en "${GREEN}Success${NC} - "
      echo -e  "Loaded ${CYAN}$(declare -F | wc -l)${NC} functions."
      if ! $(declare -F | grep bt_activate >/dev/null 2>&1); then
        echo -e "Loader ${RED}failed${NC}." && exit.
      fi
    }
  }
}






## ANSI COLOR 
## -----------------------------------------------------------------
## We use colors in multiple places to improve the user experience. 
##  
##      .-------------- # constant part.
##      vvvvv  vvvv --- # ansi code.
##
## shellcheck disable=code disable=SC2034
{
  GRAY='\033[0;37m'     #
  BLUE='\033[0;34m'     #
  CYAN='\033[0;96m'     #
PURPLE='\033[1;35m'     #
YELLOW='\033[0;33m'     #
 GREEN='\033[0;32m'     #
   RED='\033[0;31m'     #
    NC='\033[0;m'       # No Color
}

## -----------------------------------------------------------------
## Utility functions (various, useful across all libs.)
## -----------------------------------------------------------------

to_debug flow && echo "utils:q_pushd"
q_pushd () { command pushd "$@" > /dev/null 2>&1 || return ;}

to_debug flow && echo "utils:q_popd"
q_popd () { command popd "$@" > /dev/null 2>&1 || return;}

to_debug flow && echo "utils:die"
die() { NUM="${1:-2}"; echo "$*" >&2; return "$NUM"; "exit $NUM"; }

get_account() {
  this_peek | jq -r '.account | to_entries[] | select(.key|tostring) | "\(.key)"'
}

get_usr() { 
  echo "${USER}"
}

get_team() { 
  set_team && echo "${BT_TEAM}"  
}

# -----------------------------------------------------------------
# PATH SETTINGS
# -----------------------------------------------------------------

# Warn to stderr, but continue.
to_debug flow && echo "utils:warn"
warn() { >&2 echo "${@}"; }

# send to stderr.
to_debug flow && echo "utils:to_err"
to_err() { >&2 echo "${@}"; }

# send to bintools log.
to_debug flow && echo "utils:to_log"
to_log() { 
  echo -e "${@}" | \
  xargs -L 1 echo "$(date +"[%Y-%m-%d %H:%M:%S]")" | \
  tee -a "${bt_log:-"${BT}"/log/bt_log}"; 
}


# return 'true' of running on mac.  
# useful for handling  mac-isms. 
#on_mac() { $( os=$(uname -s) && [ "${os}" == "Darwin" ] && return True) }
#to_debug flow && echo "utils:on_mac"

# complain about missing a specific arg.
to_debug flow && echo "utils:needs_arg"
needs_arg() { [ -z "$OPTARG" ] && warn "No arg for --$OPT option" && usage ;}


to_debug flow && echo "utils:usage"
usage() { echo "Usage: <more instructions here...>"; } 


to_debug flow && echo "utils:stash"
stash() { 

  this="${1:-"${AWS_SHARED_CREDENTIALS_FILE}"}"
  base="$(basename "$this")"
  dt="$(gdate +%s)"

  [ -z "${BT_STASH}" ] && { 
    echo "No BT_STASH dir present."
    return 1
  } 
  cp "${this}" "${BT_STASH}/${base}.${dt}" 
}


to_debug flow && echo "utils:expired"
# Are the current credentials expired? 
# Returns True if expired, a unix era time if still valid.
expired() { 
  aws sts get-caller-identity > /dev/null to_err
  [ $? -eq 254 ] && echo "expired" 
  date
} 


# ---------------------------------------
# when passing SQL to the command-line,
# encode it first. Helps with processing.
# ---------------------------------------
#
to_debug flow && echo "utils:decode_sql"

decode_sql() {
  local SQLenc="${1}"
  [[ -z "${SQLenc}" ]] && read -r SQLenc
  [[ "${SQLenc}" = QV_SQL_ENC* ]] && { 
  echo "${SQLenc}"              | \
  perl -pe "s/QV_SQL_ENC//"    | \
  gbase64 -d                    | \
  zcat 
  }
}

to_debug flow && echo "utils:encode_sql"

encode_sql() {
  SQLraw="${1}"
  [[ -z "${SQLraw}" ]] && read -r SQLraw
  echo -ne "QV_SQL_ENC" && \
  echo "${SQLraw}" | gzip | gbase64 
}

to_debug flow && echo "utils:arg_split"

# return the index number of a particular string
# in an array.
# debug echo args: ${args[@]}
arg_split() {
  local args=( "${@:1}" )
  local n=${args[0]}
  for n in $(seq ${#args[@]}); do
    [[ "${args[$n]}" == "--" ]] && echo "$n"
  done
}

to_debug flow && echo "utils:find_in_rds"

find_in_rds() {
  this=${1}
  declare -A rds_map 
  source "${BT}"/src/rds_map.src
  for l in $(printf '%s\n' "${rds_map[@]}"); do 
    echo "$l" | perl -nle "print \"$l\" if /${this}/" 
  done
}

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

  # target info
  # -----------
  # get the proper record from the 
  # larger array of all clusters.
  [[ -n "${BT_CLUSTER}" ]] && { 
    export BT_CLUSTER="${BT_CLUSTER}"
    export BT_CLUSTER_ARRAY="$(get_forwarder "${BT_CLUSTER}")"
  } 
 
  # parse record
  declare -A fwdr
  source <(echo "${BT_CLUSTER_ARRAY}")
  to_debug rdst && echo ${CYAN}T${NC}: echo fwdr: "${fwdr[@]@A}" >&3

  # export relevant info for this target.
  export bt_hostname="${fwdr[hostname]}" \
         bt_instance="${fwdr[instance]}" \
         bt_trunk="${fwdr[trunk]}"       \
         bt_port="${fwdr[port]}"         \
         bt_endpoint="${fwdr[endpoint]}" \
         bt_cluster="${fwdr[cluster]}"


  to_debug rdst && echo "${CYAN}T${NC}: \
  bt_hostname|${bt_hostname}\n          \
  bt_instance|${bt_instance}\n          \
  bt_trunk|${bt_trunk}\n                \
  bt_port|${bt_port}\n                  \
  bt_endpoint|${bt_endpoint}\n          \
  bt_cluster|${bt_cluster}\n"         >&3

}

instance_info() { 

    :   # ssm target

} 


to_debug flow && sleep 0.5 && echo "utils:end"

