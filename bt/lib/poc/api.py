#!/usr/bin/env python3
# ---------------------------------------------------
# api.py
# ---------------------------------------------------
# A  set of functions for working with Bintools 
# internal state. 

# ----------------------------------------------------
# BT shared libs for python.
# ----------------------------------------------------
import configparser          # ini manipulation
import json                  # json manipulation
import pyjq as jq            # json manipulation
import gzip, base64, hashlib # crypto.
import re, math
import logging

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

from lib  import *
#from cache import generate_peek
#from tests import *

# In case we need to recover the TEAM var.
def get_team():
    try:
        team_cache = os.path.join(bt, "cache", "team_info")
        with open(team_cache) as team_cache:
            team = team_cache.read().strip()
    except NameError:
        pass  # TODO: Fail if no settings?
    except FileNotFoundError:
        pass  # TODO: Fail if no settings?


# team var should always be present.
try:
    team
except NameError:
    get_team()


# ----------------------------------------------------
# configparser definitions for AWS credentials.
# ----------------------------------------------------
def get_BT_configparser():

    config = configparser.ConfigParser(
        strict=False,          # merge sections from the ini file.
        default_section="bt",  # 'bt' section holds our defaults.
    )

    # read and initialize a new bt_creds ini file.
    config.read_file(open(creds_ini))

    # Now, merge the existing file. The 'strict=False'
    # setting above allows us to automatically merge
    # like-named sections. Now all we need to do is
    # loop through all the sections, printing only what
    # we want to preserve.
    config.read_file(open(creds))

    return config



# --------------------------------------------------------
# ENV integrity checks.
# --------------------------------------------------------
# Will be faster if implemented within the python framework. 

# peek -  json structure containing assertions about
#         the environment.. Works roughly like a
#         level 1 accounted cache.

# Dictionary of integrity checking functions. 
# SEE: tests for info. 
# 

def export_env():

    """
    export_env()
    -----------
    Most of BT's integrity checks use a single 'peek'
    object.  The 'peek' is a JSON structure exported to
    the shell ENV, and updated with each refresh of the
    unix prompt (and in other situations where changes
    need to be reflected in the shell).

    In the python API, the peek is decrypted, verified,
    decoded, and nested json loaded as an object.
    Rebuilding the peek object is optimized for
    speed, so we can do it once per prompt refresh.
    """
    try:
        raw_peek, raw_sig = os.environ["BT_PEEK"], os.environ["BT_SIG"]
    except KeyError as e:
        # No peek? Create one. 
        peek = get_latest_peek()
        raw_peek, raw_sig = os.environ["NEXT_PEEK"], os.environ["NEXT_SIG"]
        peek_json = decode(raw_peek, raw-sig)
        return loads(peek_json)
    raise BTEnvironmentError('Env Var {} is not set'.format(e.args[0]))

    os.environ["NEXT_PEEK"]
    os.environ["NEXT_SIG"]


def reset():
    """ Run as part of autosession (?)
        Routine that exports: BT_(SSO,TEAM,ROLE,GUILD).
        Any change signals user intent.
        Update triggers an env_sync
        Remove/set to NONE when any creds lost.
    """


def bt_export(peek):

    """
    ------------------------------------------------
    encode:  Exporter method.
    For exporting cache hints to the BT shell environment.
    Also used to encode and check integrity.
    ------------------------------------------------
    """

    # compress first (also byte encode)
    gz_b = gzip.compress(            \
           bytes(str(peek), 'UTF-8'),     \
               compresslevel=9,      \
               mtime=None            \
           )
    #print(f"gz_b_len: {len(gz_b)}")
    e = base64.b64encode(gz_b)            # b64 byte encode
    h1 = e.decode("UTF-8")                # decode b64 bytes to string
    #print(f"h1_len: {len(h1)}")
    #hh = hashlib.new('sha512_256')        # generate secure checksum
    hh = hashlib.new('sha512')        # generate secure checksum
    hh.update(bytes(h1, encoding='utf8')) # make a hash digest
    sig = sign(h1, hh) # sign the peek.
    if sig and verify(h1, sig):
        # sourceable output to stdout (for shell consumption).
        print(f"export NEXT_PEEK={h1} NEXT_SIG={sig}")



def env_update(next_peek):

    """
    env_update is run as the last step to every prompt update.  It
    completely flushes the shell ENV and populates new permissions.

    Encodes and stores 'next_peek' and 'this_peek' as exported VARS
    while updating, but removes during cleanup. Overwrites all previous
    BT vars, including a sanity check on 'BT_MODE'.
    """

    #-- Encode HINTS + SIG
    #-- Refresh all BT_ profile vars (vestigial, but important.)

    #-- including Qventus profile, whether stub or active
    #-- update any active positional profiles.

    #-- ensure config has at least minimum profiles.
    pass

# ---------------------------------------------------------
# Functions used by login routines. (Defined in the SHELL.) 
# ---------------------------------------------------------
def autosession():

    """
    Autosession discreetly authenticates whenever it detects new
    credentials are required, such as when running a tool.  It ALWAYS
    assumes there SHOULD be creds. For this reason, it does not prompt
    the user for anything, but it calls the AWS CLI, and will make a
    browser window pop up if credential verification is required. This
    is considered the 'minimally invasive' approach. NOTE: The default
    role it assumes is prod-<team>.  This will change to what is
    explicitly defined in the peek very soon.
    """
    pass

    # Uses a 'try'          (with _try) Triggers env_merge.  

    # Peeks prefer an env_merge, unless cache_audit is triggered.  Uses
    # api funcs that compare this_peek and next peek. 
    # 
    # If TEAM or TEAM_EXPIRE have changed, forces a cache_audit.  Uses
    # _try logic to catch edge cases, such as forbidden, etc. These are
    # unexpected and require situation-specific recovery, and user
    # notification. 

    # GOTCHA: NOTE: can change the current profile, so it's possible to
    # get into a ping-pong match with another autosession directive. We
    # should detect this, and automatically spawn a new shell for
    # account changes (how to do in iTerm?).



# ----------------------------------------------------
# Subclassed Exceptions
# ----------------------------------------------------



class BTAppError(Exception):
    def __init__(self, *args):
        if args:
            self.msg = args[0]
        else:
            self.msg = f"From: BTAppError "

    def __str__(self):
        #print('calling func')
        if self.msg:
            return f"BTAppError, {msg} "
        else:
            return 'BTAppError was raised.'

#raise BTAppError('Houston, we have a problem...')

class BTParseError(BTAppError):
    def __str__(self):
        print('utils')
        if self.msg:
            return f"BTParseError, {msg} "
        else:    pass

class BTIntegrityError(BTAppError):
    def __str__(self):
        print('cache')
        if self.msg:
            return f"BTIntegrityError, {msg} "
        else:    pass


"""
except BTIntegrityError from None, e:
    if getattr(e, "failed_check", None):
        text = "Check failed: %s: %s" % (e.check, e.msg)
    else:
        text = str(e) # freeform nonsense!
    # log it.
    logging.error(
        f'{self.date} - {self.time}:\n'
        f'THIS_PEEK: {dumps(this_peek)}\n'
        f'NEXT_PEEK: {dumps(next_peek)}\n'
        f'check: {e.action} failed. {e.msg}'
    )
    #sys.exit(text)  # if you must.
"""

class BTVersionError(BTAppError):
    pass

class BTConfigError(BTAppError):
    pass

class BTInstallError(BTAppError):
    pass

class BTEnvironmentError(BTAppError):
    pass

    # foo


"""
try:
    raise BTEnvironmentError('var empty')
except EmptyKeyError as exc:
    print(exc)
except Exception:
    print('caught the problem')
"""


def decode(raw_peek):
    """
    For decoding and verifying hints.
    """

    bh = raw_hint.encode("UTF-8") # decode b64 str into bytes.
    sh = raw_sig.encode("UTF-8")  # same for sig.
    peek = gzip.decompress(base64.b64decode(bh)) # decode b64; decompress.
    # decode bytes into string
    h2, sig = hint.decode("UTF-8"), sh.decode("UTF-8")
    if verify(h2, sig):
        wrap(h2, "default")
    print(f"hint: sig failed.")


from hashlib import blake2b
from hmac import compare_digest

def sign(peek, sig):
    """
    Signed hints, for security.
    """
    sig = blake2b(key=b'pseudorandom key', digest_size=32)
    sig.update(b'peek')
    return sig.hexdigest()


def verify(peek, sig):
    """
    Verify hints.
    """
    good_sig = sign(peek, sig)
    return compare_digest(good_sig, sig)




# TODOs: 
# -------------------------------------------------------------------

# repeek        env_update, do another sig check against 'next_peek'.
#              If False, we are already dirty. repeek can be scheduled
#              separately, and can backoff after retrying N times.
#              It can also trigger a cache audit, which if fails, causes
#              a full wipe. NOTE: only do this if there are issues.


# time_increased    simple check whether an expire time
#                   has increased. Pass in the profile name 
#                   expire type (SSO, CLI, BOTO, VAULT), 
#                   and a value from the new_peek. Tells  
#                   you if it has increased. (warns if it 
#                   has decreased, which isn't normal.
 
