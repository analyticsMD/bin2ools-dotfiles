# shellcheck shell=bash disable=SC2148

# debugging func
to_debug() { [[ "${BT_DEBUG}" = *$1* ]] && >&2 "${@:2}" ;} || true
to_debug flow sleep 0.5 && echo "bt:to_debug" || true

#bt_settings() { [[ "${BT_SETTINGS}" = *$1* ]] && >&2 "${@:2}" ;} || true

#export BT="${HOME}/.bt"
#. ${BT}/settings

# Creates bridge functions such that components
# installed as python packages work interchangeably
# with dotfiles components, and with Geodesic on Linux.
# 
make_funcs() { 

    #export BT_DEBUG="bt_"
    
    # -----------------------------------------------------
    # make sure we have the pipx paths installed.
    # -----------------------------------------------------
    source <(${HOME}/.bt/utils/path -s 2>/dev/null)
    #echo PATH: ${PATH}
    export T="$(echo ${PATH}                            | \
                tr ':' '\n'                             | \
                perl -lne 'print if s/(.*\/b2).*/\1/g;' | \
                head -n 1)"
    to_debug bt_ && echo ${PATH}| tr ':' '\n' | \
        perl -lne 'print if s/(.*\/b2).*/\1/g;'


    # -----------------------------------------------------
    # scan pipx for installed toolsets.
    # -----------------------------------------------------
    declare -a tools=( complete generate local )
    declare -a toolsets=()
    shopt -s extglob
    for t in $(ls -1d ${T}!(*-*) ); do 
        to_debug bt_ && echo found toolset: ${t}
        toolsets+=( "${t#*${T}}" )
    done
    echo "toolsets: ${toolsets[@]}"
    shopt -u extglob


    # -----------------------------------------------------
    # export toolset "bridge" functions 
    # -----------------------------------------------------
    umask 0077
    tmpf=$(mktemp) && echo "" > ${tmpf}
    for ts in ${toolsets[@]}; do
        for t in ${tools[@]}; do
            f="${ts}_${t}"
            [[ "$f" =~ "complete" ]] && s="source " || s=""
            echo -ne "${f}"'() {'"\n" "${s}${T}${ts}/${f}\n" '};'"\n\n" >> ${tmpf}
            echo -ne "export -f ${f}\n\n" >> ${tmpf}
        done
    done 
    source <( cat ${tmpf} ) 
    #declare -F | grep fx
    
    rm -f ${tmpf}
    umask 0022


    # -----------------------------------------------------
    # create toolset 'aliases'
    # -----------------------------------------------------

    for ts in "${toolsets[@]}"; do
        bash -c "${ts} () { "${ts}_local" ;};" 
    done
    
    echo running completions.
    for ts in ${toolsets[@]}; do "${ts}_complete"; done
} || true


#make_funcs


sts() { 
    aws sts get-caller-identity                | \
    jq .Arn                                    | \
    perl -pe 's/.*:://; s/qv-gbl//; s/\/boto.*//;'
} || true



function prompt_off() { unset PROMPT_COMMAND ;} || true
function prompt_on() { export PROMPT_COMMAND="prompt" ;} || true

function prompt() {
    # generate the next cache peek,
    # and hence, the next prompt.

    PS1="$(_prompt)" 
    export PS1
} || true

function _prompt() { 
    LOGO="$(printf '%b' "\(${GREEN}BT${NC}\)")"
    echo="${LOGO}"
} || true 


# Takes a packaged virtual env, devops-sso-util, 
# by default, and finds all the tools installed 
# as sub-projects. It then looks for a standard
# set of entrypoints, and creates the necessary 
# functions and aliases to complete the 'bt' 
# activation process. 
# 
get_tool_list() { 
    env=${1:-"devops-sso-util"}
} || true


# -----------------------------------------------------------------
# PATH SETTINGS
# -----------------------------------------------------------------

to_debug flow && echo "utils:script_info" || true

# Get info about the running script. 
script_info() {
  SRC=${1:-"${BASH_SOURCE[0]}"}
  THIS_SCRIPT="$(greadlink -f "${SRC}")"
  BT_LAUNCH_DIR="$(dirname "${THIS_SCRIPT}")"
  BT_PKG_DIR="$(dirname "${BT_LAUNCH_DIR}")"
  export BT_LAUNCH_DIR="${BT_LAUNCH_DIR}" BT_PKG_DIR="${BT_PKG_DIR}"
}  || true

cluster_info() { 

  BT_CLUSTER="${1:-"${BT_CLUSTER}"}"
  [[ -z "${BT_CLUSTER}" ]] && { 
    echo "FATAL: No BT_CLUSTER set." && exit
  }

}  || true

instance_info() { 
    :   # ssm target
} || true


to_debug flow && sleep 0.5 && echo "utils:end" || true

# ----------------
# helper functions. 
# -----------------

join_by() { local IFS="$1"; shift; echo "$*" ;} || true
