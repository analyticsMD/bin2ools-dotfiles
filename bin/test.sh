#!//usr/local/bin/bash

touch ${HOME}/.bash_profile
REF="$(cat ${HOME}/.bash_profile | \
       perl -lne 'print if m/BIN2OOLS/' | wc -l)"
echo REF: $REF
if [[ "${REF}" -eq 0 ]]; then  
  {
    echo -ne "# --------------------------\n"
    echo -ne "# BIN2OOLS entries.\n"
    echo -ne "# --------------------------\n"
    echo -ne "shopt -s expand_aliases\n"
    echo -ne "shopt -s progcomp_alias\n"
    echo -ne "_bt() { export BT=\"\${HOME}/.bt\"; . \"\${HOME}/.bt/settings\"; prompt_on ;}\n"
    echo -ne "alias bt=\"_bt; . \$(b2)\"\n"
    echo -ne "# --------------------------\n"
    export PATH="/usr/local/sbin:$PATH"
  } >> ${HOME}/.bash_profile
fi
