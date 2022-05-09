#!/usr/bin/env /usr/local/bin/bash -i

echo show me your functions...

echo I have $(declare -F | wc -l ) functions.

includex main.bash

echo Now I have $(declare -F | wc -l ) functions.


