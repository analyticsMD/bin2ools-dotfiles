#!/usr/bin/env /usr/local/bin/bash
# shellcheck shell=bash disable=SC2148

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
YELLOW='\033[0;33m'     #
 GREEN='\033[0;32m'     #
   RED='\033[0;31m'     #
    NC='\033[0;m'       # No Color
}
## -----------------------------------------------------------------
## Utility functions (various, useful across all libs.)
## -----------------------------------------------------------------

q_pushd () { command pushd "$@" > /dev/null || return ;}

q_popd () { command popd "$@" > /dev/null || return;}

die() { NUM="${1:-2}"; echo "$*" >&2; return "$NUM"; "exit $NUM"; }

# Warn to stderr, but continue.
warn() { >&2 echo "${@}"; }

# send to stderr.
to_err() { >&2 echo "${@}"; }

# send to bintools log.
bt_log() { 
  echo -e "${@}" | \
  xargs -L 1 echo "$(date +"[%Y-%m-%d %H:%M:%S]")" | \
  tee -a "${bt_log:-"${BT}"/log/bt_log}"; 
}


# return 'true' of running on mac.  
# useful for handling  mac-isms. 
#on_mac() { $( os=$(uname -s) && [ "${os}" == "Darwin" ] && return True) }

# complain about missing a specific arg.
needs_arg() { [ -z "$OPTARG" ] && warn "No arg for --$OPT option" && usage ;}

usage() { echo "Usage: <more instructions here...>"; } 

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

encode_sql() {
  SQLraw="${1}"
  [[ -z "${SQLraw}" ]] && read -r SQLraw
  echo -ne "QV_SQL_ENC" && \
  echo "${SQLraw}" | gzip | gbase64 
}

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

find_in_rds() {
  this=${1}
  declare -A rds_map 
  source "${BT}"/sources/generate.d/rds_map.src
  for l in $(printf '%s\n' "${rds_map[@]}"); do 
    echo "$l" | perl -nle "print \"$l\" if /${this}/" 
  done
}

