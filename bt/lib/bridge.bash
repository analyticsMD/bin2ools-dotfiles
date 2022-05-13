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
    . "${BT}/settings"            >/dev/null 2>&1
    . "${BT}/lib/bt.bash"         >/dev/null 2>&1
    . "${BT}/lib/utils.bash"      >/dev/null 2>&1
    . "${BT}/lib/api.bash"        >/dev/null 2>&1
    . "${BT}/lib/env.bash"        >/dev/null 2>&1
    . "${BT}/lib/rdslib.bash"     >/dev/null 2>&1
    . "${BT}/lib/bt_sourcer.bash" >/dev/null 2>&1
    #. "${BT}/lib/bridge.bash" >/dev/null 2>&1


    funcs="$(declare -F | wc -l)"
    echo -en "${GREEN}success${NC} - "


    if ! $(declare -F | grep bt_src >/dev/null 2>&1); then
        echo -e "Loaded ${CYAN}$(declare -F | wc -l)${NC} functions."
        return
    fi

} || true

this_load

source <(echo -e "$("${HOME}/utils/path" -s 2>/dev/null)")

IFS=':' read -r -a THIS_PATH <<< "${PATH}"

declare -a tools=()
for path in ${THIS_PATH[@]}; do 
    [[ "${path}" =~ \/b2 ]] && { 
       tool="$( basename "${path}" )" 
       tools+=( $tool ) 
       pkg="$( basename "$(dirname "${path}" )")" 
       pkgs+=( $pkg )
    } 
done

# --------------------------------------
# PIPX CONSOLE SPACE
# --------------------------------------
[[ -z "${core}"   ]] && c='devops-sso-util'
[[ -z "${python}" ]] && p='python3.10'

declare -a tools=( rds ssm ) 
export h="${HOME}"     v=".local/pipx/venvs" c="devops-sso-util"   l=lib \
       p='python3.10'  s=site-packages       b=b2                  tool=$t
 
declare -a TMP_PATH=() 
declare -a NEW_PATH=() 
# this array becomes the path. 
for t in ${tools[@]}; do
      declare -a local_path=() 
      local_path+=( $h $v $c $l $p $s $b$t ) 
      TMP_PATH="$( join_by '/' ${local_path[@]} )"
      echo TMP_PATH="$( join_by '/' ${local_path[@]} )"
      NEW_PATH+=( "$TMP_PATH" ) 
  done 
     
  BT_PATHS="$( join_by : ${NEW_PATH[@]} )"



# sanity check.  Generates bash code. 

cat  <<-'HERE_BE_DOCS' 

  [[ "${#BT_PATHS[@]}" -lt 1 ]] && { 
      echo -e "${RED}FATAL${NC}: pipx paths not present."
      return 1
  } 

HERE_BE_DOCS


# Function Generator.  Generates functions for all 
# packages in a nested loop. 


# use split+glob (leave ${lines} unquoted):


lines=$(cat <<HERE_BE_FUNCS
    pkg=b2rds tool=rds 
    bt_${pkg}_${tool}() { 
      source "${BT_PATH}/${b}${pkg}/${pkg}_${tool}"
    } 
    alias ${pkg}_${tool}="bt_${pkg}_${tool}" 

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



