#!/usr/bin/env /usr/local/bin/bash
# shellcheck shell=bash 

BT="${HOME}/.bt"
export BT="${BT}"

to_debug() { [[ "${BT_DEBUG}" = *$1* ]] && >&2 "${@:2}" ;}

# Make sure there's a debug function.
[[ "$(type -t to_debug)" == "function" ]] || {
  echo >&2 "WARNING: Core function: 'to_debug' not sourced."
}

# DEBUGGING -- Can be set per component, or globally, here.
#BT_DEBUG=env,flow

# uses ${HOME} to figure out the user name,
# then queries AWS SSO to look up user's group.
get_os() { uname -a | awk '{print $1}' ;}

# ----------------------------------------------------------------
# AWS_ENV  
#
# Full BT environment settings required by utilities
# # that run in ENV.  
# ----------------------------------------------------------------

export BT="${HOME}/.bt"
[[ -z "${BT}" ]] && { BT="${HOME}/.bt"; export BT="${BT}" ;}


# Establish vars that comprise the env state.
#
env_state()  { 

  #include api
  export BT_USR="$(get_usr)"
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
  export BT_SETTINGS="quiet,autologin"
  export AWS_CONFIG_FILE="${HOME}/.aws/bt_config"
  export AWS_SHARED_CREDENTIALS_FILE="${HOME}/.aws/bt_creds"

}

env_state
to_debug flow && sleep 1 && echo env:state


env_cache() { 

  [[ -z "${BT}" ]] && { BT="${HOME}/.bt"; export BT="${BT}" ;}
  declare -a files=( ${@:1} )
  
  umask 0077

  [[ ! -d "${BT_CACHE}" ]] && { 
  export BT_CACHE="${BT}/cache"
  mkdir -p ${BT_CACHE} && export BT_CACHE=${BT_CACHE}
  to_debug cche echo "cache dir: ${BT}/cache"

  # copy paths passed in.
  for FILE in ${files[@]}; do 
    to_debug cche echo copying "${FILE##*/} to ${BT_CACHE}"
    [[ -f "${FILE}" ]] && { 
        caching ${FILE} 
        cp "${FILE}" "${BT_CACHE}/${FILE##*/}"
    } || { 
      echo "${FILE##*/} is not a file, or could not be copied."
    }
  done

  umask 0022

  }
}  

env_cache 
to_debug flow && sleep 1 && echo env:cache

env_init() { 

  # Initialize our most important ENV vars:

  # BT:
  [[ -z "${BT}" ]] && { BT="${HOME}/.bt"; export BT="${BT}" ;}
  to_deploy env echo "env:init:BT ${BT}"

  [[ -z "${AWS_CONFIG_FILE}" ]] && { echo "No aws config. Exiting..." ;}

  # ROLE, TEAM, ACCOUNT.
  # if not set, check cache and profiles.
  ARGV="${1:-qventus}"
  # check ~/.aws/bt_config 
  # This file is an authority, and can be recreated.
  role="$(cat "${AWS_CONFIG_FILE}"                           | \
          perl -nle "print if s/(${ARGV}\]|role_arn.*)/\1/;" | \
          grep -EA 1 "${ARGV}\]" | tail -n 1                 | \
          perl -nle 'print if s/.*qv\-gbl\-([\w_\-]+)/\1/'  )"

  # if request is not valid, report an error. 
  [[ -z "${role}" || "${role}" = *NONE* ]] && { 
    echo -e "${RED}FATAL${NC}: \"${ARGV}\" is not a configured destination."
    echo -e "Try rebuilding your aws config by running \"${BLUE}profiles${NC}\"".
    return 0
  }

  [[ "${role}" == "qventus" ]] && {  

    # need to validate BT_TEAM var a bit further.
    [[ -n "${BT_TEAM}" || ! "${BT_TEAM}" = *NONE* ]] && { 
      export BT_TEAM="${BT_TEAM}"
    } || { 
      # team var not proper.  check team cache.
      [ -f "${BT_CACHE}/team_info" ] && { 
        team="$(cat "${BT_CACHE}/${BT_TEAM}")"
        [[ ! "${team}" = *NONE* && -n "${team}" ]] && { 
          # cache worked.
          BT_TEAM="${team}" 
          export BT_TEAM="${BT_TEAM}"
        } || { 
          # cache did not work. Warn the user to fix the problem.
          rm -rf "${BT_CACHE}/team_info"
          echo "----------------------------" 
          echo "FATAL: team not set." 
          echo "Please run 'profiles' again."
          echo "From the command line."
          echo "----------------------------" 
        }
      } || { 
        # cache not present. Populate.    
        echo "${BT_TEAM}" > "${BT_CACHE}/team_info"
      }
    }
  }
    
  # BT_ACCOUNT:   
  # use defaults if nothing explicitly passed in. 
  [[ "${role}" == "qventus" ]] && { export BT_ACCOUNT=prod && return ;} 
  # account needs more vetting. 
  declare -a ROLE
  ROLE=( $(echo "${role}" | tr '-' ' ') )  
  to_debug env echo ROLE1: "${ROLE[0]}" ROLE2: "${ROLE[1]}"
  [[ "${#ROLE[@]}" -ne 2 ]] && {
    echo -e "${RED}FATAL${NC}: ROLE: \"${role}\" does not seem to have a valid format."  
    echo -e "It must be of the form ${BLUE}<account>-<team>${NC}, e.g. \"prod-dp\"."
  }
}
    #[[ -z "${BT_ACCOUNT}" || -z "${BT_TEAM}" ]] && { 
    #[[ "${BT_ROLE}" = *NONE* ]] || \
    #[[ "${BT_ACCOUNT}"  = *NONE*    ]] || \
    #[[ "${BT_ROLE}"     = *NONE*    ]] && { "${@:1}" == "" } && {
    # use qventus as our default.
  #  [[ "${BT_ACCOUNT}" = *NONE* || -z "${BT_ACCOUNT}" ]]   && \
  #    DEFAULT=qventus 
  #    BT_ROLE="$(cat "${AWS_CONFIG_FILE}"                     | \
  #      perl -nle "print if s/(${DEFAULT}\]|role_arn.*)/\1/;" | \
  #      grep -EA 1 "${DEFAULT}\]" | tail -n 1                 | \
  #      perl -nle 'print if s/.*qv\-gbl\-([\w_\-]+)/\1/'")"
  #}


env_init
to_debug flow && sleep 1 && echo env:init



env_fuzz() { 

  export AWS_FUZZ_USE_CACHE=yes                     \
         AWS_FUZZ_PRIVATE_IP=true                   \
         AWS_FUZZ_USER="${USER}"                    \
         AWS_FUZZ_CACHE_EXPIRY=0                    \
         AWS_FUZZ_SSH_COMMAND_TEMPLATE="ssm {host}" \
         AWS_FUZZ_REGIONS="${AWS_REGION}" 

} 

env_fuzz
to_debug flow && sleep 1 && echo env:fuzz 

# ---------------------------------------------------------
# dirs, vars, & libs.
# ---------------------------------------------------------



get_sso() { 
  echo "${USER}"
}



get_usr() { 
  echo "${USER}"
}



# ---------------------------------------------------------
# libs
# ---------------------------------------------------------


# SANITY FUNCTIONS
# -----------------
# Should be run by all generators, and scripts. 
# 
env_sanity() { 

  # prevent running as root on MacOS. 
  BT_OS="$(get_os)"
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

} 

env_sanity

to_debug flow && sleep 1 && echo env:sanity


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
}



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
}



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
}

# other vars
#CREDENTIAL_CMD="aws-sso-credential-process"
#CREDENTIAL_CMD+=" --profile qventus "
#CREDENTIAL_CMD+=" --start-url ${AWS_CONFIGURE_SSO_DEFAULT_SSO_START_URL} "
#CREDENTIAL_CMD+=" --region ${AWS_CONFIGURE_SSO_DEFAULT_SSO_REGION} "
#CREDENTIAL_CMD+=" --role-name aws_team_${BT_TEAM} "
#CREDENTIAL_CMD+=" --account-id ${identity} "

# NOTHING BELOW HERE.

# settings. env should do the cache. 
# init should do the init. ONLY DONE HERE.  ONE ENTRY POINT. 
#BT_TEAM=$(head -n1 "${BT}/cache/team_info")
#export BT_TEAM="${BT_TEAM}"
#(do others as well.  And set TEAM to defaults. 

# Routines to avoid duplicates in paths and to cleanly manage 
# outside of .bash_profile, etc.



# NOTE: A path file has been installed under /etc/paths.d

# Helper functions: path_edit, path_dedupe


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
}

env_aws


# Spawn new session cleanly with refreshed credentials. 
# Remove all remnants of potentially bad configs. 
# 
new_session() {
    BT_TEAM="$(get_team)"
    role=${1:-"${BT_TEAM}"}
    #devops-sso-util login --profile qventus 
    assume -a "${role}" -o qventus | grep -v Stylish
    source <(echo "$(assume -s)") 
    aws_profile --unset
    aws_profile qventus
    perms && { 
      GREEN='\033[0;32m'   # for ANSI color
      NC='\033[0;m'        # No Color
      echo "${GREEN}Success!!${NC}"
    } || {
      RED='\033[0;31m'     # for ANSI color
      NC='\033[0;m'        # No Color
      echo "${RED}Failed!${NC}"
    } 
} 

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
  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "USAGE:"
    echo "aws_profile              <- print out current value"
    echo "aws_profile PROFILE_NAME <- set PROFILE_NAME active"
    echo "aws_profile --unset      <- unset the env vars"
  elif [ -z "$1" ]; then
    if [ -z "$AWS_PROFILE$AWS_DEFAULT_PROFILE" ]; then
      echo "No profile is set"
      return 1
    else
      to_debug aws echo "profile: $AWS_PROFILE default: $AWS_DEFAULT_PROFILE\n"
    fi
  elif [ "$1" = "--unset" ]; then
    AWS_PROFILE=
    AWS_DEFAULT_PROFILE=
    # needed because of https://github.com/aws/aws-cli/issues/5016
    export -n AWS_PROFILE AWS_DEFAULT_PROFILE
  else
    # needed because of https://github.com/aws/aws-cli/issues/5546
    if ! aws configure list-profiles | grep -Fq -- "$1"; then
      echo "$1 is not a valid profile"  
      return 2
    else
      export AWS_PROFILE=$1 AWS_DEFAULT_PROFILE=$1
    fi;
  fi;
}



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

# qv standards
declare -x BT_CREDS="${HOME}/.aws/bt_creds"
declare -x BT_CONFIG="${HOME}/.aws/bt_config"
declare -x qv_gbl=us-west-2
declare -x qv_start_url=https://qventus.awsapps.com/start

 
aws_defaults() { 


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

# ----------------------------------------------------------------
# variables that define the behavior of aws-vault backend secrets. 
# Qventus uses aws-vault to encrypt credentials at rest on laptops, 
# ecs, and ec2 hosts.  This is specifically to remove any long term 
# credentials stored in the clear on laptops, etc. 

# Lowest maintenance alternative is the 'file' option, which uses 
# encrypted flat files in the aws-vault file space.
# export AWS_VAULT_FILE_PASSPHRASE=(autogenerated-password)

# The autogenerated password frees you from the need to type 
# regular passwords to unlock your credentials.  Instead, a randomly 
# generated password is created with each 8h session, and loaded
# into this variable. This makes the password a 'throw-away' credential,
# not unlike the temporary session tokens deployed by AWS.

# Other useful var (not currently implemented).
# See flag: --backend
# AWS_VAULT_BACKEND=file
# See flags--prompt
# AWS_VAULT_PROMPT=terminal

# AWS_ROLE_ARN: ARN of IAM role in the active profile
# AWS_ROLE_SESSION_NAME: name of the role session in the active profile

# AWS_STS_REGIONAL_ENDPOINTS: must be "regional" or "legacy"
# AWS_MFA_SERIAL: id number of MFA device. We do not need this, as we 
#                 use Okta for MFA before Federated Authentication. 

# TTLs for sessions:
# AWS_SESSION_TOKEN_TTL:         8h
# AWS_CHAINED_SESSION_TOKEN_TTL: 1h
# AWS_ASSUME_ROLE_TTL:           1h 
# AWS_FEDERATION_TOKEN_TTL:     12h
# AWS_MIN_TTL:                   5m

# Comma separated key-value list of tags passed with the 
# AssumeRole call, overrides session_tags profile config variable.
# AWS_SESSION_TAGS: 

# Comma separated list of transitive tags. 
# Overrides transitive_session_tags profile config variable
# AWS_TRANSITIVE_TAGS: 

# We currently do not support the macos keychain or pass options
# for credential protection on the local host.  We might someday, 
# and if you really want them, you can manage your own configs. 

# AWS_VAULT_KEYCHAIN_NAME: Name of macOS keychain to use (see the flag --keychain)
# AWS_VAULT_PASS_PASSWORD_STORE_DIR: Pass password store directory (see the flag --pass-dir)
# AWS_VAULT_PASS_CMD: Name of the pass executable (see the flag --pass-cmd)
# AWS_VAULT_PASS_PREFIX: Prefix to prepend to the item path stored in pass (see the flag --pass-prefix)

aws_profile qventus

}

aws_defaults




## ----------------------------------------------------------------
## AWS SETTINGS
## ----------------------------------------------------------------
# Save secrets history in ssm, via chamber. 
# once saved, create a new password, and then 
# migrate aws-vault creds to a new file.
# (There are only one or two per person.)
# Then change the password. Script should 
# log this in the background.
# 
aws_vault_rotate() {
  # generate new secret. 
  s=$(openssl rand -base64 40 | colrm 27)
  # update backend.
   
  # update secret.
  declare -x AWS_VAULT_FILE_PASSPHRASE=$s
} 

aws_creds_regen() {

    :

}


