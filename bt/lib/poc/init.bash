#!/usr/bin/env /usr/local/bin/bash

# init.bash
# ----------
# Loads libraries for a one-shot
# script, passed in as an arg. 

# parallel loader project 
declare -a CMD=()
CMD+=( ${*:1} ) 

# starter file, for the shell script loader. 
export BT="${HOME}/.bt"

# source the script:  loader.sh
. ${BT}/lib/loaderx.bash

loader_addpath "${BT}/lib"
#loader_addpath "${BT}/src"
#loader_addpath "${BT}/gen"
#loader_addpath "${BT}/utils"

loadx ${CMD[*]}

# loaders use advanced glob patterns, 
# hence, this one loads all files within 
# the 'lib' directory that DO NOT begin
# with an underscore (_). 
includex ${BT}/lib/[^_]*.bash

includex "${BT}/settings" >/dev/null 2>&1
. "${BT}/settings"

echo CMD: ${CMD[@]}
callx ${CMD[@]}
