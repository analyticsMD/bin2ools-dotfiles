# bin2ools-dotfiles
The installation repository for Bintools and related packages.  

![Screenshot of my shell prompt](docs/bintools.png)


# PREPARING TO INSTALL BINTOOLS

Please watch this short video and follow the steps outlined to clean up your laptop and prepare     
to install Homebrew, and other installation tools.  If you do not perform this step, it can be      
difficult to guarantee the install will succeed.  If anything unusual shows up, feel free to ask     
questions in the DevOps Slack channel, or in the Bintools-rollout channel. They will be answered quickly! 

https://www.loom.com/share/8b0fee43baf24488a6a114aac075be11

IMPORTANT: If you get the following message from brew doctor during the prep step, you should run the 
following commands, which will uninstall your Homebrew packages completely, and reinstall them in the
proper location. NOTE: This is **absolutely necessary** for your system to operate properly, moving forward. 




## Installation

[]()  **Warning:** See above if this is your first time installing Bintools.  Be sure to review the short video.  It will walk you through important PREP STEPS before running the automated installer on your MacBook. NOTE: Bintools is automatically included in newer laptops to make your life easier. 

### Using this Github repository, and the automatic installer. 

The script below clones the repository under ~/.bintools-dotfiles in your home directory. It's important to keep this location, as other tools and scripts may look to find it there.  The bootstrapper script will clone (or pull) the latest version and copy the files to this directory.  The installer usually takes 10-15 minutes, and installs all components hands-free.  If you have no Git credential helper installed, it will install one on your behalf, asking once or twice for your Github credentials using a pop up browser page. It also asks for your root password exactly once, and will produce an Okta credential popup upon completion, so you can perform your first login.  

If the installer has trouble for any reason, you can safely rerun it multiple times.  It is idempotent.  Just cut and paste one of the commands below.  The first commmand installs ONLY the basic rds and ssm tools and the zero-trust login framework.  The second link installs Database graphic tools, such as MySQL Bench and DataGrip in addition to the basic tools. Other tools are also available for install. The list is steadily growing!  See the addenda notes for a list of packages near the end of this doc for other notable features that can be added to your bintools!

```bash
u=https://bit.ly/3Kavmy1 f=${HOME}/i.sh && (curl -L $u||wget -O - $u||fetch -o - $u) > $f && chmod 700 $f && $f
```

```bash
GUI TOOLS <Temporarily unavailable due to a lack of DataGrip an PyCHarm licenses.>
```


### Git-free install

To install these dotfiles without Git (e.g. on a Linux-based deployment container:

```bash
cd; curl -#L https://github.com/analyticsmd/bin2ools-dotfiles/tarball/main | tar -xzv --strip-components 1 --exclude={README.md,bootstrap.sh,.osx,LICENSE-MIT.txt}
```

Dotfiles sometimes change.  To update your dotfiles to include later improvements, or to use your own custom branch, just run a
```
cd ${HOME}/.bin2ools-dotfiles; git pull
```


```bash
export PATH="/usr/local/bin:$PATH"
```

### Sensible macOS defaults

When setting up a new Mac, you may want to set some sensible macOS defaults:

```bash
./.macos
```


## Feedback

Suggestions/improvements
[welcome](https://github.com/gangofnuns/bin2ools/issues)!


## HOW TO USE BIN2OOLS

https://www.loom.com/share/cc82d46c8b9e41e3ac29aab56b725b8c


## Original Authors (the Gods we stand upon). 

| [![twitter/mathias](http://gravatar.com/avatar/24e08a9ea84deb17ae121074d0f17125?s=70)](http://twitter.com/mathias "Follow @mathias on Twitter") |
|---|
| [Mathias Bynens](https://mathiasbynens.be/) |

## Thanks to…

* @ptb and [his _macOS Setup_ repository](https://github.com/ptb/mac-setup)
* [Ben Alman](http://benalman.com/) and his [dotfiles repository](https://github.com/cowboy/dotfiles)
* [Cătălin Mariș](https://github.com/alrra) and his [dotfiles repository](https://github.com/alrra/dotfiles)
* [Gianni Chiappetta](https://butt.zone/) for sharing his [amazing collection of dotfiles](https://github.com/gf3/dotfiles)
* [Jan Moesen](http://jan.moesen.nu/) and his [ancient `.bash_profile`](https://gist.github.com/1156154) + [shiny _tilde_ repository](https://github.com/janmoesen/tilde)
* Lauri ‘Lri’ Ranta for sharing [loads of hidden preferences](https://web.archive.org/web/20161104144204/http://osxnotes.net/defaults.html)
* [Matijs Brinkhuis](https://matijs.brinkhu.is/) and his [dotfiles repository](https://github.com/matijs/dotfiles)
* [Nicolas Gallagher](http://nicolasgallagher.com/) and his [dotfiles repository](https://github.com/necolas/dotfiles)
* [Sindre Sorhus](https://sindresorhus.com/)
* [Tom Ryder](https://sanctum.geek.nz/) and his [dotfiles repository](https://sanctum.geek.nz/cgit/dotfiles.git/about)
* [Kevin Suttle](http://kevinsuttle.com/) and his [dotfiles repository](https://github.com/kevinSuttle/dotfiles) and [macOS-Defaults project](https://github.com/kevinSuttle/macOS-Defaults), which aims to provide better documentation for [`~/.macos`](https://mths.be/macos)
* [Haralan Dobrev](https://hkdobrev.com/)
* Anyone who [contributed a patch](https://github.com/mathiasbynens/dotfiles/contributors) or [made a helpful suggestion](https://github.com/mathiasbynens/dotfiles/issues)
