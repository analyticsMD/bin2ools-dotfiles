# utility libs.
#export BT_DEBUG=stng,lgin,flow,rds,rdsc,cche,qv,prmt
to_debug() { [[ "${BT_DEBUG}" = *$1* ]] && >&2 "${@:2}" ;}
q_pushd()  { pushd ${1} >/dev/null 2>&1 || return ;}
q_popd()   { popd ${1} >/dev/null 2>&1 || return ;}

export BT="${HOME}/.bt"
to_debug flow && echo BT: "${BT}"

#to_debug flow && sleep 1 && echo "main-addpath"

to_debug flow && sleep 1 && echo "(main.bash) bt_env,arr,data,utils,rdslib,api"
includex livex.bash* 2>/dev/null

#to_debug flow && sleep 1 && echo "main-other"
#include prompt 2>/dev/null
#include sec
#include release

