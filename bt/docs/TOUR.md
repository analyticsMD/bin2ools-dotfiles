# GUIDED TOUR

This is your step-by-step walk-through for some of the most common work flows in the     
Bintools framework.  Bintools tries to make people more productive by simplifying their     
navigation and permissions frameworks.  BT makes it easy to get work done with less typing,    
and less fiddling with credentials.  It is also more secure and less costly to maintain     
than systems that use passwords, key pairs, VPNs, or key fobs.    


&nbsp; 
&nbsp; 


#  COMMON USE CASES ... 

Let's start with logging into AWS.  You shouldn't have to do this, as Bintools will    
automatically recognize when you are not logged in.  Still, it may help from time     
to time.  Type the following command into a new shell on your laptop.   


&nbsp; 
&nbsp; 


```
autologin
```

&nbsp; 
&nbsp;   

This will initiate a login flow through your default web browser.  It is usually     
just one or two clicks to authenticate through Okta.  The diagram below summarizes     
the login flow.
 

&nbsp; 
&nbsp; 


![](./doc/okta-sign-in.png)
 

&nbsp; 
&nbsp; 


Your screen focus is shifted to an open web browser where you are asked for your     
Okta login and MFA token.  The MFA token is cached for a period of days, and will     
prompt only on the occasion that it has expired.   Okta is the Qventus standard for     
managing all permissions, and Bintools implements those standards completely.    
Further, Bintools permissions do not require you to keep credentials on your laptop.    
All permanent credentials are stored by Okta alone in the cloud.   



&nbsp; 
&nbsp;   



Once it is complete and you have pressed the 'Allow' button, you can shift focus     
back to your shell prompt.  


&nbsp;   
&nbsp;   


You should now see a few lines above your terminal prompt that inform you     
of your new login status.   There is also a notice about when that access    
expires.   Typically, this is 8 hours or more.   When your credentials do       
expire, the next command you type will re-initiate the browser login sequence.     


&nbsp;   
&nbsp;   




# GETTING WORK DONE: 

A tour of some of Bintools most used components. 


&nbsp;   
&nbsp;   




# SHELL ACCESS 

Type the following at the command prompt:  

```
ssm<space><tab>
```

You should see a list of hosts, or possibly a message saying: 

```140 hosts found, press [space] to see all.```

Tab complete to any host.  Hit return. 
 
Within 2-4 seconds you will be logged into the host you chose.  That's it.      
No passwords.   No VPNs.   No stored credentials.  You can sudo to root,     
and you have access to all ssm agent commands on the host.     

 
To log into multiple hosts, simply create more shell windows.   Each one    
will automatically log you in by default.  As you finish with each shell,     
simply close it.     
 
 
 

&nbsp;   
&nbsp;   



 
 # RDS ACCESS 

 
 

&nbsp;   
&nbsp;   




At a new shell prompt, type:   "

```
rds[space][tab]
```

You will see a tab-completed list of ALL the RDS clusters where your team has direct access.    
If you highlight any of these and hit return, you will see some text scroll by, and about    
8-9 seconds later you will see a mysql prompt.   That's it.   You are logged into your favorite    
DB cluster.    
 

&nbsp; 
&nbsp;   



Login Succeeded!  That's a good first step.  If you are seeing anything else,    
this is a good time to hit up one of the DevOps team to ask for a little help.   

&nbsp; 
&nbsp; 


# Getting (and staying) authenticated    
 
Couple things worth noting about your first login.  Notice how you didn't need to     
use Pritunl.  You also didn't have to mess with any ssh public or private keys,    
nor is it necessary to store secrets anywhere on your hard drive where they might    
be leaked or compromised.  You have your Okta password, and your MFA token.  All  
access stems from that.  This makes the new system safer than the old methods of    
logging into AWS, where there were many passwords, and even more credentials lining    
our hard drives with no expiration, and no protection.   
  

&nbsp; 
&nbsp;   


# Automated RE-authentication

In many bintools scripts and command aliases, you will see a function called     
*requires_login $TEAM*.  This function performs the same routine as the above     
alias -- it logs you in, and if for some reason your temporary credentials have    
expired, or are no longer valid, _you will automatically be reauthenticated_.    
 
If you haven't logged in yet today, you may see your web browser open up and     
redirect you from AWS to an Okta login page.     
 
Type in your Okta password, and MFA credentials.  Hit return, and in a few      
seconds, hit the 'allow' button when you are prompted.     
  
You should now be logged in!  You can now switch back to your terminal and     
continue working. You now have a session token that will persist for up to 12 hours.     
As the rest of these examples will show, this token can be refreshed, re-acquired,     
wiped, or even delegated to other shells.    


&nbsp; 
&nbsp;   


USING YOUR CREDENTIALS


&nbsp; 
&nbsp;   


For example, while you have this temporary session open, you can run commands like     
this one, which lists all the s3 buckets in the current account.   

```
aws s3 ls
```
  
Most groups have all the necessary permissions to run this command, and it is a good     
indicator of whether your new permissions are in full effect. Many of the commands use     
a routine which prints out AWS S3 buckets to demonstrate that the proper access has      
been achieved.        
 




# SHELL ACCESS (via ssm). 
  
![ssm demo](doc/ssm_demo.gif)



# SHELL ACCESS (via ssh - including tunneling)      
 

NOTE: This solution also supports ssh tunneling to other hosts.    



# SHELL ACCESS (via browser - coming soon.).         
 


# RDS Access (via SHELL).      
 




![RDS login example, with tab completion](doc/rds_demo_opt.gif)


### Opening a session to multiple RDS clusters at once.  
 
 
 Just open more shells.  You can log into the same RDS cluster many times,    
 or into many RDS clusters.    
 


### Opening a session using MySQL Workbench, DataGrip, or DBeaver. 

```
 COMING SOON.
 ```
 
 
### Sharing AWS diagnostic data with a fellow team member. 


```
 COMING SOON.  
 ```

 
### Removing unsafe credentials.


```
 COMING SOON. 
```
 
# ADVANCED FEATURES

### Navigating through multiple accounts.

### Working with Generators

### Link sharing

### Credential safety

### Touching many hosts at once 

### Touching many RDS clusters at once. 


Bintools utilities use AWS SSO authentication everywhere, with the exception of     
the prod account, where we use IAM authentication.   The only difference comes with    
how we protect the IAM credentials, since a permanent credential must be present on     
your laptop, we use aws-vault to present it in an encrypted format.      
 

# COMMENTS

NO UNSAFE CREDENTIALS.
