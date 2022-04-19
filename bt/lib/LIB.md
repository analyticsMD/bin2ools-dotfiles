
# NOTE: Workflow
# ---------------
# (bash or zsh)-> sources "settings"
# 
# -->  which runs prompt.py  

#    -->  which calls: 
# 
#                1.) new_peek() 
#                2.) either env_sync() or cache_audit() 
#                3.) env_update()
# 
# Every prompt update triggers the same cycle. 
# Autosession (integrated into tools) uses a similar cycle. 
#
#              1.) Generate new peek, and new sig.
#                  if hash digest matches then nothing has changed.
#                  We stop and update the prompt.
#
#              2.) build the colorzed, role, and timer prompts, 
#
#              3.) Log diffs, or "no changes" messages.

