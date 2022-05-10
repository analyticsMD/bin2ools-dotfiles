#!/usr/bin/env python3

# Examine all credential caches and build a stateful summary object in the 
# form of a serialized class. The class, called a "PEEK", summarizes 
# authentication states for an AWS user, and account. To deter tampering, 
# the PEEK is encoded and cryptographically signed before it is sent.
# 
# With each successive command line prompt, a new PEEK is created and 
# compared it to the current.  If something changed, verify the integrty of 
# the new config.  The peek object contains NO CREDENTIALS of its own,
# beyond the fingerprint of the hash signing signatures, which are 
# regenerated with each new command prompt.
#
# Work flow: 
# ----------
# Upon detecting changes, we perform an "env_update" to syncronize all  
# local credential caches, and user shell environments.
# 
# There are two routines to converge the cache peek with what our credential
# caches report to be 'active': The first, env_sync, is built for speed. The 
# second, cache_audit, is designed to be more methodical, and does not fear 
# completely wiping the user's personal cache space if needed. 

import sys, os
import configparser, math, json, re
# datetime 
from datetime import datetime as dt
from tzlocal import get_localzone
import pytz, time
# file paths
from os import path, chdir
from os.path import join

# BT libs
from utils import *
from api import *
# for JSON schema files.
from jsmin import jsmin

#import importlib
#importlib.reload(new_obj)
from lib import new_obj

# --------------------------------------------------------------------------
# important BT environment vars.
# --------------------------------------------------------------------------
# config params
bt       = getenv("BT")
home     = getenv("HOME")
init     = getenv("BT_OS")
usr      = getenv("BT_USR")
init     = getenv("BT_INIT")
mode     = getenv("BT_MODE")
settings = getenv("BT_SETTINGS")
# chained profiles.
acct     = getenv("BT_ACCOUNT")
sso      = getenv("BT_SSO")
team     = getenv("BT_TEAM")
role     = getenv("BT_ROLE")
guild    = getenv("BT_GUILD")
# integrity checks.
sig      = getenv("BT_SIG")
hints    = getenv("BT_PEEK")

# --------------------------------------------------------------------------
# important files and paths
# --------------------------------------------------------------------------
# aws credentials template.  Used to regenerate credentials files..
creds_ini = os.path.join(bt, "config.d", "bt_creds.ini")
# BT creds file.
creds = os.path.join(home, ".aws", "bt_creds")
cache_log = os.path.join(bt, "log", "bt_cache.log")


def get_team():

    try:
        team = getenv(BT_TEAM)
    except NameError as e:
        team = "NONE"

    if team == "NONE" or team is None:
        team_cache = os.path.join(bt, "cache", "team_info")
        with open(team_cache) as tc:
            team = tc.readline().rstrip()
            if team != "NONE" and not None:
                data = new_obj("teams")
                teams = [t for t in data["teams"].keys()]
                if team in teams:
                    return team
    return None


def get_account_by_id(aws_id=None):

    try:
        account = getenv(BT_ACCOUNT)
    except NameError as e:
        team = "NONE"

    default = 351480950201
    if aws_id is None:    # return default
        return "NONE"

    data = new_obj("accounts")   # get accounts.
    aws_ids = [a for a in data["accounts"].values()]
    for id in aws_ids:
        if id == aws_id:
            name = aws_ids[id]
        return aws_id



def get_account(account=None):

    try:
        account = getenv(BT_ACCOUNT)
    except NameError as e:
        pass

    data = new_obj("accounts")
    accounts = [a for a in data["accounts"].keys()]
    if account in accounts:
        return account
    else:
        return "NONE"

# --------------------------------------------------------------------------
# configparser definitions for AWS credentials.
# --------------------------------------------------------------------------
def get_BT_configparser():

    config = configparser.ConfigParser(
        strict=False,  # merge sections from the ini file.
        default_section="bt",  # 'bt' section holds our defaults.
    )

    # read and initialize a new bt_creds ini file.
    #config.read_file(open(creds_ini))

    # 'strict=False' lets us merge like-named sections.  
    # Now we loop through each section adding only what's 
    # relevant to the latest peek.
    #config.read_file(open(creds))

    return config


# lib
#config = get_BT_configparser()


# SSO cache
# ---------
# In a perfect world we would model each cache as a separate class with
# its own abstract parent, and the cache peek would be a composite.
# Maybe later there will be time for that.

def get_caches():
    """
    Cache files are distinct per account, and chain position.
    Retrieve cache data from a designated cache file.

   Returns:
        A json object with cache data. Certain chain positions
        have their own designated caches. This will converge, eventually.
    """

    # find the appropriate cache dir.
    rgx = r'([a-fA-F0-9]{40})\.json$'
    for cache_dir in ["sso", "cli"]:
        cache_path = os.path.join(home, ".aws", f"{cache_dir}", "cache")
        cache_file = [f for f in os.listdir(cache_path) if re.search(rgx, f)]
        if len(cache_file) < 1:
            continue
        try:
            f = open(os.path.join(cache_path, cache_file[0]))
        except IOError as e:
            print(f'error {e}')
        else:
            with f:
                this_cache = json.load(f)
                return this_cache


    """ Caches have a "service_type", and a "regex_pattern".
        The services are short strings (keys), and the regexes
        represent the file names for each cache.

                Cache name       Regex
                vvvvvvvvvv       vvvvv
    """
    cache[name] = {  "sso"  :    r'([a-fA-F0-9]{40})\.json$',   # regexes
                    "boto"  :    r'boto.*',                     # 
                     "cli"  :    r'([a-fA-F0-9]{40})\.json$'    }

    #                       |                                   # 
    # sso cache name        |   # regex                         # 
    # ----------------------------------------------------------- 
    caches['sso']['rgx' ]   =   r'([a-fA-F0-9]{40})\.json$'
    caches['sso']['path']   =   os.path.join(home, ".aws", cache['name'], "cache")
    caches['sso']['files']  =   [f for f in os.listdir(caches['sso']['path'])
                                if re.search(caches['sso']['rgx'] , f)]
    #                       |   # ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^  ^   
    #                       |   # list of matching files.
    #                       |   
    # cli cache name        |   # regex 
    # ----------------------------------------------------------- 
    caches['cli']['rgx']    =   r'([a-fA-F0-9]{40})\.json$'
    caches['cli']['path']   =   os.path.join(home, ".aws", cache['name'], "cache")
    caches['cli']['files']  =   [f for f in os.listdir(caches['cli']['path'])
                                if re.search(caches['cli']['rgx'] , f)]
    #                       |   
    # boto cache name       |   # regex 
    # ----------------------------------------------------------- 
    caches['boto']['rgx']    =   r'(boto.*)\.json$'
    caches['boto']['path']   =   os.path.join(home, ".aws", cache['name'], "cache")
    caches['boto']['files']  =   [f for f in os.listdir(caches['sso']['path'])
                                 if re.search(caches['cli']['rgx'] , f)]

    # NOTE: we make this a generator, since more
    # cache types may be added in the future.
    for k in ['boto', 'sso', 'cli']:
        if len(caches[k]['files']) < 1:
            print("{k}: not available.\n")
            continue

        # take only the first of each.
        for c in range(len(caches[k]['path'])):
            path = caches[k]['path'][c]
            try:
                f = open(path)
                #except (IOError, Error) as e:
                #print(f"{k}: not available.\n")
            except: # catch *all* exceptions
                e = sys.exc_info()[0]
            else:
                with f:
                    this_cache = json.load(f)
                    yield this_cache
                    #return

    else:
        return None


def get_latest_peek():
    global fmts, config, peek, idx

    peek =     new_obj("peek")       # get new peek.
    accounts = new_obj("accounts")   # get accounts.
    idx = peek["chains"]["default"]  # load chain profiles
    expire_idx = peek["expires"]     # load expires
    config = get_BT_configparser()   # parse 1st cache 
    fmts = [ "%Y-%m-%d %H:%M:%S",    # load time formats
             "%Y-%m-%dT%H:%M:%SZ",
             "%Y-%m-%dT%H:%M:%SUTC" ]

    for section in config.sections():
        SEC, sec = section.upper(), section.lower()

        try:
            idx.index(sec)            # load chain position.
        except ValueError as e:       # not a chained profile.
            continue

        idx = peek["chains"]["default"]  # load chain profiles
        pos = int(idx.index(sec))        # chain position.

        local_tz = get_localzone()       # local tz

        utc_now = dt.utcnow().timestamp()         # utcnow timestamp

        # one of the non-primary caches is active.
        caches = get_caches()
        if pos == 0 and cache is not None:
            dt_str = cache["expiresAt"] if ("expiresAt" in cache) else utc_now
            dt_str = cache["Expiration"] if ("Expiration" in cache) else utc_now
            fmt = fmts[2]

        if config.get(sec, "expiration"):
            dt_str, fmt = config.get(sec, "expiration"), fmts[0]

            # now
            epoch_unaware = dt.fromtimestamp(utc_now) # epoch date_obj 
            epoch_aware = (epoch_unaware              # epoch date_obj 
                          .replace(tzinfo=pytz.utc)
                          .astimezone(pytz.utc))      # (tz aware) 

            # this chain position's expire time
            for fmt in fmts:
                try:
                    dt_unaware = dt.strptime(dt_str, fmt)
                except ValueError as e:
                    continue                          # got date_obj 

            dt_aware = (dt_unaware
                       .replace(tzinfo=local_tz)
                       .astimezone(local_tz))         # (tz aware)

            seconds_to_exp = (dt_aware - epoch_aware).total_seconds()
            if seconds_to_exp > 1:
                # Expire time is in the future. Add it.
                peek["expires"][idx.index(sec)] = int(epoch_aware.timestamp()) + int(seconds_to_exp)

            # BT uses preconfigured, chained profiles in fixed positions 
            # to simplify multi-account navigation.  A 'chain position' 
            # is a well-defined step in a standardized role chain, each 
            # step must be authenticated before the next can be accessed.  
            # We return the number of the chain position. This is 
            # the index used to select a profile name.  To summarize
            # the authentication state of the chain, we use a string 
            # like a bitfield.

            zeros = "0" * len(idx)
            bitfield = list(zeros)
            for pos in range(len(idx)-1):
                if expire_idx[pos] > 1:
                    bitfield[pos] = "1"
                    continue
                bitfield[pos] = "0"
            peek["assert"] = ''.join(bitfield)

            # By convention the 'team' chain position
            # is always the name of the user's team.
            team = get_team()
            account = get_account("prod") # returns default

            if pos == 2 and account is not None:
                pass

 
                # AWS_ID is the users tmp id. We return 'NOTSEEN' if hidden, or not set.
                peek["aws_ids"][idx.index(sec)] =  config.get(sec, "aws_access_key_id")

                # tokens -- Retrieve a fingerprint of each credential.
                peek["tokens"][idx.index(sec)] = f'{config.get(sec, "aws_session_token")[-7:]}'

                peek["profiles"][idx.index("sso")] = team
                peek["profiles"][idx.index("team")] = f"aws_team_{team}"
                peek["profiles"][idx.index("role")] = f"{account}-{team}"
                if pos in range(1, len(idx)-1):
                    # For other chain positions, we parse the
                    # role name from awsume, or if not present, we fall back 
                    # to building from rules based on the user's target account, 
                    # the default account, and team name. 
                    words = config.get(sec, "awsumepy_command").split()
                    profile = [w for w in words if not w.startswith('-') and w not in idx][0]
                    peek["profiles"][idx.index(sec)] = profile

    return json.dumps(peek)

#get_latest_peek()
