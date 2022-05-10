#!/usr/bin/env python3

# --------------------------------------------------------
# bt_export.py
# --------------------------------------------------------
# Manages cache coherency.
#
# BT libraries
from api import bt_export
from cache import get_latest_peek
import gzip, base64, hashlib # crypto.

peek = get_latest_peek()
#print(f"this: {peek}")
encoded = bt_export(peek)
if encoded == None: 
    pass
else:
    print(f"{encoded}")
