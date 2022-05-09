#!/usr/bin/env /usr/local/bin/bash

# _init.bash
# ----------
# Intended to load libraries for a one-shot
# script, given as an arg. 

# parallel loader project 
declare -a CMD=()
CMD+=( ${*:1} ) 

# starter file, for the shell script loader. 
export BT="${HOME}/.bt"

# load loader.sh
. ${BT}/lib/loaderx.bash

loader_addpath "${BT}/lib"
#loader_addpath "${BT}/src"

loadx ${CMD[*]}

includex ${BT}/lib/[^_]*.bash
includex "${BT}/settings" >/dev/null 2>&1
. "${BT}/settings"

echo CMD: ${CMD[@]}
callx ${CMD[@]}
