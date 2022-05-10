# Welcome to the basement. 


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


# NOTE: We must use a different loader for assoc arrays.
sourceror() {  
  arr=${@}
  for name in ${arr[@]}; do
    #declare -A "$name"=()
    . <( cat "${BT}/src/${file}.arr" )  # assoc. array
  done
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




