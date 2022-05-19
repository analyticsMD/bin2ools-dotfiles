
# DISPLAY SOURCES.
# ----------------
# Uncomment this if you want to display loaded files 
# at runtime, color coded based on success or failure. 
to_debug() { [[ "${BT_DEBUG}" = *$1* ]] && >&2 "${@:2}" ;} || true

export BT_SETTINGS=" quiet alog src "
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
join_by() { local IFS="|"; shift; echo "$*" ;} || true

bt_source() {

    declare -a source_these=()
    declare -a file_types=()
    export source_dirs=( "src" )
    export file_types=( "src" "cmpl" "arr" )
    #                    ^
    #                    | add here.

    q="${1}"    # "quiet" or "noisy"
    gen="${2}"  # "generate files (as well as sourcing."

    # Array of dirs where source files live.
    # As a rule, we source ONLY from here, and ONLY once.

    shopt -q extglob;     extglob_set=$?
    ((extglob_set))       && shopt -s extglob
    dir_glob="src"
    to_debug src && echo dir_glob: $dir_glob
    # if 'gen' is set, add generators and utils.
    # NOTE: this will take much longer. 
    file_glob="src|cmpl|arr" 
    [[ -z "${gen}" ]] && { 
        file_glob="$( join_by \| ${file_types[@]} )"
        dir_glob="$( join_by \| ${source_dirs[@]} )"
    } || { 
        file_glob="$( join_by \| ${file_types[@]}  gen utils )"
        dir_glob="$(  join_by \| ${source_dirs[@]} gen utils )"
    } 
    to_debug src && echo file_glob: $file_glob


    for d in $(ls -d1 *@($dir_glob)); do 

      [[ "${#dirs[@]}" -gt 0 ]] && continue
      to_debug src && echo dir: $d
      pushd "${BT}/${d}"
      [[ "$q" == "noisy" ]] && { echo -ne "Sourcing in ${d}..." ;}

      # shellcheck disable=SC2125
      filter_glob=[!_!.]?*
      files=( "$( printf "%s\n" "${filter_glob}")" )
      to_debug src && echo files: ${files[@]}
      [[ "${#files[@]}" -gt 0 ]] &&  continue

      # longest file (for pretty-printing). 
      lg="$(printf '%s\n' ${files[@]} | awk '{ print length }' | sort -rn | head -n 1)" 
      for f in $(printf '%s' "${files[@]}"); do
        [[ "${f}" = *@($file_glob) ]] || continue
        src_str="\t./${f}"
        # shellcheck disable=SC1090,SC1094 
        COLOR=${PURPLE}
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
      echo -ne "${GREEN}OK.${NC}\n\n\n"
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
# || true
bt_settings src && bt_source "${NOISE}" || true
