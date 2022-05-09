#!/usr/bin/env /usr/local/bin/bash

to_debug flow && sleep 0.5 && echo api:start
to_debug flow && echo api:perms

# prove you have perms.
perms() {
  account="$(cat "${AWS_CONFIG_FILE}"                           | \
             perl -nle "print if s/(${ARGV}\]|role_arn.*)/\1/;" | \
             grep -E -A 1 "${ARGV}\]" | tail -n 1               | \
             perl -nle 'print if s/\s*role_arn\s*\=\s*.*::([\w_\-]+)/\1/;')"

  login="$(aws sts get-caller-identity 2>/dev/null  | \
           jq -r '.Arn'                             | \
           cut -d':' -f 5-6                         | \
           cut -d'/' -f 1-2)"
  [ -z "$login" ] && { 
    echo -e Failed && return 1
  } || { 
    echo -e "${login}"
  }
}


get_account() {
  this_peek | jq -r '.account | to_entries[] | select(.key|tostring) | "\(.key)"'
}


to_debug flow && echo api:regen_qv_stubs

regen_qv_stub() { 

    [[ -n "${AWS_SHARED_CREDENTIALS_FILE}" ]] && {
      CREDS="${AWS_SHARED_CREDENTIALS_FILE}"
      perl -pe '\n\n[qventus]\n  
              manager = awsume\n
              region = us-west-2/\n\n/g' >> "${CREDS}"
    }
    #stash_creds
} 


to_debug flow && echo api:wipe

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
  "${DEFAULT_AWSLIB}" logout  > /dev/null 2>&1
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
  "${DEFAULT_AWSLIB}" check >/dev/null 2>&1
  echo "all cached sessions removed."
}


to_debug flow && echo api:unset_profile

unset_profile() { 
  ${BT}/cmd/assume --unset >/dev/null 2>&1
  aws_profile --unset
  unset AWSUME_PROFILE AWSUME_DEFAULT_PROFILE AWS_PROFILE AWS_DEFAULT_PROFILE
}


to_debug flow && echo api:autologin

# unattended login
autologin() { 

  export AWS_CONFIG_FILE="${HOME}/.aws/bt_config"
  export AWS_SHARED_CREDENTIAL_FILE="${HOME}/.aws/bt_creds"
  #ACCT_ID="$(find_in_accounts "${BT_ACCOUNT}" | awk '{print $2}')"


  [[ "${BT_TEAM}" == "NONE" || \
      -z "${BT_TEAM}"       ]] && { 
     echo "Failed to find a Team. Please rerun ~/.bt/gen/profiles"
     return 1
  } 

  env_init
  to_debug flow && echo api:autologin:env_init.

  # look for expired creds.
  raw="$("${DEFAULT_AWSLIB}" check 2>&1)" 
  to_debug lgin echo raw check output: "${raw}"
  sso="$(echo "${raw}" | \
      perl -nle 'print if s/.*(valid until [\w\-\:\ ]+|fix|expired).*/\1/')"
  to_debug lgin echo sso: $sso
  
  to_debug lgin echo "BT_ROLE: ${BT_ROLE} BT_ACCOUNT: ${BT_ACCOUNT} BT_TEAM: ${BT_TEAM}" 

  # refresh just the sso token (12 hour lifespan).
  # collect the status, which is your expire time.
  status=unset
  [[ "${sso}" = fix*     || \
     "${sso}" = expired* ]] && { 
    cmd="$("${DEFAULT_AWSLIB}" login --profile "${BT_TEAM}")" 
    status="$(echo "$cmd" | perl -nle \
            'print if s/.*(valid until [\w\-\:\ ]+)/$1/')"
  }
  to_debug lgin echo status_cmd: $cmd
  to_debug lgin echo status: $status
  # this should fail hard for multi-account.
  if aws_profile "${BT_ROLE}" >/dev/null 2>&1; then 
     to_debug lgin echo profile set to: ${BT_ROLE}   
  else 
    echo "Could not set profile to: ${BT_ROLE}."
    echo "Please rerun the 'profiles' command."
    return
  fi

  chain=unset
  [[ "${chain}" == "unset" ]] && { 
    chain="$("${DEFAULT_AWSLIB}" login --profile "${BT_ROLE}")" 
    status="$(echo "$chain" | perl -nle 'print if m/Successful/')"
  }

  [[ "${status}" == "unset" || "${sso}" =~ valid ]] && { 
    ts="$sso"
  } || { 
    ts="${status}"
  }

  t="$(echo "${ts}" | \
      perl -pe 's/valid until //' | \
      ddiff -E -qf %S now)"

  [[ "$t" -gt 0 ]] && { 
    X="$(gdate --utc -d "0 + ${t} seconds" +"%Hh:%Mm:%Ss")"
  } 
  to_debug lgin echo "ts:$ts, t:$t, X:${X} R:${BT_ROLE}"
  export "ts=${ts} t=${t} X=${X} R=${BT_ROLE}" 

  arn=unset
  [[ "${chain}" =~ Successful ]] && {
    arn="$(aws sts get-caller-identity --profile "${BT_ROLE}" 2>&1 | \
      jq -r '.Arn' | cut -d':' -f 5-6 | cut -d'/' -f 1-2)"
      # (prints some informative stats about the session.)
    echo -e "LOGIN: $arn"
  }
  to_debug lgin echo in: $arn

  # construct a header.
  if [[ "${t}" -ge 601 ]]; then
    echo -e in: ${GREEN}${BT_ACCOUNT}${NC} expires: ${GREEN}${X}${NC}"\n"
  elif [[ "${t}" -ge 11 ]]; then
    echo -e in: ${YELLOW}${BT_ACCOUNT}${NC} expires soon: ${YELLOW}${X}${NC}"\n"
  elif [[ "${t}" -eq 0 ]]; then  
    echo -e in: ${CYAN}unknown${NC}."\n"
  elif [[ "${t}" -lt 0 ]]; then 
    echo -e ${RED}expired${NC}."\n"
  else 
      :
  fi
  return
  
} 



# NOTE: We must use a different loader for assoc arrays.
sourceror() {  
  arr=${@}
  for name in ${arr[@]}; do
    #declare -A "$name"=()
    . <( cat "${BT}/src/${file}.arr" )  # assoc. array
  done
} 



# Takes either an AWS account name, or an AWS account_id.
# Returns a name and id pair, or an empty string. 
account_lookup() { 

  acct="${1:-prod}"
  [[ "$acct" =~ [0-9]{12} ]] && { acct_id="${acct}" && unset acct ;}
  #acct_id="${2:-123456789012}"

  JSON_OBJ="$(cat "${BT}/data/json/bt/accounts.json")"
  #JSON_OBJ="{\"account\":{\"${acct}\":${acct_id}}"

  # forward lookup
  [[ -n "${acct}" ]] && { 
     : # need jq. for number lookup.
  }

  # reverse lookup
  [[ -n "${acct_id}" ]] && { 

    acct="$(echo "${acct_id}" |                         \
             jq -r  '.account |                         \
                 to_entries[] |                         \
        select(.key|tostring) | "\(.key)"' "${JSON_OBJ}")"

    echo "${acct}" "${acct_id}"
  } 
}

to_debug flow && echo api:autologin.end
to_debug flow && sleep 0.5 && echo api:end

