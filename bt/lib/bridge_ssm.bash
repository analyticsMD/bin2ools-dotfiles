export BT_PATH=/Users/marc/.local/pipx/venvs/devops-sso-util/lib/python3.10/site-packages/b2ssm/ssm_complete

h='${HOME}'
v=".local/pipx/venvs"
c='${core}'
l=lib
p='python3.10'
s=site-packages
b=b2
pkg='ssm'

declare -a path=( $h $v $c $l $p $s $b $pkg ) 

bt_ssm_complete() { 
    source ${BT_PATH}
    path="$(dirname ${HOME}/.local/pipx/venvs/${CORE}/lib/${py}/site-packages/b2ssm/ssm_complete)" 
     
} 


bt_ssm_generate() { 
    /Users/marc/.local/pipx/venvs/devops-sso-util/lib/python3.10/site-packages/b2ssm/ssm_generate
} 


bt_ssm_local() { 
    /Users/marc/.local/pipx/venvs/devops-sso-util/lib/python3.10/site-packages/b2ssm/ssm_local ${1}
} 

alias ssm="bt_ssm_local "
alias ssm_complete="bt_ssm_complete "
alias ssm_generate="bt_ssm_generate "
