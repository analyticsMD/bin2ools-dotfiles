#!/usr/bin/env /usr/local/bin/bash
# shellcheck shell=bash

to_debug flow && sleep 0.5 && echo rds:start

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
}

to_debug flow && echo rds:rds_usage

mysql_help() { 

  echo "mysql client help here."
} 

to_debug flow && echo rds:mysql_help

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
  h="$(echo "${stats}" | cut -d'%' -f 1)"
  in="$(echo "${stats}" | cut -d'%' -f 2)"
  t="$(echo "${stats}" | cut -d'%' -f 3)"
  p="$(echo "${stats}" | cut -d'%' -f 4)"
  e="$(echo "${stats}" | cut -d'%' -f 5)"

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

}

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
}

to_debug flow && echo rds:split_rds_args


# Returns the common name of the 
# target RDS cluster (writer endpoint). 
get_db_target() { 
  [[ -n "${args[0]}" ]] && { 
    echo "${args[0]}" 
  } || { 
    echo "NONE"
  } 
} 

to_debug flow && echo rds:get_db_target


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

}

to_debug flow && echo rds:get_rds_args


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
}  

set_iam_user() { 
  echo "dba_guild"
}

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
}


set_tunnel_user() { 

  [[ "${BT_TEAM}" == "arch" && \
     "${BT_method}" = ssh-*  ]] && { 

    export BT_tunnel_user=ec2-user
  } || { 
    export BT_tunnel_user=ssm-user
  } 

  echo "${BT_tunnel_user}"
} 


# Connection method: Pure ssm.
# ----------------------------
# Uses ssm for tunneling, and for forwarding. 
# ssm forwarder is a 'cocat' command, so not 
# completely ssm based, but pretty close.
# 
pure_ssm() { 

 true  
 #mkdir -p ~/.ssh/sockets && chmod 0700 ~/.ssh/sockets

}  


# Connection method: ssh tunnel - VPN style.
# ------------------------------------------
ssh_vpn() { 

  : # will add soon.  

} 

ssh_master_socket() { 

  : # will add soon. 

}

# create a temporary path for use with 
# session data of various sorts. 
#
get_tmppath() { 

  tmppath="$(gmktemp -p "${HOME}"/tmp rds.XXXXXXXXXXXX)"

  echo "${tmppath}"
} 

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
}
 
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
}  

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
} 

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

} 



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
}  


wipe_ssm_ports() { 
  port=${1:-"33"} 
  signal=${2:-"QUIT"}
  echo kill -s ${signal}             \
      $(ps -A                 | \
        grep "[p]ortNumber=" | \
        grep "${port}"        | \
        awk '{print $1}'     | \
        perl -pe 's/\n/ /')
}
   
wipe_mysql_listeners() { 
  port=${1:-"33"} 
  signal=${2:-"QUIT"}
  kill -s ${signal}        \
      $(lsof -i -P -n         | \
        grep -i "[l]isten"   | \
        grep "${port}"        | \
        awk '{print $2}'     | \
        perl -pe 's/\n/ /'    )
}

#netstat -an | grep -i listen | grep -E '\.33\d\d'

autoclean() { 
  echo "Current socket state: "
  show_all_ports
}

socket_peek() { 
  while read -ra sock; do 
    set '__' $sock 
    name="${1:-""}" pid="${2:-""}" port="${3:-""}" st="${4:-""}"
  done< <(show_all_ports)
} 



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

}

to_debug flow && echo rds:close_socket || true
to_debug flow && sleep 0.5 && echo rds:end || true


