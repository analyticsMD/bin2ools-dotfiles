#!/usr/bin/env /usr/local/bin/bash
# shellcheck shell=bash disable=SC2148

# global debug function.
to_debug()    { [[ "${BT_DEBUG}"    = *$1* ]] && >&2 "${@:2}" ;} || true

to_debug flow && sleep 1 && echo data:start

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
}

to_debug flow echo data:use_array

# Same as use_array() but preserves keys.
use_array_assoc() {
    local r=$( declare -p $1 )
    echo ${r#declare\ -a\ *=}
}  

to_debug flow echo data:use_array_assoc

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
}

to_debug flow echo data:json_to_bash



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

}

to_debug flow echo data:bash2json

# list of arrays to choose from.
array_list=( "role_types" "primary" "delegated"  \
               "restricted" "unrestricted" "guild" )

#[ -n "${array_list["${ref}"]}" ]]     && \
#declare -p "${array_list["${ref}"]}" || \
#return 

to_debug flow echo data:config_arrays

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
}


# USAGE:  . get_array "teams"  # sources the array. 
# search it in the usual manner.

# Globbing
# --------
# Advanced globbing is an easy way to sort through files.
# But we need to Keep tabs on whether a particular glob was
# originally set.  We should only toggle the setting if
# originally not set.
#
shopt -s extglob
shopt -s nullglob
shopt -s dotglob
shopt -s nocasematch

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
to_debug flow echo data:find_in
find_in() { 
  declare -n a=${1} && . <( "${a[@]@A}")
  s=${2:-"_"} && name=${1:-"accounts"}
  [[ $s == '_' ]] && for e in ${a[@]:1}; do echo $e; done && return 0
  [[ "${a[*]:2}" = "${s}" ]] && echo ${s} || echo -ne ""
}



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
to_debug flow echo data:is_in
is_in() { 
  _this=${1:=NONE} 
 sz="${#_this[@]}" 
 arr="${_this[*]}" 
 local array=("${@:1:$1}"); shift "$(($1 + 1))" in
} 

to_debug flow echo data:find_in_accounts

#shellcheck disable=SC2068
find_in_accounts() {
  this=${1} 
  source "${BT}"/src/accounts.gen
  for l in $(printf '%s\n' ${ACCOUNTS[@]}); do 
    echo "$l" | perl -nle "print \"$l\" if /${this}/" | perl -pe "s/%/ /g"
  done
}

to_debug flow echo data:find_in_rds

# shellcheck disable=SC2068,SC2154
find_in_rds() {
  this=${1} 
  source "${BT}"/src/rds_map.src
  for l in $(printf '%s\n' ${rds_map[@]}); do 
    echo "$l" | perl -nle "print \"$l\" if /${this}/"; 
  done
}
#debug echo ${#rds_map[@]} server mapped.


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
} 

to_debug flow echo data:key_sort

# shellcheck disable=SC2068,SC2120
role_arrays() {
  local -n a_of_a="${1:-this_index}"
  for a in $(${a_of_a[@]@A} && printf "role_%s\n" ${a_of_a[@]}); do
     local -n this_arr="${a}"
     for t in $(${this_arr[@]@A} && printf "%s\n" ${this_arr[@]} | sort); do
         echo "$a": "$t"
     done
  done
}

to_debug flow echo data:role_arrays

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
}

to_debug flow echo data:this_index

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
} 

to_debug flow echo data:find_in_this


# Test 
is_account() {
  local -n acct_ref="$1"
  [[ "${2}" =~ [0-9]{12} ]] && account_rev && return
  echo "${acct_ref[$2]}" 
}

to_debug flow echo data:is_account

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
} 

primary() { 
  TEAM="${1:-"NONE"}"
  find_in primaries "${TEAM}" && echo "${TEAM}" || echo -ne ""
} 

delegated() { 
  TEAM="${1:-"NONE"}"
  find_in delegated "${TEAM}" && echo "${TEAM}" || echo -ne ""
} 

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
}

to_debug flow echo data:get_inst

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

