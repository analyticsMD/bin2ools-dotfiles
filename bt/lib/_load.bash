#!/usr/local/bin/bash

export BT="${HOME}/.bt"
. ./loaderx.bash

# Add directories to search path.
loader_addpath "${BT}/lib"

# Load main script.
load main.bash
