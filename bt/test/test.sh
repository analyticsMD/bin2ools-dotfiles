#!/usr/bin/env /usr/local/bin/bash

export BT=${HOME}/local/bin

q_pushd () { command pushd "$@" > /dev/null ;}

q_popd () { command popd "$@" > /dev/null ;}

declare -a source_dirs
source_dirs+=(sources sources/generate.d)
#source_dirs+=(config.d)

for d in ${source_dirs[@]}; do
  q_pushd ${BT}/$d
  echo "Sourcing in ./$d ..."
  while IFS='\n' read -r f; do
    [[ "$f" =~ \.(src|cmpl|gen)$ ]] || continue
    echo -ne "\t$f ..." && source $f >/dev/null
    [ $? -eq 0 ] && echo -ne "success.\n" || echo -ne "failed!i\n"
  done < <( pushd ${BT}/$d && find . -maxdepth 1 -type f -print | sort && popd)
  q_popd
done
