#!/usr/bin/env python3

# Mini ini-file  parser
# ---------------------
# Writes a sourceable bash array.

# for maintaining JSON schema files with comments.
# ----------------------------------------------------
# For defining paths to creds files, json definitions,
# and cache files used for maintaining internal cached
# states in BT.
# ----------------------------------------------------

import sys, os
from os import path, chdir, getenv
from os.path import join
# import pandas as pd

# for maintaining JSON schema files with comments.
# ----------------------------------------------------
from os import getenv
from json import *
from jsmin import jsmin
import re, math

# jsonified tabular config structures.
# import pandas dataframes
# ----------------------------------------------------
# BT shared libs for python.
# ----------------------------------------------------
import configparser

# ----------------------------------------------------
# For shared datetime manipulations
# ----------------------------------------------------
from datetime import datetime as dt
from tzlocal import get_localzone
import pytz


# Useful.  Function that maps undeclared ini options.
#
def ConfigSectionMap(section):

    dict1 = {}
    options = Config.options(section)
    for option in options:
        try:
            dict1[option] = Config.get(section, option)
            if dict1[option] == -1:
                DebugPrint("skip: %s" % option)
        except:
            print("exception on %s!" % option)
            dict1[option] = None
    return dict1


bt = getenv("BT")
data_path = path.join(bt, "data", "json", "bt")

# JSON files that provide definitions.
# Instantiate a new python object from json..
# -------------------------------------------
# usage:         peek  = new_obj("peek")
#                chain = new_obj("chain")
#                accounts = new_obj("accounts")
# -------------------------------------------
# definitions:   ${BT}/data/json/bt/peek.json
#                ${BT}/data/json/bt/chain.json
#                ${BT}/data/json/bt/accounts.json


def new_obj(obj_name=str):
    dp = os.path.join(data_path, f"{obj_name}.json")
    with open(dp) as j:
        return loads(jsmin(j.read()))


# TODO:
# -----
# import pandas
#
# guilds_df = pd.DataFrame(
#    data=guild_types,
#    columns=[‘perms’, ‘members’, 'profiles']
# )

# TODO: make separate 'dumps' routine for writing
#       python object data back to the string.

# TODO: export the object into the global namespace.
#
# TODO: Add dataframe objects for arr, so we can
#       eliminate bash arrays (for zsh compatibility).


# ----------------------------------------------------
# important BT environment vars.
# ----------------------------------------------------
# config params
bt       = getenv("BT")
home     = getenv("HOME")
init     = getenv("BT_OS")
usr      = getenv("BT_USR")
init     = getenv("BT_INIT")
mode     = getenv("BT_MODE")
settings = getenv("BT_SETTINGS")

# session types.
sso      = getenv("BT_SSO")
team     = getenv("BT_TEAM")
role     = getenv("BT_ROLE")
guild    = getenv("BT_GUILD")

# integrity checks.
#sig      = getenv("BT_SIG")
#hints    = getenv("BT_PEEK")

# ----------------------------------------------------
# important files and paths
# ----------------------------------------------------
def focus():
    """
    Change focus on the current chain.  Reloads the active
    credential associated with a fixed chain position into 
    the ENV.
    """
    pass


def env_sync(INTEGRITY_CHECKS):
    """
    env_sync - fast cache integrity checks.
    ---------------------------------------------------------------------------
    Unlike the more rigorous cache_audit, env_sync is made for speed. It
    is run with each prompt refresh, and looks for integrity problems
    that can be corrected without session calls to AWS.

    Deserializes and loads 'this_peek' object from ENV, for comparison.
    Performs an integrity check for 'next_peek' cache state.  On
    success, calls env_update and passes in the 'next_peek' so it can
    become 'this_peek'.

    -- merges and reconciles next_peek with this_peek in a
       predefined order.  If it finds irreconcilable problems, it will
       abort and run a cache_audit instead.

    -- Runs fix routines if needed. Logs the findings and results.
       awsume -a <pos> -o qventus
       assume -s | eval.
    """
    pass

#    # Make a dict of 'integrity' functions 
#    # to pass around and loop through.  Quite handy...
#    #
#    for func in INTEGRITY_CHECKS:
#        try:
#            INTEGRITY_CHECKS['func'](action, msg)
#        except BTAppError(Exception) as e:
#            pass  # TODO: Fail if no settings?
#
#            #raise:
#                # reraise exceptions to capture in logging.
#                #BTIntegrityCheckError
#                #pass
#
#    # log everything in env_sync and cache_audit.
#    logging.basicConfig(level=logging.INFO,
#                        filename=cache_log,
#                        format=(f'%(asctime)s'
#                                f'%(levelname)s:'
#                                f'%(message)s'))
#
#
#
#    try:
#        raw_peek = os.environ["BT_HINTS"]
#        raw_sig  = os.environ["BT_SIG"]
#    except KeyError as e:
#        logging.error(f"failed to get json object: raw_peek")
#    #raise BTConfigError('Env Var {} is not set'.format(e.args[0]))
#        #logging.error("error reading the file")
#
#
#    # chain: [ "sso", "team", "role", "guild" ]
#    """
#    chain = jq.one(".chains.default", peek)
#
#    """
#    # account: { "prod": "351480950201" }
#    """
#    account = int(jq.one(".account.default", peek))
#
#    mask = jq.one(".assert", peek)
#    expires = jq.one(".expires", peek)
#    user_pos = jq.one('.position.default', peek)
#    token, id = jq.one(".hints.{pos}").split("_")
#    jq_str = f"""'.account | with_entries(select(key == ([.{account_id}])")).key'"""
#    hint = jq.one(f"{jq_str}", this_peek)
#
#    # test 1: validate current login position.
#    position  = chain[get_position(new_peek)] # chain position, e.g. 2
#    profile = jq.one(f".profiles.{position}", new_peek) # profile name
#    account = int(jq.one(".account.default", new_peek)) # aws_account_id
#    expire = jq.one(f".expires[{position}]", new_peek) # seconds to expire
#
#    # test 2: validate position, account
#    if ( 0 <= position <= 3                     and
#         position <= get_highest_active_session and 
#         account == 351480950201                and 
#         is_active(expire)
#       )
#        pass
#     # -- validate active profiles 
#
#    if verify_assert(peek, profile, position):
#        logging.info(f"assert ok: new_peek: profile: {profile}, position: {position}")
#    else:
#        logging.error(f"assert invalid: new_peek: profile: {profile}, position: {position}")
#
#     # 1.) lookup active profiles by name. return list. (compare to previous)
#     # 2.) return designated active profile. compare to 'this_peek'. (compare to previous)
#     #      If user data not avail, use default active profile.
#     # 3.) return list of changes to expires in active profiles (0 is good; otherwise cache_audit.) 
#     # 4.) return list of POS id or token changes in active slots (0 is good. otherwise, cache_audit))
#     # 5.) positions (i.e. user asserted session)
#     # 6.) changes to profile names (name of role, and guild,e.g.)
#
#    # OK CHANGES: 
#    #- recorded change in a positional profile, i.e. 
#    #- qventus creds should reflect current profile. 
#    #- Timeout should reflect current profile (check). 
#    #- exists in assert
#    #- expire is further out 
#    #- asserted position is present
#    #- profile name changed.
#    #- credentials changed (old peek -> new peek) 
#    #- cache_merge checks integrity
#
#    # exceptions to fix: 
#    #- qventus id, expire, or creds do not reflect current profile. 
#    #- stale expires exist; expired assertions exist. (rebuild file).
#    #- account changed in new  
#    #    (action: update env, regen accountfile ).
#
#    # Invalidators: Tests that would cause an abortion if creds failed. 
#    #- assert mask changed, but no token or expire changes. 
#    #  account_id changed, but no position changed. 
#    #- change in profile assertion (or account) but no change 
#    #  in corresponding expires, id, or token.
#    #  (found by comparing environments and hints.)
#    #- expires missing for asserted profiles. 
#    #- no new id or token for asserted profiles. 
#
#    # log entry: 
#    #peek = get_peek()  
#
#       -- qventus creds current? If not, refresh. 
#       -- bt_config and bt_creds ok?  If not regen. 
#    """
#
#    #raise BTEnvironmentError('Env variable {} not set'.format(e.args[0]))
#        # get all chain profiles.
#        chain_profs = jq.one(".chains.default", peek)
#
#        for cp.upper in chain_profs:
#            try:
#                cp = os.environ.get(f"BT_{cp()}", 'NONE') 
#            except KeyError:
#                'BT_SSO', 'BT_TEAM', 'BT_ROLE', 'BT_GUILD'  = ( 
#                    os.environ[f"BT_{chain_profile.upper()}"], 'NONE'),
#                    os.environ[f"BT_{chain_profile.upper()}"], 'NONE'),
#                    os.environ[f"BT_{chain_profile.upper()}"], 'NONE'),
#                    os.environ[f"BT_{chain_profile.upper()}"], 'NONE')
#                )
#            #raise KeyError(key) from None
#                pass
#
#    expires = jq.one(".expires", peek)
#
#    if verify_active_session():
#        env_update
#        return
#    else:
#        env_audit
#    return
#}

