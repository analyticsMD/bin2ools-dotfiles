#!/usr/bin/env /usr/local/bin/bash
# shellcheck shell=bash

to_debug flow && sleep 0.5 && echo pmpt:start

to_debug flow && echo pmpt:this_peek

this_peek () { 
  [ -z "${BT_PEEK}" ] && { 
    : #echo "No BT_PEEK var was found."
      #return 1
  }
  echo "${BT_PEEK}" | gbase64 -d | zcat | jq 
}


to_debug flow && echo pmpt:next_peek

next_peek() {
  [ -z "${NEXT_PEEK}" ] && { 
    echo "No NEXT_PEEK found."
    return 1
  }
  echo "${NEXT_PEEK}" | gbase64 -d | zcat | jq 
}

to_debug flow && echo pmpt:diff_peek


diff_peek() { 

  # Render leaf nodes in both peeks as k/v pairs. 
  # Diff the old and new peeks.  Report changes as 
  # a series of bitmasks to simplify fast assertions.
  #
  shopt -s extglob
  usr=$(get_usr)

  diff --side-by-side -B                                                   \
    <(this_peek | jq -Sc 'paths(scalars) as $p|[$p, getpath($p)]')         \
    <(next_peek | jq -Sc 'paths(scalars) as $p|[$p, getpath($p)]')       | \
    perl -pe 's/[\<\>\[\]\|\"]//gx; 
      s/(assert),([10]{4})\s*
        \1      ,\2       \s*\n/|ASRT\2/gx; 
      s/(assert),([10]{4})\s*
        \1      ,([10]{4})\s*\n/|ASRT\2>\3|/gx;
      s/(account),(\w+),(\d+)\s*
        \1       ,\2   ,\3\s*\n/|\2|/gx; 
      s/(account),(\w+),(\d+)\s*
        \1       ,(\w+)   ,(\d+)\s*\n/|\2>\4|/gx; 
      s/(aws_ids),([0]),(\w+)(\w{3})\s+
        \1       ,\2   ,\3   \4     \s*\n/AWS|\4/gx; 
      s/(aws_ids),([1-3]),(\w+)(\w{3})\s+
        \1       ,\2     ,\3   \4     \s*\n/|\4/gx; 
      s/(aws_ids),([0]),(\w+)(\w{3})\s+
        \1       ,\2   ,(\w+)(\w{3})\s*\n/AWS|\4>\6/gx;
      s/(aws_ids),([1-3]),(\w+)(\w{3})\s+
        \1       ,\2     ,(\w+)(\w{3})\s*\n/|\4>\6/gx; 
      s/(tokens),([0]),([\w\/\=\+]+)([\w\/\=\+]{3})\s+
        \1,      \2,   \3           \4\s*           \n/|TOK|\4/gx;
      s/(tokens),([1-3]),([\w\/\=\+]+)([\w\/\=\+]{3})\s+
        \1      ,\2     ,\3           \4\s*            \n/|\4/gx;
      s/(tokens),([0]),([\w\/\=\+]+)([\w\/\=\+]{3})\s*
        \1      ,\2   ,([\w\/\=\+]+)([\w\/\=\+]{3})\s*\n/|TOK|\4>\6/gx; 
      s/(tokens),([1-3]),([\w\/\=\+]+)([\w\/\=\+]{3})\s+
        \1      ,\2     ,([\w\/\=\+]+)([\w\/\=\+]{3})\s*\n/|\4>\6/gx;
      s/(position),(default),([0-3])\s+
        \1        ,\2       ,\3     \n//gx; 
      s/chains.*\n//gx;
      s/(profiles),([01]),([\w_-]+)\s*
        \1        ,\2    ,\3       \n//gx; 
      s/(profiles),([23]),((NOT|UN)SEEN)\s*
        \1        ,\2    ,\3            \n//gx;
      s/(profiles),([23]),([\w_-]+)\s*
        \1        ,\2    ,\3       \n/PRF\2|\3/gx;
      s/(profiles),([23]),([\w_-]+)\s*
        \1        ,([23]),([\w_-]+)\n/PRF\2|\3/gx; 
      s/(expires),([0-3]),0\s*\1,\2,0\s*\n//gx; 
      s/(expires),([0-3]),(\d+)\s*
        \1       ,\2     ,\3\s*\n/\nEXP\2|\3\n/gx; 
      s/(expires),([0-3]),(\d+).*\1,\2,(\d+)/\nEXP\2|\3|\4\n/gx;
      s/|(EEN)//gx;
      s/^\s*\n$//gx;'                                                    | \
      while IFS= read -r e; do                                             \
        echo "${e}" 2>/dev/null &&                                         \
        [[ "${e}" = EXP* ]] && echo "${e}"                               | \
          perl -pe 's/^EXP\d\|//g'                                       | \
            ddiff -i '%s' -Eqf %S now                                      \
      ;done                                                              | \
      perl -pe 's/^EXP.*//g; s/\n+/ /g; s/^\s*$//g' && echo -ne "\n"

      shopt -u extglob
}


to_debug flow && echo pmpt:assert_next

# Encapsulate the logic of handling changes in authentication.
#
assert_next() {
  #export BT_DEBUG=cche
  [[ -z "${NEXT_PEEK}" || -z "${NEXT_SIG}" ]] && { 
    to_debug cche echo -ne "fetching peek..."
    ${BT}/lib/bt_export.py | eval
    [[ -z "${NEXT_PEEK}" || -z "${NEXT_SIG}" ]] && { 
      to_debug cche echo "No peek." 
      return 1
    }
    [[ "${NEXT_SIG}" == "${BT_SIG}" ]] && { 
      to_debug cche echo "sigs equal: no change."
      unset NEXT_SIG NEXT_PEEK
      return
    } 
  }

  [[ -z "${BT_PEEK}" || -z "${BT_SIG}" ]] && { 
    to_debug cche echo "no previous. Merging..."
    peek_merge
    return
  } 

  # assert changes.
  [[ -z "${BT_PEEK}" || -z "${BT_SIG}" ]] || \
  [[ -n "${BT_PEEK}" || -n "${BT_SIG}" ]] && \
  [[    "${BT_PEEK}"         =~ ^\s*   ]] || \
  [[    "${BT_SIG}"          =~ ^\s*   ]] && {
    peek_merge
    return
  } 

  diff_peek
}

to_debug flow && echo pmpt:peek_merge

# Replace latest peek with the last.
peek_merge() { 

  [[ -z "${BT_PEEK}" || -z "${BT_SIG}" ]] || \
  [[ -n "${BT_PEEK}" || -n "${BT_SIG}" ]] && \
  [[    "${BT_PEEK}"         =~ ^\s*   ]] || \
  [[    "${BT_SIG}"          =~ ^\s*   ]] && {
    export BT_PEEK="${NEXT_PEEK}" BT_SIG="${NEXT_SIG}"
    unset NEXT_PEEK NEXT_SIG 
    source <(${BT}/lib/bt_export.py)
    diff_peek
  } 
} 

# ----------------------------------------------
# prompt
# ----------------------------------------------
# Shows aws login status, and when creds expire.
# NOTE: requires: dateutils
#

to_debug flow && echo pmpt:kickstart

# kickstart the prompt.
ks() { 

[[ -z "${NEXT_PEEK}" ]] && { 
  source <(${BT}/lib/bt_export.py)
  assert_next 2>/dev/null
  diff_peek 2>/dev/null
}

} 

[[ -z "${NEXT_PEEK}" ]] && { 
  source <(${BT}/lib/bt_export.py)
  assert_next 2>/dev/null
  diff_peek 2>/dev/null
}


to_debug flow && echo pmpt:prompt_on

# turn off the prompt 
# -------------------
function prompt_off() { unset PROMPT_COMMAND ;}
function prompt_on() { export PROMPT_COMMAND="prompt" ;} 


function prompt() {
  # generate the next cache peek, 
  # and hence, the next prompt.

  PS1="$(_prompt)"
  export PS1
}


# fast check: No audits required.
# corrects for: ENV wiped in subshell.
#   -- token hints for focal session highest session matches token ENV var.
#   -- if yes, return true.



to_debug flow && echo pmpt:_prompt_func


# ascii color routines can affect 
# the printable width of your prompt. 
# Be sure to use Octal caracter defs,
# otherwise you will get weird mismatches 
# when text on screen wraps around.
#
_nc() { echo -e "\001${NC}\002" ;}

_prompt() { 

  # Examine the current env state. 
  get_role() { 
      echo "${BT_ROLE}" || echo "qventus"
  }
  get_team() { 
      echo "${BT_TEAM}" || echo "arch"
  }
  usr="$(get_usr)"
  sso="$(get_usr)"
  team="$(get_team)"
  account="$(get_account)"
  session="$(get_role)"
  guild="NONE"

  readarray -t F < <(this_peek |                   \
                     jq -r '"\(.assert)
                             \(.account|to_entries[]|select(.key)|.key)
                             \(.position.default)"')

  # load peek info in one operation.
  vals="$(printf '%s ' "$(this_peek | \
      jq -r '.assert,.chains.default[],.aws_ids[],.tokens[],.profiles[],.expires[]')")"
  declare -a symbols=( "${vals}" ) C A T P E X
  #debug echo "symbols: ${#symbols[@]}"

  assert=${symbols[0]}
  C=( "${symbols[@]:1:4}"  )
  A=( "${symbols[@]:5:4}"  )
  T=( "${symbols[@]:9:4}"  )
  P=( "${symbols[@]:13:4}" )
  E=( "${symbols[@]:17}"   )

  for e in $(this_peek | jq -r '.expires[]'); do
    exp="$(echo ${e} | ddiff -i '%s' -Eqf %S now)"
    EXP+=( "${exp}" )
  done

  t="$(_timer "${EXP}")"
  c="$(_colorize "${t}")"
  r="$(_role "${R}" "${t}")"
  
  MASK="$(echo "${F[0]}" | perl -nle 'print tr/1//')"
  to_debug pmpt echo "MASK: ${MASK}"

  [[ "${session}" == "${P[2]}" ]] && MASK=3  # account profile is present.
  [[ "${session}" == "${P[3]}" ]] && MASK=4  # guild profile is present.

  # set focus
  [[ "${F[2]}" == "1" || "${F[2]}" == "3" ]] && focus="${F[2]}" # explicitly set.
  [[ "${MASK}" -lt 2 ]] && focus=0
  [[ "${MASK}" -gt 2 ]] && focus=2


  printf '%s' "$c" "[-" "$r" "->" "$X" "]$n\w\$ " && return

  # when no sessions are active.
  if [[ "${t}" -ge 0 ]]; then  
    printf '%s' "$c" "[-" "$r" "->]" "$n" "\w\$ " && return
  else 
    # show nothing, if BT_SETTINGS=quiet
    [[ "${BT_SETTINGS}" =~ no_prompt ]] && {
      printf '%s' "$c" "[---->]" "$n" "\w\$ " && return
    }
    # fallback to normal prompt. 
  fi
  
}

to_debug flow && echo pmpt:_timer

_timer() {
 
  focus_secs="${1}"
  [[ -z "${focus_secs}" ]] && focus_secs=0

  # When role is active, show role timer.
  [[ "${focus_left}" -gt 1 ]] && {
    timer="$( echo                                      \
            "$(gdate --iso-8601=seconds                 \
              -d@ $(("$(gdate +%s)" + "${focus_left}")) \
            )" | ddiff -E -qf %Hh:%Mm:%Ss now           \
          )"
    
    echo -ne "${t}" && return
  } 
 
  # if both are inactive, show no timer. 
  #[[ "${focus_secs}" -lt 1 ]] && \
  #echo -ne "" && return

  # in test mode, show dummy timer.
  #role="$(get_role)"
  role="qventus"
  [[ -n "${BT_MODE}" &&  \
    "${BT_MODE}" == "test" ]] && { 
    timer="--:--:--" && echo -ne "${timer}" && return
  }

  # otherwise, do not display a timer.
    echo -ne "" && return
}


to_debug flow && echo pmpt:_role

_role() { 

  # peek at caches to ensure nothing 
  # has changed.
  #_autosource

  profile="${1}" 
  expire="${2}" 

  # For the empty display, we use '--'
  [[ "${profile}"  -eq 2 ]] && { 
   
      role="$(get_role)"
      echo -ne "${role}" && return
  }  

  [[ "${profile}" -eq 1 ]] && { \
      team="$(get_team)" 
      echo -ne "${team}" 
      return
  } 

  [[ "${profile}" -lt 1 ]] && { \
      echo -ne "--" 
      return
  }
  role="--" && echo -ne "${role}" && return

}


to_debug flow && echo pmpt:_colorize

# colorize the output based on expire time 
# of the current focus. Prompt goes YELLOW 
# when expire time is within 5 minutes. 
#
_colorize() {

  expire="${1}" 
  expires=0

  # focus takes precedence when defining color.
  #expires=230
  if   [[ "${expire}" -lt  -1 ]]; then color="${RED}"
  elif [[ "${expire}" -eq   0 ]]; then color="${GRAY}"
  elif [[ "${expire}" -lt 300 ]]; then color="${YELLOW}"
  elif [[ "${expire}" -gt 301 ]]; then color="${GREEN}"
  else
    :
  fi
  echo -e "\001${color}\002"
}

to_debug flow && echo pmpt:autosession

# unattended login
# ----------------
# This function is used by various generators and scripts 
# that may be run unattended. Without this, they cannot 
# guarantee a viable environment at startup. 
# 
autosession() { 

  [[ $(which assume) ]] || { 
     echo "${RED}FATAL: ${NC}Cannot find 'assume' utility." 
     echo "Check that \$PATH is properly generated."
     return 1
  } 

  CREDS="${AWS_SHARED_CREDENTIALS_FILE}"
  rotate
  focus="$(diff_peek | \
             cut -d'|' -f 7 | \
             xargs -I '{}' grep -A 8 {} ${CREDS} | \
             grep awsumepy_command | awk '{print $4}')"
  echo focus: "${focus}"
  [[ -n "${focus}" ]] && { 
     source <(assume ${focus} -o qventus -s)
     aws_whoami >/dev/null 2>&1 && {
       echo "${GREEN}success.${NC}" 
       return
     } || { 
       "echo ~Illusion sounds~."
     }
  }  

  #status=( $(diff_peek | gawk -F\| '{print $NF}') )
  target=( "$(parse_session "${status[0]}")"  ) 
  
  team="${target[0]}"   
  account="${target[1]}"   
  aws_id="${target[2]}"   
  guild="${target[3]}"   

  position="$(this_peek | jq '.position.default')"
  [[ "${position}" -eq 0 ]] && position=3 

  for e in "${status[@]:1:${position}}"; do 
    [[ $e -gt 1 ]] && active=yes || active=no
  done

  [[ "${active}" == "yes" ]] && { 
    debug echo "Active session found.  Reusing..."
    source <( assume -o qventus -s) 
  } 

  update_env

}


to_debug flow && echo pmpt:_colorize

# colorize the output based on expire time 
# of the current focus. Prompt goes YELLOW 
# when expire time is within 5 minutes. 
#
_colorize() {

  expire="${1}" 
  expires=0

  # focus takes precedence when defining color.
  expires=230
  if   [[ "${expire}" -lt  -1 ]]; then color="${RED}"
  elif [[ "${expire}" -eq   0 ]]; then color="${GRAY}"
  elif [[ "${expire}" -lt 300 ]]; then color="${YELLOW}"
  elif [[ "${expire}" -gt 301 ]]; then color="${GREEN}"
  else
    :
  fi
  echo -e "\001${color}\002"
}



to_debug flow && echo pmpt:update_env 


# Update the user's ENV. 
# Recover from many known scenarios. 
#
update_env() {

  [[ "${BT_PROMPT}" == "debug" ]] && { 
  OUT="$(diff_peek | \
    perl -pe \
      's/^|(ASRT[01]{4}).*PRF([0-3)|([\w_-]+)(\s+\-?[\d+]{1,4})/
           \1             |\2       \3       \4/gx; 
       s/\s/\|/g; s/^[\|]+//g; s/[\|]+$//g')"
  } && echo "DBG> $OUT"

  # TODO:
  # - if flagged: focus -> determine new focus.
  # - switch focus.
  # - update AUTH tokens (all 3, use AWSUME)
  ASRT="$(this_peek | jq -r '.assert' | perl -nle 'print tr/1//')"

  [[ "${ASRT}" -gt 0 ]] && { 
    # try multiple times to regain creds from lower chains.
    source <(assume -o qventus -s && echo BT_TEST=assert 2>/dev/null)
    [[ -z "${BT_TEST}" ]] && { 
      # if we fail again, regenerate creds.
      echo "assert failed."
      source <(assume -o qventus -s) 
    } 

    [[ -z "${AWS_SESSION_TOKEN}" ]]  && { 
    echo -ne "WARN: assume ENV failed. Regenerating creds stub...\n"
    source <(assume -s 2>/dev/null)  
      _try assume -o qventus -s -- regen_qv_stub regen_creds
    } 

    [[ -z "${AWS_SESSION_TOKEN}" ]]  && { 
      echo -ne "WARN: assume ENV failed. Regenerating creds...\n"
      source <(assume -s 2>/dev/null)  
      _try assume -o qventus -s -- autosession
    } 

    [[ -z "${AWS_SESSION_TOKEN}" ]] && { 
      echo -ne "WARN: Failed a third time. Full relogin.\n" 
      return 1
    } 
  }

  #  debug echo "regenerating creds"
  #  regen_creds 
  #  debug echo "assuming ${role} (second attempt)"
  #  assume -a "${role}" -o qventus
  #  source <(assume -s 2>/dev/null) 

  # set the focus of the chian (aka MASK).
  # If not explicit, assume the most  recent role 
  # (as determined by the cache).
  team="$(cat ${AWS_CONFIG_FILE} | \
          perl -nle 's/.*aws_team_([\w_\-]+)/\1/' | \
          tail -n 1)" 
  account="$(get_account)"
  MASK=2  # default.
  [[ "${MASK}" -eq 4 ]] && export BT_GUILD="${account}-guild-${guild}" && return
  [[ "${MASK}" -eq 3 ]] && export BT_ROLE="${account}-${team}" && return
  [[ "${MASK}" -eq 2 ]] && export BT_TEAM="${team}" && return
  [[ "${MASK}" -eq 1 ]] && export BT_SSO="${BT_USR}" && return 
  [[ "${MASK}" -eq 0 ]] && export BT_SSO=NONE \
                                  BT_TEAM=NONE \
                                  BT_ROLE=NONE \
                                  BT_GUILD=NONE && return

}

to_debug flow && sleep 0.5 && echo pmpt:end

