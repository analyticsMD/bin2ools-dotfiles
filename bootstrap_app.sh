#!/usr/local/bin/bash

set -e
# prep steps (run only once)

# install a few deps
brew install bash coreutils jq perl zlib xz tree pstree git
brew tap microsoft/git
brew install --cask git-credential-manager-core

# uncomment if needed.
# brew tap "syncdk/aws-session-manager-plugin"
# brew install awscli@2 aws-session-manager-plugin

# checkout dotfiles repo.
repo="https://github.com:analyticsmd/bin2ools-dotfiles.git"
git clone $repo ${HOME}/.bin2ools-dotfiles

# link into repo.
ln -s ${HOME}/.bt ${HOME}/.bin2ools-dotfiles/bt


# install devops package.
url="git+https://github.com/analyticsmd"
path="devops-sso-util"
get="@master#subdirectory"
pipx install "devops-sso-util @ $url/$path/$get=cli"
pipx install "bin2ools-ssm @ $url/$path/$get=bin2ools-ssm"
pipx install "bin2ools-rds @ $url/$path/$get=bin2ools-rds"

echo "ALMOST DONE!  Generating AWS Profiles..."
export BT_ACCOUNT=prod BT=${HOME}/.bt && cd ${BT}
${BT}/gen/profiles



