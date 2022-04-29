#export BT_DEBUG=stng,lgin,flow,rds,rdsc,cche,qv,prmt
to_debug() { [[ "${BT_DEBUG}" = *$1* ]] && >&2 "${@:2}" ;}

BT=${HOME}/.bt
export BT="${BT}"
to_debug flow && echo BT: ${BT}

#to_debug flow && sleep 1 && echo "main-loader"
#source ${BT}/lib/loader.sh

#to_debug flow && sleep 1 && echo "main-addpath"
#loader_addpath ${BT}/lib

# utility libs.
q_pushd()  { pushd ${1} >/dev/null 2>&1 || return ;}
q_popd()   { popd ${1} >/dev/null 2>&1 || return ;}

to_debug flow && sleep 1 && echo "main-bt_env"
include bt_env 2>/dev/null

to_debug flow && sleep 1 && echo "main-api"
include api    2>/dev/null

to_debug flow && sleep 1 && echo "main-arr"
include arr    #2>/dev/null

to_debug flow && sleep 1 && echo "main-data"
include data   #2>/dev/null

to_debug flow && sleep 1 && echo "main-main.sh"
include utils

to_debug flow && sleep 1 && echo "main-rdslib"
include rdslib

to_debug flow && sleep 1 && echo "main-other"
#include prompt 2>/dev/null
#include sec
#include release

