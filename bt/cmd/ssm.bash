#!/usr/local/bin/bash
# shellcheck shell=bash disable=SC1083 format=SC1083
export BT=${HOME}/.bt
. ${BT}/lib/initx.bash
autologin "${BT_ACCOUNT}"

hn="${1:-}" #echo hn: ${hn}
[[ "${hn}" == '' ]] && unset "${hn}"
declare -A inst_map # fully populated inst_map array.

[[ "${POETRY_ACTIVE}" == "1"      && \
   "${POE_ACTIVE}"    == "poetry" && \
   -f "${BT}/lib/inst_map.src"    ]] && { 
    . "${BT}/lib/inst_map.src"
} || { 
  . "${BT}/src/inst_map.src"
}

[[ "${#inst_map[@]}" -lt 10 ]] && {
  echo "inst_map array not found." && exit
}

id=NONE cmd=NONE ip=NONE 
# use fuzzy matching mode if no host is supplied.
[ -z "${hn}" ] && { 
  ip="$(/usr/local/bin/aws-fuzzy --ip-only)" 
  srch="${ip}"
 
  for rec in ${inst_map[@]}; do 
    [[ "${rec}" =~ ${srch} ]] && { 
      mapfile tmp -t < <(echo ${rec} | tr , '\n')  
      id="${tmp[1]}" hn="${tmp[0]}" ip="${tmp[2]}" && break 
    }
  done || echo "host: ${hn} not recognized."

  cmd="aws ssm start-session --target ${srch}"
  echo -e "connecting to: \"${CYAN}${hn}${NC}\""
  echo cmd: ${cmd}
} 

srch="${hn}"
for rec in ${inst_map[@]}; do 
  [[ "${rec}" =~ ${srch} ]] && { 
    mapfile tmp -t < <(echo ${rec} | tr , '\n')  
    id="${tmp[1]}" hn="${tmp[0]}" ip="${tmp[2]}" && break 
  }
done || echo "host: ${hn} not recognized."

cmd="aws ssm start-session --target ${id}"
echo -e "connecting to: \"${CYAN}${hn}${NC}\""
echo cmd: ${cmd}
${cmd}
