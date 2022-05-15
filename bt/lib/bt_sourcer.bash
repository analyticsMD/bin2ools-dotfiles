
# DISPLAY SOURCES.
# ----------------
# Uncomment this if you want to display loaded files 
# at runtime, color coded based on success or failure. 
to_debug() { [[ "${BT_DEBUG}" = *$1* ]] && >&2 "${@:2}" ;} || true

#export BT_SETTINGS="quiet alog src"
bt_settings() { [[ "${BT_SETTINGS}" = *$1* ]] && >&2 "${@:2}" ;} || true

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


bt_src() {

    declare -a source_these=()
    export source_these=( arr src gen arr utils )
    #                     ^
    #                     | add here.
    q="${1}"  # "quiet" or "noisy"
     
    source_these=( arr src gen arr utils )
  
    # Array of dirs where source files live.
    # As a rule, we source ONLY from here, and ONLY once.
    dirs=( ${source_these[@]} )                

    shopt -q extglob;     extglob_set=$?
    ((extglob_set))       && shopt -s extglob
    rgx="$( join_by \| ${source_these[@]} )"
    echo rgx: "$rgx"
    return
    for d in $(ls @($rgx)); do 
      to_debug src && echo dir: $d
      q_pushd "${BT}/${DIR}"
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
      echo -ne "OK.\n\n\n"
    done

    [[ "${NOISE}" == "noisy" ]] && { 
        tree -a -C "${BT}/src" --noreport --dirsfirst -F
        echo -e "${GRAY}_____${NC}" 
    }  
    # toggle off globbing, but only if it was off before.
    ((extglob_set))     && shopt -u extglob
} || true

# For fun, show a pretty tree-based display.  
#( NOTE: BT_SETTINGS=quiet suppresses this.) 
# 
# shellcheck disable=SC2015
popd -1 >/dev/null 2>&1 || true
bt_settings src && bt_src "${NOISE}" || true
