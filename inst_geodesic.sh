#!/usr/bin/env bash

#functions
function mytime {
  t=$(date "+%Y-%m-%d %H:%M:%S")
  echo "[$t] --->"
}

function die {
  msg=$1
  echo -e "\e[31;1m$msg\e[0m"
  exit 1
}

function good {
  msg=$@
  echo -e "\e[32;1m$msg\e[0m"
}

function bad {
  msg=$@
  echo -e "\e[31;1m$msg\e[0m"
}

function warn {
	msg=$@
	echo -e "\e[33;1mWarning -> $msg\e[0m"
}

function usage {
  echo -e "\e[34;1mUsage: $0
Example: $0\e[0m"
  exit 1
}

function roll {
	sp='|-\|'
	printf ' '
	sleep 0.1
	while true; do
		printf '\e[32;1m\b%.1s\e[0m' "$sp"
		sp=${sp#?}${sp%???}
		sleep 0.1
	done &
}

#variables
docker_intel_url="https://desktop.docker.com/mac/main/amd64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-amd64"
docker_silicon_url="https://desktop.docker.com/mac/main/arm64/Docker.dmg?utm_source=docker&utm_medium=webreferral&utm_campaign=docs-driven-download-mac-arm64"
xquartz_pkg="https://github.com/XQuartz/XQuartz/releases/download/XQuartz-2.8.4/XQuartz-2.8.4.pkg"

# common errors.
[[ -z ${HOME} ]] && die "No HOME var. Need to set HOME var for continue."
[[ "${SHELL##*/}" != "bash" ]] && die "Wrong SHELL. Need to set bash as shell."
[[ "${BASH_VERSION%%.*}" -lt 5 ]] && die "bad shell version: ${BASH_VERSION}. Major version should be at least 5."

#good "So far so good!" && exit 0

which docker &>/dev/null || {
	warn "Docker not installed. Installing docker..."
	which arch &>/dev/null || die "arch not installed. Install arch before continue with the installation."
	which curl &>/dev/null || die "curl not installed. Install curl before continue with the installation."
	which hdiutil &>/dev/null || die "hdiutil not installed. Install hdiutil before continue with the installation."

	my_arch=$(arch)
	case $my_arch in
		x86_64 | i386)
			good "x86_64|i386 arch detected. Downloading docker for intel..."
			docker_url=$docker_intel_url
			;;
		arm64)
			good "arm64 arch detected. Downloading docker for silicon..."
			docker_url=$docker_silicon_url
			which softwareupdate &>/dev/null || die "softwareupdate not installed. Install softwareupdate before continue with the installation."
			good "But first we need to update some resources..."
			softwareupdate --install-rosetta --agree-to-license
			;;
		*)
			die "Unknown arch: $my_arch"
			;;
	esac
	roll && my_pid=$!
	curl -fsSL $docker_url -o /tmp/Docker.dmg || {
		kill $my_pid && wait $my_pid &>/dev/null
		die "Error downloading Docker package. Check the url and try again."
	}
	kill $my_pid && wait $my_pid &>/dev/null && echo
	good "Docker package downloaded. Installing docker..."

	hdiutil attach /tmp/Docker.dmg &>/dev/null || die "Error mounting Docker package. Check the package and try again."
	[[ -d /Applications/Docker.app ]] && {
		warn "Docker.app already exists. Removing it..."
	  rm -rf /Applications/Docker.app
	}
	/Volumes/Docker/Docker.app/Contents/MacOS/install --accept-license || die "Error installing Docker. Check the package and try again."
	hdiutil detach /Volumes/Docker &>/dev/null || die "Error unmounting Docker package. Check the package and try again."

	good "Docker installed. Cleaning up..."
	rm -f /tmp/Docker.dmg
}

docker_version=$(docker --version |awk '{split($3,a,"."); print a[1]}' || echo 0)
[[ $docker_version -lt 20 ]] && warn "Docker version is a little bit old. The script was tested with a Docker version 20.x."

which xquartz &>/dev/null || {
	warn "XQuartz not installed. Installing XQuartz..."
	which curl &>/dev/null || die "curl not installed. Install curl before continue with the installation."
	which hdiutil &>/dev/null || die "hdiutil not installed. Install hdiutil before continue with the installation."

	roll && my_pid=$!
	curl -fsSL $xquartz_pkg -o /tmp/XQuartz.pkg || {
		kill $my_pid && wait $my_pid &>/dev/null
		die "Error downloading XQuartz package. Check the url and try again."
	}
	kill $my_pid && wait $my_pid &>/dev/null && echo
	good "XQuartz package downloaded. Installing XQuartz..."
	open -a installer /tmp/XQuartz.pkg || die "Error installing XQuartz. Check the package and try again."
}

good "So far so good!" && exit 0

# First, install homebrew
#/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

### Run XQuartz startup command

### add bt_utils function to ~/.bash_profile


### Run btx function (_btx function) which (starts XQuartz)

###    which runs the 'bt' command (_bt function)

