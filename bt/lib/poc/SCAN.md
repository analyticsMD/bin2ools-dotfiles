# CREDENTIAL SCANNING

One of the things BINTOOLS tries to do is make your
work life safer.  It spends a good deal of time verifying
your environment and closing security loopholes such 
as credentials stored in the clear. 

# Install airIAM. Create a user report. Find most used personal credentials. 
# Scans for those keys inside ~/.aws.  Ask permission.
# Looking for credentials. 

# FIRST TIME?  Let's clean up!
# ---------------------------- 
# If this is your first time installing Bintools, you
# may have a few long-term AWS Credentials lingering 
# in your homedir.  This is considered unsafe. 
# 
# Bintools can clean them up for you! 

# Hit [OK] to identify any long term credentials in your 
# .aws dir and protect them with encryption.  The process 
# is menu-driven, private, and all secrets are retrievable
# (yes, even by headless automation). 

# The encrypted files are locked with passwords. 
# You may want to type your own, otherwise Bintools can create 
# strong passwords for you. 

# IMPORTANT: Addressing this issue today helps us reduce your 
# overall risk, as a company, so please consider it. You can 
# also type "OPT OUT" and run the script at any time, by pasting 
# the following into a shell prompt: 

> ${BINTOOLS}/init/cred_protect 
 
# Stay Safe!  -- Qventus Security

 
