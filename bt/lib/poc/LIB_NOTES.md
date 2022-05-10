# send to debug (when BT_DEBUG is configured in settings.)
#debug() { [ -n "${BT_DEBUG}" ] && >&2 bt_log "${@}";}
#BT_DEBUG=yes

#stash ~/.aws/bt_creds
#cat "${BT}/config.d/bt_creds.ini" > ~/.aws/bt_creds

# Test peek cache
#focus="$(this_peek | jq -r '.position | .default')"
#account="$(this_peek | jq -r '.account')"

#for (( i=0; i<"${#c[*]}"; i++ )); do
#  [[ "${a[$i]}" == "${AWS_ID}" ]] && assume -s
#done

#for (( i=1; i<"${MASK}"; i++ )); do
#  [[ "${e[$i]}" -ge "1" ]] && \
#  assume -a "${p[$i]}" -o "${c[$i]}"
#done

# TODO When using multi-account creds profiles, do it with
#      _try wrapper routines. A _try routine is what discovers 
#      creds are missing, and recovers them. Will need  a 
#      routine that recovers quickly when things are malfunctioning.


# TODO: create BT JSON funcs that: 
#       1.) create lookup table of names & positions. 
#       2.) performs each assertion once per session.
#       3.) returns true / false per session.
# Speeds and simplifies verification code.

# Run by users and utilities on logins and logouts.
# Triggers the 'prompt cycle' to find the difference 
# and take action via a 'cache_audit'.  Mostly, this
# function forces a cache_peek, and then cache_audit. 
# when it notices differences requiring a thorough 
# coherency check. 

  # part of regen_creds now.
  #umask 0077 
  #write_profiles 
  #umask 0022


# shellcheck disable=SC2120
write_profiles() {
  # create a pointer to the profile we want to rebuild.
  PROFILE=${1:-"qventus"}
  CRED_FILE="${AWS_SHARED_CREDENTIALS_FILE}"
  [[ -z "${CRED_FILE}" ]] && \
  echo "FATAL: No credentials file." && exit 1

  declare -a profiles=( "prod" "identity" )
  declare -A params
  params["manager"]="awsume" 
  params["region"]="${AWS_DEFAULT_SSO_REGION}"


  # shellcheck disable=SC1083
  echo "" > "${CRED_FILE}"

  { 
    for PF in "${profiles[@]}"; do 
      echo -ne "#[$PF]\n"                   
      for prm in "${!params[@]}"; do 
        echo "#${prm}" = "${params[$prm]}"
      done 
      echo -ne "\n\n"                    
    done 
  } >> "${CRED_FILE}"
  # persist the qventus profile, if active.
  IFS='|' read -r -a chain <<< "$(chain_peek)"
  # shellcheck disable=SC2015
  if [[ "${chain[1]}" -gt 0 ]]; then
    #persist_profile 
    true
  else 
    # otherwise, write a stub.  
    echo -ne "[$PROFILE]\n"               | tee -a "${CRED_FILE}" 
    for prm in "${!params[@]}"
    do      
      echo "${prm}"  =  "${params[$prm]}" | tee -a "${CRED_FILE}" 
    done 
    echo -ne "\n\n"                       | tee -a "${CRED_FILE}"
  fi 
}
# Persist an active profile across
# rebuilds of bt_creds.

# shellcheck disable=SC1083,SC2120
persist_profile() { 
  #aws_defaults
  # takes one arg - the profile to be persisted.
  CRED_FILE="${AWS_SHARED_CREDENTIALS_FILE}"
  # source existing profiles into assoc arrays.
  echo <("${BT}"/lib/ini_parser < "${CRED_FILE}")
  source <("${BT}"/lib/ini_parser < "${CRED_FILE}")

  # create a pointer to the profile we want to rebuild.
  PROFILE=${1:-"qventus"}
  # shellcheck disable=SC1083,SC2086
  eval profile=\( \${profile[@]} \) 
  declare -A params
  params["manager"]="awsume" 
  params["region"]="${AWS_DEFAULT_SSO_REGION}"
  # test the imported profile (the fast way).
  if [[ -n "${PROFILE[*]}" ]]; then   
    debug echo "Found profile: ${profile}"
    # shellcheck disable=SC2236,SC2015
    if [[ ! -z "${profile[expiration]+_}" ]]; then
      # if active, write the profile back..
      seconds="$(echo "${profile[expiration]}" | ddiff -E -qf %s now)"
      if [[ "${seconds}" -gt "0"  ]]; then  
        echo -ne "[$PROFILE]\n"                  | tee -a "${CRED_FILE}" 
        for param in "${!PROFILE[@]}"
        do                                                    
          echo "${param}" =  "${params[param]}"  | tee -a "${CRED_FILE}"
        done 
        echo -ne "\n\n"                          | tee -a "${CRED_FILE}"
      else
        debug echo "Write failed."
      fi
    else
      debug echo "Profile no longer invalid."   
    fi 
  else
    debug persisted profile: "$profile".
  fi
}


# fast check: No audits required.
# corrects for: ENV wiped in subshell.

cache_audit() { 
:
  # Full audit. Starts with fast recovery, 
  # then moves to harder tasks, if state 
  # does not improve.
} 

# date -dst 1640957229 ddiff -i %S -E --from-zone -0800 now --fmt 1640906842 
#_decode | jq -r '.expires[]' | perl $dt = DateTime->from_epoch( epoch => $epoch );
#_decode | jq -r '.expires[]' | perl -pe 's/([\d.]+)/localtime $1/e;' 

#    env_sync - fast cache integrity checks.
#    ---------------------------------------------------------------------------
#    Unlike the more rigorous cache_audit, env_sync is made for speed. It
#    is run with each prompt refresh, and looks for integrity problems
#    that can be corrected without session calls to AWS.
#
#    Deserializes and loads 'this_peek' object from ENV, for comparison.
#    Performs an integrity check for 'next_peek' cache state.  On
#    success, calls env_update and passes in the 'next_peek' so it can
#    become 'this_peek'.
#
#    -- merges and reconciles next_peek with this_peek in a
#       predefined order.  If it finds irreconcilable problems, it will
#       abort and run a cache_audit instead.
#
#    -- Runs fix routines if needed. Logs the findings and results.
#       awsume -a <pos> -o qventus
#       assume -s | eval.
#    """
#
    # Make a dict of 'integrity' functions 
    # to pass around and loop through.  Quite handy...
    #
#    """
#    for func in INTEGRITY_CHECKS:
#        try:
#            INTEGRITY_CHECKS['func'](action, msg)
#        except BTAppError(Exception), e:
#            pass  # TODO: Fail if no settings?
#    raise:
#        # reraise exceptions to capture in logging.
#        BTIntegrityCheckError
#    """
#
#    # chain: [ "sso", "team", "role", "guild" ]
##     
##    """
##    # account: { "prod": "351480950201" }
##    """
##    account = int(jq.one(".account.default", peek))
##
##    mask = jq.one(".assert", peek)
##    expires = jq.one(".expires", peek)
##    user_pos = jq.one('.position.default', peek)
##    token, id = jq.one(".hints.{pos}").split("_")
#    jq_str = f"""'.hints | with_entries(select("\([.key])==\([.{sn}])"))|.{sn}'"""
#    hint = jq.one(f"{jq_str}", this_peek)
#
#    # test 1: validate current login position.
#    position  = chain[get_position(new_peek)] # chain position, e.g. 2
#    profile = jq.one(f".profiles.{position}", new_peek) # profile name
#    account = int(jq.one(".account.default", new_peek)) # aws_account_id
#    expire = jq.one(f".expires[{position}]", new_peek) # seconds to expire
#
#    # test 2: validate position, account
#    if ( 0 <= position <= 3                     and
#         position <= get_highest_active_session and 
#         account == 351480950201                and 
#         is_active(expire)
#       )
#        pass
#     # -- validate active profiles 
#
#    if verify_assert(peek, profile, position):
#        logging.info(f"assert ok: new_peek: profile: {profile}, position: {position}")
#    else:
#        logging.error(f"assert invalid: new_peek: profile: {profile}, position: {position}")
#
#     # 1.) lookup active profiles by name. return list. (compare to previous)
#     # 2.) return designated active profile. compare to 'this_peek'. (compare to previous)
#     #      If user data not avail, use default active profile.
#     # 3.) return list of changes to expires in active profiles (0 is good; otherwise cache_audit.) 
#     # 4.) return list of POS id or token changes in active slots (0 is good. otherwise, cache_audit))
#     # 5.) positions (i.e. user asserted session)
#     # 6.) changes to profile names (name of role, and guild,e.g.)

    # OK CHANGES: 
    #- recorded change in a positional profile, i.e. 
    #- qventus creds should reflect current profile. 
    #- Timeout should reflect current profile (check). 
    #- exists in assert
    #- expire is further out 
    #- asserted position is present
    #- profile name changed.
    #- credentials changed (old peek -> new peek) 
    #- cache_merge checks integrity

    # exceptions to fix: 
    #- qventus id, expire, or creds do not reflect current profile. 
    #- stale expires exist; expired assertions exist. (rebuild file).
    #- account changed in new  
    #    (action: update env, regen accountfile ).

    # Invalidators: Tests that would cause an abortion if creds failed. 
    #- assert mask changed, but no token or expire changes. 
    #  account_id changed, but no position changed. 
    #- change in profile assertion (or account) but no change 
    #  in corresponding expires, id, or token.
    #  (found by comparing environments and hints.)
    #- expires missing for asserted profiles. 
    #- no new id or token for asserted profiles. 

    # log entry: 
    #peek = get_peek()  

#       -- qventus creds current? If not, refresh. 
#       -- bt_config and bt_creds ok?  If not regen. 
#    """

    #raise BTEnvironmentError('Env variable {} not set'.format(e.args[0]))
        # get all chain profiles.
#        chain_profs = jq.one(".chains.default", peek)
#
#        for cp.upper in chain_profs:
#            try:
#                cp = os.environ.get(f"BT_{cp()}", 'NONE') 
#            except KeyError:
#                'BT_SSO', 'BT_TEAM', 'BT_ROLE', 'BT_GUILD'  = ( 
#                    os.environ[f"BT_{chain_profile.upper()}"], 'NONE'),
#                    os.environ[f"BT_{chain_profile.upper()}"], 'NONE'),
#                    os.environ[f"BT_{chain_profile.upper()}"], 'NONE'),
#                    os.environ[f"BT_{chain_profile.upper()}"], 'NONE')
#                )
#            #raise KeyError(key) from None
#                pass
#
#    expires = jq.one(".expires", peek)
#
#    [[ -z "${verify}" ]] && { 
#        env_update
#        return
#    } || { 
#        env_audit
#        return
#    } 
#} 
# ----------------------------------------------------------------
# PATHS
# ----------------------------------------------------------------
# Routines to avoid duplicates in paths and to cleanly manage 
# outside of .bash_profile, etc.
#

# NOTE: A path file has been installed under /etc/paths.d

# Helper functions: path_edit, path_dedupe
# 
# USAGE: 
# path_edit -p /this/path (prepends to $PATH)
# path_edit -a /that/path (appends to $PATH)
# path_edit -r /unwanted/path (removes from $PATH)
#path_edit() {
#  add=${1:-""}
#  THIS=$(echo -ne ${2:-""} | perl -pe 's/\s*//g')
#
#  [[ -z "${add}"  ]] && return 1
#  [[ -z "${THIS}" ]] && return 2

#  _PATH=${PATH}

#  case ":$_PATH:" in
#    *":$THIS:"*) return;; # already exists
#  esac

#  case $add in
#    -p ) _NEW=":${THIS}:${_PATH}:" ;;
#    -a ) _NEW=":${_PATH}:${THIS}:" ;;
#    -r ) ;;
#    * ) return 3 ;;
#  esac

#  _NEW=$(echo $_NEW | perl -pe 's/::/:/g; s/\/\//\//g; s/:$//; s/^://')
#  export PATH=${_NEW}
#}

#export -f path_edit

#path_dedupe () { 
#  _PATH=${1:-${PATH}}
#  THIS="$(printf '%s:' $(echo -ne ${_PATH}) | \
#  awk -v RS=: -v ORS=: '!arr[$0]++' |\
#  sed -e 's/^?[\s:\n]*$?//; s/[:]+/[:]/g; s/:$//; s/^://;')"
#  echo $THIS
#  declare -x PATH="${THIS}"
#} 

#path_set () { THIS=${1:-${PATH}}; export PATH=${THIS} ;} 

# Build a clean path from existing ENV, 
# using path groupings, and deduping.
# check path for dupes.  repath if true.



#
#  [[ ! -e "${BT}/cache" ]] && \
#  mkdir -p "${BT}/cache"
#
#  [[ -f "${BT}/cache/path_info" ]] && { 
#    source "${BT}/cache/path_info" && return
#  } || { 
#    echo -ne "WARNING: path_info file not found! Regenerating...\n"
#    # NOTE: 'bt_paths' contains baseline paths. 
#    #       'path.d'   contains mode-specific paths. 
#    perl "${BT}/inst/add_path.pl"       \
#         "${BT}/inst/path.d/${BT_MODE}" \
#         >  "${BT}/cache/path_info"     \
#         2> "${BT}/log/bt_path_log"
#  }
#}
