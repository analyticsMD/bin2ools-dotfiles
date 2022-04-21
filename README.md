# bintools dotfiles

## Installation

[Logo](docs/bintools.png)! 

### Using Git and the bootstrap script

Cut-and-paste the following one-liner into a terminal on your mac laptop. 
You will be prompted for your root password once, and then you must confirm by   
hitting return at a second prompt.    

Later, you will also see two pop-up windows appear at varying times. The first.  
asks for your github password; The last walks you through logging into Okta.  
This script represents a complete, end-to-end install of all components needed.
Runtime: ~ 5min   

```bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" && brew install bash && curl -fsSL https://raw.githubusercontent.com/analyticsMD/bin2ools-dotfiles/main/bin/installer | /usr/local/bin/bash
```


## Kudos 

To the many contributors who created this framework.  We'll be adding proper appreciation here very soon!

Forked from:  Mathiasbynens@github.com

## Feedback

Suggestions/improvements
[welcome](https://github.com/mathiasbynens/dotfiles/issues)!

