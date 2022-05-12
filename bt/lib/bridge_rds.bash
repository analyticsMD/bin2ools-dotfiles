
bt_rds_complete\(\) \{ 
    source /Users/marc/.local/pipx/venvs/devops-sso-util/lib/python3.10/site-packages/b2rds/rds_complete
\} 


bt_rds_generate\(\) \{ 
    /Users/marc/.local/pipx/venvs/devops-sso-util/lib/python3.10/site-packages/b2rds/rds_generate
\} 


bt_rds_local\(\) \{ 
    /Users/marc/.local/pipx/venvs/devops-sso-util/lib/python3.10/site-packages/b2rds/rds_local $\{1\}
\} 

alias rds="bt_rds_local "
alias rds_complete="bt_rds_complete "
alias rds_generate="bt_rds_generate "
