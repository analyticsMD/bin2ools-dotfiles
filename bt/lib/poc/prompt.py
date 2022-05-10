#!/usr/bin/env python3
# ---------------------------------------------------
# prompt.py
# ---------------------------------------------------
# A mini-executable for pushing out a dynamic prompt
# in bash / zsh.  

# ----------------------------------------------------
# BT shared libs for python.
# ----------------------------------------------------
import configparser          # ini manipulation
import json                  # json manipulation
import pyjq as jq            # json manipulation
import gzip, base64, hashlib # crypto.
import re, math

# ----------------------------------------------------
# For shared datetime manipulations
# ----------------------------------------------------
from datetime import datetime as dt
from tzlocal import get_localzone
import pytz

# ----------------------------------------------------
# For defining paths to creds files, json definitions,
# and cache files used for maintaining internal cached
# states in BT.
# ----------------------------------------------------
import sys, os
from os import path, chdir, getenv
from os.path import join

from cache import get_latest_peek
from data  import *
from prompt import *

# --------------------------------------------------------
# Trigger the next prompt cycle.
# --------------------------------------------------------

def next_prompt():

    """
    Generates a new peek with the latest cache_data, 
    then performs either a fast update (env_sync) or a 
    rigorous one (cache_audit).
    """
    peek = get_latest_peek()
    bt_encode(peek)
    #print(f"this: {peek}")

    #(next_peek, next_sig) =
    try:
        this_sig = getenv(BT_SIG)
    except:
        IndexError, cache_audit(next_peek)
        # no previous peek. Force cache_audit.
        cache_audit(next_peek)
    #except: BTParseError
        if next_sig == this_sig:
            (this_sig, this_peek) = env_sync(next_peek)
            env_update(this_sig, this_peek) # updates env. 
        print(f"caught logging error.")
    finally:
        if this_sig != next_sig:
            print("log this")  # log json diffs.
        build_prompt(next_peek)
        export_prompt()


def export_prompt():
    """Export ascii colorized text for new prompt.
    """
    pass

def build_prompt(peek_obj):
    """
    Builds each new prompt, after env_sync and cache_audit
    have reconciled peek object info to a consisent state.

    Calling this function triggers a new prompt to be created
    from the latest peek without repolling any other resources.

    Uses pyjq bindings to unpack expire and profile values from
    the peek object.

    Constructs a new ascii colored prompt and injects into
    the $SHELL ENV.  Helps with support for multiple shells,
    such as zsh.
    """

    #--  pulls the role, and expire from the latest peek:

    #--  uses the qventus profile, e.g. 
    #    'sso', '[team]', '[acct-team]', or [acct-guild-team]
    #    does not reflect other profiles.

    #--  Changes prompt color as status approaches expired. 


    """
    NOTES: 
    ------
    We only display the color and name of the *focal* profile.
    However, the prompt is adjustable through ENV vars.

    By exporting BT_PROMPT=no_timer, you can remove the timer
    option. You cannot remove the color or profile display option.
    These will always inform you when you are authenticated.
    You can, however, completely turn off the prompt. This
    is not recommended.
    """

    next_prompt()

