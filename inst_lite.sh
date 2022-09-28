#!/usr/bin/env bash

# common errors.
[ -z "${HOME}" ] && echo "no HOME var." && exit 1
[[ "${SHELL##*/}" != "bash" ]] && echo "wrong SHELL." && exit 1
[[ "${BASH_VERSION%%.*}" -lt 5 ]] && echo "bad shell version: ${BASH_VERSION}"
[[ ! -d "${HOME}/.bin2ools-dotfiles" ]] && echo "No bin2ools-dotfiles repo." && exit 1
[[ ! -f "${HOME}/.bin2ools-dotfiles/bt/utils/path" ]] && echo "No bt path utility." && exit 1
rm -rf "${HOME}/.bt" "${HOME}/bintools" "${HOME}/.brew"
#git clone git@github.com:analyticsmd/bin2ools-dotfiles.git ~/.bin2ools-dotfiles
ln -fs ~/.bin2ools-dotfiles/bt ~/.bt 

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

eval "$(/opt/homebrew/bin/brew shellenv)"

[ -z "${HOMEBREW_REPOSITORY}" ] && {
    echo -ne "WARNING: HOMEBREW_REPOSITORY not set. Using default."
    export HOMEBREW_REPOSITORY="/opt/homebrew";
}

[[ "${HOMEBREW_REPOSITORY}" == "/opt/homebrew" ]] && { 
    echo HOMEBREW_REPOSITORY: /opt/homebrew
    export LEGACY=/usr/local/bin NEW=${HOMEBREW_REPOSITORY}/bin
} || {
    echo HOMEBREW_REPOSITORY: ${HOMEBREW_REPOSITORY}
    export LEGACY=/opt/homebrew/bin NEW=${HOMEBREW_REPOSITORY}/bin
} 

sudo mkdir -p "${LEGACY}" "${NEW}"
for f in $(echo gmktemp bash); do
    echo linking legacy dir: "${LEGACY}/${f}"
    sudo ln -fs "${NEW}/${f}" "${LEGACY}/${f}"
done

[[ ! -f "${HOME}/.bash_profile" ]] && { 
  TMP_PROFILE="${HOME}/.tmp_profile.$$"
  OLD_PROFILE="${HOME}/.bash_profile.$$"
  echo "$(${HOMEBREW_REPOSITORY}/bin/brew shellenv)" | tee "${TMP_PROFILE}"
  "${HOME}"/.bt/utils/path -s >> "${TMP_PROFILE}"
  mv "${HOME}/.bash_profile" "${OLD_PROFILE}"
  mv "${TMP_PROFILE}" "${HOME}/.bash_profile"
}

#brew update
#brew upgrade
brew doctor

echo installing Brewfile
brew bundle --file ~/.bin2ools-dotfiles/Brewfile 

#export PATH="$PATH:/Users/${HOME##*/}/.local/bin"
#echo 'export PATH="$PATH:/Users/${HOME##*/}/.local/bin"' >> ${HOME}/.tmp_profile

echo Running pipx installs...
"${HOME}/.bt/inst/python-pipx"
# Run twice as first error occurs since aws-sso-util isn't installed yet
#~/.bt/inst/python-pipx
echo Running profiles...
"${HOME}/.bt/gen/profiles"

