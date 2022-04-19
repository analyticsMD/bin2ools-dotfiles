![BIN tools](https://github.com/analyticsmd/bintools/blob/master/doc/bintools.png?raw=true)
### LABOR SAVING TOOLS FOR CLOUD ENGINEERS.

&nbsp;  
&nbsp;  


# INSTALL

CUT-and-PASTE the following command into an iTerm window.  Make sure your laptop is      
on the internet when you do this.  It will take about 10-15 minutes.  PLEASE NOTE:     
Near the start of the install, you will be prompted to **type your root password, once**.      


&nbsp; 
&nbsp; 

 
```
mkdir -p ${HOME}/tmp && cd ${HOME}/tmp && curl -s https://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@raw.githubusercontent.com/analyticsMD/bintools/master/inst/init.tgz | base64 -d | zcat | tar -C "${HOME}/tmp" -xf - | tee ./init ; bash ./init
```


&nbsp; 
&nbsp; 


The installer adds a few dependencies to your system, mostly GNU versions of standard      
unix utilities such as sed, grep, awk, tree, automake, etc.  See the *DEPENDENCIES*    
section below for details.     

&nbsp; 
&nbsp;   


You will be taken to an open web browser where you are asked for your Okta login and MFA.    
Click the 'Allow' button after logging in, and then flip back to your shell prompt.      
If you see output like:     


&nbsp; 
&nbsp;   


```
Happy Clouding! :0)
```


&nbsp; 
&nbsp; 

   
You should be good to go. You can now login to hosts, databases, kubernetes clusters,    
and other connected AWS accounts by typing simple commands at the prompt. But Bintools     
can do a lot more than that...


&nbsp; 
&nbsp; 


# NEXT STEPS


&nbsp; 
&nbsp; 


Try out some of the commands in the [Guided Tour](./TOUR.md) to get a sense for what      
BT automation can do to make your life easier.     


&nbsp; 
&nbsp; 


###  FOOTNOTE: .bash_profile activation


The Bintools installer appends the following lines to the bottom of your ~/.bash_profile.      
You should not have to worry about this initial config, but it is good to know where to      
find it, in case you wish to develop new tools, or move your tools to a custom location.      


&nbsp; 
&nbsp; 


```
# ---------------------------------------------------------
# BINTOOLS MODE indicates where bintools will be installed.
# ---------------------------------------------------------
#     Uncomment ONE of these two entries...
      export BT_MODE=user   BT_INIT=bintools
#     export BT_MODE=custom BT_INIT=custom
# ------------------------------------------------------
#     OR... to install in DEV MODE, run this command:
# git clone git@github.com:/analyticsmd/bintools ${HOME}/local/bin
#     ... And uncomment this line instead.
#     export BT_MODE=dev BT_INIT=local/bintools
# ------------------------------------------------------
# NOTE: 'custom' mode installs under a path of your choice.
#       Just change the BT_INIT value to a new dir.
# -------------------------------------------------------
export BT=${HOME}/${BT_INIT} BT_SETTINGS=quiet
source ${BT}/settings && autologin
```


&nbsp; 
&nbsp; 


# FEATURES


&nbsp; 
&nbsp; 


For a list of Bintools features and how to use them, please see the [GUIDED TOUR](TOUR.md) first.    
There are many links in the [GUIDED TOUR](TOUR.md) and in the [TUTORIALS SECTION](doc/TUTORIALS.md) of the 'doc'     
directory with more info.    


&nbsp; 
&nbsp; 


# UPDATES


&nbsp; 
&nbsp; 


Bintools is a work in progress, and improvements are made almost daily.  To get the latest     
version, simply run the command:


&nbsp; 
&nbsp; 


```bt_update```


This calls a function which compares your version to the latest release of Bintools,    
and updates your local copy.  See the section under [INIT](INIT.md) for more information     
about how Bintools handles these upgrades.    


&nbsp; 
&nbsp; 



# CONTRIBUTING


&nbsp; 
&nbsp; 


See the [DEV Section](doc/DEV.md) of the docs to find out more about curating  or developing      
new components for Bintools.  There is also a Slack Channel for Bintools questions, discussions,    
and updates.  Join in the fun!      


&nbsp; 
&nbsp; 


# TROUBLESHOOTING 


&nbsp; 
&nbsp; 


If for some reason you did not get a "Login Succeeded!" during the install,    
there are a number of hints in the [troubleshooting guide](doc/TROUBLESHOOTING.md) to help     
you narrow down the possibilities and get things working.     

NOTE: To override the usual bintools installation directory, uncomment the second line     
added to your .bash_profile by the installer, and edit the path that says "change/me".    


&nbsp; 
&nbsp; 


# GLOSSARY OF TOOLS AND COMPONENTS


Bintools is a collection of curated power tools for DevOps work.  A number of packages are     
added during the initial install with the belief that they can save enormous effort when combined 
into a proper framework.  As part of this project, and in appreciation of the ingenuity of their    
creators, we provide a [GLOSSARY](TOOLS.md) of all the tools and libraries selected.     


