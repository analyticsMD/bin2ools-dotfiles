
bt_ssm_complete\(\) \{ 
    source /Users/marc/.local/pipx/venvs/devops-sso-util/lib/python3.10/site-packages/b2ssm/ssm_complete
\} 


bt_ssm_generate\(\) \{ 
    /Users/marc/.local/pipx/venvs/devops-sso-util/lib/python3.10/site-packages/b2ssm/ssm_generate
\} 


bt_ssm_local\(\) \{ 
    /Users/marc/.local/pipx/venvs/devops-sso-util/lib/python3.10/site-packages/b2ssm/ssm_local $\{1\}
\} 

alias ssm="bt_ssm_local "
alias ssm_complete="bt_ssm_complete "
alias ssm_generate="bt_ssm_generate "
