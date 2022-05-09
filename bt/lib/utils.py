#!/usr/bin/env python3

# ----------------------------------------------------------------------------
# utils.py
# ----------------------------------------------------------------------------
# A set of functions for testing the integrity of 
# BT data objects.

# ----------------------------------------------------------------------------
# BT shared libs for python.
# ----------------------------------------------------------------------------
import configparser          # ini manipulation
import json                  # json manipulation
import pyjq as jq            # json manipulation
import gzip, base64, hashlib # crypto.
import re, math
import logging

# ----------------------------------------------------------------------------
# For shared datetime manipulations
# ----------------------------------------------------------------------------
from datetime import datetime as dt
from tzlocal import get_localzone
import pytz
import time

# ----------------------------------------------------------------------------
# For defining paths to creds files, json definitions, and cache files
# used for maintaining internal cached states in BT.
# ----------------------------------------------------------------------------
import sys, os
from os import path, chdir, getenv
from os.path import join

#from cache import generate_peek

# Is this session active?
def is_active(dt_str):
    """
    Takes either epoch timestamp OR a date string.

    Converts a single datetime string into UTC-aware datetime object
    for all session types. Must be localtime aware to perform the proper
    delta in UTC, then convert back to a local timezone for display.
    """
    local_tz = get_localzone()

    fmts = [
     '%Y-%m-%d %H:%M:%S',
     '%Y-%m-%dT%H:%M:%SZ',
     '%Y-%m-%dT%H:%M:%SUTC'
    ]

    #dt_str = '2021-12-31 04:41:52'

    for fmt in fmts:
        try:
            print(f"Retrying for proper format...")
            # try various conversions until a one works.
            dt_naive = dt.strptime(dt_str, fmt)
            dt_aware = dt_naive.replace(tzinfo=local_tz).astimezone(pytz.utc)

        except (ValueError) as e:
            print(f"Bad time format: {fmt}. Retrying...")
            continue

        except (Exception) as e:
            print(f"Using epoch time: {dt_str}")
            ts = int(time.mktime(dt.strptime(dt_str, fmts[0]).timetuple()))
            dt_aware = dt.utcfromtimestamp(ts).replace(tzinfo=pytz.utc).astimezone(local_tz)

        #else:
        #    #print(f"WARNING: No parseable time format for {dt_str}.")
        #    raise BTParseError(f"Data: {e.args[0]}")
        #    logging.error(f"error parsing datetime data.")

        finally:
            # Procedure:
            # ----------
            # 1.) Convert all input to UTC datetime objects (timezone unaware). 
            # 2.) Try multiple formats until a valid one is found.
            # 3.) Add tz awareness for all datetimes.
            # 4.) Perform calculations, diffs, etc.
            # 5.) Convert to local tz for display.
            for fmt in fmts:
                try:
                    dt_naive = dt.strptime(dt_str, fmt)
                except Exception as e:
                    print(f"exception: {e}")
                    continue

            dt_aware = dt_naive.replace(tzinfo=local_tz).astimezone(pytz.utc)

            # now in UTC
            now_naive  = dt.strptime(dt.utcnow().strftime(fmt), fmt)
            # utc -> local
            now_aware = now_naive.replace(tzinfo=pytz.utc).astimezone(pytz.utc)
            #assert local_now.replace(tzinfo=None) == now

            if dt_aware > now_aware:
                print(f"d/dt: {(dt_aware - now_aware).total_seconds()}")
            return int((dt_aware - now_aware).total_seconds())


# --------------------------------------------------------------
# Hint encoding and decoding utils
# --------------------------------------------------------------

