#!/usr/bin/env /usr/local/bin/bash

# Generator for poetry helper functions and aliases. 
# These make the transition seamless between dotfiles
# and python pipx packages.

# ----------------
# helper functions. 
# -----------------

join_by() { local IFS="$1"; shift; echo "$*" ;}

this_load() {

    # Static libs.  No globbing.  Anything else was too brittle.
    . "${BT}/lib/bt.bash" >/dev/null 2>&1
    . "${BT}/lib/utils.bash" >/dev/null 2>&1
    . "${BT}/lib/api.bash" >/dev/null 2>&1
    . "${BT}/lib/env.bash" >/dev/null 2>&1
    . "${BT}/lib/rdslib.bash" >/dev/null 2>&1
    . "${BT}/lib/bt_sourcer.bash" >/dev/null 2>&1
#    . "${BT}/lib/bridge.bash" >/dev/null 2>&1
#    . "${BT}/lib/bridge_ssm.bash" >/dev/null 2>&1

    funcs="$(declare -F | wc -l)"
    echo -en "${GREEN}success${NC} - "


    if ! $(declare -F | grep bt_src >/dev/null 2>&1); then
        echo -e "Loaded ${CYAN}$(declare -F | wc -l)${NC} functions."
        return
    fi

} || true

this_load



export h='${HOME}'     v=".local/pipx/venvs" c='${core}' l=lib \
       p='python3.10'  s=site-packages       b=b2        pkg='ssm'

# this array becomes the path. 
declare -a local_path=( $h $v $c $l $p $s $b$pkg ) 

BT_PATH="$( join_by '/' ${local_path[@]} )"



EXIT

# sanity check.  Generates bash code. 

cat  <<-'HERE_BE_DOCS' 

echo BT_PATH: ${BT_PATH}

[[ ! "${BT_PATH}" =~ "${PATH}" ]] && { 
   echo -e "${RED}FATAL${NC}: path not present."
   return 1
} 

HERE_BE_DOCS


# Function Generator.  Generates functions for all 
# packages in a nested loop. 


# use split+glob (leave ${lines} unquoted):


lines=$(cat <<HERE_BE_FUNCS
    pkg=foo tool=bar 
    bt_${pkg}_${tool}() { 
      source \"${BT_PATH}/${b}${pkg}/${pkg}_${tool}\"
    } 
    alias ${pkg}_${tool}=\"bt_${pkg}_${tool}\" 

HERE_BE_FUNCS
)

export pkg="ssm" tool="complete"
declare -a tools=( "complete" "generate" "local" )
declare -a pkgs=(  "ssm"      "rds"      ""      )

for pkg in ${pkgs}; do 
  for tool in ${tools}; do
    for line in ${lines}; do
    lines=$(cat <<HERE_BE_FUNCS

      bt_${pkg}_${tool}() { 
        source \"${BT_PATH}/${b}${pkg}/${pkg}_${tool}\"
      } 
      alias ${pkg}_${tool}=\"bt_${pkg}_${tool}\" 

HERE_BE_FUNCS
)
    done
  done
done

IFS=$'\n'      # split on non-empty lines
set -o noglob  # disable globbing as we only 

# want the split part.

for pkg in ${pkgs[@]}; do
  for tool in ${tools[@]}; do
    for line in ${lines[@]}; do
      export pkg="${pkgs[0]}" tool="${tools[0]}"
      echo ${line}
    done
  done
done

echo # done. 



