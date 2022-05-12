#!/usr/bin/env /usr/local/bin/bash

# BT_LOADER
# ---------
# Small mini-loader for dotfiles in your shell. 

# DISPLAY SOURCES.
# ----------------
# Uncomment this if you want to display loaded files 
# at runtime, color coded based on success or failure. 

#export BT_SETTINGS="quiet alog src"
bt_settings() { [[ "${BT_SETTINGS}" = *$1* ]] && >&2 "${@:2}" ;}

# ----------------------------------------------------------------
# GENERATORS 
# ----------------------------------------------------------------
# Scripts that generate bintools automated configs.
# See: ${BT}/utils/gen
  
# ----------------------------------------------------------------
# SOURCING
# ----------------------------------------------------------------
# Bintools does a lot of sourcing to create a productive environment. 
#
# WHERE TO SEARCH.
# --------------_-
# Search these top-level directories under your Bin2ools home, 
# e.g. ${HOME}/.bt/foo, ${HOME}/.bt/bar, etc., for sourceable files.
#
declare -a source_these=()
export source_these=( arr src gen arr utils )
#                     ^
#                     | add here.


bt_src() {

    q="${1}"  # "quiet" or "noisy"
     
    source_these=( arr src gen arr utils )
  
    # Array of dirs where source files live.
    # As a rule, we source ONLY from here, and ONLY once.
    dirs=( ${source_these[@]} )                

    shopt -q extglob;     extglob_set=$?
    ((extglob_set))       && shopt -s extglob
  
    for d in $(printf "%s\n" "${dirs[@]}"); do
      # sources dirs only. 
      to_debug src && echo dir: $d
      [[ "${d}" = @(src|gen|utils) ]] || continue  
      DIR="${BT}/${d}" && q_pushd 2>/dev/null "${DIR}"
      [[ "$q" == "noisy" ]] && echo -ne "Sourcing in ${DIR}...\n\n"
      # shellcheck disable=SC2125
      glob=[!_!.]?*
      files=( "$( printf "%s\n" "${glob}")" )
      to_debug src && echo ${files[@]}
      # longest file (for pretty-printing). 
      lg="$(printf '%s\n' ${files[@]} | awk '{ print length }' | sort -rn | head -n 1)" 
      for f in $(printf '%s' "${files[@]}"); do
        [[ ${f} = *.@(new|cmpl|src|gen|arr) ]] || continue
        src_str="\t./${f}"
        # shellcheck disable=SC1090,SC1094 
        COLOR=${BLUE}
        [[ "$q" == "noisy" ]] && { 
            src_str="\t./${f}"
            # shellcheck disable=SC1090,SC1094 
            source ./"${f}" >/dev/null 2>&1 &&    \
            status="success!" COLOR="${GREEN}" || \
            status="failed." COLOR="${RED}"
            printf "%b%*.b%b${COLOR}%s${NC}%b\n"  \
              "$src_str" $(( lg - "${#f}" + 4 )) "."30 "" "${status}"

        } || {  
            source ./"${f}" >/dev/null 2>&1 
        } 
      done
      # shellcheck disable=SC2119
      q_popd && echo "done."
      echo -ne "\n\n\n"
    done

    [[ "${NOISE}" == "noisy" ]] && { 
        tree -a -C "${BT}/src" --noreport --dirsfirst -F
        echo -e "${GRAY}_____${NC}" 
    }  
    # toggle off globbing, but only if it was off before.
    ((extglob_set))     && shopt -u extglob
}

# For fun, show a pretty tree-based display.  
#( NOTE: BT_SETTINGS=quiet suppresses this.) 
# 
# shellcheck disable=SC2015
bt_settings src && bt_src "${NOISE}" && return

