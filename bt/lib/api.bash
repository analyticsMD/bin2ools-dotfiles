#!/usr/local/bin/bash

export BT=${HOME}/.bt
to_debug flow && sleep 1 && echo api:_

to_debug() { [[ "${BT_DEBUG}" = *$1* ]] && >&2 "${@:2}" ;}
#export BT_DEBUG=lgin


# Set and unset AWS_PROFILE.
# --------------------------
# Uses the 'aws configure list-profiles' command for 
# validation (also has auto-completion routines, which 
# are a bit slow).
#
aws_profile() {
  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    
    echo "aws_profile              <- print out current value"
    echo "aws_profile PROFILE_NAME <- set PROFILE_NAME active"
    echo "aws_profile --unset      <- unset the env vars"
  elif [ -z "$1" ]; then
    if [ -z "$AWS_PROFILE$AWS_DEFAULT_PROFILE" ]; then
      echo "No profile is set"
      return 1
    else
      echo "$AWS_PROFILE$AWS_DEFAULT_PROFILE"
    fi
  elif [ "$1" = "--unset" ]; then
    AWS_PROFILE=
    AWS_DEFAULT_PROFILE=
    # needed because of https://github.com/aws/aws-cli/issues/5016
    export -n AWS_PROFILE AWS_DEFAULT_PROFILE
  else
    # needed because of https://github.com/aws/aws-cli/issues/5546
    if ! aws configure list-profiles | grep -s "$1"; then
      echo "$1 is not a valid profile"
      return 2
    else
      export AWS_PROFILE=$1 AWS_DEFAULT_PROFILE=$1
    fi;
  fi;
}

to_debug flow && sleep 1 && echo api:aws_prof


# prove you have perms.
perms() {
  login="$(aws sts get-caller-identity 2>/dev/null  | \
           jq -r '.Arn'                             | \
           cut -d':' -f 5-7                         | \
           perl -pe 's/(.*)\/[^\/]+/\1/')"
  [ -z "$login" ] && { 
    echo -e Failed && return 1
  } || { 
    echo -e "${login}"
  }
}

to_debug flow && sleep 1 && echo api:perms

get_account() {
  this_peek | jq -r '.account | to_entries[] | select(.key|tostring) | "\(.key)"'
}

to_debug flow && sleep 1 && echo api:perms
to_debug lgin echo "id: ${ACCT_ID} ts: $ts secs: $t left: $T" 

regen_qv_stub() { 

    [[ -n "${AWS_SHARED_CREDENTIALS_FILE}" ]] && {
      CREDS="${AWS_SHARED_CREDENTIALS_FILE}"
      perl -pe '\n\n[qventus]\n  
              manager = awsume\n
              region = us-west-2/\n\n/g' >> "${CREDS}"
    }
    #stash_creds
} 

to_debug flow && sleep 1 && echo api:regen_qv_stubs

# unset all sessions and settings.
# --------------------------------
# This is critical, and if skipped will 
# cause major inconsistent behavior in 
# role chaining routines. 
# NOTES on aws-vault credential processes:
# https://github.com/99designs/aws-vault/blob/master/USAGE.md#environment-variables
#
wipe () { 
  #stash_creds  # broken. copies wrong file. 
  #cat "${BT}/cfg/bt_creds.ini" > ~/.aws/bt_creds
  devops-sso-util logout  > /dev/null 2>&1
  # remove expired creds from cli, awsume caches
  rm -rf "${HOME}"/.aws/sso/cache/*
  rm -rf "${HOME}"/.aws/cli/cache/*
  #regen_creds 
  rm -rf "${HOME}"/.awsume/cache/*
  awsume --unset > /dev/null 2>&1
  aws_profile --unset
  unset AWSUME_PROFILE AWSUME_DEFAULT_PROFILE AWS_PROFILE AWS_DEFAULT_PROFILE
  # check we have no stale identities remaining.
  aws-whoami >/dev/null 2>&1 || echo "no identities left."
  devops-sso-util check >/dev/null 2>&1
  echo "all cached sessions removed."
}

to_debug flow && sleep 1 && echo api:wipe

check_login_status() { 

  to_debug() { [[ "${BT_DEBUG}" = *$1* ]] && >&2 "${@:2}" ;}

  to_debug flow && sleep 1 && echo api:autologin.check.loader
  #to_debug flow && sleep 1 && echo api:autologin.check.main

  [[ "${BT_ACCOUNT}" == "NONE" || \
     "${BT_TEAM}"    == "NONE" ]] && {
    to_err "bad ENV settings." && return 1
    to_debug flow && sleep 1 && echo api:autologin.check.bad_vars1
  } 
  
  [[ -z "${BT_ACCOUNT}" || \
     -z "${BT_TEAM}"    ]] && {
    to_err "bad ENV settings." && return 1
    to_debug flow && sleep 1 && echo api:autologin.check.bad_vars2
  } 

  ACCT_ID="$(find_in_accounts "${BT_ACCOUNT}" | awk '{print $2}')"
  
  to_debug flow && sleep 1 && echo api:autologin.check.expires
  ts="$(devops-sso-util check \
      -a "${ACCT_ID}"       \
      --role-name "${BT_ACCOUNT}-${BT_TEAM}" 2>&1 | \
      perl -nle 'print if s/.*expiration: ([\w\-\: ]+)/$1/')"
  t="$(echo "$ts" | ddiff -E -qf %S now)" 

  [[ "${t}" -lt 59 ]] && { t=0 ;}

  declare -a T=() 
  for n in $(bc <<< "s=$t%60;h=$t/3600;m=($t-(h*3600)-s)/60;h;m;s"); do
    T+=( "$n" ) 
  done

  X="$(printf "(%02d)h:(%02d)m:(%02d)s" "${T[0]}" "${T[1]}" "${T[2]}")"
  #to_debug echo "ts:${ts} t:${t} T:${T} X:${X}"
  to_debug flow && sleep 1 && echo api:autologin.check.post_expires

  # role auth
  [[ -n "${BT_ACCOUNT}" && "${t}" -gt 5 ]] && { 
      echo "expires: ${GREEN}${X}${NC}" && return  
    } || { 
      echo "${RED}expired.${NC}" && return
    }
}

to_debug flow && sleep 1 && echo api:check_login_status
  
# unattended login
autologin() { 
  echo -ne "LOGIN: "

  to_debug flow && sleep 1 && echo api:autologin
  env_init
  to_debug flow && sleep 1 && echo api:autologin:env_init..
  
  [[ "${BT_TEAM}" == "NONE" || \
      -z "${BT_TEAM}"       ]] && { 
     echo "Failed to find a Team. Please rerun ~/.bt/gen/profiles"
     exit 1
  } 
  
  [[ "${BT_ACCOUNT}" == "NONE" || \
      -z "${BT_ACCOUNT}"       ]] && { 
     export BT_ACCOUNT="prod"  # default for now. 
     export BT_ROLE="${BT_ACCOUNT}-${BT_TEAM}"
  }
  to_debug flow && sleep 1 && echo api:autologin.

  status="$(check_login_status >2/dev/null)"  
  to_debug lgin echo status: $status
  to_debug flow && sleep 1 && echo api:autologin.check

  [[ $status = *expired* ]] && {  
    awsume --unset > /dev/null 2>&1
    aws_profile --unset
    unset AWSUME_PROFILE AWSUME_DEFAULT_PROFILE AWS_PROFILE AWS_DEFAULT_PROFILE
    to_debug lgin echo "BT_ROLE: ${BT_ROLE} BT_ACCOUNT: ${BT_ACCOUNT} BT_TEAM: ${BT_TEAM}" 
    devops-sso-util login --profile "${BT_ROLE}" 2>/dev/null 
    aws_profile "${BT_ROLE}"
    echo -e "${GREEN}$(perms)${NC}"
  }
  
  to_debug flow && sleep 1 && echo api:autologin:status
  [[ "${status}" = *unknown* ]] && {  
    echo -e "${RED}Failed.${NC}"
  }
  
  to_debug flow && sleep 1 && echo api:autologin.expires
  seconds="$(echo "${status}" | ddiff -E -qf %S now)"
  [[ "${seconds}" -gt 1 ]] && { 
    echo -ne "${GREEN}${BT_ACCOUNT} - expires: ${status}${NC}\n"
  }
  to_debug flow && sleep 1 && echo api:autologin.end
}    

