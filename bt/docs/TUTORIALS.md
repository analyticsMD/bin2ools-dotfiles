# TUTORIALS SECTION

Here we've added a good deal more in-depth information about how to build new 
services within Bintools, what components are in use, and activelyl being prototyped.
Copious liner notes on the decisions made, and areas of potential difficulty. 


### Secure, frictionless multi-account auth.


One password per day.  That's all.  Really.  

Credentials are authenticated using OKta Federated Auth and 
auto-refreshed via automation. This means you're not constantly being
logged out at inopportune moments.  Helps to keep the train of thought
going as well.

Permissions policies are in place for your team to start using today. 
See the [STEP-BY-STEP tutorial](TUTORIAL.md) to get oriented quickly. 


### Interactive SSM and SSH Sessions on demand.

Passwordless command-line or browser based access to every AWS server
your Team touches.  All of them.  Built-in TAB completion ensures access 
in a couple of keystrokes.  No key pairs required.  No further setup required. 


### Secure and frictionless RDS Sessions via RDS IAM.

Skip right to the [RDS IAM](cmd/RDS_IAM.md) page to explore. Works for shell sesssions, MySQL Workbench, and DBeaver. 
All RDS clusters at Qventusa are supported. Does not require RDS passwords, or Pritunl.  Uses your Okta
credentials to grant appropriate access.

![BIN tools](https://github.com/analyticsmd/bintools/blob/master/doc/render1633689466859.gif?raw=true)
doc/render1633689466859.gif

# Time saving tools. 

* fzf and autojump integration
* ssh or ssm from anywhere without pritunl.
* credential encryption and rotation
* easy install





# GENERATORS


As a cloud maker, there are probably a number of hosts and database
clusters you have command-line access to. Bintools lets you connect
to these resources via AWS ssm, or ssh+ssm, or other protocols, with
a minimum of muddling.

NOTE: As a convenient side-effect, this also eliminates the need for
(very unsafe) credentials stored in-the-clear inside your ~/.aws directory.  

Because servers in the cloud tend to change, each type of resource or
service has a 'generator' which can be run periodically (or automatically,
via cron).  The generators rebuild local files with tab-completeable
definitions of all the resources your AWS profiles have access to.  
As your cloud shifts, so will your files reflect the new state of things.
No more static editing to keep on top of changing topology!

### Example:

The following command runs a series of generators which reside under
${BT}/utils/gen.  Each time they are run, the generators auto-recreate
alias and config files in the ~/bin/cmd/generate.d directory which reflect a
somewhat opinionated way to organize one's access.  Generating these files
creates a shorthand for reaching AWS resources through bash auto-completion.
(yes, zsh is also available.)

### Session access

At your shell prompt, try typing: ```qa-<tab>```

The [tab] symbol will trigger bash command-completion, which if you've
run the installer and added the one-liner to your ~/.bash_profile, has
now been enabled.  Your command-line should show a list of server names
in the QA environment, which you can now log into at the click of a button.

NOTE:
----
* No fiddling with Pritunl needed.

* No need to remember  hostnames, instances, or ips (the familiar names
  all tab-complete).

* The same works well for RDS cluster endpoints across all environments.

### qa hosts...
```
qa-app-01-app            qa-app-02-sf        qa-app-04-app-container  qa-jenkins
qa-app-01-sf             qa-app-03-app       qa-app-04-app-cron       qa-app-05-app-cron
qa-app-02-app            qa-app-03-sf        qa-app-04-sf             qa-automation-box
```

Select one of the hosts and press ```[return]```

Within a few seconds you should be visited with a prompt for that host.
(NOTE: you may be redirected to a page for your Okta credentials first.)


# LIST OF TOOLS

With a little fiddling, you should soon have your own tab-completion
rules configured on a bunch of powerful unix hosts, ready to navigate
your new environment.  

Here are a few examples of tools being worked on as part of the framework,
and also a glossary of "Best of Breed" open source tools now available
as part of that effort.

```
pdsh  - Powerful parallel ssh tool when coupled with ssm and ssh config
        generators which live under $BT/cmd/gen (see below).
        The generator command above regenerates a complete list of hosts
        for ssh, including the logic for how to access them all (via jump hosts,
        Bastions, VPNs, etc.)

        NOTE: You can do things like inspect a configuration across
        all hosts of a particular class in a matter of seconds:

        Example:  
        > pdsh -g tomcat -p 20 -t 30 "cat /opt/tomcat/conf/web.properties | grep jdbc:mysql"

         Gives a full list of running hosts in AWS. Couple this
        with grep to find out about a particular host quickly.

inst             - Installer scripts for helping with the infirm,
                   elderly, or permanently in Hospice.

utils/gen/*      - generate sets of aliases and configs for logging
                   into all the resource where you have access.  Host
                   logins are already adjusted for NATs and other obstacles.

utils/drift      - A script suitable for running periodically on your
                   laptop. Produces a report that shows all terraform
                   changes across all environments.

```


# MORE TO COME

WANTED: Scripts for performing tasks like mysql & mirth administration.
querying AWS apis, etc.

Tools go through a basic submission and testing process for
each tagged release.

Wish list for AWS Tools:
```
aws_ecr_login        -- Log into our ECR for publishing.

aws_get_ami          -- Get the most recent ami for imaging.

aws_get_rds_clusters -- List all our RDS clusters.

aws_get_sg           -- List the elements of any Security Group.

aws_get_stacks       -- Get a list of all the current stacks by offical name.

aws_token_set        -- Set a 2FA token from the command line.
```
