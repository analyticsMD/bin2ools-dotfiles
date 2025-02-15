# Enhanced file path completion in bash


[![Linux test status](https://img.shields.io/circleci/build/gh/sio/bash-complete-partial-path?label=linux-test)][badge-link]
[![macOS test status](https://img.shields.io/github/workflow/status/sio/bash-complete-partial-path/ci-github?label=macos-test)][badge-link]
[![FreeBSD test status](https://img.shields.io/cirrus/github/sio/bash-complete-partial-path?label=freebsd-test)][badge-link]
[![Windows test status](https://img.shields.io/badge/windows--test-manual-yellow)][badge-link]

[badge-link]: tests/README.md


This project adds incomplete file path expansion to bash (the feature that was
originally unique to zsh).

When the Tab key is pressed bash expands only the last piece of the path by
default, but with the completion functions from this project it will assume any
of path elements might be incomplete. For example: `cd /u/s/app<Tab>` will
produce nothing by default, but will be expanded to `cd /usr/share/applications`
if you've configured bash to load this file.

Introductory overview is available at
[author's blog](https://potyarkin.ml/posts/2018/enhanced-file-path-completion-in-bash-like-in-zsh/).

Watch a demo screencast to see this feature in action:

[![asciicast](https://asciinema.org/a/191776.svg)](https://asciinema.org/a/191776)

To enable the described behavior source [**this file**][main] from your
~/.bashrc and run `_bcpp --defaults`. Supported features are:

- Special characters in completed path are automatically escaped if present
- Tilde expressions are properly expanded (as per [bash documentation])
- If user had started writing the path in quotes, no character escaping is
  applied. Instead the quote is closed with a matching character after expanding
  the path.
- If [bash-completion] package is already in use, this code will safely override
  its `_filedir` function. No extra configuration is required, just make sure
  you source this project *after* the main bash-completion.

Completion functions have been tested and reported to work on:

- Linux (Debian 9)
- macOS (requires gnu-sed from brew)
- Windows (MSYS)


## Installation and updating

First you need to copy [bash_completion][main] file to your machine.  Copy and
paste the following commands into your terminal to fetch the latest version of
the script to the default location (requires `curl` to be installed).

```shell
# Install or update bash-complete-partial-path
mkdir -p "$HOME/.config/bash-complete-partial-path/" && \
curl \
 -o "$HOME/.config/bash-complete-partial-path/bash_completion" \
 "https://raw.githubusercontent.com/sio/bash-complete-partial-path/stable/bash_completion"
```

To enable the new completion behavior put the following lines into your
`~/.bashrc` (or your OS equivalent).

```shell
# Enhanced file path completion in bash - https://github.com/sio/bash-complete-partial-path
if [ -s "$HOME/.config/bash-complete-partial-path/bash_completion" ]
then
    source "$HOME/.config/bash-complete-partial-path/bash_completion"
    _bcpp --defaults
fi
```

Make sure you source this project *after* the main bash-completion which may be
included in your  `~/.bashrc` file.


## Runtime requirements

To use this completion script make sure your OS provides the following
dependencies:

- GNU Bash, version 4 or newer (version 3.2 is not yet supported, see
  [#8](https://github.com/sio/bash-complete-partial-path/issues/8))
- GNU Sed (install it with brew on macOS)
- Core unix-like userland (mktemp, mkfifo, rm)


## Custom feature selection

If you like the project idea overall but do not agree with default behavior,
you can select which features to enable with `_bcpp` manager function. Sourcing
the file without calling this function has no side effects.

```
Usage: _bcpp OPTIONS
    Manage enhanced path completion in bash

Options:
    --defaults
        Enable the subset of features recommended by maintainer.
        Currently equals to:
        "--files --dirs --cooperate --nocase --readline"
    --all
        Enable all optional features. Equals to:
        "--files --dirs --cooperate --nocase --readline"
    --help
        Show this help message

Individual feature flags:
    --files
        Enable enhanced completion for file paths
    --dirs
        Complete `cd` with paths to directories only
    --cooperate
        Cooperate with system-wide bash-completion if it's in use.
        This function must be invoked AFTER the main bash-completion
        is loaded.
        Deprecated alias: --override
    --nocase
        Make path completion case insensitive
    --readline
        Configure readline for better user experience. Equals to:
        "--readline-menu --readline-color --readline-misc"
    --readline-color
        Enable colors in completion
    --readline-menu
        Use `menu-complete` when Tab key is pressed instead of default
        `complete`. Use Shift+Tab to return to previous suggestion
    --readline-misc
        Other useful readline tweaks
```


## Working together with other completion scripts

Partial path completion provided by this project is designed to work correctly
when [bash-completion] is in use (see `--cooperate` flag). Make sure you
invoke `_bcpp` after the main completion script has been sourced.

Enhanced completion will work for most, but not all commands unfortunately.
Some completion scripts within [bash-completion] project do not rely on global
`_filedir*` functions but instead implement their own logic for path
completion. For such scripts there is no simple way to inject modified
completion algorithm without disabling the rest of their functionality.

If for any particular command you'll prefer partial path completion over its
provided completion script, you can run `complete -F _bcpp_complete_file
COMMANDNAME` (and/or add that to ~/.bashrc)


## Support

#### Issue tracker

GitHub's [issue tracker] is the primary venue for asking and answering support
questions. Please don't forget to search closed issues for the topic you're
interested in!

If you know an answer to the question asked by someone else, please do not
hesitate to post it! That would be a great help to the project!

#### Email

If for some reason you'd rather not use the [issue tracker], contacting me via
email is OK too. Please use a descriptive subject line to enhance visibility
of your message. Also please keep in mind that support through the channels
accessible to the public is preferable because one answer can help many people
who might read it later.

My email is visible under the GitHub profile and in the commit log.

#### Community support

You might get faster and more interactive support from other users.

This project does not (yet) have a dedicated community venue, but experienced
Linux users will most likely be able to figure out most common questions. You
can try asking at the local Linux-related forums, IRC/Discord/Telegram chats
or on Reddit/StackOverflow.


## Contributing

Thank you for taking an interest in this project! If you wish to improve it
please open an issue or create a pull request.
If you just want to share your emotions, we encourage you to do so
[here](https://github.com/sio/bash-complete-partial-path/issues/6)!

Your help is most needed in the following areas:

- Documenting the project
- Finding (and fixing) existing bugs
- Testing the script on other operating systems and reporting the results (both
  positive and negative)
- Expanding OS support (if it's lacking)
- Adding better demo asciicasts and screenshots

The project was created to do one thing (autocomplete partial paths) and to do
it well. Please try to keep all code in one file and to keep it short. Major new
functionality is probably better suited for a separate project.

I'm open to dialog and I promise to behave responsibly and treat all
contributors with respect. Please try to do the same, and treat others the way
you want to be treated.

Thank you again!


## Information for developers

#### Debugging

Executing `set -v; set -x` before attempting completion enables printing a lot
of useful debugging information

#### Automated testing

Tests are implemented with Python and Pexpect. [Read more here](tests/README.md)


## License and copyright

Copyright © 2018-2019 Vitaly Potyarkin

```
   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use these files except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```

[bash-completion]: https://github.com/scop/bash-completion
[bash documentation]: https://www.gnu.org/software/bash/manual/html_node/Tilde-Expansion.html
[main]: bash_completion
[issue tracker]: https://github.com/sio/bash-complete-partial-path/issues
