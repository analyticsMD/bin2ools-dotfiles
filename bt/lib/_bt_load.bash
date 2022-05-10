#!/usr/bin/env /usr/local/bin/bash

# BT_LOADER
# ---------
# Small mini-loader for dotfiles in your shell. 

# DISPLAY SOURCES.
# ----------------
# Uncomment this if you want to display loaded files 
# at runtime, color coded based on success or failure. 
#
# export BT_SETTINGS=quiet


# WHERE TO SEARCH.
# --------------_-
# Search these top-level directories under your Bin2ools home, 
# e.g. ${HOME}/.bt/foo, ${HOME}/.bt/bar, etc., for sourceable files.
#
declare -a source_these=( src )
#                          ^
#                          | add here.


bt_load() {  
  
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
  # Globbing
  # --------
  # Advanced globbing is an easy way to sort through files. 
  # 
  shopt -q extglob;     extglob_set=$?
  ((extglob_set))       && shopt -s extglob

  # Array of dirs where source files live.
  # As a rule, we source ONLY from here, and ONLY once.
  dirs=( ${source_these[@]} )                

  for d in $(printf "%s\n" "${dirs[@]}"); do
    # sources dirs only. 
    [[ "${d}" = src* ]] || continue  
    DIR="${BT}/${d}" && q_pushd 2>/dev/null "${DIR}"
    echo -ne "\n\n${BLUE}Sourcing in ${DIR}...${NC}\n\n"
    # shellcheck disable=SC2125
    glob=[!_]?*
    files=( "$( printf "%s\n" "${glob}")" )
 
    # longest file. 
    lg=0
    for f in $(printf '%s' "${files[@]}"); do 
      this=${#f}
      [[ "$lg" -le "$this" ]] && lg=$this 
    done
 
    for f in $(printf '%s' "${files[@]}"); do
      [[ ${f} = *.@(new|cmpl|src|gen|arr$) ]] || continue
      src_str="\t./${f}"
      # shellcheck disable=SC1090,SC1094 
      source ./"${f}" >/dev/null 2>&1    && \
      status="success!" COLOR="${GREEN}" || \
      status="failed."  COLOR="${RED}"  
      printf "%b%*.b%b${COLOR}%s${NC}%b\n"  \
          "$src_str" $(( lg - "${#f}" + 10 )) "."30 "" "${status}"
    done
    # shellcheck disable=SC2119
    q_popd && "echo thanks!"
  done

  echo -e ${GRAY}_____${NC} 

  # toggle off globbing, but only if it was off before.
  ((extglob_set))     && shopt -u extglob
  echo -ne "\n\n\n"
  
  # For fun, show a pretty tree-based display.  
  #( NOTE: BT_SETTINGS=quiet prevents this.) 
  tree -a -C "${BT}"/src --noreport --dirsfirst -F

}

# shellcheck disable=SC2015
[[ "${BT_SETTINGS}" = *quiet* ]] && q > /dev/null 2>&1 || q

