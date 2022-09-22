#!/usr/bin/env /usr/local/bin/bash

# shellcheck shell=bash
# global settings
# today, this is still prod, but will change very soon.
#
export DEFAULT_ACCOUNT="prod"   
export HOMEBREW_PYTHON="3.10"
#export DEFAULT_ROLE="${DEFAULT_ACCOUNT}"-"${BT_TEAM}"

# set PYTHON env vars. 
# (Helps avoid confusion on hosts with many pythons).
get_python_exec() { 
    THIS_CELLAR=$(brew config 2> /dev/null | \
             perl -nle 'print if s/^HOMEBREW_CELLAR: //')
    [[ -z "${THIS_CELLAR}" || ! -d "${THIS_CELLAR}" ]] && { 
        echo "FATAL: Local Homebrew Cellar not found."
        echo "       Is Homebrew installed properly?"
        exit 1
    } 
    # NOTE: BT always uses the latest patch release of 3.10. 
     
    THIS_PYTHON="$(ls ${THIS_CELLAR}/python@${HOMEBREW_PYTHON} | sort -rV | head -n 1)"
    #echo THIS_PYTHON: "${THIS_PYTHON}"
    [[ -z "${THIS_PYTHON}" || -e "${THIS_PYTHON}" ]] && { 
        echo "FATAL: A Homebrew installed version of Python@${HOMEBREW_PYTHON}3.10" 
        echo "       was not found on this system.  This is a " 
        echo "       requirement of the bintools platform." 
        exit 1
    }
    
    THIS_EXEC="$(ls ${THIS_CELLAR}/Python@${HOMEBREW_PYTHON}/${THIS_PYTHON}/bin/python3)" 
    #echo THIS_EXEC: $THIS_EXEC
    [[ -z "${THIS_EXEC}" || -e "${THIS_EXEC}" ]] && { 
        echo "FATAL: A Homebrew installed version of Python@3.10" 
        echo "       was not found on this system.  This is a " 
        echo "       requirement of the bintools platform." 
        exit 1
    } 
    
    echo "${THIS_EXEC}"
} 

b2() { export BT="${HOME}/.bt" ;} || true

# global debug function.
to_debug()    { [[ "${BT_DEBUG}"    = *$1* ]] && >&2 "${@:2}" ;} || true
to_debug flow && sleep 0.5 && echo rds:start || true

get_src_dir() {

    . <(${HOME}/.bt/utils/path -s 2>/dev/null)  # find a better path.

    SRC="$(dirname "$(echo "${PATH}"        | \
           perl -pe 's/:/\n/g'              | \
           grep -E 'devops|aws)-sso-util\/' | \
           grep '\/b2'                      | \
           perl -pe 's/^\/Users\/[\w_\-+]+(.*)/\$\{HOME\}\1/' | \
           head -n 1 )"                       \
    )"
    export SRC=\"${SRC}\"\n\n
    echo -ne "export SRC=\"${SRC}\"\n\n"

  declare -fx get_src_dir
  export SRC="$(echo get_src_dir)"
}



# RDS usage message
rds_usage () {
    echo " usage "
    echo " -----"
    echo " <cluster>         - rds cluster to connect with."
    echo " --user <user> - NOTE: This is NOT your user name. This is a "
    echo "                     team or guild user of the form \"dba-guild\"",
    echo "                     or \"team-devops\"."
    echo " -h                - print this message."

    echo -ne "\n\n\n"
    echo -ne "================================================================\n"
    echo -ne "All mysql client args can also be added, after a '--'. \n"
    echo -ne "Use '--mysql-help' flag for details.\n"
    echo -ne "================================================================\n\n\n"
    mysql_help
    exit 1
} || true

to_debug flow && echo rds:rds_usage || true

mysql_help() { 

  echo "mysql client help here."
} || true

to_debug flow && echo rds:mysql_help || true

# expects a login.
get_forwarder() { 

  [[ -z "${BT_TEAM}" ]] && { 
    echo "FATAL: Problem determining your TEAM." 
    echo "       Please contact DevOps."
    exit 1
  } 

  this="${1:-NONE}"
  # look up cluster info.
  #to_debug rds find_in_rds "${this}"
  stats="$(find_in_rds "${this}")" 

  to_debug rds echo stats: $stats  
  h="$(echo "${stats}"  | cut -d'%' -f 1)"
  in="$(echo "${stats}" | cut -d'%' -f 2)"
  t="$(echo "${stats}"  | cut -d'%' -f 3)"
  p="$(echo "${stats}"  | cut -d'%' -f 4)"
  e="$(echo "${stats}"  | cut -d'%' -f 5)"

  to_debug rds echo -ne "h: ${h}\ni: ${in}\nt: ${t}\np: ${p}\ne: ${e}\n"
  [[ -z "${e}" ]] && { 
    echo "FATAL: Could not get variables for cluster ${this}."
    return 1
  }

  this=${1:-"NONE"}
  declare -A fwdr
  fwdr=(  [hostname]="$h"  [instance]="$in"   ) 
  fwdr+=( [trunk]="$t"         [port]="${p}"  )
  fwdr+=( [endpoint]="${e}" [cluster]="$this" )
  echo "${fwdr[@]@A}"

} || true

to_debug flow && echo rds:get_forwarder

# returns sourceable arrays for rds and mysql params
parse_rds_args() { 

  declare -a args=( "${@}" )  # all passed-in args
  declare -a rds_args=()      # rds args (before the -- )
  declare -a mysql_args=()    # mysql args (after the -- ) 

  bt_cluster="${args[0]}"  # first arg (always the cluster name)
  div="$(arg_split "--" "${args[@]:1}")" # position of divider arg ( -- )
  
  # Split args into before and after the divider.
  # If no divider, no mysql args.
  [[ -n "${div}" ]] && { 
    mysql_args=( "${args[@]:$div+1:${#args[@]}}" )
    rds_args=(   "${args[@]:1:$div-1}"           )
  } || {  
    rds_args=(   "${args[@]:1:${#args[@]}}"      )
  }
 
  echo "$(get_rds_args ${rds_args[@]})" 
  echo "$(get_mysql_args ${mysql_args[@]})" 
} || true

to_debug flow && echo rds:split_rds_args || true


# Returns the common name of the 
# target RDS cluster (writer endpoint). 
get_db_target() { 
  [[ -n "${args[0]}" ]] && { 
    echo "${args[0]}" 
  } || { 
    echo "NONE"
  } 
} || true

to_debug flow && echo rds:get_db_target || true


# shellcheck disable=SC2120
get_rds_args() { 

  declare -a rds_args=( "${@}" )  
  shopt -u nocasematch
  
  i=0
  while (( i <= ${#rds_args[@]} )); do
    #echo i: $i A: "${rds_args[@]:$i:1}"
    case "${rds_args[@]:$i:1}" in
  
      # show usage menu
      -h           | \
      -I | --help  ) help=true; shift ;;
  
      # RBAC account to use
      --user    ) iam_user="${rds_args[*]:$i+1:1}";   shift 2 ;;
      --method  ) method="${rds_args[*]:$i+1:1}"; shift 2 ;; 
          
     *) shift ;;
     
    esac
    ((i++)) 
  done

  [[ -n "${iam_user}" ]] && export BT_iam_user="${iam_user}"
  [[ -n "${method}"   ]] && export BT_method="${method}"
  [[ "$help" == true  ]] && rds_usage && return 1

  echo "${rds_args[@]@A}" 

} || true

to_debug flow && echo rds:get_rds_args || true


# shellcheck disable=SC2120
get_mysql_args() { 

  declare -a mysql_args
  shopt -u nocasematch

  while (( "${#@}" )); do
    to_debug rds echo "now: ${1}"  
    case "${1}" in
  
      # show usage menu
      -h                              | \
      -I | --help                     ) help=true; shift ;;
  
      # boolen flags.
      -a | --my-boolean-flag          | \
           --disable-auto-rehash      | \
           --no-auto-rehash           | \
           --auto-vertical-output     | \
      -A | --rehash | --auto-rehash   | \
      -B | --batch                    | \
      -b | --no-beep                  | \
           --column-type-info         | \
      -c | --comments                 | \
           --skip-comments            | \
      -C | --compress                 | \
      -E | --vertical                 | \
      -f | --force                    | \
      -G | --named-commands           | \
           --disable-named-commands   | \
      -H | --html                     | \
           --histignore               | \
      -i | --ignore-spaces            | \
      -X | --xml                      | \
      -L | --line-numbers             | \
      -j | --syslog                   | \
           --skip-line-numbers        | \
      -n | --unbuffered               | \
      -N | --column-names             | \
           --skip-column-names        | \
      -o | --one-database             | \
           --disable-pager            | \
      -q | --quick                    | \
      -r | --raw                      | \
           --reconnect                | \
           --disable-reconnect        | \
           --skip-reconnect           | \
      -s | --silent                   | \
      -t | --table                    | \
      -v | --verbose                  | \
      -V | --version                  | \
      -w | --wait                     | \
      -U | --safe-updates             | \
           --i-am-a-dummy             | \
           --disable-tee              | \
           --connect-expired-password | \
           --binary-mode              | \
           --print-defaults           | \
           --show-warnings            ) 
  
      [[ "${1}" =~ ^\- ]] && mysql_args+=( "${@:1:1}" ) 
      shift ;;
  
       # Argument flags.
      
      -D | --database                 | \
           --default-character-set    | \
           --delimiter                | \
      -e | --execute                  | \
           --init-command             | \
           --local-infile             | \
           --pager                    | \
           --host                     | \
           --prompt                   | \
           --password                 | \
           --protocol                 | \
      -u | --user                     | \
           --tee                      | \
           --connect-timeout          | \
           --max-allowed-packet       | \
           --net-buffer-length        | \
           --select-limit             | \
           --max-join-size            | \
           --plugin-dir               | \
           --compression-algorithms   | \
           --zstd-compression-level   | \
           --load-data-local-dir      ) 
  
      [[ -n "${1}" && -n "${2}" && "${2:1:1}" != "-" ]] && { 
        if [[ "${1}" == --execute || "${1}" == -e ]]; then 
          # NOTE: encode sql to avoid formatting problems.
          sql="$(echo "${@:2:1}" | parallel --shellquote | encode_sql)" 
          mysql_args+=( "${@:1:1}" "\"${sql}\"" )
        else 
          mysql_args+=( "${@:1:1}" "${@:2:1}" )
        fi 
      } || { 
        echo "ERROR: Cannot parse arg for " "${*:1:1}: " "\"${*:2:1}\""
        exit 1
      } 
      shift 2 ;;
       
      # with equals sign
      --net-buffer-length=* | select-limit=* | \
      --max-join-size=* | --plugin-dir=*     | \
      --tee=* | --connect-timeout=*          | \
      --local-infile=* | --pager=*           | \
      --delimiter=* | --execute=*            | \
      --zstd-compression-level=*             | \
      --compression-algorithms=*             | \
      --default-character-set=*              | \
      --load-data-local-dir=*                | \
      --max-allowed-packet=*                 | \
      --protocol=* | --host=*                | \
      --init-command=* | --password=*        | \
      --database=*                           ) 
  
        if [[ "${1}" = --execute=* || "${1}" = -e=* ]]; then 
          sql="$(echo "${1#*=}" | parallel --shellquote | encode_sql )"
          mysql_args+=( "${1%=*}=${sql}" ); 
        else 
          mysql_args+=( "${1}" )
        fi
        shift ;;
   
        # -*|--*=) # unsupported flags
        #   echo "Error: Unsupported flag ${1}" >&2
        #   exit 1
        #   ;;
  
      *) shift ;;  # toss anything else.
  
    esac
  done

  echo "${mysql_args[@]@A}"
}  || true

set_iam_user() { 
  echo "dba_guild"
} || true

# Select a default iam_user. 
# Not called if the user specifically designates.
#
iam_user() { 

  # Determine default user, based on team.
  iam_user="${1:-restricted}" 

  [[ -n "${BT_iam_user}" && \
     -z "${iam_user}"     ]] && { 
    echo "${BT_iam_user}" && return 
  }

  iam_user=restricted    # default
  is_primary="$(find_in primary | grep "${BT_TEAM}")"
  is_primary="$(echo dba_guild )"
  
  [[ -n "${is_primary}" ]] && { 

    export BT_iam_user=dba_guild
    echo "${BT_iam_user}" && return 
  }

  [[ -z "${is_primary}" ]] && { 

    BT_iam_user=team-"${BT_TEAM}"
    export BT_iam_user
    echo "${BT_iam_user}" && return
  } 

  export BT_iam_user="restricted"    # default
  echo "${BT_iam_user}"
} || true


set_tunnel_user() { 

  [[ "${BT_TEAM}" == "arch" && \
     "${BT_method}" = ssh-*  ]] && { 

    export BT_tunnel_user=ec2-user
  } || { 
    export BT_tunnel_user=ssm-user
  } 

  echo "${BT_tunnel_user}"
} || true


# Connection method: Pure ssm.
# ----------------------------
# Uses ssm for tunneling, and for forwarding. 
# ssm forwarder is a 'cocat' command, so not 
# completely ssm based, but pretty close.
# 
pure_ssm() { 

 true  
 #mkdir -p ~/.ssh/sockets && chmod 0700 ~/.ssh/sockets

} || true 


# Connection method: ssh tunnel - VPN style.
# ------------------------------------------
ssh_vpn() { 

  : # will add soon.  

}  || true

ssh_master_socket() { 

  : # will add soon. 

} || true

# create a temporary path for use with 
# session data of various sorts. 
#
get_tmppath() { 

  tmppath="$(gmktemp -p "${HOME}"/tmp rds.XXXXXXXXXXXX)"

  echo "${tmppath}"
}  || true

# ----------------------------------------------------
# get an RDS IAM login token
# ----------------------------------------------------
# These expire in 15 minutes.
#
get_iam_token() { 

  iam_user="${1}"
  endpoint="${2}"
  tmppath="${3:-"NONE"}"

  [[ -z "${iam_user}" || -z "${endpoint}" ]] && { 
    echo "FATAL: iam_user and endpoint must be set"
    echo "       to acquire an RDS IAM token."
    return 1
  } 

  # N.B. -- Potentially confusing override of the
  # built-in 'echo' function, as a way to present
  # credentials to an aws-cli call without needing
  # to fork a sub-shell.
  #
  # fifos can speed up token calls.
  [[ "${tmppath}" == "NONE" ]] && { 
    tmppath="$(get_tmppath)"
  } 
  mkfifo "${tmppath}".fifo
  
  # Side-step the need for a subshell.
  #
  exec 5<> "${tmppath}".fifo
  
  #aws rds generate-db-auth-token \
  #--hostname "saintlukes-amd.cluster-cum1rxsnisml.us-west-2.rds.amazonaws.com" \
  #--port 3306 --username "dba_guild" 
  
  aws rds generate-db-auth-token                 \
    --hostname                     "${endpoint}" \
    --port                                 3306  \
    --username "${iam_user}" >"${tmppath}".fifo  \
  TOKEN="$(cat "${tmppath}".fifo)"

  [[ -z "${TOKEN}" ]] && warn "WARNING: NO TOKEN."
  
  to_debug rds echo TOKEN:
  echo "${TOKEN}"
} || true
 
# -------------------
# reprocess mysql args.
# -------------------
# NOTE: This is necessary to deal with 
# in-line SQL, which we encode for passing 
# between processes. 
# 
reprocess_mysql_args() { 

  declare -a mysql_args
  mysql_args=( "${@}" )

  # NOTE: This includes decoding in-line SQL.
  to_debug rds printf "mysql flag: |%s|\n" "${mysql_args[@]}"
  
  # reparse mysql flags
  declare -a cfg_args

  i=0
  while (( i < "${#mysql_args[@]}" )); do
    arg="${mysql_args[*]:$i:1}"
    case "${arg}" in
        -e=* | --execute=*  )
          k=${arg%=*}
          v="${arg#*=}"
          [[ "${v}" = *QV_SQL_ENC* ]] && { 
            sql="$(echo "${v}" | decode_sql)"
            cfg_args+=( "$k=${sql}" )  
          } || { 
            cfg_args+=( "${arg}" )
          } 
          ;;
        --*=* | -*=* ) cfg_args+=( "${arg}" ) 
          ;;
        --*   | -* )   cfg_args+=( "${arg}" ) 
          ;;
        * ) 
            [[ "${arg}" = *QV_SQL_ENC* ]] && { 
              sql="$(echo "${arg}" | sed -e 's/\"//g' |  decode_sql)"
              cfg_args+=( "\"${sql}\"" ) 
            } || { 
              cfg_args+=( "\"${arg}\"" )
            } 
         ;;
      esac
      (( i++ ))
  done
  
  to_debug rds echo cfg_args: "${cfg_args[@]@A}" 
  echo "${cfg_args[@]@A}" 
} || true

# Try to connect.
# ---------------
# update status to parent while connecting.
#
repoll() { 

  p=${1}
  
  TICKS=
  to_debug rdsl && echo polling port: "${p}"   3>&1
  while ! nc -z 127.0.0.1 "${p}" >/dev/null 2>&1; do
    ((TICKS++)) 
    sleep 0.1
    if ((TICKS % 15 == 0 && TICKS <= 300)); then
      echo -ne "."   3>&1 
    fi
    [[ "${TICKS}" -ge 300 ]] && \
    echo timed out. && exit 1
  done
  n=1
  for i in seq 30; do 
    OUT="$(mysql -h 127.0.0.1 -P ${p} -u this --skip-password --wait 2>&1)"
    [[ "${OUT}" = ERROR* ]] && { 
        echo "Detected MySQL listener!"
        return 
    } || {
      echo -ne - 3>&1
      sleep $n
      n=$(( n ))
      continue
  }
  done  
} || true

# BACKOFF POLLER
# --------------
# Polling to see if a socket stays alive. 
# Re-init when it isn't.
#
backoff_poll() { 

  cmd_id="${1}"

  echo "aws ssm list-command-invocations \
       --command-id \"${cmd_id}\" --query \
       'CommandInvocations[].CommandPlugins[].{Status:Status,Output:Output}'"

  response="$(aws ssm list-command-invocations \
           --command-id "${cmd_id}" \
           --query 'CommandInvocations[].CommandPlugins[].{Status:Status,Output:Output}')"

  echo response: $response  >&3

} || true



# -----------------------------------------
# Spawn a daemon that hunts for
# and cleans up the following: 
# -----------------------------------------
# * stale mysql tunnels 
# * stale mysql connections 
# * stale ssm sessions
# * remote forwarding tunnels that 
#   have timed out or failed.
# 

# Workhorse regex for
# finding processes we care about.
#
show_all_ports() {
    lsof -i -P -n                        | \
    perl -nle 'print if 
    s/^                                  # 1. substitution regex.
       (mysql|aws|session_m)             # 2. match processes.
       \s+(\d+)\s.*TCP.*\-\>             # 3. ( ignore text we
       (?:(?:(?:\d{1,3}\.){3})\d{1,3}):  #      DO NOT care about...)
       (33\d\d|443)\s+\((\w+)\)          #
       /\1 \2 \3 \4/x                    # 4. print what we DO care about.
              ' | sort                   #    so cool it tingles. 
    echo "--------------------------------"
    netstat -an | grep -i listen | grep -E '\.33\d\d' 
} || true 


wipe_ssm_ports() { 
  port=${1:-"33"} 
  signal=${2:-"QUIT"}
  echo kill -s ${signal}             \
      $(ps -A                 | \
        grep "[p]ortNumber=" | \
        grep "${port}"        | \
        awk '{print $1}'     | \
        perl -pe 's/\n/ /')
} || true
   
wipe_mysql_listeners() { 
  port=${1:-"33"} 
  signal=${2:-"QUIT"}
  kill -s ${signal}        \
      $(lsof -i -P -n         | \
        grep -i "[l]isten"   | \
        grep "${port}"        | \
        awk '{print $2}'     | \
        perl -pe 's/\n/ /'    )
} || true

#netstat -an | grep -i listen | grep -E '\.33\d\d'

autoclean() { 
  echo "Current socket state: "
  show_all_ports
} | true

socket_peek() { 
  while read -ra sock; do 
    set '__' $sock 
    name="${1:-""}" pid="${2:-""}" port="${3:-""}" st="${4:-""}"
  done< <(show_all_ports)
} || true



# close the tunnels passed in as args.
# (or ALL, if no args.)
# 
close_socket() {

  #tmppath="$(gmktemp -p ${HOME}/tmp ${this}.XXXXXXXXXXXX)"
  #tmpfile="${tmppath##*/}" 
  
  #fee_fifo_fum="${HOME}"/.ssh/sockets/${tmpfile}.fifo
  #mkfifo $fee_fifo_fum
  #read -rsn1;  <$fee_fifo_fum >/dev/null 2>&1
  #read -rsn1 -p "Press any key to close session."; cat <$fee_fifo_fum
 
  for tun in "${@}"; do
  
    stats="$(find_in_rds "${tun}")" 
    trunk="$(   echo "${stats}" | cut -d'%' -f 3)"
    port="$(    echo "${stats}" | cut -d'%' -f 4)"
    PID="$(lsof -t -i @localhost:"${port}" -sTCP:listen)"
    echo FOUND:
    echo "${PID}"
    [[ -n "${PID}" ]] && { 


      #echo "sending HUP to port: ${port}, for ${trunk}."
      kill -HUP "${PID}"
    }

  done
  reset

} || true

to_debug flow && echo rds:close_socket || true
to_debug flow && sleep 0.5 && echo rds:end || true


# ------------------------------------------------------
# util.bash
# ------------------------------------------------------
# shellcheck shell=bash disable=SC2148


# Uncomment for debugging output across all libs.
# Define specific tags in BT_DEBUG for less noise.
#export BT_DEBUG="stng flow lgin util data rds rdsc cche qv dg prmt"

#to_debug flow sleep 0.5 && echo "utils:to_debug" || true 
#to_debug flow echo "utils:ansi_color" || true 
#to_debug flow && echo pmpt:get_funcs  || true

metaloader() { 
  [[ "${LOADER}" == "loader" ]] && { 
    loader <<< cmds
  } 
  [[ "${LOADER}" == "legacy" ]] && {
    legacy_loader 
  } 
  echo "FATAL: No loader config was given."
}

loader() ( 
    # script loader (runs exactly once)
    [[ ! "${LOADER_ACTIVE}" = true ]] && {
        . "${BT}/lib/bt_loader.bash" >/dev/null 2>&1
    }

    # pass directives from a multiline var, or a heredoc. 
    xargs -0 <<< $*

    {
        funcs="$(declare -F | wc -l)"
        echo -en "${GREEN}Success${NC} - "
        funcs="$(declare -F | grep -v '\-f _' | wc -l)"
        echo -e  "Loaded ${CYAN}${funcs}${NC} functions."
        if [[ "${funcs}" -lt 60 ]]; then
            echo -e "WARNING: Loader ${YELLOW}failed${NC}." 
            #echo -en "Retrying with legacy_loader .... " 
            #coproc (echo $(legacy_loader)) && echo -e "${GREEN}succeeded${NC}".
            #echo  <&"${COPROC[1]}"
            #echo -ne "\n"
        fi
    }
) || true



# Commands for the loader to exec, passed in as a variable.
cmds() { 

    shopt -s extglob
    cmds="$(                                                          \
        ls -1d ${HOME}/.bt/@(lib|gen|src|cache)                     | \
            perl -pe "s/([\w_\-]+)/loader_addpath \1/;"               \
        ls -1 ${HOME}/.bt/lib/@(utils|bt|env|rdslib|data|api)\.bash | \
            perl -pe "s/([\w_\-]+)/includex \1/;" | sort -r           \
        loader_flag "$(which aws)"                                    \
    )"    
    shopt -u extglob 
    echo ${cmds}
} || true




legacy_loader() { 

    # Static libs. No globbing. A bit too brittle.
    funcs="$(declare -F | grep -v "\-f _" | wc -l )" && {
        echo -e "Loaded ${CYAN}${funcs}${NC} functions."
        return 0
    } 

} || true



#to_debug flow && sleep 0.5 && echo "stgs:loader"
#to_debug flow && sleep 0.5 && echo "stgs:includex"
#to_debug flow && sleep 0.5 && echo "stgs:addpath" || true






## ANSI COLOR 
## -----------------------------------------------------------------
## We use colors in multiple places to improve the user experience. 
##  
##      .-------------- # constant part.
##      vvvvv  vvvv --- # ansi code.
##
## shellcheck disable=code disable=SC2034
{

  echo -e "\001${color}\002"

  GRAY='\001\033[0;37m\002'     #
  BLUE='\001\033[0;34m\002'     #
  CYAN='\001\033[0;96m\002'     #
PURPLE='\001\033[1;35m\002'     #
YELLOW='\001\033[0;33m\002'     #
 GREEN='\001\033[0;32m\002'     #
   RED='\001\033[0;31m\002'     #
    NC='\001\033[0;m\002'       # No Color
} || true

set_red="$(  tput setaf 1)"
set_green="$(tput setaf 2)"
set_yellow="$( tput setaf 3)"
set_blue="$( tput setaf 4)"
set_purple="$( tput setaf 5)"
set_cyan="$( tput setaf 6)"
set_nc="$(   tput setaf 7)"

## -----------------------------------------------------------------
## Utility functions (various, useful across all libs.)
## -----------------------------------------------------------------

to_debug flow && echo "utils:q_pushd" || true
q_pushd() { command pushd "$@" > /dev/null 2>&1 || return ;} || true

to_debug flow && echo "utils:q_popd" || true
q_popd() { command popd "$@" > /dev/null 2>&1 || return;} || true

# walk back through a pop stack
#q_mpopd() { n=$1; while [[ $n > 0 ]]; do q_popd; n=$((n-1)); done ;} || true
#q_mpopd() { popd ;} || true

to_debug flow && echo "utils:die" || true
die() { NUM="${1:-2}"; echo "$*" >&2; return "$NUM"; "exit $NUM"; } || true

get_account() {
  cat "${BT}/data/json/bt/accounts.json" | \
                    jq -r      '.account | \
                            to_entries[] | \
                   select(.key|tostring) | "\(.key)"'
} || true

get_usr() { 
  echo "${USER}"
} || true

get_team() { 
  [[ -z "${BT}" ]] && { BT="${HOME}/.bt"; export BT="${BT}" ;}
  set_team && echo "${BT_TEAM}"  
} || true

aws_defaults() { 

  # qv standards
  export BT_CREDS="${HOME}/.aws/bt_creds"
  export BT_CONFIG="${HOME}/.aws/bt_config"
  export qv_gbl=us-west-2
  export qv_start_url=https://qventus.awsapps.com/start

  # For reliability, Bintools isolates its configs from the defaults.
  export AWS_CONFIG_FILE="${BT_CONFIG}"            \
         AWS_SHARED_CREDENTIALS_FILE=${BT_CREDS} \
         AWS_SDK_LOAD_CONFIG=1

  # aws-sso-credential-process 
  # when run on a headless system; credential_process captures 
  # stdout and stderr, so the URL and code that are printed out 
  # for use when the browser popup do not appear to the user.
  export AWS_SSO_INTERACTIVE_AUTH=true

  # for configuring the devops-sso-util credential process.
  export AWS_CONFIGURE_SSO_DEFAULT_SSO_START_URL=${qv_start_url} 
  export AWS_CONFIGURE_SSO_DEFAULT_SSO_REGION=${qv_gbl} 
  export AWS_CONFIGURE_DEFAULT_SSO_REGION=${qv_gbl}
  export AWS_CONFIGURE_DEFAULT_REGION=${qv_gbl}

  export AWS_LOGIN_SSO_DEFAULT_SSO_START_URL=${qv_start_url} 
  export AWS_LOGIN_SSO_DEFAULT_SSO_REGION=${qv_gbl} 
  export AWS_DEFAULT_SSO_START_URL=${qv_start_url} 
  export AWS_DEFAULT_SSO_REGION=${qv_gbl}
  export AWS_DEFAULT_REGION=${qv_gbl}
  export AWS_SSO_CREDENTIAL_PROCESS_DEBUG=true
  export AWS_SDK_LOAD_CONFIG=1   # for golang, terraform, e.g.
                                 # which do not use ~/.aws/config

  # You should not need to touch these.
  export AWS_VAULT_PL_BROWSER=com.google.chrome 
  export AWS_DEFAULT_OUTPUT=json
  export AWS_DEFAULT_SSO_REGION=${qv_gbl} 
  export AWS_DEFAULT_REGION=${qv_gbl} 
  export AWS_REGION=${qv_gbl}

} || true

# -----------------------------------------------------------------
# PATH SETTINGS
# -----------------------------------------------------------------

# Warn to stderr, but continue.
to_debug flow && echo "utils:warn" || true
warn() { >&2 echo "${@}"; } || true

# send to stderr.
to_debug flow && echo "utils:to_err"
to_err() { >&2 echo "${@}"; } || true

# send to bintools log.
to_debug flow && echo "utils:to_log" || true
to_log() { 
  echo -e "${@}" | \
  xargs -L 1 echo "$(date +"[%Y-%m-%d %H:%M:%S]")" | \
  tee -a "${bt_log:-"${BT}"/log/bt_log}"; 
} || true


# return 'true' of running on mac.  
# useful for handling  mac-isms. 
#on_mac() { $( os=$(uname -s) && [ "${os}" == "Darwin" ] && return True) }
#to_debug flow && echo "utils:on_mac"

# complain about missing a specific arg.
to_debug flow && echo "utils:needs_arg" || true
needs_arg() { [ -z "$OPTARG" ] && warn "No arg for --$OPT option" && usage ;} || true


to_debug flow && echo "utils:usage" || true
usage() { echo "Usage: <more instructions here...>"; } || true


to_debug flow && echo "utils:expired"

# ---------------------------------------
# when passing SQL to the command-line,
# encode it first. Helps with processing.
# ---------------------------------------
#
to_debug flow && echo "utils:decode_sql" || true

decode_sql() {
  local SQLenc="${1}"
  [[ -z "${SQLenc}" ]] && read -r SQLenc
  [[ "${SQLenc}" = QV_SQL_ENC* ]] && { 
  echo "${SQLenc}"              | \
  perl -pe "s/QV_SQL_ENC//"    | \
  gbase64 -d                    | \
  zcat 
  }
} || true

to_debug flow && echo "utils:encode_sql" || true

encode_sql() {
  SQLraw="${1}"
  [[ -z "${SQLraw}" ]] && read -r SQLraw
  echo -ne "QV_SQL_ENC" && \
  echo "${SQLraw}" | gzip | gbase64 
} || true

to_debug flow && echo "utils:arg_split" || true

# return the index number of a particular string
# in an array.
# debug echo args: ${args[@]}
arg_split() {
  local args=( "${@:1}" )
  local n=${args[0]}
  for n in $(seq ${#args[@]}); do
    [[ "${args[$n]}" == "--" ]] && echo "$n"
  done
} || true

to_debug flow && echo "utils:find_in_rds" || true

find_in_rds() {
  this=${1}
  declare -A rds_map 
  source "${BT}"/src/rds_map.src
  for l in $(printf '%s\n' "${rds_map[@]}"); do 
    echo "$l" | perl -nle "print \"$l\" if /${this}/" 
  done
} || true




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

} || true

instance_info() { 

    :   # ssm target

} || true


to_debug flow && sleep 0.5 && echo "utils:end" || true



# find a toml file. 
function locate_toml() {
	local path
	IFS="/" read -ra path <<<"$PWD"
	for ((i=${#path[@]}; i > 0; i--)); do
		local current_path=""
		for ((j=1; j<i; j++)); do
			current_path="$current_path/${path[j]}"
		done
		if [[ -e "${current_path}/$1" ]]; then
			echo "${current_path}/"
			return
		fi
	done
	return 1
} || true



this_peek () { 
  [ -z "${BT_PEEK}" ] && { 
    : #echo "No BT_PEEK var was found."
      #return 1
  }
  echo "${BT_PEEK}" | gbase64 -d | zcat | jq 
} || true




# PKG="${1}" # pass in package name (devops-sso-util).


to_debug flow && sleep 1 && echo data:start || true

# This lib embeds a bunch of our setup data
# for later use.  Routines that read/write json
# objects are used for compatibility with zsh, 
# python, golang, and other. 

# SEE: https://stackoverflow.com/questions/10582763/how-to-return-an-array-in-bash-without-using-globals/49971213

# TODO: These static arrays need to be added to json
#       configurations stored in ssm, or more likely
#       in ConsoleMe... 
#

# load arrays with curl: 
# curl file:///${BT}/config.d/bt.json

# arg1: name
# stdin: json obj:   '{"a":"z","b":"y","c":"x"}' 
#    or: json array: '["a", "b", "c"]'
#  file: stdout or file.


# Print array definition to use with assignments, for loops, etc.
#   varname: the name of an array variable.

use_array() {
    local r=$( declare -p $1 )
    r=${r#declare\ -a\ *=}
    # Strip keys so printed definition will be a simple list (like when using
    # "${array[@]}").  One side effect of having keys in the definition is 
    # that when appending arrays (i.e. `a1+=$( use_array a2 )`), values at
    # matching indices merge instead of pushing all items onto array.
    echo ${r//\[[0-9]\]=}
} || true

to_debug flow echo data:use_array || true

# Same as use_array() but preserves keys.
use_array_assoc() {
    local r=$( declare -p $1 )
    echo ${r#declare\ -a\ *=}
} || true 

to_debug flow echo data:use_array_assoc || true

json2bash() { 

  [[ -n "${1}" ]] && {  
    local -n ref="${1:-"NONE"}"  # 1st arg is a name ref 
                                 # 1st arg is a name ref 
  }                              # for the array.

  # arg2 is file path (or stdin).
  [[ -n "${2}" ]] && {  
    local file="${2:-/dev/stdin}"
    # use basename as array ref.
    ref="$(basename "$file" | cut -d. -f1)"
  } 

  json="$(<"${file:-/dev/stdin}")"

  # contents.  
  case "${json}" in 
    "["*) type=a;  declare -a "${ref}";;
    "{"*) type=aa; declare -A "${ref}";;
    *) echo "not a json map or array."
    return 1
  esac

  [[ "${type}" == "aa" ]] && { 
    
    while IFS= read -rd '' key && IFS= read -rd '' value; do
      __data["${key}"]="${value}"
    done < <(
             set -o pipefail | \
             jq -j 'to_entries[] | 
                   (.key,   "\u0000", 
                    .value, "\u0000"
                   )
                   ' "${json}")

       # if curl or jq failed. 
       # Needs bash 4.4 or newer.
       wait "$!" || return 1

  } || { 

      __data=()
    while read -r v; do
      __data+=("$v")
    done < <(jq -c '.[]' "${json}")
    wait "$!" || return 1
  } 
} || true

to_debug flow echo data:json_to_bash || true



# Pass an array ref, or associative array: returns json.
bash2json() { 
  local -n ref="${1:-"NONE"}"  # 1st arg is a name ref 
  tmp=( "${ref}[@]" ) 
  debug echo tmp: ${ref[@]}

  # while array type?
  [[ "$(declare -p tmp 2>/dev/null)" == "declare -A"* ]] && type=aa 
  [[ "$(declare -p tmp 2>/dev/null)" == "declare -a"* ]] && type=a
  declare -p ${!ref}

  echo type: $type
  [[ "${type}" == "aa" ]] && { 
    for k in "${!ref[@]}"; do
      printf '%s\0%s\0' "$k" "${ref[$k]}"
    done | jq -Rs '
      split("\u0000")
      | . as $a
      | reduce range(0; length/2) as $i 
        ({}; . + {($a[2*$i]): ($a[2*$i + 1]|fromjson? // .)})
    '

    wait "$!" || return 1 # if jq fails. Needs bash 4.4.
  } || { 

  [[ "${type}" == "a" ]] && { 
      
      jq -nc '$ARGS.positional' --args "${ref[@]}"
      wait "$!" || return 1 # if jq fails. Needs bash 4.4.
    } 
  }

} || true

to_debug flow echo data:bash2json || true

# list of arrays to choose from.
array_list=( "role_types" "primary" "delegated"  \
               "restricted" "unrestricted" "guild" )

#[ -n "${array_list["${ref}"]}" ]]     && \
#declare -p "${array_list["${ref}"]}" || \
#return 

to_debug flow echo data:config_arrays || true

declare -a role_types=(  role_types                  \
                                        primary      \
                                        delegated    \
                                        unrestricted \
                                        restricted   \
                                        guild        \
)
declare -a primary=(   primary                       \
                                        admin        \
                                        arch         \
                                        sec          \
                                        devops       \
)
declare -a delegated=(    delegated                  \
                                        int          \
                                        ds           \
                                        dp           \
                                        app          \
                                        qa           \
  )
declare -a unrestricted=(  unrestricted              \
                                        identity     \
                                        prod         \
                                        cnc          \
                                        demo         \
                                        qa           \
                                        dev          \
                                        devdata      \
)

declare -a restricted=(   restricted                 \
                                        dns          \
                                        master       \
                                        audit        \
                                        security     \
)

declare -a guild=(         guild                     \
                                        cicd         \
                                        terraform    \
                                        helm         \
                                        dba          \
                                        ml           \
                                        ssm          \
)


get_arrayref() {
    local this_arr 
    array_def "${1}"            # call function to populate the array
    declare -p this_arr         # test the array
} || true


# USAGE:  . get_array "teams"  # sources the array. 
# search it in the usual manner.

# Globbing
# --------
# Advanced globbing is an easy way to sort through files.
# But we need to Keep tabs on whether a particular glob was
# originally set.  We should only toggle the setting if
# originally not set.
#
#shopt -s extglob
#shopt -s nullglob
#shopt -s dotglob
#shopt -s nocasematch

# NOTE:
# -----
# Does not preserve indices or work with sparse arrays.
# Element 0 in each array is the array name, 
# used for pass-by-reference. 
#
# examples:
# ---------
# find_in role_primary sec
#
# shellcheck disable=SC2068,SC2086
to_debug flow echo data:find_in || true
find_in() { 
  declare -n a=${1} && . <( "${a[@]@A}")
  s=${2:-"_"} && name=${1:-"accounts"}
  [[ $s == '_' ]] && for e in ${a[@]:1}; do echo $e; done && return 0
  [[ "${a[*]:2}" = "${s}" ]] && echo ${s} || echo -ne ""
} || true



# USAGE
# -----

# find_in role_types _
# produces full list if "_" is given as arg 2.

# prints match if a match is found.
# find_in role_types delegated

# prints nothing if no match is found.
# find_in role_types foobar


# TODO:
# -----
# This is a library of things that should go away. 
#
# These constants should all be generated by AWS calls.
# The iDP provider should be the source of truth for Bintools. 
#
# source only once per shell

# current flow is...
# (ENV vars)> vars_to_json > json_object > encode | decode > apply_env 

# NOTE: 
# -----
# Does not preserve indices 
# or work with sparse arrays.
#
to_debug flow echo data:is_in || true
is_in() { 
  _this=${1:=NONE} 
 sz="${#_this[@]}" 
 arr="${_this[*]}" 
 local array=("${@:1:$1}"); shift "$(($1 + 1))" in
} || true

to_debug flow echo data:find_in_accounts || true

#shellcheck disable=SC2068
find_in_accounts() {
  this=${1} 
  source "${BT}"/src/accounts.gen
  for l in $(printf '%s\n' ${ACCOUNTS[@]}); do 
    echo "$l" | perl -nle "print \"$l\" if /${this}/" | perl -pe "s/%/ /g"
  done
} || true


# usage: 
# ------
# find_in_rds          wellspan-amd
# find_in role_types   primary 
# find_in guilds       (terraform|cicd) 
# find_in accounts     identity

# key_sort ACCOUNTS

# key_sort determines whether we're dealing with 
# a plain or associative array. 
key_sort() { 
  local -n a_of_a="${1:-this_index}"
  [[ "$(printf %s "${!a_of_a[@]}")" =~ ^[0-9]+$ ]] && type=a
} || true
    

to_debug flow echo data:key_sort || true

# shellcheck disable=SC2068,SC2120
role_arrays() {
  local -n a_of_a="${1:-this_index}"
  for a in $(${a_of_a[@]@A} && printf "role_%s\n" ${a_of_a[@]}); do
     local -n this_arr="${a}"
     for t in $(${this_arr[@]@A} && printf "%s\n" ${this_arr[@]} | sort); do
         echo "$a": "$t"
     done
  done
} || true

to_debug flow echo data:role_arrays || true

#role_arrays

# array of arrays
# ---------------
# bash has no native array of arrays implementation,
# but there is a need here, so... 
#
# 'this_index' array holds keys to other arrays,
# and can handle arrays or hashes.
this_index() {
  local -n a_of_a=${1:this_index}
  [[ "$(printf %s "${!a_of_a[@]}")" =~ ^[0-9]+$ ]] && type=a
  paste \
  <( ! [[ "$type" == "a" ]] && \
     for e in $("${a_of_a[@]@A}" && printf "%s\n" "${!a_of_a[@]}"); do echo "$e"; done) \
  <( for e in $("${a_of_a[@]@A}" && printf "%s\n"  "${a_of_a[@]}"); do echo "$e"; done) 
} || true

to_debug flow echo data:this_index | true

# read example: 
# -------------
#      find_in [HASH|ARRAY] some_thing
# echo find_in ACCOUNTS master
# find_in ACCOUNTS master
# echo find_in ROLE_TYPES: primary
# find_in ROLE_TYPES primary

# write example: 
# -------------- 
#    FOO["newKey"]="111222333444"
#    declare -A FOO newKey # make it so.
#    find_in   FOO        # shallow merge just happens.
# 
find_in_this() { 
  local -n a_of_a=${1:-this_index}
  while IFS= read -r line; do 
    echo "$line" | grep "$2"
  done <<< "$( this_index "${1}")" 
} || true

to_debug flow echo data:find_in_this || true


# Test 
is_account() {
  local -n acct_ref="$1"
  [[ "${2}" =~ [0-9]{12} ]] && account_rev && return
  echo "${acct_ref[$2]}" 
} || true

to_debug flow echo data:is_account  || true
    

# Queries aws for a list of all instances. 
# Caches them as an associative array in a local file. 
#
cache_inst() { 

    
  TEAM="$(get_team)" 
  [[ -z "${TEAM}" ]] && echo "FATAL: No team var." && exit 1
  try_login 
 
  declare -a tmp
  tmp+=( "$(aws ec2 describe-instances \
          --output json \
          --region us-west-2 \
          --filters Name=tag-key,Values=Name \
          --query 'Reservations[*].Instances[*].{
                   Instance:InstanceId,
                   Name:Tags[?Key==`Name`]|[0].Value,
                   PrivAddr:PrivateIpAddress,
                   KeyName:KeyName,
                   PubAddr:PublicIpAddress
                 }' | \
          jq -r '.[][]|
                (.Name|gsub(" "; "_"))+","+
                (.Instance)+","+
                (.PrivAddr)+","+
                (.KeyName)+","+
                (.PubAddr)+"%"
        ')" )

    [ ! -d "${BT}/utils/gen" ] && \
    bt_log "FATAL: ${BT}/utils/gen dir not found." && die "${@}"

    ### build an associative array of hosts and descriptors.
    ### ----------------------------------------------------
    mkdir -p "${HOME}/tmp"
    tmppath="$(gmktemp -p "${HOME}"/tmp inst_map.XXXXXXXXXXXX)"
    echo -ne 'declare -A inst_map=( ' > "$tmppath" 
    while IFS= read -r l; do 
      while IFS=',' read -r n i ip k pp; do
        s="[$n]=$n,$i,$ip,$k,$pp%"
        bash -c "echo -ne $(printf ' %q' "$s ")" >> "${tmppath}"
        debug echo "wrote: $s"
      done 
    done < <(printf '%s\n' "${tmp[@]}" | sort)
    echo -ne ")\n" >> "$tmppath"
    # move new array to src dir.
    mv "$tmppath" "${BT}/src/inst_map.src"
} || true

gen_ssm_json() { 

  TEAM="$(get_team)" 
  [[ -z "${TEAM}" ]] && echo "FATAL: No team var." && exit 1
 
  aws ec2 describe-instances \
      --output json \
      --region us-west-2 \
      --filters Name=tag-key,Values=Name \
      --query 'Reservations[*].Instances[*].{
               Instance:InstanceId,
               Name:Tags[?Key==`Name`]|[0].Value,
               PrivAddr:PrivateIpAddress,
               KeyName:KeyName,
               PubAddr:PublicIpAddress
             }' | jq '[ .[] | INDEX(.Name) ]' | tee "${BT}/data/json/aws/ssm.json"

    [ ! -d "${BT}/gen" ] && \
    bt_log "FATAL: ${BT}/utils/gen dir not found." && die "${@}"
}

to_debug flow echo data:cache_inst


# Once the cache is written (see cache_inst, above)
# this function will instantiate the associative array
# with all instance and container values. 
# 
# returns: associative array: inst_map 
# 
get_inst() {  

  declare -A inst_map
  inst_file="${BT}/src/inst_map.src"
  inst_size=$(cat "${BT}"/src/inst_map.src | wc -c)

  # inst_file is considered stale if older 
  # than 1 week, or smaller than 200 bytes.  
  [[ "$(( $(date +"%s") - $(gstat -c "%Y" "${inst_file}") ))" -gt 604800 || \
     "${inst_size}" -lt 200 ]] && { 
    echo "Instance cache is stale. Refreshing...."
    cache_inst "$@"
  }

  # shellcheck disable=SC1090,SC1094 
  { 
    debug echo file contents: "$(cat "${inst_file}")"
    source <(cat "${inst_file}")
    echo -ne sourced contents: "${#inst_map[@]}" hosts
  }
} || true

get_inst_json() {  

  declare -A inst_map
  inst_file="${BT}/src/inst_map.src"
  inst_size=$(cat "${BT}"/src/inst_map.src | wc -c)

  # inst_file is considered stale if older 
  # than 1 week, or smaller than 200 bytes.  
  [[ "$(( $(date +"%s") - $(gstat -c "%Y" "${inst_file}") ))" -gt 604800 || \
     "${inst_size}" -lt 200 ]] && { 
    echo "Instance cache is stale. Refreshing...."
    cache_inst_json "$@"
  }

  # shellcheck disable=SC1090,SC1094 
  { 
    debug echo file contents: "$(cat "${inst_file}")"
  }
} || true

primary() { 
  TEAM="${1:-"NONE"}"
  find_in primaries "${TEAM}" && echo "${TEAM}" || echo -ne ""
} || true

delegated() { 
  TEAM="${1:-"NONE"}"
  find_in delegated "${TEAM}" && echo "${TEAM}" || echo -ne ""
} || true

# ( keyOrValue, arrayKeysOrValues ) 
function teams() {
  declare -a primary
  declare -a delegated
  declare -a all 
  all=( "${delegated:1}" "${primary:1}" ) 
  team=${1:-"NONE"}
  for e in "${all[@]}"; do 
    echo e: "${e}" t: "${team}"
  done
}


primary() { 
  TEAM="${1:-"NONE"}"
  find_in primaries "${TEAM}" && echo "${TEAM}" || echo -ne ""
} || true

delegated() { 
  TEAM="${1:-"NONE"}"
  find_in delegated "${TEAM}" && echo "${TEAM}" || echo -ne ""
} || true

# ( keyOrValue, arrayKeysOrValues ) 
function teams() {
  declare -a primary
  declare -a delegated
  declare -a all 
  all=( "${delegated:1}" "${primary:1}" ) 
  team=${1:-"NONE"}
  for e in "${all[@]}"; do 
    echo e: "${e}" t: "${team}"
  done
} 

get_inst() {  

  declare -A inst_map
  inst_file="${BT}/src/inst_map.src"
  inst_size=$(cat "${BT}"/src/inst_map.src | wc -c)

  # inst_file is considered stale if older 
  # than 1 week, or smaller than 200 bytes.  
  [[ "$(( $(date +"%s") - $(gstat -c "%Y" "${inst_file}") ))" -gt 604800 || \
     "${inst_size}" -lt 200 ]] && { 
    echo "Instance cache is stale. Refreshing...."
    cache_inst "$@"
  }

  # shellcheck disable=SC1090,SC1094 
  { 
    debug echo file contents: "$(cat "${inst_file}")"
    source <(cat "${inst_file}")
    echo -ne sourced contents: "${#inst_map[@]}" hosts
  }
} || true

primary() { 
  TEAM="${1:-"NONE"}"
  find_in primaries "${TEAM}" && echo "${TEAM}" || echo -ne ""
} || true

delegated() { 
  TEAM="${1:-"NONE"}"
  find_in delegated "${TEAM}" && echo "${TEAM}" || echo -ne ""
} || true

# ( keyOrValue, arrayKeysOrValues ) 
function teams() {
  declare -a primary
  declare -a delegated
  declare -a all 
  all=( "${delegated:1}" "${primary:1}" ) 
  team=${1:-"NONE"}
  for e in "${all[@]}"; do 
    echo e: "${e}" t: "${team}"
    [[ "${e}" == "${team}" ]] && return 0; 
  done
  return 1
} || true

to_debug flow echo data:get_inst || true

# jq queries and functions. 

# search by array by value.
#'.accounts |to_entries[]|select(.value == 351480950201).key'

# jq -n '"1111"|split("1";"")'   # count array. 
# 
#!/usr/bin/env /usr/local/bin/bash

# shellcheck shell=bash disable=SC2148

# TODO: These static arrays need to be added to json
#       configurations stored in ssm, or more likely
#       in ConsoleMe... 
#
declare -a role_types=(    role_types                \
                                        primary      \
                                        delegated    \
                                        unrestricted \
                                        restricted   \
                                        guild        \
)
declare -a primary=(   primary                       \
                                        admin        \
                                        arch         \
                                        sec          \
                                        devops       \
)
declare -a delegated=(    delegated                  \
                                        int          \
                                        ds           \
                                        dp           \
                                        app          \
                                        qa           \
)
declare -a unrestricted=(  unrestricted              \
                                        identity     \
                                        prod         \
                                        cnc          \
                                        demo         \
                                        qa           \
                                        dev          \
                                        devdata      \
)
declare -a restricted=(   restricted                 \
                                        dns          \
                                        master       \
                                        audit        \
                                        security     \
)
declare -a guild=(         guild                     \
                                        cicd         \
                                        terraform    \
                                        helm         \
                                        dba          \
                                        ml           \
                                        ssm          \
)



# Globbing
# --------
# Advanced globbing is an easy way to sort through files.
# But we need to Keep tabs on whether a particular glob was
# originally set.  We should only toggle the setting if
# originally not set.
#
#shopt -s extglob
#shopt -s nullglob
#shopt -s dotglob
#shopt -s nocasematch

to_debug flow && sleep 1 && echo data:end || true

to_debug flow && sleep 0.5 && echo api:start || true
to_debug flow && echo api:perms || true


# Show current permissions. 
# -------------------------
# Parses .aws config for details.
# Tries to aide those who have experienced loss. 
#
perms() {
  # time parse our surroundigs.    
  account="$(cat "${AWS_CONFIG_FILE}"                           | \
             perl -nle "print if s/(${ARGV}\]|role_arn.*)/\1/;" | \
             grep -E -A 1 "${ARGV}\]" | tail -n 1               | \
             perl -nle 'print if s/\s*role_arn\s*\=\s*.*::([\w_\-]+)/\1/;')"

  echo account: ${account}

  login="$(aws sts get-caller-identity 2>/dev/null  | \
           jq -r '.Arn'                             | \
           cut -d':' -f 5-6                         | \
           cut -d'/' -f 1-2)"
  [ -z "$login" ] && { 
    echo -e Failed && return 1
  } || { 
    echo -e "${login}"
  }
} || true


#get_account() {
#  this_peek | jq -r '.account | to_entries[] | select(.key|tostring) | "\(.key)"'
#} || true


set_team() { 

  [[ -z "${BT}" ]] && { BT="${HOME}/.bt"; export BT="${BT}" ;}

  aws_defaults   # required to find your team.

  # set team cache
  [ ! -f "${BT}/cache/team_info" ] && { 
    [[ -n "${BT_TEAM}" ]] && ! [[ "${BT_TEAM}" =~ [^a-zA-Z0-9] ]] && { 
      echo "setting team cache to ${BT_TEAM}"
      echo "${BT_TEAM}" > "${BT}/cache/team_info"    
    }
  } 

  # Unset cache if improperly set.
  [ -f "${BT}/cache/team_info" ] && { 
    team="$(/bin/cat "${BT}/cache/team_info")"
    [[ -z "${team}"              || \
       "${team}" =~ NONE         || \
       "${team}" =~ [^a-zA-Z0-9] ]] && { 
        echo -ne "${YELLOW}WARNING${NC}: Team var not proper.  Flushing team cache."
      unset BT_TEAM
      rm -rf "${BT}/cache/team_info"
      return 
    }  
  }

  # Try refreshing the BT_TEAM var from the AWS config. 
  team="$(cat "${AWS_CONFIG_FILE}"                                  | \
      perl -nle "print if s/.*aws_team_([\w_\-]+).*/\1/;" | tail -n 1)"

  # aws config has (seemingly) valid info. 
  if [[ -n "${team}" ]] && \
     ! [[ "${team}" =~ [^a-zA-Z0-9] ]]; then

    BT_TEAM="${team}" 
    export BT_TEAM="${BT_TEAM}" 
    # Cache not present. Populate.    
    echo "${BT_TEAM}" > "${BT}/cache/team_info"
    to_debug prof && echo "env:set_team succeeded - team is: ${BT_TEAM}"

  else 
    # Otherwise, warn the user to fix the problem.
    echo -e BT_TEAM: "${BT_TEAM}"
    echo -e             ^ ^ ^ ^ 
    echo -e ${YELLOW}WARNING${NC}: Examine carefully. 
    echo -e This subsystem has noted it is not correct.
  fi  

} 

to_debug flow && echo api:wipe || true


# unset all sessions and settings.
# --------------------------------
# This is critical, and if skipped will 
# cause major inconsistent behavior in 
# role chaining routines. 
# NOTES on aws-vault credential processes:
# https://github.com/99designs/aws-vault/blob/master/USAGE.md#environment-variables
#
wipe () { 

  # logout from whatever you can find.  
  "${DEFAULT_AWSLIB}" logout  > /dev/null 2>&1

  # remove expired creds from cli, awsume caches
  rm -rf "${HOME}"/.aws/{sso,cli}/cache/* 
  rm -rf "${HOME}"/.awsume/cache/*

  awsume --unset > /dev/null 2>&1
  aws_profile --unset

  unset AWSUME_PROFILE AWSUME_DEFAULT_PROFILE AWS_PROFILE AWS_DEFAULT_PROFILE
  # check we have no stale identities remaining.

  aws-whoami >/dev/null 2>&1 || echo "no identities left."
  "${DEFAULT_AWSLIB}" check >/dev/null 2>&1
  echo "all cached sessions removed."
  # also wipe local session counter.
  unset t ts X 
} || true


to_debug flow && echo api:unset_profile || true

unset_profile() { 
  ${BT}/cmd/assume --unset >/dev/null 2>&1
  aws_profile --unset
  unset AWSUME_PROFILE AWSUME_DEFAULT_PROFILE AWS_PROFILE AWS_DEFAULT_PROFILE
} || true



# Creates bridge functions such that components
# installed as python packages work interchangeably
# with dotfiles components, and with Geodesic on Linux.
# 
map_tools() { 

  [[ -z "${BT}" ]] && echo "FATAL: BT var not set." && exit 1

    # -----------------------------------------------------
    # make sure we have the pipx paths exported.
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
    echo -ne "loaded toolsets: ${CYAN}${toolsets[@]}${NC}\n"
    shopt -u extglob

    # -----------------------------------------------------
    # export toolset "map" functions 
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
        bash -c "${ts} ()      { "${ts}_local"           ;};" 
        bash -c "${ts}_cmpl () { . "${RDS}/${ts}_complete" ;};" 
        bash -c "${ts}_gen ()  {   "${RDS}/${ts}_generate" ;};" 
        declare -f ${ts} ${ts}_cmpl ${ts}_gen
    done
    
    echo -ne "running completions.\n"
    for ts in ${toolsets[@]}; do "${ts}_complete"; done
} || true


#make_funcs


sts() { 
    aws sts get-caller-identity                | \
    jq .Arn                                    | \
    perl -pe 's/.*:://; s/qv-gbl//; s/\/boto.*//;'
} || true



ppt() { 
  t="$(echo "${ts}" | ddiff -E -qf %S now)"
  X="$(gdate --utc -d "0 + ${t} seconds" +"%Hh:%Mm:%Ss")"
  pr= tt= pt= 
  # construct a header.
  if [[ -n "${t}" ]] && ! [[ "${t}" =~ [^0-9] ]] && [[ "${t}" -ge 601 ]]; then
    pr="${YELLOW}${BT_TEAM}${NC}@${CYAN}${BT_ACCOUNT}${NC}"
    tt="${GREEN}${X}${NC}"
    pt="${GRAY}BT${NC}[${pr}|${tt}]\w\$ "
  elif [[ -n "${t}" ]] && ! [[ "${t}" =~ [^0-9] ]] && [[ "${t}" -ge 11 ]]; then
    pr="${YELLOW}${BT_TEAM}${NC}@${CYAN}${BT_ACCOUNT}${NC}"
    tt="${YELLOW}${X}${NC}"
    pt="${GRAY}BT${NC}[${pr}|${tt}]\w\$ "
  elif [[ -z "${t}" ]] || [[ "${t}" -eq 0 ]]; then  
    pr="${CYAN}unset${NC}@${CYAN}${BT_ACCOUNT}${NC}"
    tt="${GRAY}0h:00m:00s${NC}"
    pt="${GRAY}BT${NC}[${pr}]\w\$ "
  elif [[ -n "${t}" && "${t}" = \-[0-9]+ && "${t}" -lt 0 ]]; then 
    pr="${RED}${BT_TEAM}${NC}@${RED}${BT_ACCOUNT}${NC}"
    tt=''
    pt="${PURPLE}BT${NC}[${pr}]\w\$ "
  else 
    pr=''
    tt=''
    pt="${PURPLE}BT${NC}[${GRAY}--${NC}]\w\$ "
  fi

  static='(BT)\w\$ '
  __bt=$static
  [[ -n "${t}" ]] && { 
      __bt="$(echo "${pt//'\n'}")"
  } 
  export PS1="${__bt}"
}

prompt_off() { unset PROMPT_COMMAND; export PS1="$static" ;}

prompt_on() { PROMPT_COMMAND=ppt ;}

to_debug flow && sleep 0.5 && echo "stgs:arg_parsing"  || true

account="${1:-"prod"}"

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


to_debug flow && sleep 0.5 && echo "utils:end" || true

# ----------------
# helper functions. 
# -----------------

join_by() { local IFS="$1"; shift; echo "$*" ;} || true


to_debug flow && sleep 0.5 && echo env:start

to_debug flow echo BT: "${BT}"
# Make sure there's a debug function.
[[ "$(type -t to_debug)" == "function" ]] || {
  echo >&2 "WARNING: Core function: 'to_debug' not sourced."
}

# DEBUGGING -- Can be set per component, or globally, here.
#BT_DEBUG=env,flow


# ----------------------------------------------------------------
# AWS_ENV  
#
# Full BT environment settings required by utilities
# # that run in ENV.  
# ----------------------------------------------------------------

[[ -z "${BT}" ]] && { BT="${HOME}/.bt"; export BT="${BT}" ;} || true

to_debug flow && echo env:state || true

# Establish vars that comprise the env state.
#
env_state()  { 

  [[ -z "${BT}" ]] && { BT="${HOME}/.bt"; export BT="${BT}" ;}

  #include api
  export BT_USR="$(echo "${USER}")"
  # note: used for assertions, derived from 'bt_peek'.
  export BT_GUILD="NONE"

  # set the account file.
  AWS_CREDS_DEFAULT="${HOME}/.aws/bt_creds"
  AWS_CFG_DEFAULT="${HOME}/.aws/bt_config"

  # set default aws configs.
  [[ -z "${BT_ACCOUNT}"            || \
     "${BT_ACCOUNT}" == "NONE"     || \
     "${BT_ACCOUNT}" == "qa"       || \
     "${BT_ACCOUNT}" == "prod"     || \
     "${BT_ACCOUNT}" == "identity" ]] && { 
    
    AWS_CREDS="${AWS_CREDS_DEFAULT}" 
    AWS_CFG="${AWS_CFG_DEFAULT}" 
  }

  #  Testing, for now.
  AWS_CREDS="${AWS_CREDS_DEFAULT}.${BT_ACCOUNT}" 
  AWS_CFG="${AWS_CFG_DEFAULT}.${BT_ACCOUNT}" 
  to_debug env echo AWS_CFG: "${AWS_CFG}"
  to_debug env echo AWS_CREDS: "${AWS_CREDS}"

  # sso 
  export QV_REGION=us-west-2
         QV_URL=https://qventus.awsapps.com/start

  # settings
  export AWS_CONFIG_FILE="${HOME}/.aws/bt_config"
  export AWS_SHARED_CREDENTIALS_FILE="${HOME}/.aws/bt_creds"

} || true

#env_state || true

to_debug flow && echo env:cache || true

env_cache() { 

  [[ -z "${BT}" ]] && { BT="${HOME}/.bt"; export BT="${BT}" ;}
  declare -a files=( ${@:1} )
  
  umask 0077

  [[ ! -d "${BT}/cache" ]] && { 
  export BT_CACHE="${BT}/cache"
  mkdir -p ${BT_CACHE} && export BT_CACHE=${BT_CACHE}
  to_debug cche echo "cache dir: ${BT}/cache"

  # copy paths passed in.
  for FILE in ${files[@]}; do 
    to_debug cche echo copying "${FILE##*/} to ${BT_CACHE}"
    [[ -f "${FILE}" ]] && { 
        caching ${FILE} 
        cp "${FILE}" "${BT}/cache/${FILE##*/}"
    } || { 
      echo "${FILE##*/} is not a file, or could not be copied."
    }
  done

  umask 0022

  }
} || true 

#env_cache || true

env_fuzz() { 

  export AWS_FUZZ_USE_CACHE=yes                     \
         AWS_FUZZ_PRIVATE_IP=true                   \
         AWS_FUZZ_USER="${USER}"                    \
         AWS_FUZZ_CACHE_EXPIRY=0                    \
         AWS_FUZZ_SSH_COMMAND_TEMPLATE="ssm {host}" \
         AWS_FUZZ_REGIONS="${AWS_REGION}" 

} || true

#env_fuzz || true 
to_debug flow && echo env:fuzz  || true

## ----------------------------------------------------------------
## AWS ENVIRONMENT VARS
## ----------------------------------------------------------------
# Qventus has a complicated set of AWS environment
# variables used to standardize its AWS deployments. 
# 
# Changing some of these can have difficult ramifications
# unless you know what you're doing. Where necessary, 
# the Security Team has added notes to explain some of
# the gotchas.  

# Truth be told, it's best if you do not monkey with 
# these too much unless you understand what you're doing. 
# 
#                        --- The QV Security Team 
env_aws() { 

  #source "${BT}/lib/aws" 
  #aws_defaults

  AWS_CONFIG="${BT_CONFIG}"
  AWS_CREDS="${BT_CREDS}"
  # aws files.
  export AWS_CONFIG_FILE="${AWS_CONFIG}"                            \
         AWS_SDK_LOAD_CONFIG=1                                      \
         AWS_SHARED_CREDENTIALS_FILE="${AWS_CREDS}" 

  # aws-sso-credential-process 
  # when run on a headless system; credential_process captures 
  # stdout and stderr, so the URL and code that are printed out 
  # for use when the browser popup do not appear to the user.
  export AWS_SSO_INTERACTIVE_AUTH=true

  # AWS VARS - You should not need to touch these.
  export AWS_VAULT_PL_BROWSER=com.google.chrome 
  export AWS_DEFAULT_OUTPUT=json
  export AWS_SSO_CREDENTIAL_PROCESS_DEBUG=true 
  export AWS_CONFIGURE_SSO_DEFAULT_SSO_START_URL=${qv_start_url} 
  export AWS_CONFIGURE_SSO_DEFAULT_SSO_REGION=${qv_gbl} 
  export AWS_LOGIN_SSO_DEFAULT_SSO_START_URL=${qv_start_url} 
  export AWS_LOGIN_SSO_DEFAULT_SSO_REGION=${qv_gbl} 
  export AWS_DEFAULT_SSO_START_URL=${qv_start_url} 
  export AWS_DEFAULT_SSO_REGION=${qv_gbl} 
  export AWS_DEFAULT_REGION=${qv_gbl} 
  export AWS_REGION=${qv_gbl}
} || true

#env_aws || true

to_debug flow && echo env:set_team || true 

to_debug flow && echo env:init || true

env_init() { 

  # Initialize our most important ENV vars:
  [[ -z "${BT}" ]] && { BT="${HOME}/.bt"; export BT="${BT}" ;}
  to_debug env echo "env:init:BT ${BT}"

  # env_init is called by autologin. 
  # Something is wrong if we don't have an AWS ENV by now.
  env_aws
  env_state
  env_cache
  env_fuzz
  [[ -z "${AWS_CONFIG_FILE}" ]] && { echo "No aws config. Exiting..." ;}

  # ROLE, TEAM, ACCOUNT.
  # if not set, check cache and profiles.
  ARGV="${1:-"${DEFAULT_ROLE}"}"
  
  # check ~/.aws/bt_config 
  # This file is an authority, and can be recreated.
  role="$(cat "${AWS_CONFIG_FILE}"                           | \
          perl -nle "print if s/(${ARGV}\]|role_arn.*)/\1/;" | \
          grep -EA 1 "${ARGV}\]" | tail -n 1                 | \
          perl -nle 'print if s/.*qv\-gbl\-([\w_\-]+)/\1/'   )"
  to_debug lgin echo role: $role
  # if request is not valid, report an error. 
  [[ -z "${role}" || "${role}" == *- || "${role}" = *NONE* ]] && { 
    echo -e "${RED}FATAL${NC}: \"${role}\" is not a configured destination."
    echo -e "Try rebuilding your aws config by running \"${CYAN}profiles${NC}\"".
    return
  }
 
  to_debug env && echo DEFAULT_ROLE: "${DEFAULT_ROLE}"
  [[ "${role}" == "${DEFAULT_ROLE}" ]] && {  
    export BT_ROLE="${DEFAULT_ROLE}"
  }

  # need to validate BT_TEAM.
  set_team
  if [ -f "${BT}/cache/team_info" ]; then
    team="$(cat "${BT}/cache/team_info")"
  else 
    team="NONE"
  fi

  if ! [[ "${team}" =~ NONE         ]] && 
     ! [[ "${team}" =~ [^a-zA-Z0-9] ]] &&
       [[ -n "${team}"              ]]; then 
    # cache worked.
    BT_TEAM="${team}" 
    export BT_TEAM="${BT_TEAM}"
  else  
    # cache did not work. Warn the user to fix the problem.
    rm -rf "${BT}/cache/team_info"
    echo -e "----------------------------" 
    echo -e "${YELLOW}WARNING${NC}: team not set." 
    echo -e "Please run 'profiles' again."
    echo -e "----------------------------" 
  fi 

  # account needs more vetting. 
  declare -a ROLE
  ROLE=( $(echo "${role}" | tr '-' ' ') )  
  to_debug env echo ACCOUNT: "${ROLE[0]}" TEAM: "${ROLE[1]}"
  [[ "${#ROLE[@]}" -ne 2 ]] && {
    echo -e "${RED}FATAL${NC}: ROLE: \"${role}\" does not seem to have a valid format."  
    echo -e "It must be of the form ${BLUE}<account>-<team>${NC}, e.g. \"prod-dp\"."
  } || { 
    export BT_ACCOUNT="${ROLE[0]}" BT_TEAM="${ROLE[1]}" BT_ROLE="${ROLE[0]}"-"${ROLE[1]}"
  }


  to_debug env && echo env_init:BT_TEAM: "${BT_TEAM}"
  to_debug env && echo env_init:BT_ACCOUNT: "${BT_ACCOUNT}"
  to_debug env && echo env_init:BT_ROLE: "${BT_ROLE}"
  to_debug flow && echo env_init:end 
  
} || true

env_init || true


# ---------------------------------------------------------
# dirs, vars, & libs.
# ---------------------------------------------------------

get_sso() { echo "${USER}" ;} || true




# ---------------------------------------------------------
# libs
# ---------------------------------------------------------



# SANITY FUNCTIONS
# -----------------
# Should be run by all generators, and scripts. 
# 
env_sanity() { 

  # prevent running as root on MacOS. 
  # Uses ${HOME} to figure out the user name,
  # then queries AWS SSO to look up user's group.
  BT_OS="$(uname -a | awk '{print $1}')"
  [[ "${BT_OS}" == "Darwin" && "$(id -u)" == "0" ]] && { 
    echo -ne "\n\n----------------------------------\n"
    echo -ne     "This script cannot be run as root.\n"
    echo -ne     "Please run as your regular user.  \n"
    echo -ne     "----------------------------------\n\n"
    read -r -n1
    return 1
  }

  # sso and team state.
  [[ -z "${BT_USR}" && "${BT_OS}" == "Linux" ]] && { 
    echo -ne "WARN: Could not find critical variables: "
    echo -ne "${RED}USR${NC}\n" 
  } 

  #debug BINTOOLS: ${BT}\nTEAM:     ${BT_TEAM}\nAWS_ENV:    \n"$(env | grep AWS_)"

} || true

#env_sanity || true

to_debug flow && echo env:sanity || true


# ---------------------------------------------------------------
# MINI-API
# --------------------------------------------------------------

  # Need a function that returns an array of strings
  # for each of these. Use json objects. 
  # -- Pass in a value, get back a num. 
  # -- pass in a role, get back the type.
  # -- pass in a team, get back whether delegated or primary. 
  # -- Get list of primaries or delegates from all accounts. 

# list elements.
function _all() {
  # guilds, roles, teams, delegated, primary, usrs (later), rds, inst 
  
    "${1:="NONE"}"
    case "${1}"    in 
      guilds)      ;; 
      roles)       ;; 
      teams)       ;; 
      usrs)        ;; 
      delegated)   ;; 
      primary)     ;; 
      role_types)  ;; 
      rds)         ;;
      inst)        ;;
    esac
    # echo space delimited list of words
} || true



# function: _is
# -----------------------
# Tests group membership.
#
# Usage: _is primary <role>   
#         _is <type>  <element>
#
# Looks up current role in a list of primary roles.
# 
# NOTE: all types are keywords
# 
function _is() { 

    "${1:="NONE"}"  # type
    "${2:="NONE"}"  # element

    case "${1}" in 
      guild)        ;; 
      account)      ;; 
      primary)      ;; 
      delegated)    ;; 
      team)         ;; 
      role)         ;; 
      inst)         ;; 
      usr)          ;; 
      rds)          ;;
    esac
        
    return 0 
} || true



# function: _get
# -----------------------
# Tests group membership.
#
# Usage: _get account prod
#        _get <type>  <name>
# Returns json with {<name>: <element>}
#
# Looks up named item in a json array of items.
# NOTE: all types are keywords
# 
function _get() { 
  debug "role_types: " && declare -p role_types

    "${1:="NONE"}"  # type
    "${2:="NONE"}"  # element

    case "${1}" in

      users)          obj="users"        ;; 
      teams)          obj="teams"        ;; 
      roles)          obj="roles"        ;; 
      guilds)         obj="guilds"       ;; 
      accounts)       obj="accounts"     ;; 
      primaries)      obj="primaries"    ;; 
      delegated)      obj="delegated"    ;; 
      instances)      obj="instances"    ;; 
      rds_clusters)   obj="rds_clusters" ;;
      role_types)     obj="role_types"   ;;

    esac

  OBJ="${BT}/data/json/bt/${obj}.json"    
  JQ_STR='| to_entries[] | select( "$name" )'
  CMD="$(printf '.%s %s' "${obj}" "${JQ_STR}")"

  echo cat "${OBJ}" | jq --arg name "${2}" "${CMD}"

  #all_accounts = (unrestricted + restricted)
  #accounts = unrestricted
  # ${all_accounts[*]}
} || true



## ----------------------------------------------------------------
## AWS SETTINGS
## ----------------------------------------------------------------
## Qventus has a lot of infrastructure in AWS. This library
## contains streamlined functions to make that environment
## is easy to work with. 

# Set and unset AWS_PROFILE.
# --------------------------
# Uses the 'aws configure list-profiles' command for 
# validation (also has auto-completion routines, which 
# are a bit slow).
#
aws_profile () {
  DEFAULT_ROLE="prod-${BT_TEAM}"
  ARGV="${1:-"${DEFAULT_ROLE}"}"  
  if [ "$ARGV" = "--help" ] || [ "$1" = "-h" ]; then
    echo "USAGE:"
    echo "aws_profile              <- print out current value"
    echo "aws_profile PROFILE_NAME <- set PROFILE_NAME active"
    echo "aws_profile --unset      <- unset the env vars"
  elif [ -z "$ARGV" ]; then
    if [ -z "$AWS_PROFILE$AWS_DEFAULT_PROFILE" ]; then
      echo "No profile is set"
      return 1
    else
      to_debug aws echo "profile: $AWS_PROFILE default: $AWS_DEFAULT_PROFILE\n"
    fi
  elif [[ "$ARGV" = "--unset" ]]; then
    AWS_PROFILE=
    AWS_DEFAULT_PROFILE=
    # needed because of https://github.com/aws/aws-cli/issues/5016
    export -n AWS_PROFILE AWS_DEFAULT_PROFILE
  elif [[ "$ARGV" = *${DEFAULT_ROLE}* ]]; then 
      export AWS_PROFILE=${ARGV} AWS_DEFAULT_PROFILE=${ARGV}
  
  elif [[ "$ARGV" =~ "${BT_TEAM}" ]]; then
    # needed because of https://github.com/aws/aws-cli/issues/5546
    declare -a profiles=()
    for p in $(aws configure list-profiles); do
        profiles+=( "${p}" )
    done    
    for o in ${profiles[@]}; do 
      [[ "${ARGV}" !=  "${p}" ]] && { 
        continue
      } || {
        debug_on env && echo matched: "${p}"
        export AWS_PROFILE="${p}" AWS_DEFAULT_PROFILE="${p}"
        return 
      }
    done
  else
    echo "${ARGV} is not currently a valid profile."
  fi
} || true
    


## ----------------------------------------------------------------
## AWS ENVIRONMENT VARS
## ----------------------------------------------------------------
# Qventus has a complicated set of AWS environment
# variables used to standardize its AWS deployments. 
# 
# Changing some of these can have difficult ramifications
# unless you know what you're doing. Where necessary, 
# the Security Team has added notes to explain some of
# the gotchas.  

# Truth be told, it's best if you do not monkey with 
#                        --- The QV Security Team 

to_debug flow && echo env:aws_defaults || true

#aws_defaults || true

to_debug flow && echo env:aws_profile  || true
aws_profile "${DEFAULT_ROLE}" || true


# unattended login
autologin() { 

  [[ -z "${BT}" ]] && echo "FATAL: BT var not set." && exit 1

  # get path. 
  # try cache first.
  [[ ! -f "${BT}"/cache/path_info ]] && {
    "${BT}"/utils/path -s 2>/dev/null | tee "${BT}/cache/path_info"
  }
  source <(echo "$("${BT}"/utils/path -s 2>/dev/null)" )

  # fail loudly if path isn't getting set.
  PATH_FAIL="$(echo ${PATH} | perl -pe 's/:/\n/g' | grep "\.local/bin")"
  [ -z "${PATH_FAIL}" ] && echo -e "${RED}FATAL${NC}: Bin2ools PATH not set."

  # fall back to aws-sso-util when devops isn't available.
  export AWSLIB="devops"
  # if devops-sso-util is not installed, use aws-sso-util.
  [[ ! -e "${HOME}/.local/bin/${AWSLIB}-sso-util}" ]] && {
    export AWSLIB="aws"
    export DEFAULT_AWSLIB="${AWSLIB}-sso-util"
  }

  # set AWS config.
  [[ -z "${AWS_CONFIG_FILE}" ]] && \
      export AWS_CONFIG_FILE="${HOME}/.aws/bt_config"
  [[ -z "${AWS_SHARED_CREDENTIAL_FILE}" ]] && \
      export AWS_SHARED_CREDENTIAL_FILE="${HOME}/.aws/bt_creds"

  # set team
  set_team 
  if [[ -z "${BT_TEAM}"              ]] || \
     [[ "${BT_TEAM}" =~ [^a-zA-Z0-9] ]] || \
     [[ "${BT_TEAM}" = *NONE*        ]]; then
     echo -ne "${RED}FATAL${NC}: Missing Team var. \n"
     echo -ne "Please rerun: ${PURPLE}~/.bt/gen/profiles${NC} and \n"
     echo -ne "try again.\n\n"
     exit 1
  fi 

  export DEFAULT_ROLE="${DEFAULT_ACCOUNT}"-"${BT_TEAM}"
  # set account (or use default.)
  export DEFAULT_ACCOUNT="prod"
  [[ -z "${BT_ACCOUNT}" ]] && { export BT_ACCOUNT="${DEFAULT_ACCOUNT}" ;}
  
  
  # set role.
  [[ -n "${DEFAULT_ACCOUNT}" && -n "${BT_TEAM}" ]] && {
      [[ -z "${BT_ROLE}" ]] && { 
        export DEFAULT_ROLE="${DEFAULT_ACCOUNT}-${BT_TEAM}"
      } 
  } 
  #ACCT_ID="$(find_in_accounts "${BT_ACCOUNT}" | awk '{print $2}')"
 

  env_init
  #to_debug flow && echo api:autologin:env_init.

  # look for expired creds.
  raw="$("${DEFAULT_AWSLIB}" check 2>&1)" 
  to_debug lgin echo raw check output: "${raw}"

   [ -z "${sso}" ] && {
         cmd="$("${DEFAULT_AWSLIB}" login --profile "${BT_TEAM}")"
         ts="$(echo "$cmd" | perl -nle \
               'print if m/20\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ/')"
   }

  sso="$(echo "${raw}" | tail -n 1 | \
      perl -nle 'print if s/.*(20\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ|fix|expired).*/\1/')"

  to_debug lgin echo sso: ${sso}
  to_debug lgin echo "BT_ROLE: ${BT_ROLE} BT_ACCOUNT: ${BT_ACCOUNT} BT_TEAM: ${BT_TEAM}" 

  # Refresh just the sso token (12 hour lifespan). Collect the new expire time. 
  # NOTE: Format can be different for iam.
  case "${sso}" in 

      expired)
        cmd="$("${DEFAULT_AWSLIB}" login --profile "${BT_TEAM}")" 
        ts="$(echo "$cmd" | perl -nle \
              'print if m/20\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ/')"
        ;; 

      fix)  
        cmd="$("${DEFAULT_AWSLIB}" login --force-refresh --profile "${BT_TEAM}")" 
        ts="$(echo "$cmd" | perl -nle \
            'print if s/.* (20\d\d-\d\d-\d\d \d\d\:\d\d.*)/\1/')"
        ;;

      *) ts="${sso}"
         ;;

  esac

  to_debug lgin && echo -ne "VARS: cmd: |$cmd| ts: |$ts| sso: |$sso|\n"
  #[[ -z "${ts}" ]] && echo -e "${YELLOW}WARNING${NC}: Timestamp not parsed."

  t="$(echo "${ts}" | ddiff -E -qf %S now)"
  to_debug lgin echo ts: $ts sso: $sso cmd: $cmd

  [[ -n "$t" && "$t" =~ [0-9]+ && "$t" -gt 0 ]] && { 
    X="$(gdate --utc -d "0 + ${t} seconds" +"%Hh:%Mm:%Ss")"
  } 
  to_debug lgin echo "ts:$ts, t:$t, X:${X} R:${BT_ROLE}"
  export ts=${ts} t=${t} X=${X} R=${BT_ROLE} 

  # Fail hard if setting BT_ROLE fails, as might be
  # the case with new accounts in multi-account.
  if aws_profile "${BT_ROLE}" >/dev/null 2>&1; then 
     to_debug lgin echo profile set to: ${BT_ROLE}   
  else 
    echo "Could not set profile to: ${BT_ROLE}."
    echo "Please rerun the 'profiles' command."
    return
  fi

  ppt  # build a dynamic prompt.
  return
}
to_debug flow && echo api:autologin.end || true

to_debug flow && sleep 0.5 && echo env:end || true
#!/usr/bin/env  /usr/local/bin/bash

die() { echo "$*" >&2; exit 2; }

needs_arg() { if [ -z "$OPTARG" ]; then die "No arg for --$OPT option" && usage; fi; }

to_err() { >&2 echo "$@"; }

os=$(uname -s) && [ "${os}" == "Darwin" ] && b64=gbase64 || b64=base64

log() { echo -e ${@} | tee -a ${log}; }

debug() { [ ! -z "${debug}" ] && >&2 log ${@}; }

silent_pushd() { builtin pushd "$@" > /dev/null; }

get_tags() { 
    __key=$1
    aws ssm list-tags-for-resource \
        --region "${aws_region}" \
        --resource-type "Parameter" \
        --resource-id "${__key}" | \
    jq -r '.TagList[] | (.Key+"|"+.Value)'
} 

put_tag() { 
    __key=$1
    __tag=$2
    __val=$3
    BASE="aws ssm add-tags-to-resource \
        --resource-type Parameter \
        --resource-id " 
    ARGS="\"${__key}\" --tags Key=\"${__tag}\",Value=\"${__val}\""
    CMD="${BASE} ${ARGS}"
    [ ! -z ${dry_run} ] && echo ${BASE} ${ARGS} && exit 0
    eval ${CMD} && echo success || echo fail
} 

del_tag() { 
    __key=$1
    __tag=$2
    aws ssm remove-tags-from-resource \
    --resource-type "Parameter" \
    --resource-id "${__key}" \
    --tag-keys "${__tag}" && \
    echo success || echo fail

}

# Rules for encoding:
# 1.) if payload is one line only, we pass through.
#     This is the case, e.g., for ssh private keys that
#     have had newlines removed, passwords, and previously
#     encoded templates passed from stdin.)
# 2.) if payload contains multiple lines, we encode by
#     gzipping then base64 encoding the full text. This is
#     useful for encoding template files. In reverse, we do
#     the opposite, e.g. gunzip, then base64 decode. We also 
#     tag any encoded key (see tag_* functions).
# 3.) if the key is tagged with 'encoding:lines_to_spaces',
#     keys are removed by the decode() function.
#
# error correction:
# This function throws an error if a payload is too big to 
# fit into a key (see AWS standards). Later: We will split
# these into multiple files.
#
ssm_encode() {
    #IFS='%%'
    local  __key=$1
    local  __payload=$2
    local  __encoding=$3
    key=${__key}
    payload=${__payload}
    
    # prefer explicit encoding, if given.
    if [ ! -z ${__encoding} ]; then 
        encoding="${__encoding}"
    fi

    # fall back to existing encoding.
    if [ ${encoding} == "" ]; then
        exists=$(aws ssm get-parameter --name "${key}" && echo success || echo fail)
        if [ "${exists}" == "success" ]; then 
            declare -A tags
            while IFS='|' read -r k v; do
                tags[$k]=$v
            done < <(get_tags ${key})
        fi
        encoding=${tags['encoding']}
    fi
   
    # use 'raw' as a default
    if [ -z ${encoding} ]; then
        encoding="raw"
    fi

    lines=$(echo "${payload}" | wc -l)
    chars=$(echo "${payload}" | wc -c)
    to_err key: ${key} payload - lines: $lines, chars $chars

    if [[ $lines -ge 2 && ${encoding} == "raw" ]]; then 
        die "ERROR: ${key} has multiple lines.  It cannot be encoded as 'raw'."
    fi
    if [[ $chars -ge 8192 && ${encoding} != "gz+b64" ]]; then 
        die "ERROR: ${key} has more than 8192 chars. Encoding must be 'gz+b64'."
    fi
    
    if [ "${encoding}" == 'raw' ]; then     
        encoded=${payload}
    elif [ "${encoding}" == 'newlines_to_spaces' ]; then 
        encoded=$(echo "${payload}")
    elif [ "${encoding}" == 'gz+b64' ]; then
        encoded=$(echo "${payload}" | gzip | ${b64})
    else
        to_err "WARNING: Unrecognized encoding: ${encoding}. Using raw."
        encoded=${payload}  # for bad encodings.
    fi 

    echo "${encoded}"
}

# See rules for encoding, above. 
# If a key is tagged with an encoding of 'newlines_to_spaces', then 
# lines are returned upon decoding. key_dump, in contast, returns 
# a single line suitable for file dumps. 
#
ssm_decode() { 
    local  __key=$1
    local  __payload=$2
    local  __encoding=$3
    key=${__key}
    payload=${__payload}
   
    # prefer explicit encoding, if given.
    if [ ! -z ${__encoding} ]; then 
        encoding="${__encoding}"
    fi
   
    # prefer explicit encoding, if given.
    if [ ! -z ${__encoding} ]; then 
        encoding="${__encoding}"
    fi

    # fall back to existing encoding.
    if [ -z ${encoding} ]; then 
        exists=$(aws ssm get-parameter --name "${key}" && echo success || echo fail)
        if [ "${exists}" == "success" ]; then 
            declare -A tags
            while IFS='|' read -r k v; do
                tags[$k]=$v
            done < <(get_tags ${key})
        fi
        encoding=${tags['encoding']}
    fi
   
    # use 'raw' as a default
    if [ -z ${encoding} ]; then
        encoding="raw"
    fi

    # decode
    if [ "${encoding}" == 'raw' ]; then     
        decoded=${payload}
    elif [ "${encoding}" == 'newlines_to_spaces' ]; then 
        decoded="$(echo -ne ${payload} | \
        perl -pe '! s/ (?!(PRIVATE|KEY|RSA|END|OPENSSH|BEGIN|KEYBEGIN|CERTIFICATE|OPENSSH))/\n/g')"
    elif [ "${encoding}" == 'gz+b64' ]; then
        decoded=$(echo ${payload} | ${b64} -d -i | gzip -d)
    else
        :
    fi 

    echo "${decoded}"

}

arg_parse() { 

        # Each host is tagged as part of a designated environment. 
        # get my instance_id 
        TOKEN=$(curl -qs --connect-timeout 2 \
               -X PUT "http://169.254.169.254/latest/api/token" \
               -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
        instance_id=$(curl -qs --connect-timeout 2 \
                     -H "X-aws-ec2-metadata-token: $TOKEN" \
                     http://169.254.169.254/latest/meta-data/instance-id)
        ( 
            [ -z "${instance_id}" ] && \
            to_err "WARN: failed to get instance_id for this host." && \
            exit
        ) 
        
	stack=$(aws ec2 describe-tags \
        --filters "Name=resource-id,Values=${instance_id}" | \
        jq -r '(.Tags[]|select(.Key=="qventus:stack")|.Value)')
    to_err setting stack to: ${stack}
   
    if [ "${help}" == "true" ]; then 
        usage
    fi

    rgx='^/'
    if [[ ! -z "${key}" && "$key" =~ "${rgx}" ]]; then 
        to_err "ERROR: key is not of the proper format."
        usage
    fi 
} 

# Compare the contents of an ssm key to that of a file.
# Report differneces as a diff.
#
compare() {
    dir="${BASH_SOURCE%/*}"
    if [[ ! -d "${dir}" ]]; then dir="$PWD"; fi

    # note: we remove the final newline, for consistency.
    diff -B \
      <(${dir}/../key_get -k "${1}" 2> /dev/null | perl -pe 'eof&&chomp') \
      <(cat "${2}" | perl -pe 'next if /^\s*$/; eof&&chomp')
}

# dependencies: jq, svn, moretools
# check deps - note: ts = moreutils.
deps() {

    declare -a deps=("jq" "ts")
    for dep in ${deps[@]}; do
        if ! command -v ${dep} >/dev/null 2>&1 ; then
            echo ${dep} not installed! | log
            exit 1
        fi
    done
    
}

set_path() {
    shopt -s expand_aliases
    shopt -s progcomp_alias
    source <(path -s -x 2>/dev/null)
}

