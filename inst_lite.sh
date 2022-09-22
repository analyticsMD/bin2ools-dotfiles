#!/usr/bin/env bash

# common errors.
[ -z "${HOME}" ] && echo "no HOME var." && exit 1
[[ "${SHELL##*/}" != "bash" ]] && echo "wrong SHELL." && exit 1
[[ "${BASH_VERSION%%.*}" -lt 5 ]] && echo "bad shell version: ${BASH_VERSION}"

rm -rf ${HOME}/.bt ${HOME}/bintools ${HOME}/.bin2ools-dotfiles ${HOME}/.brew


# removed /usr/local/bin links to ~/.local and ~/.brew

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' > ~/.tmp_profile
echo "$(/opt/homebrew/bin/brew shellenv | tee ${HOME}/.tmp_profile)"
[ -f "${HOME}/.tmp_profile" ] && . ${HOME}/.tmp_profile

brew update
brew upgrade
brew doctor

git clone git@github.com:analyticsmd/bin2ools-dotfiles.git ~/.bin2ools-dotfiles
ln -fs ~/.bin2ools-dotfiles/bt ~/.bt 

brew bundle --file ~/.bin2ools-dotfiles/Brewfile 

export PATH="$PATH:/Users/${HOME##*/}/.local/bin"
echo 'export PATH="$PATH:/Users/${HOME##*/}/.local/bin"' >> ${HOME}/.tmp_profile
mv ${HOME}/.bash_profile ${HOME}/.bash_profile.bak.$$
mv ${HOME}/.tmp_profile ${HOME}/.bash_profile

echo Running pipx installs...
${HOME}/.bt/inst/python-pipx
# Run twice as first error occurs since aws-sso-util isn't installed yet
#~/.bt/inst/python-pipx
echo Running profiles...
${HOME}/.bt/gen/profiles

