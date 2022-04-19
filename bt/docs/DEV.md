# BINTOOLS FOR DEVELOPERS

If you wish to develop tools for the bintools repository, here are
some recommended best practices for maintaining your development 
environment, and keeping it separate and sane from your day-to-day
usage. 

First, uncomment the 'developer' line in your ~/.bash_profile, which 
will activate settings that look for a second set of install tools 
under ~/local/bin. These tools will supercede the regular bintools 
installed under ~/bin (~/local/bin is listed in the PATH before ~/bin). 

If you are a developer working with Bintools, you will probably 
recognize the patterns incorporated that make it easy to evolve 
the toolset in useful directions. 

Visit the [GitHub repository for Bintools](https://github.com/analyticsMD/bintools) for more info on tweaking and sending PRs.
Since your ordinary dev instance is likely to be under ~/local/bin, it is 
best to checkout the Github repository at that location, e.g.

&nbsp;  
&nbsp;


```
> git clone git@github.com:analyticsMD/bintools.git ~/local/bin
```

&nbsp;  
&nbsp;


If there is already a repo in that location, the upgrade process
(See: bt_upgrade) will rotate the current repo to make way for the
new one. 


# DEVELOPERS

https://github.com/analyticsmd/bintools/blob/master/doc/.gif?raw=true

If you want to develop more tools and publish them, feel free!
Just checkout your dev version of the tools under ~/local/bin,
and add an extra line to your PATH variable:  

```
if [[ -d ~/local/bin ]]; then
    export PATH="~/local/bin:${PATH}"
fi
```

# CUTTING A NEW RELEASE

To cut a new release install from your local developer repo, first
create a PR.  Once your changes have been merged, do a git pull on 
the master branch, and build a new secure archive under the 
'${BT}/sec' directory.

Follow the instructions in the [SECURITY](sec/SECURITY.md), [RELEASE](sec/RELEASE.md), and [DEV](doc/DEV.md) docs to
perform the steps for upgrading the bootstrapper and installer.

(Also, please check back frequently on this doc for more info about developing.)

