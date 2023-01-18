#!/usr/bin/env bash

# common errors.
[ -z "${HOME}" ] && echo "no HOME var." && exit 1
[[ "${SHELL##*/}" != "bash" ]] && echo "wrong SHELL." && exit 1
[[ "${BASH_VERSION%%.*}" -lt 5 ]] && echo "bad shell version: ${BASH_VERSION}"

# First, install homebrew
#/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

eval "$(brew shellenv)"
export BREW_PATH="$(which brew | perl -pe 's/\/bin\/brew//')"¬
export LEGACY=/usr/local/bin NEW=/opt/homebrew/bin

[[ -z "${HOMEBREW_REPOSITORY}" && -z "${BREW_PATH}" ]] && {
    echo -ne "FATAL: HOMEBREW_REPOSITORY not set. Did you install homebrew?"
    echo -ne "       If not, then please install -- or just make sure that 
    echo -ne "       Docker and XQuartz are installed, then run this script again."

    exit
}

if [[ ! -f "${HOME}/.bash_profile"   ]] || \
   [[ ! $(grep -qsi bin2ools "${HOME}/.bash_profile") ]]; then
  TMP_PROFILE="${HOME}/.tmp_profile.$$"
  OLD_PROFILE="${HOME}/.bash_profile.$$"
  echo "$(${HOMEBREW_REPOSITORY}/bin/brew shellenv)" | tee "${TMP_PROFILE}"
  "${HOME}"/.bt/utils/path -s >> "${TMP_PROFILE}"
  mv "${HOME}/.bash_profile" "${OLD_PROFILE}"
  mv "${TMP_PROFILE}" "${HOME}/.bash_profile"
fi

#brew update
#brew upgrade
brew doctor
#  show stopper.

(base64 -d) < cat << EOF
Y2FzayBkb2NrZXIKY2FzayB4cXVhcnR6Cg==
EOF > ${HOME}/.BREWFILE_GEODESIC

gbase64 <file> -w 76

echo installing Brewfile
brew bundle --file ~/.BREWFILE_GEODESIC


cat << GEODESIC_BREWFILE
brew cask install docker
brew cask install xquartz
GEODESIC_BREWFILE > .Brewfile_geodesic


### Run XQuartz startup command 

### add bt_utils function to ~/.bash_profile


DOCKER_INSTALLED="$(docker --version)"
[[ "${DOCKER_INSTALLED}" !~ "build" ]] && {{ 
    echo "DOCKER NOT INSTALLED. Please install Docker."
    exit
}

[[ 

XQUARTZ_INSTALLED="$(test -f /opt/X11/bin/Xquartz && echo T || echo F)"
if [[ "${XQUARTZ_INSTALLED}" == "T" ]] && {
    echo "Starting X11..."
}  || {
    echo "XQuartz is not installed.  Please install." 
    echo "You can get it from GitHub at this url: "
    echo "https://github.com/XQuartz/XQuartz/releases/download/XQuartz-2.8.4/XQuartz-2.8.4.pkg"
    echo "Just run the package installer, then rerun this script."
    exit
}


### Run btx function (_btx function) which (starts XQuartz)

###    which runs the 'bt' command (_bt function)

